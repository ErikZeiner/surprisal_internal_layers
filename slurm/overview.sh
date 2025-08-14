#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=14
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

python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-1.3b -d NS &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-2.7b -d DC &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-2.7b -d S_N400 &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-6.7b -d Fillers &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-6.7b -d NS &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-6.7b -d UCL &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-13b -d DC &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-13b -d M_N400 &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-13b -d S_N400 &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-13b -d ZuCO &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-30b -d Fillers &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-30b -d UCL &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-66b -d M_N400 &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-66b -d ZuCO &
wait