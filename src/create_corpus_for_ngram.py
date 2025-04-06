from transformers import AutoTokenizer
import sys
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("-m", "--model", required=True)
args = parser.parse_args()

tokenizer = AutoTokenizer.from_pretrained(args.model)
tokenizer.pad_token = tokenizer.eos_token

for line in sys.stdin:
    line = line.strip()
    if line:
        print(" ".join(tokenizer.tokenize(line, padding=True, add_special_tokens=False)))
