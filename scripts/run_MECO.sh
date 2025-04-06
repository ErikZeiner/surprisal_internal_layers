for lang in du ee en fi ge gr he it ko no ru sp tr
do
    echo "Processing $lang"
    python src/run_gpt2.py  -m facebook/xglm-564M -d MECO/$lang
    python src/run_gpt2.py  -m facebook/xglm-1.7B -d MECO/$lang
    python src/run_gpt2.py  -m facebook/xglm-2.9B -d MECO/$lang
    python src/run_gpt2.py  -m facebook/xglm-4.5B -d MECO/$lang
    python src/run_gpt2.py  -m facebook/xglm-7.5B -d MECO/$lang
done