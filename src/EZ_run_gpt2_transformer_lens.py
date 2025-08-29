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

from torch.nn.utils.rnn import pad_sequence
from transformer_lens import HookedTransformer
import cProfile, pstats, io
from pstats import SortKey

os.environ["TOKENIZERS_PARALLELISM"] = "false"
parser = argparse.ArgumentParser()
parser.add_argument("-m", "--model", required=True)
parser.add_argument("-b", "--batchsize", default=4, type=int)
parser.add_argument("-q", "--quantize", default="")
parser.add_argument("-d", "--data", default="DC")
parser.add_argument("--trial", action="store_true")
parser.add_argument("--method", choices=["tuned-lens", "logit-lens"], default="logit-lens")
parser.add_argument("-c", "--cache", default="~/_cache/huggingface/hub")
parser.add_argument("--prefix",default="")
args = parser.parse_args()

@torch.no_grad()
def main():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    article2tokens = json.load(open(f"data/{args.data}/tokens.json"))

    access_token = HUFFINGFACE_KEY
    # hf_tokenizer = AutoTokenizer.from_pretrained(args.model, cache_dir=args.cache)
    # hf_tokenizer.pad_token = hf_tokenizer.eos_token

    path = f"results/{args.method}/{args.data}/{os.path.basename(args.model)}"
    os.makedirs(path, exist_ok=True)

    # hf_model = AutoModelForCausalLM.from_pretrained(args.model, token=access_token, cache_dir=args.cache)
    # hf_model.to(device).eval()
    gpt2_model = HookedTransformer.from_pretrained(args.model, device=device,cache_dir=args.cache,fold_ln=False,
    center_writing_weights=False,
    center_unembed=False)
    gpt2_model.eval()

    tokenizer = gpt2_model.tokenizer
    tokenizer.pad_token = tokenizer.eos_token

    loss_fct = CrossEntropyLoss(ignore_index=-100, reduction="none")
    # bos_string = hf_tokenizer.decode(hf_model.config.bos_token_id)
    # bos_string = tokenizer.decode(gpt2_model.config.bos_token_id)
    bos_string = tokenizer.decode(tokenizer.bos_token_id)
    
    article2surprisals = defaultdict(lambda: defaultdict(list))
    # article2entropies = defaultdict(lambda: defaultdict(list))
    # article2renyi_entropies = defaultdict(lambda: defaultdict(list))

    if args.trial:
        article2tokens = {k: v for k, v in list(article2tokens.items())[:1]}

    eps=1e-8

    print(args.model)


    pr = cProfile.Profile()
    pr.enable()
    for article_id, sents in article2tokens.items():
        print(article_id)
        for i in tqdm(range(0, len(sents), args.batchsize)):
            batch_sents = sents[i:i+args.batchsize]
            tok_lss = []
            for sent in batch_sents:
                tok_ls = [gpt2_model.to_tokens(" " + tok, prepend_bos=False).shape[1] for tok in sent]
                tok_lss.append(tok_ls)

            batch_strings = [bos_string + " " + " ".join(sent) for sent in batch_sents]
            tokenized = [gpt2_model.to_tokens(s, prepend_bos=False)[0] for s in batch_strings]

            pad_id = gpt2_model.tokenizer.pad_token_id or gpt2_model.tokenizer.eos_token_id
            encoded_sents = pad_sequence(tokenized, batch_first=True, padding_value=pad_id).to(device)


            logits, cache = gpt2_model.run_with_cache(encoded_sents[:,:-1])
            gold_logit = logits[:, :-1, :]

            layer_reps = torch.cat([(cache["embed"] + cache["pos_embed"]).unsqueeze(0), cache.stack_activation("resid_post")],dim=0)  # (num_layers+1, batch, seq, d_model)
            target_ids = encoded_sents[:, 1:].to(gold_logit.device)
            layer_logits = torch.einsum("l b s d, d v -> l b s v", gpt2_model.ln_final(layer_reps), gpt2_model.unembed.W_U) + gpt2_model.unembed.b_U

            for layer_id, layer_logit in enumerate(layer_logits):
                surprisal_subwords = loss_fct(layer_logit.transpose(1,2), target_ids) + eps

                for sent_sup_sub, tok_ls in zip(surprisal_subwords, tok_lss):
                    sent_sup_words = [sup.detach().sum().cpu().numpy().tolist() for _, sup in zip(tok_ls, torch.tensor_split(sent_sup_sub, torch.cumsum(torch.tensor(tok_ls), dim=0)))]
                    article2surprisals[layer_id][article_id].append(sent_sup_words)

            del layer_reps,layer_logits
            del surprisal_subwords
            # del entropy_subwords
            # del renyi_entropy_subwords

        assert len(article2surprisals[0][article_id]) == len(sents)
        assert len([surprisal for sent_surprisals in article2surprisals[0][article_id] for surprisal in sent_surprisals]) == len([tok for sent in sents for tok in sent])

    pr.disable()
    s = io.StringIO()
    sortby = SortKey.CUMULATIVE
    ps = pstats.Stats(pr, stream=s).sort_stats(sortby)
    ps.print_stats()
    out_dir = f'results/logit-lens/{args.data}/{args.model}/'
    os.makedirs(out_dir, exist_ok=True)

    with open(os.path.join(out_dir, f'measurement_tl_{args.model.replace("/","-")}_{args.data}_{args.method}.txt'), 'w') as file:
        file.writelines(s.getvalue())

    if not args.trial:
        json.dump(article2surprisals, open(f"{path}/{args.prefix}_tl_surprisal.json", "w"))
        print(f'SUCCESSFUL RUN: {args.model} {args.data}')

        # json.dump(article2entropies, open(f"{path}/entropy.json", "w"))
        # json.dump(article2renyi_entropies, open(f"{path}/renyi-entropy.json", "w"))

if __name__ == "__main__":
    main()
