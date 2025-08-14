import json
import os
import argparse
import torch

from tqdm import tqdm
from collections import defaultdict
from transformers import AutoTokenizer, AutoModelForCausalLM
from torch.nn import CrossEntropyLoss
from tuned_lens import TunedLens

from config import HUFFINGFACE_KEY

# <ERIK CODE>
import unicodedata
# </ERIK CODE>

os.environ["TOKENIZERS_PARALLELISM"] = "false"
parser = argparse.ArgumentParser()
parser.add_argument("-m", "--model", required=True)
parser.add_argument("-b", "--batchsize", default=4, type=int)
parser.add_argument("-q", "--quantize", default="")
parser.add_argument("-d", "--data", default="DC")
parser.add_argument("--trial", action="store_true")
parser.add_argument("--method", choices=["tuned-lens", "logit-lens"], default="logit-lens")
parser.add_argument("-c", "--cache", default="~/_cache/huggingface/hub")
args = parser.parse_args()

@torch.no_grad()
def main():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    article2tokens = json.load(open(f"data/{args.data}/tokens.json"))
    # <ERIK CODE>
    # article2tokens = json.load(open(f"data/{args.data}/corrected_noaccent_tokens.json"))
    # with open(f'data/{args.data}/tokens.json', 'r', encoding='utf-8') as file:
    #     article2tokens = json.load(file)
    # with open(f"data/{args.data}/tokens.json",'r') as f:
    #     norm = unicodedata.normalize('NFKC', f.read())
    #     article2tokens = json.loads(norm)
    # </ERIK CODE>
    loss_fct = CrossEntropyLoss(ignore_index=-100, reduction="none")

    access_token = HUFFINGFACE_KEY
    tokenizer = AutoTokenizer.from_pretrained(args.model, cache_dir=args.cache)
    tokenizer.pad_token = tokenizer.eos_token

    path = f"results/{args.method}/{args.data}/{os.path.basename(args.model)}"
    os.makedirs(path, exist_ok=True)

    if args.quantize == "4bit":
        gpt2_model = AutoModelForCausalLM.from_pretrained(args.model, token=access_token, load_in_4bit=True, cache_dir=args.cache)
        gpt2_model.eval()
    elif args.quantize == "8bit":
        gpt2_model = AutoModelForCausalLM.from_pretrained(args.model, token=access_token, load_in_8bit=True, cache_dir=args.cache)
        gpt2_model.eval()
    else:
        gpt2_model = AutoModelForCausalLM.from_pretrained(args.model, token=access_token, cache_dir=args.cache)
        gpt2_model.to(device).eval() 

    if "gpt" in args.model or "falcon" in args.model:
        last_ln = gpt2_model.transformer.ln_f
        lm_head = gpt2_model.lm_head
    elif "opt" in args.model:
        last_ln = gpt2_model.model.decoder.final_layer_norm # changed
        lm_head = gpt2_model.lm_head
    elif "xglm" in args.model:
        last_ln = gpt2_model.model.layer_norm
        lm_head = gpt2_model.lm_head
    elif "pythia" in args.model:
        last_ln = gpt2_model.gpt_neox.final_layer_norm
        lm_head = gpt2_model.embed_out
    else:
        raise ValueError("model name must contain 'gpt,' 'opt,' or 'falcon'")
    loss_fct = CrossEntropyLoss(ignore_index=-100, reduction="none")
    bos_string = tokenizer.decode(gpt2_model.config.bos_token_id)
    
    article2surprisals = defaultdict(lambda: defaultdict(list))
    # article2entropies = defaultdict(lambda: defaultdict(list))
    # article2renyi_entropies = defaultdict(lambda: defaultdict(list))

    if args.trial:
        article2tokens = {k: v for k, v in list(article2tokens.items())[:1]}

    eps=1e-8
    if args.method == "tuned-lens":
        tuned_lens = TunedLens.from_model_and_pretrained(gpt2_model).to(gpt2_model.device)


    for article_id, sents in article2tokens.items():
        print(article_id)
        for i in tqdm(range(0, len(sents), args.batchsize)):
            batch_sents = sents[i:i+args.batchsize]
            tok_lss = []
            for sent in batch_sents:
                tok_ls = [len(tokenizer(" "+tok, return_tensors="pt", add_special_tokens=False)["input_ids"][0]) for tok in sent]
                tok_lss.append(tok_ls)
            encoded_sents = tokenizer([bos_string + " " + " ".join(sent) for sent in batch_sents], return_tensors="pt", padding=True, add_special_tokens=False)["input_ids"].to(device)

            # (info, layres, batchsize, input_length, hidden_size)
            outputs = gpt2_model(encoded_sents[:,:-1], output_hidden_states=True)
            gold_logit = outputs[0]

            reps = torch.stack(outputs[2]).to(gold_logit.device)
            target_ids = encoded_sents[:,1:].to(gold_logit.device)
            if args.method == "tuned-lens":
                tuned_lens = tuned_lens.to(gold_logit.device)

            del outputs

            for layer_id, layer_rep in enumerate(reps):
                if layer_id == len(reps) - 1:
                    layer_logit = lm_head(layer_rep).to(gold_logit.device)
                    assert torch.equal(layer_logit, gold_logit)
                    # ps = layer_logit.softmax(dim=-1) + eps
                    # entropy_subwords = (-ps*(ps).log2()).sum(dim=-1) # buggy
                    # renyi_entropy_subwords = (ps**0.5).sum(dim=-1).log2() # buggy
                else:
                    if args.method == "logit-lens":
                        layer_logit = lm_head(last_ln(layer_rep)).to(gold_logit.device)
                    else:
                        layer_logit = tuned_lens(layer_rep, idx=layer_id).to(gold_logit.device)
                    # ps = layer_logit.softmax(dim=-1) + eps
                    # entropy_subwords = (-ps*(ps.log2())).sum(dim=-1) + eps # buggy
                    # renyi_entropy_subwords = (ps**0.5).sum(dim=-1).log2() + eps # buggy

                surprisal_subwords = loss_fct(layer_logit.transpose(1,2), target_ids) + eps

                for sent_sup_sub, tok_ls in zip(surprisal_subwords, tok_lss):
                    sent_sup_words = [sup.detach().sum().cpu().numpy().tolist() for _, sup in zip(tok_ls, torch.tensor_split(sent_sup_sub, torch.cumsum(torch.tensor(tok_ls), dim=0)))]
                    article2surprisals[layer_id][article_id].append(sent_sup_words)

            del reps
            del surprisal_subwords
            # del entropy_subwords
            # del renyi_entropy_subwords

        assert len(article2surprisals[0][article_id]) == len(sents)
        assert len([surprisal for sent_surprisals in article2surprisals[0][article_id] for surprisal in sent_surprisals]) == len([tok for sent in sents for tok in sent])

    if not args.trial:
        json.dump(article2surprisals, open(f"{path}/surprisal.json", "w"))
        #<ERIK CODE>
        print(f'SUCCESSFUL RUN: {args.model} {args.data}')
        #</ERIK CODE>
        # json.dump(article2entropies, open(f"{path}/entropy.json", "w"))
        # json.dump(article2renyi_entropies, open(f"{path}/renyi-entropy.json", "w"))

if __name__ == "__main__":
    main()
