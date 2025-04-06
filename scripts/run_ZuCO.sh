#!/bin/bash

python src/run_gpt2.py -m gpt2 -d ZuCO
python src/run_gpt2.py -m gpt2-medium -d ZuCO
python src/run_gpt2.py -m gpt2-large -b 2 -d ZuCO
python src/run_gpt2.py -m gpt2-xl -b 2 -d ZuCO

python src/run_gpt2.py -m facebook/opt-125m -d ZuCO
python src/run_gpt2.py -m facebook/opt-1.3b -d ZuCO
python src/run_gpt2.py -m facebook/opt-2.7b -d ZuCO
python src/run_gpt2.py -m facebook/opt-6.7b -d ZuCO
python src/run_gpt2.py -m facebook/opt-13b -q 8bit -d ZuCO
python src/run_gpt2.py -m facebook/opt-30b -q 8bit -d ZuCO
python src/run_gpt2.py -m facebook/opt-66b -q 4bit -d ZuCO

python src/run_gpt2.py -m EleutherAI/pythia-70m-deduped -d ZuCO
python src/run_gpt2.py -m EleutherAI/pythia-160m-deduped -d ZuCO
python src/run_gpt2.py -m EleutherAI/pythia-410m-deduped -d ZuCO
python src/run_gpt2.py -m EleutherAI/pythia-1b-deduped-v0 -d ZuCO
python src/run_gpt2.py -m EleutherAI/pythia-1.4b-deduped -d ZuCO
python src/run_gpt2.py -m EleutherAI/pythia-2.8b-deduped -d ZuCO
python src/run_gpt2.py -m EleutherAI/pythia-6.9b-deduped -d ZuCO -q 8bit
python src/run_gpt2.py -m EleutherAI/pythia-12b-deduped -d ZuCO -q 8bit


python src/run_gpt2.py -m gpt2 -d ZuCO --method tuned-lens
python src/run_gpt2.py -m gpt2-large -d ZuCO --method tuned-lens
python src/run_gpt2.py -m gpt2-xl -d ZuCO --method tuned-lens

python src/run_gpt2.py -m facebook/opt-125m -d ZuCO --method tuned-lens
python src/run_gpt2.py -m facebook/opt-1.3b -d ZuCO --method tuned-lens
python src/run_gpt2.py -m facebook/opt-6.7b -d ZuCO --method tuned-lens

python src/run_gpt2.py -m EleutherAI/pythia-70m-deduped -d ZuCO --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-160m-deduped -d ZuCO --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-410m-deduped -d ZuCO --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-1b-deduped-v0 -d ZuCO --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-1.4b-deduped -d ZuCO --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-2.8b-deduped -d ZuCO --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-6.9b-deduped -d ZuCO --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-12b-deduped -d ZuCO --method tuned-lens -q 8bit