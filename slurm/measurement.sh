#!/bin/bash
#SBATCH --array=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=cpu-single
#SBATCH --time=04:00:00
#SBATCH --mem-per-cpu=16G
#SBATCH --job-name=measurement
#SBATCH --output=measurement_logs/%A_%a.out
#SBATCH --export=NONE

#module load devel/miniforge
#conda activate surprisal-cpu
#conda activate surprisal_internal_layers

#datasets=("DC")
#"Fillers" "M_N400" "NS" "S_N400" "UCL" "ZuCO")
data="DC"
#data=${datasets[$SLURM_ARRAY_TASK_ID-1]}
prefix="local"
model="facebook/opt-125m"

python src/run_gpt2.py -m $model -c "./_cashe/" --data $data --prefix $prefix
python src/EZ_run_gpt2_nnsight.py -m $model -c "./_cashe/" --data $data --prefix $prefix
python src/EZ_run_gpt2_transformer_lens.py -m $model -c "./_cashe_tl/" --data $data --prefix $prefix
#wait
#python src/EZ_tl_test.py


