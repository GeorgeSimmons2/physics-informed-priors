#!/bin/bash
#SBATCH --job-name=repro_figures
#SBATCH --partition=hmem
#SBATCH --nodes=1
#SBATCH --ntasks=40
#SBATCH --mem-per-cpu=16000
#SBATCH --time=04:00:00
#SBATCH --output=sentinel/repro_figures_%j.log
# All four figures, from BOTH NPT routes.  The Al_12 band cache (31 native 4x4x4 Hessians)
# is the slow part and is built once; the a(T) and FCC figures are then drawn twice, from
# the saved-theta run and from the rebuilt-committee run.
set -euo pipefail
REPO=${REPO:-$SLURM_SUBMIT_DIR}
cd "$REPO"; export REPO THREADS=40
echo "host=$(hostname) started=$(date)"
NPT_TAG=saved bash run_all.sh figures
echo "── now the rebuilt-committee route (a(T) and FCC only differ) ──"
NPT_TAG=e2e   bash run_all.sh figures
echo "finished=$(date)"
