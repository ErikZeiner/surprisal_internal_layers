[Large Language Models Are Human-Like Internally](https://arxiv.org/abs/2502.01615).   
Tatsuki Kuribayashi, Yohei Oseki, Souhaib Ben Taieb, Kentaro Inui, Timothy Baldwin. (arXiv)

The project is under progress, and the codes are verison 0.

## Replication

### Environment
```
# with Python 3.11.10
pip install -r requirements.txt

# set OPENAI_KEY and HUFFINGFACE_KEY in src/config.py (if one replicates the experiments from scratch)

# install spacy data (if one replicates the experiments from scratch)
python -m spacy download en_core_web_md

# install kenlm (if one replicates the analyses from scratch)
git clone https://github.com/kpu/kenlm.git
cd kenlm
mkdir -p build
cd build
cmake ..
make -j 4
```

### Directories  
```
./  
├ data: human reading data  
├ preprocess: codes for enriching linguistic information to data  
├ results: cognitive modeling results   
├ scripts: scripts to run the experiments  
├ src: codes  
├ visualization: see experimental results  
└ work: additional data needed for analyses 
``` 


### Preprocess (one can skip)
```
# see data/*/preprocess.ipynb to create required data

python preprocess/DC/add_annotation.py
python preprocess/NS/add_annotation.py
python preprocess/NS_MAZE/add_annotation.py
python preprocess/Fillers/add_annotation.py
python preprocess/UCL/add_annotation.py
python preprocess/M_N400/add_annotation.py
python preprocess/S_N400/add_annotation.py
python preprocess/MECO/add_annotation.py
python preprocess/ZuCO/add_annotation.py

python src/get_clause_final_info.py -i data/DC/tokens.json 
python src/get_clause_final_info.py -i data/NS/tokens.json 
python src/get_clause_final_info.py -i data/UCL/tokens.json 
python src/get_clause_final_info.py -i data/Fillers/tokens.json 
python src/get_clause_final_info.py -i data/ZuCO/tokens.json 
```

### surprisal computation (one can skip)
```
bash scripts/run_*.sh # "*" should be dataset name
```

### regression modeling (one can skip)
```
bash scripts/modeling.sh
```

### main results
```
see visualization/visualization.ipynb
```

### analylses
```
see visualization/analyze_error.ipynb
see visualization/measure_contexualization.ipynb
```

### preprocess for contextualization analysis (one can skip)
```
cd work/openwebtext
python download.py
python merge_text.py > all.txt
cat all.txt | python ../../src/create_corpus_for_ngram.py -m gpt2 > gpt2_tokenized.txt
cat all.txt | python ../../src/create_corpus_for_ngram.py -m facebook/opt-125m > opt_tokenized.txt
cat all.txt | python ../../src/create_corpus_for_ngram.py -m EleutherAI/pythia-70m-deduped > pythia_tokenized.txt
cd ../../kenlm/build
bin/lmplz -o 5 < gpt2_tokenized.txt >gpt2_2gram.arpa
bin/lmplz -o 5 < opt_tokenized.txt >opt_2gram.arpa
bin/lmplz -o 5 < pythia_tokenized.txt >pythia_2gram.arpa

python src/run_ngram.py -m work/openwebtext/gpt2_2gram.arpa -t gpt2 -d DC
python src/run_ngram.py -m work/openwebtext/opt_2gram.arpa -t facebook/opt-125m -d DC
python src/run_ngram.py -m work/openwebtext/pythia_2gram.arpa -t EleutherAI/pythia-70m-deduped -d DC
```


