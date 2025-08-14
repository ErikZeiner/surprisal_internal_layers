#!/bin/bash
#SBATCH --partition=cpu-single
#SBATCH --ntasks=1
#SBATCH --time=00:20:00
#SBATCH --mem=8gb
#SBATCH --export=NONE

module load devel/miniforge
conda activate surprisal

script="run_gpt2.py"
model="gpt2"
batchsize=4
quantize=""
data="DC"
prefix="helix"

echo "run $script:
- model: $model
- batchsize: $batchsize
- quantize: '$quantize'
- data: $data
- prefix: $prefix"

python src/$script -m $model -c "./_cashe/" --data $data --prefix $prefix
