#!/bin/bash
#SBATCH --array=1-13
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=5
#SBATCH --partition=cpu-single
#SBATCH --time=04:00:00
#SBATCH --mem-per-cpu=24G
#SBATCH --job-name=run_models
#SBATCH --export=NONE

module load devel/miniforge
conda activate surprisal

script="run_gpt2.py"
langs=("du" "ee" "en" "fi" "ge" "gr" "he" "it" "ko" "no" "ru" "sp" "tr")
lang=${datasets[$SLURM_ARRAY_TASK_ID-1]}
prefix="helix"

python src/$script -c "./_cashe/" --prefix $prefix -m facebook/xglm-564M -d MECO/"$lang" &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/xglm-1.7B -d MECO/"$lang" &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/xglm-2.9B -d MECO/"$lang" &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/xglm-4.5B -d MECO/"$lang" &
python src/$script -c "./_cashe/" --prefix $prefix -m facebook/xglm-7.5B -d MECO/"$lang" &
wait