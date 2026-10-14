#!/bin/bash
# Train the small Al MACE model exactly as the published one (models/Al_small_stagetwo.model):
# mace-torch 0.3.16, seed 1, CPU, float64, 16 threads, on ../data/Al/subset_20_percent.extxyz (1,579 frames;
# MACE holds 5% out for validation with the same seed).  Every argument not given here is a mace-torch 0.3.16
# default; the full resolved configuration of the published run is in models/train_config.txt.
#
#   bash train.sh            submit to SLURM (PARTITION, default compute)  — ~5.5 h
#   LOCAL=1 bash train.sh    run here
#
# Output: repro_models/Al_small_stagetwo.model (the final, stage-two / SWA model used everywhere) and
# repro_models/Al_small.model (stage one, not used).  Bit-identical weights are not guaranteed across
# hardware or thread counts (floating-point reduction order); compare the error tables in the log with
# models/train_log.txt instead.
set -euo pipefail
D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
DATA=$(cd "$D/../data/Al" && pwd)/subset_20_percent.extxyz
[ -f "$DATA" ] || { echo "missing $DATA — fetch tier B (scripts/fetch_data.sh)"; exit 1; }
mkdir -p "$D/models" "$D/repro_train" "$D/logs"
CMD="cd $D/repro_train && OMP_NUM_THREADS=16 python3 -m mace.cli.run_train \
  --name Al_small --train_file $DATA --valid_fraction 0.05 --seed 1 \
  --energy_key dft_energy --forces_key dft_forces --E0s average \
  --model MACE --hidden_irreps '16x0e + 16x1o' --r_max 6.0 --num_interactions 2 --max_L 1 \
  --correlation 3 --MLP_irreps 16x0e \
  --batch_size 16 --max_num_epochs 400 --patience 50 --eval_interval 5 --ema --swa \
  --default_dtype float64 --device cpu --save_cpu \
  --model_dir $D/models --checkpoints_dir $D/repro_train/checkpoints \
  --results_dir $D/repro_train/results --log_dir $D/repro_train/logs"
if [ "${LOCAL:-0}" = 1 ]; then
    bash -c "$CMD"
else
    sbatch --parsable -p "${PARTITION:-compute}" -c 16 --mem=32G -t 24:00:00 -J mace_al_train \
        -o "$D/logs/train_%j.log" --wrap "$CMD"
fi
