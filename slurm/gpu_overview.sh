#!/bin/bash
#SBATCH --partition=gpu-single
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --gres=gpu:A100:6
#SBATCH --time=4:00:00
#SBATCH --mem=128G

module load devel/cuda/11.6
module load devel/miniforge
conda activate surprisal

script="run_gpt2.py"
model="gpt2"
batchsize=4
quantize=""
data="DC"
prefix="helix"

#python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-1.3b -d NS &
#python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-2.7b -d DC &
#python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-2.7b -d S_N400 &
#python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-6.7b -d Fillers &
#python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-6.7b -d NS &
#python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-6.7b -d UCL &
#python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-13b -d DC &
#python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-13b -d M_N400 &
#python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-13b -d Fillers
#python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-13b -d S_N400 &
#python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-13b -d ZuCO &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-30b -d Fillers
#python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-30b -d UCL &
#python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-66b -d M_N400 &
#python src/$script -c "./_cashe/" --prefix $prefix -m facebook/opt-66b -d ZuCO &
