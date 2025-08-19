#!/bin/bash
#SBATCH --array=1-7
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --partition=cpu-single
#SBATCH --time=04:00:00
#SBATCH --mem-per-cpu=16G
#SBATCH --job-name=measurement
#SBATCH --output=measurement_logs/%A_%a.out
#SBATCH --export=NONE

module load devel/miniforge
conda activate surprisal

datasets=("DC" "Fillers" "M_N400" "NS" "S_N400" "UCL" "ZuCO")
data=${datasets[$SLURM_ARRAY_TASK_ID-1]}
prefix="helix"
model="gpt2"

#python src/run_gpt2.py -m $model -c "./_cashe/" --data $data --prefix $prefix &
python src/EZ_run_gpt2_nnsight.py -m $model -c "./_cashe/" --data $data --prefix $prefix &
python src/EZ_run_gpt2_transformer_lens.py -m $model -c "./_cashe/" --data $data --prefix $prefix &
wait

