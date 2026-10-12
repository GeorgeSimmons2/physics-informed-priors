#!/bin/bash
# mace_al_elastic — constrain the elastic constants of a trained MACE model without losing accuracy.
#
#   bash run.sh replot      the figure from the published data (results/compare_data.npz)       seconds, tier A
#   bash run.sh constrain   rows → design (energies + forces) → QP, on the PUBLISHED model        SLURM, ~1 h
#   bash run.sh compare     before/after errors and C_ij for the constrain output               SLURM, ~10 min
#   bash run.sh train       retrain the model from scratch (seed 1)                             SLURM, ~5.5 h
#   bash run.sh all         train → constrain → compare on the RETRAINED model, chained          SLURM
#   bash run.sh verify      compare a rerun ($OUT, default repro_results/) with results/         seconds
#   bash run.sh matscipy    independent C_ij check (matscipy stress–strain on ASE Atoms)        ~1 min
#
# Every rerun writes to repro_* (repro_results/, repro_models/); results/ and models/ are the published
# artifacts and are never overwritten.  Needs tier B (../data/Al/) for everything except replot and verify.
# Env: PARTITION (compute), OUT, MODEL_FILE, THREADS (16)
set -euo pipefail
D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO=$(dirname "$D")
MODE=${1:-replot}
PART=${PARTITION:-compute}
mkdir -p "$D/logs"
need_data() {
    for f in subset_20_percent.extxyz manual_df_test_Al.xyz; do
        [ -f "$REPO/data/Al/$f" ] || { echo "missing data/Al/$f — run scripts/fetch_data.sh (tier B)"; exit 1; }
    done
}
sub() {  # name, dependency ("" or afterok:<id>), env, command
    sbatch --parsable -p "$PART" -c "${THREADS:-16}" --mem=32G -t 12:00:00 -J "$1" ${2:+-d $2} \
        -o "$D/logs/$1_%j.log" --export=ALL,THREADS=${THREADS:-16},OMP_NUM_THREADS=${THREADS:-16}$3 \
        --wrap "cd $D && $4"
}
FIT="python3 1_constraints.py && python3 2_design.py && julia --project=$REPO 3_qp.jl"

case "$MODE" in
replot)
    python3 "$D/4_compare.py" --replot ;;
matscipy)
    python3 "$D/5_elastic_matscipy.py" ${2:+"$2"} ;;
constrain)
    need_data
    j=$(sub mace_al_constrain "" ",OUT=${OUT:-$D/repro_results}${MODEL_FILE:+,MODEL_FILE=$MODEL_FILE}" "$FIT")
    echo "constrain $j   → ${OUT:-$D/repro_results}/qp_elastic.txt; then: bash run.sh compare" ;;
compare)
    need_data
    j=$(sub mace_al_compare "" ",OUT=${OUT:-$D/repro_results}${MODEL_FILE:+,MODEL_FILE=$MODEL_FILE}" "python3 4_compare.py")
    echo "compare $j   → ${OUT:-$D/repro_results}/compare_elastic.{txt,pdf}" ;;
train)
    need_data
    bash "$D/train.sh" ;;
all)
    need_data
    M=$D/repro_models/Al_small_stagetwo.model
    O=${OUT:-$D/repro_results_retrained}
    j1=$(bash "$D/train.sh")
    j2=$(sub mace_al_constrain "afterok:$j1" ",OUT=$O,MODEL_FILE=$M" "$FIT")
    j3=$(sub mace_al_compare "afterok:$j2" ",OUT=$O,MODEL_FILE=$M" "python3 4_compare.py")
    echo "train $j1 → constrain $j2 → compare $j3   → $O/; then: OUT=$O bash run.sh verify" ;;
verify)
    python3 - "$D/results" "${OUT:-$D/repro_results}" <<'PY'
import os, re, sys
import numpy as np
pub, new = sys.argv[1:]
def nums(path):
    return [float(x) for x in re.findall(r"[-+]?\d+\.\d+(?:e[-+]?\d+)?", open(path).read())] if os.path.exists(path) else None
print(f"published {pub}\nrerun     {new}\n")
for f in ("theta_constrained_elastic.csv", "theta0.csv"):
    a, b = (os.path.join(d, f) for d in (pub, new))
    if os.path.exists(b):
        x, y = np.loadtxt(a, delimiter=","), np.loadtxt(b, delimiter=",")
        print(f"{f:32s} max|Δθ| = {np.abs(x - y).max():.2e}   (‖θ‖ = {np.linalg.norm(x):.2e})")
for f in ("qp_elastic.txt", "compare_elastic.txt"):
    a, b = nums(os.path.join(pub, f)), nums(os.path.join(new, f))
    if a and b and len(a) == len(b):
        d = np.abs(np.array(a) - np.array(b))
        print(f"{f:32s} {len(a)} numbers, max |Δ| = {d.max():.3g}  (at {a[int(d.argmax())]:g})")
    elif b:
        print(f"{f:32s} different layout — compare by eye")
print("\nA rerun on the published model should match to solver tolerance; a retrained model (run.sh all)")
print("should match statistically: test RMSEs within a few %, every constrained C_ij on target.")
PY
    ;;
*)
    sed -n 2,14p "$0"; exit 1 ;;
esac
