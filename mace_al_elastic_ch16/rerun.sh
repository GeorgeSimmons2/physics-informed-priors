#!/bin/bash
# rerun.sh — this directory's whole pipeline, chained on SLURM.  It is a copy of ../mace_al_elastic with the
# changes listed in CHANGES.md; everything is written inside this directory (models/, results/, pops/rows/,
# pops/results/, logs/), so the published ../mace_al_elastic is never touched.
#
#   [train.sh, if TRAIN=1] → 1_constraints + 2_design + 3_qp → 4_compare → 5_elastic_matscipy
#                          → pops: p1 rows (needs only the model) → p1b + p2 cloud (needs the QP too)
#                          → p3 committees → p4 evaluate + p5 figures + p6 deviation-vs-error
#   and, with TRAIN=1, plot_training.py (training loss against optimiser step) once training finishes.
#
# Run: FORCE=1 bash rerun.sh    (FORCE=1 TRAIN=1 bash rerun.sh to train the model first)      Env: PARTITION (compute)
#      FORCE=1 is required once results/ exists: the rerun replaces the run published here.
set -euo pipefail
D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(dirname "$D")
PART=${PARTITION:-compute}
if [ -e "$D/results/qp_elastic.txt" ] && [ "${FORCE:-0}" != 1 ]; then
    echo "results/ already holds this directory's published run, and a rerun writes over it (models/ too with TRAIN=1)."
    echo "In the reproduction repo, git diff then compares the rerun with it and git checkout -- . restores it."
    echo "Run FORCE=1 bash rerun.sh to proceed."
    exit 1
fi
mkdir -p "$D/logs" "$D/pops/logs" "$D/results" "$D/pops/results"
ENV="ALL,THREADS=16,OMP_NUM_THREADS=16,OUT=$D/results,POPS_OUT=results"
sub() {  # name, dependencies (colon-separated job ids, or ""), working dir, command
    sbatch --parsable -p "$PART" -c 16 --mem=32G -t 24:00:00 -J "$1" ${2:+-d afterok:$2} \
        -o "$3/logs/$1_%j.log" --export="$ENV" --wrap "cd $3 && $4"
}
dep=""
if [ "${TRAIN:-0}" = 1 ]; then
    dep=$(bash "$D/train.sh")
    tc=$(sub train_curve "$dep" "$D" "python3 plot_training.py")
    echo "train $dep → training-loss plot $tc"
fi
c=$(sub al_constrain "$dep" "$D" "python3 1_constraints.py && python3 2_design.py && julia --project=$REPO 3_qp.jl")
m=$(sub al_compare "$c" "$D" "python3 4_compare.py && python3 5_elastic_matscipy.py $D/results/Al_small_stagetwo_elastic.model")
p1=$(sub pops_rows "$dep" "$D/pops" "python3 p1_rows.py")
p2=$(sub pops_cloud "$p1:$c" "$D/pops" "python3 p1b_export_csv.py && julia --project=$REPO -t 16 p2_cloud.jl")
p3=$(sub pops_sample "$p2" "$D/pops" "julia --project=$REPO p3_sample.jl")
p4=$(sub pops_eval "$p3" "$D/pops" "python3 p4_evaluate.py && python3 p5_figures.py && python3 p6_maxdev_vs_error.py")
echo "constrain $c → compare + matscipy $m;  pops rows $p1 → cloud $p2 → sample $p3 → evaluate + figures $p4"
