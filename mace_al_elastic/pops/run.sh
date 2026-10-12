#!/bin/bash
# Constrained POPS for the elastic-constrained MACE readout, chained on SLURM:
#   p1_rows.py (per-observation rows, ~1 h) → p1b_export_csv.py → p2_cloud.jl (clouds) → p3_sample.jl (committees)
#   → p4_evaluate.py (test-set UQ, per-member C_ij and a0) → p5_figures.py (separate half-width PDFs/PNGs).
# Reads the published mean model (../models, ../results); writes only to rows/ and $POPS_OUT (default
# repro_results/) here — results/ is the published run and is never overwritten.
# Run: bash run.sh [after_jobid]      (after_jobid: start p1b after an already-running p1 instead of submitting p1)
#      bash run.sh replot            the figures only, from results/eval_data.npz → results/repro_*.pdf (tier A, seconds)
set -euo pipefail
D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(cd "$D/../.." && pwd)
PART=${PARTITION:-compute}
if [ "${1:-}" = replot ]; then python3 "$D/p5_figures.py" --replot; exit; fi
POPS_OUT=${POPS_OUT:-repro_results}
mkdir -p "$D/logs"
sub() {  # name, dependency, threads, command
    sbatch --parsable -p "$PART" -c "$3" --mem=32G -t 12:00:00 -J "$1" ${2:+-d afterok:$2} -o "$D/logs/$1_%j.log" \
        --export=ALL,THREADS=$3,OMP_NUM_THREADS=$3,POPS_OUT=$POPS_OUT --wrap "cd $D && $4"
}
if [ -n "${1:-}" ]; then j1=$1; else j1=$(sub pops_rows "" 16 "python3 p1_rows.py"); fi
j2=$(sub pops_cloud "$j1" 16 "python3 p1b_export_csv.py && julia --project=$REPO -t 16 p2_cloud.jl")
j3=$(sub pops_sample "$j2" 4 "julia --project=$REPO p3_sample.jl")
j4=$(sub pops_eval "$j3" 16 "python3 p4_evaluate.py && python3 p5_figures.py")
echo "rows $j1 → cloud $j2 → sample $j3 → evaluate + figures $j4   → $D/$POPS_OUT/"
