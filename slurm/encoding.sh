#!/bin/bash
#SBATCH --array=1-7
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=3
#SBATCH --partition=cpu-single
#SBATCH --time=04:00:00
#SBATCH --mem-per-cpu=8G
#SBATCH --job-name=run_models
#SBATCH --output=logs/%A_%a.out
#SBATCH --export=NONE

module load devel/miniforge
conda activate surprisal

datasets=("DC" "Fillers" "M_N400" "NS" "S_N400" "UCL" "ZuCO")
data=${datasets[$SLURM_ARRAY_TASK_ID-1]}
prefix="helix"

python src/run_gpt2.py -m gpt2 -c "./_cashe/" --data $data --prefix $prefix
python src/run_gpt2.py -m facebook/opt-125m -c "./_cashe/" --data $data --prefix $prefix
python src/run_gpt2.py -m EleutherAI/pythia-70m-deduped -c "./_cashe/" --data $data --prefix $prefix