import json
import os
import argparse
import torch

from tqdm import tqdm
from collections import defaultdict
from transformers import AutoTokenizer, AutoModelForCausalLM
from torch.nn import CrossEntropyLoss
from tuned_lens import TunedLens

import nnsight
from nnsight import NNsight
import cProfile, pstats, io
from pstats import SortKey

from config import HUFFINGFACE_KEY

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
    tokenizer = AutoTokenizer.from_pretrained(args.model, cache_dir=args.cache)
    tokenizer.pad_token = tokenizer.eos_token

    path = f"results/{args.method}/{args.data}/{os.path.basename(args.model)}"
    os.makedirs(path, exist_ok=True)

    if args.quantize == "4bit":
        gpt2_model = AutoModelForCausalLM.from_pretrained(args.model, token=access_token, load_in_4bit=True,
                                                          cache_dir=args.cache)
        gpt2_model.eval()
    elif args.quantize == "8bit":
        gpt2_model = AutoModelForCausalLM.from_pretrained(args.model, token=access_token, load_in_8bit=True,
                                                          cache_dir=args.cache)
        gpt2_model.eval()
    else:
        gpt2_model = AutoModelForCausalLM.from_pretrained(args.model, token=access_token, cache_dir=args.cache)
        gpt2_model.to(device).eval()

    loss_fct = CrossEntropyLoss(ignore_index=-100, reduction="none")
    bos_string = tokenizer.decode(gpt2_model.config.bos_token_id)

    article2surprisals = defaultdict(lambda: defaultdict(list))

    if args.trial:
        article2tokens = {k: v for k, v in list(article2tokens.items())[:1]}

    eps = 1e-8

    print(args.model)

    ##NNsight START

    model = NNsight(gpt2_model)

    pr = cProfile.Profile()
    pr.enable()
    for article_id, sents in article2tokens.items():
        print(article_id)
        for i in tqdm(range(0, len(sents), args.batchsize)):
            batch_sents = sents[i:i + args.batchsize]
            tok_lss = []
            for sent in batch_sents:
                tok_ls = [len(tokenizer(" " + tok, return_tensors="pt", add_special_tokens=False)["input_ids"][0]) for
                          tok in sent]
                tok_lss.append(tok_ls)
            encoded_sents = \
                tokenizer([bos_string + " " + " ".join(sent) for sent in batch_sents], return_tensors="pt",
                          padding=True,
                          add_special_tokens=False)["input_ids"].to(device)
            target_ids = encoded_sents[:, 1:].to(device)

            layer_logits = []
            with model.trace(encoded_sents[:, :-1]) as tracer:
                for layer_id, layer in enumerate(['token'] + list(model.transformer.h)):
                    if layer == 'token':
                        token_embd = model.transformer.wte.output + model.transformer.wpe.output
                        layer_logit = model.lm_head(model.transformer.ln_f(token_embd))
                    else:
                        layer_logit = model.lm_head(model.transformer.ln_f(layer.output[0]))
                    layer_logits.append(layer_logit.save())

            for layer_id, layer_logit in enumerate(layer_logits):
                surprisal_subwords = loss_fct(layer_logit.transpose(1, 2), target_ids) + eps

                for sent_sup_sub, tok_ls in zip(surprisal_subwords, tok_lss):
                    sent_sup_words = [sup.detach().sum().cpu().numpy().tolist() for _, sup in zip(tok_ls,
                                    torch.tensor_split(sent_sup_sub,torch.cumsum(torch.tensor(tok_ls), dim=0)))]
                    article2surprisals[layer_id][article_id].append(sent_sup_words)
            del layer_logits
            del surprisal_subwords

        assert len(article2surprisals[0][article_id]) == len(sents)
        assert len([surprisal for sent_surprisals in article2surprisals[0][article_id] for surprisal in
                    sent_surprisals]) == len([tok for sent in sents for tok in sent])

    pr.disable()
    s = io.StringIO()
    sortby = SortKey.CUMULATIVE
    ps = pstats.Stats(pr, stream=s).sort_stats(sortby)
    ps.print_stats()
    with open(f'results/logit-lens/{args.data}/{args.model}/measurement_nn_{args.model.replace("/","-")}_{args.data}_{args.method}.txt','w') as file:
        file.writelines(s.getvalue())

    if not args.trial:
        json.dump(article2surprisals, open(f"{path}/{args.prefix}_nn_surprisal.json", "w"))
        print(f'SUCCESSFUL RUN: {args.model} {args.data}')


if __name__ == "__main__":
    main()
