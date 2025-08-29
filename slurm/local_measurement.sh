#!/bin/bash

#data="DC"
prefix="local_"
model="gpt2"

for model in "gpt2" "facebook/opt-125m" "EleutherAI/pythia-70m-deduped"; do
for data in "Fillers" "M_N400" "NS" "S_N400" "UCL" "ZuCO"; do
  python src/run_gpt2.py -m $model -c "./_cashe_basic/" --data $data --prefix $prefix
  python src/EZ_run_gpt2_nnsight.py -m $model -c "./_cashe_nn/" --data $data --prefix $prefix
  python src/EZ_run_gpt2_transformer_lens.py -m $model -c "./_cashe_tl/" --data $data --prefix $prefix
done
done



#wait
#python src/EZ_tl_test.py


