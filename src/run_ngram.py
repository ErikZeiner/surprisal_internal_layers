import json
import torch
import os
import argparse
import numpy as np
from tqdm import tqdm
from collections import defaultdict
from surprisal import KenLMModel
from transformers import AutoTokenizer

os.environ["TOKENIZERS_PARALLELISM"] = "false"
parser = argparse.ArgumentParser()
parser.add_argument("-m", "--model", required=True)
parser.add_argument("-t", "--tokenizer", default="gpt2")
parser.add_argument("-d", "--data", default="DC")
args = parser.parse_args()

@torch.no_grad()
def main():
    tokenizer = AutoTokenizer.from_pretrained(args.tokenizer)
    tokenizer.pad_token = tokenizer.eos_token

    article2tokens = json.load(open(f"data/{args.data}/tokens.json"))
    path = f"results/ngram/{args.data}/{os.path.basename(args.model)}"
    os.makedirs(path, exist_ok=True)
    
    article2surprisals = defaultdict(list)


    print(args.model)
    ngram_lm = KenLMModel(model_path=args.model)
    for article_id, sents in article2tokens.items():
        print(article_id)
        for sent in sents:
            word_length = [len(tokenizer.tokenize(t, padding=True, add_special_tokens=False)) if i == 0 else len(tokenizer.tokenize(" "+t, padding=True, add_special_tokens=False)) for i, t in enumerate(sent)]
            sent = " ".join(tokenizer.tokenize(" ".join(sent), padding=True, add_special_tokens=False))
            surprisals = ngram_lm.surprise(sent)[0].surprisals.tolist()
            i=0
            word_surprisals = []
            for l in word_length:
                word_surprisals.append(sum(surprisals[i:i+l]))
                i+=l
            article2surprisals[article_id].append(word_surprisals)

        
        assert len(article2surprisals[article_id]) == len(sents)
        assert len([surprisal for sent_surprisals in article2surprisals[article_id] for surprisal in sent_surprisals]) == len([tok for sent in sents for tok in sent])
    json.dump(article2surprisals, open(f"{path}/surprisal.json", "w"))

if __name__ == "__main__":
    main()
