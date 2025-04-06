python src/run_gpt2.py -m gpt2 -d S_N400
python src/run_gpt2.py -m gpt2-medium -d S_N400
python src/run_gpt2.py -m gpt2-large -b 2 -d S_N400
python src/run_gpt2.py -m gpt2-xl -b 2 -d S_N400

python src/run_gpt2.py -m facebook/opt-125m -d S_N400
python src/run_gpt2.py -m facebook/opt-1.3b -d S_N400
python src/run_gpt2.py -m facebook/opt-2.7b -d S_N400
python src/run_gpt2.py -m facebook/opt-6.7b -d S_N400
python src/run_gpt2.py -m facebook/opt-13b -q 8bit -d S_N400
python src/run_gpt2.py -m facebook/opt-30b -q 8bit -d S_N400
python src/run_gpt2.py -m facebook/opt-66b -q 4bit -d S_N400

python src/run_gpt2.py -m EleutherAI/pythia-70m-deduped -d S_N400
python src/run_gpt2.py -m EleutherAI/pythia-160m-deduped -d S_N400
python src/run_gpt2.py -m EleutherAI/pythia-410m-deduped -d S_N400
python src/run_gpt2.py -m EleutherAI/pythia-1b-deduped -d S_N400
python src/run_gpt2.py -m EleutherAI/pythia-1.4b-deduped -d S_N400
python src/run_gpt2.py -m EleutherAI/pythia-2.8b-deduped -d S_N400
python src/run_gpt2.py -m EleutherAI/pythia-6.9b-deduped -d S_N400
python src/run_gpt2.py -m EleutherAI/pythia-12b-deduped -d S_N400


python src/run_gpt2.py -m gpt2 -d S_N400 --method tuned-lens
python src/run_gpt2.py -m gpt2-large -d S_N400 --method tuned-lens
python src/run_gpt2.py -m gpt2-xl -d S_N400 --method tuned-lens

python src/run_gpt2.py -m facebook/opt-125m -d S_N400 --method tuned-lens
python src/run_gpt2.py -m facebook/opt-1.3b -d S_N400 --method tuned-lens
python src/run_gpt2.py -m facebook/opt-6.7b -d S_N400 --method tuned-lens

python src/run_gpt2.py -m EleutherAI/pythia-70m-deduped -d S_N400 --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-160m-deduped -d S_N400 --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-410m-deduped -d S_N400 --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-1b-deduped-v0 -d S_N400 --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-1.4b-deduped -d S_N400 --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-2.8b-deduped -d S_N400 --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-6.9b-deduped -d S_N400 --method tuned-lens
python src/run_gpt2.py -m EleutherAI/pythia-12b-deduped -d S_N400 --method tuned-lens -q 8bit