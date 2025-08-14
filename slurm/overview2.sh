#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=7
#SBATCH --partition=cpu-single
#SBATCH --time=04:00:00
#SBATCH --mem-per-cpu=24G
#SBATCH --job-name=run_models
#SBATCH --export=NONE

module load devel/miniforge
conda activate surprisal

script="run_gpt2.py"
model="gpt2"
batchsize=4
quantize=""
data="DC"
prefix="helix"

python src/$script -c "./_cashe/" --prefix $prefix -m EleutherAI/pythia-1b-deduped -d Fillers &
python src/$script -c "./_cashe/" --prefix $prefix -m EleutherAI/pythia-1.4b-deduped -d NS &
python src/$script -c "./_cashe/" --prefix $prefix -m EleutherAI/pythia-2.8b-deduped -d S_N400 &
python src/$script -c "./_cashe/" --prefix $prefix -m EleutherAI/pythia-6.9b-deduped -d Fillers &
python src/$script -c "./_cashe/" --prefix $prefix -m EleutherAI/pythia-6.9b-deduped -d UCL &
python src/$script -c "./_cashe/" --prefix $prefix -m EleutherAI/pythia-12b-deduped -d M_N400 &
python src/$script -c "./_cashe/" --prefix $prefix -m EleutherAI/pythia-12b-deduped -d ZuCO &
wait