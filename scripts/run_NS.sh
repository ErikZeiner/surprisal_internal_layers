#!/bin/bash

python src/run_gpt2.py -m gpt2 -d NS
python src/run_gpt2.py -m gpt2-medium -d NS
python src/run_gpt2.py -m gpt2-large -b 2 -d NS
python src/run_gpt2.py -m gpt2-xl -b 2 -d NS

python src/run_gpt2.py -m facebook/opt-125m -d NS
python src/run_gpt2.py -m facebook/opt-1.3b -d NS
python src/run_gpt2.py -m facebook/opt-2.7b -d NS
python src/run_gpt2.py -m facebook/opt-6.7b -d NS
python src/run_gpt2.py -m facebook/opt-13b -q 8bit -d NS
python src/run_gpt2.py -m facebook/opt-30b -q 8bit -d NS
python src/run_gpt2.py -m facebook/opt-66b -q 4bit -d NS

python src/run_gpt2.py -m EleutherAI/pythia-70m-deduped -d NS
python src/run_gpt2.py -m EleutherAI/pythia-160m-deduped -d NS
python src/run_gpt2.py -m EleutherAI/pythia-410m-deduped -d NS
python src/run_gpt2.py -m EleutherAI/pythia-1b-deduped -d NS
python src/run_gpt2.py -m EleutherAI/pythia-1.4b-deduped -d NS
python src/run_gpt2.py -m EleutherAI/pythia-2.8b-deduped -d NS
python src/run_gpt2.py -m EleutherAI/pythia-6.9b-deduped -d NS
python src/run_gpt2.py -m EleutherAI/pythia-12b-deduped -d NS


python src/run_gpt2.py -m gpt2 -d NS --method tuned-lens
python src/run_gpt2.py -m gpt2-large -d NS --method tuned-lens
python src/run_gpt2.py -m gpt2-xl -d NS --method tuned-lens

python src/run_gpt2.py -m facebook/opt-125m -d NS --method tuned-lens
python src/run_gpt2.py -m facebook/opt-1.3b -d NS --method tuned-lens
python src/run_gpt2.py -m facebook/opt-6.7b -d NS --method tuned-lens

python src/run_gpt2.py -m EleutherAI/pythia-70m-deduped -d NS --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-160m-deduped -d NS --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-410m-deduped -d NS --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-1b-deduped-v0 -d NS --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-1.4b-deduped -d NS --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-2.8b-deduped -d NS --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-6.9b-deduped -d NS --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-12b-deduped -d NS --method tuned-lens -q 8bit