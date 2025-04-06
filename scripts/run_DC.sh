#!/bin/bash

python src/run_gpt2.py -m gpt2 
python src/run_gpt2.py -m gpt2-medium 
python src/run_gpt2.py -m gpt2-large
python src/run_gpt2.py -m gpt2-xl

python src/run_gpt2.py -m facebook/opt-125m
python src/run_gpt2.py -m facebook/opt-1.3b 
python src/run_gpt2.py -m facebook/opt-2.7b 
python src/run_gpt2.py -m facebook/opt-6.7b 
python src/run_gpt2.py -m facebook/opt-13b -q 8bit 
python src/run_gpt2.py -m facebook/opt-30b -q 8bit 
python src/run_gpt2.py -m facebook/opt-66b -q 4bit 

python src/run_gpt2.py -m EleutherAI/pythia-70m-deduped -d DC
python src/run_gpt2.py -m EleutherAI/pythia-160m-deduped -d DC
python src/run_gpt2.py -m EleutherAI/pythia-410m-deduped -d DC
python src/run_gpt2.py -m EleutherAI/pythia-1b-deduped -d DC
python src/run_gpt2.py -m EleutherAI/pythia-1.4b-deduped -d DC
python src/run_gpt2.py -m EleutherAI/pythia-2.8b-deduped -d DC
python src/run_gpt2.py -m EleutherAI/pythia-6.9b-deduped -d DC
python src/run_gpt2.py -m EleutherAI/pythia-12b-deduped -d DC


python src/run_gpt2.py -m gpt2 --method tuned-lens
python src/run_gpt2.py -m gpt2-large --method tuned-lens
python src/run_gpt2.py -m gpt2-xl --method tuned-lens

python src/run_gpt2.py -m facebook/opt-125m --method tuned-lens
python src/run_gpt2.py -m facebook/opt-1.3b --method tuned-lens
python src/run_gpt2.py -m facebook/opt-6.7b --method tuned-lens

python src/run_gpt2.py -m EleutherAI/pythia-70m-deduped -d DC --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-160m-deduped -d DC --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-410m-deduped -d DC --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-1b-deduped-v0 -d DC --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-1.4b-deduped -d DC --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-2.8b-deduped -d DC --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-6.9b-deduped -d DC --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-12b-deduped -d DC --method tuned-lens -q 8bit