#!/bin/bash
#SBATCH --partition=cpu-single
#SBATCH --ntasks=1
#SBATCH --time=00:20:00
#SBATCH --mem=8gb
#SBATCH --export=NONE

module load devel/miniforge

model="gpt2"
batchsize=4
quantize=""
data="DC"
prefix="helix"

python src/run_gpt2.py -m $model -c "./_cashe/" --data $data --prefix $prefix