#!/bin/bash


python src/run_gpt2.py -m gpt2 -d UCL
python src/run_gpt2.py -m gpt2-medium -d UCL
python src/run_gpt2.py -m gpt2-large -b 2 -d UCL
python src/run_gpt2.py -m gpt2-xl -b 2 -d UCL

python src/run_gpt2.py -m facebook/opt-125m -d UCL
python src/run_gpt2.py -m facebook/opt-1.3b -d UCL
python src/run_gpt2.py -m facebook/opt-2.7b -d UCL
python src/run_gpt2.py -m facebook/opt-6.7b -d UCL
python src/run_gpt2.py -m facebook/opt-13b -q 8bit -d UCL
python src/run_gpt2.py -m facebook/opt-30b -q 8bit -d UCL
python src/run_gpt2.py -m facebook/opt-66b -q 4bit -d UCL

python src/run_gpt2.py -m EleutherAI/pythia-70m-deduped -d UCL
python src/run_gpt2.py -m EleutherAI/pythia-160m-deduped -d UCL
python src/run_gpt2.py -m EleutherAI/pythia-410m-deduped -d UCL
python src/run_gpt2.py -m EleutherAI/pythia-1b-deduped -d UCL
python src/run_gpt2.py -m EleutherAI/pythia-1.4b-deduped -d UCL
python src/run_gpt2.py -m EleutherAI/pythia-2.8b-deduped -d UCL
python src/run_gpt2.py -m EleutherAI/pythia-6.9b-deduped -d UCL
python src/run_gpt2.py -m EleutherAI/pythia-12b-deduped -d UCL


python src/run_gpt2.py -m gpt2 -d UCL --method tuned-lens
python src/run_gpt2.py -m gpt2-large -d UCL --method tuned-lens
python src/run_gpt2.py -m gpt2-xl -d UCL --method tuned-lens

python src/run_gpt2.py -m facebook/opt-125m -d UCL --method tuned-lens
python src/run_gpt2.py -m facebook/opt-1.3b -d UCL --method tuned-lens
python src/run_gpt2.py -m facebook/opt-6.7b -d UCL --method tuned-lens

python src/run_gpt2.py -m EleutherAI/pythia-70m-deduped -d UCL --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-160m-deduped -d UCL --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-410m-deduped -d UCL --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-1b-deduped-v0 -d UCL --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-1.4b-deduped -d UCL --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-2.8b-deduped -d UCL --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-6.9b-deduped -d UCL --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-12b-deduped -d UCL --method tuned-lens -q 8bit