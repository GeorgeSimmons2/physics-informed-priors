#!/bin/bash
#SBATCH --job-name=repro_fcc_only
#SBATCH --partition=hmem
#SBATCH --nodes=1
#SBATCH --ntasks=8
#SBATCH --mem-per-cpu=16000
#SBATCH --time=01:00:00
#SBATCH --output=sentinel/repro_fcc_only_%j.log
set -euo pipefail
REPO=${REPO:-$SLURM_SUBMIT_DIR}; cd "$REPO"; export REPO
A12="$REPO/models/Al_12_4_6A_2_/results"
for tag in saved e2e; do
  if [ "$tag" = saved ]; then PFX=""; else PFX="e2e_"; fi
  echo "── $tag"
  DIR_UNCON="$A12/repro_${PFX}npt_thermal_expansion_naive_worst_member" \
  DIR_CON="$A12/repro_${PFX}npt_multivolume_softest" \
  OUT="$REPO/thermal_expansion_vs_experiment/repro_fcc_compare_constrained_vs_naive_300K_$tag" \
    julia --project -t 8 thermal_expansion_vs_experiment/fcc_compare_constrained_vs_naive.jl
done
