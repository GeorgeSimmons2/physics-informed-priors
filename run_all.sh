#!/bin/bash
# run_all.sh — the three modes of this repository.
#
#   bash run_all.sh replot      rebuild every figure from the SAVED parameters   (tier A only)
#   bash run_all.sh reproduce   re-derive the parameters, then verify them       (needs tier B)
#   bash run_all.sh all         reproduce, then rerun the NPT, then replot       (~12–15 h)
#   bash run_all.sh verify      compare whatever exists against the published θ  (seconds)
#
# `replot` is the one that works on a fresh clone with nothing fetched. It reads only
# committed data and reproduces every figure in the paper. Start there.
#
# `reproduce` and `all` need the tier-B archive:  bash scripts/fetch_data.sh
set -euo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO
MODE=${1:-help}

need_tierB() {
  if [ ! -f "$REPO/models/Al_12_4_6A_2_/A.csv" ]; then
    echo "Tier B is not present — '$MODE' needs the design matrices."
    echo "Run:  bash scripts/fetch_data.sh"
    exit 1
  fi
}

case "$MODE" in

replot)
  echo "── rebuilding every figure from the saved parameters ──────────────"
  cd "$REPO"
  echo "  [1/3] bands_four_panel"
  julia --project bands_four_panel/plot_four_panel_bands.jl
  echo "  [2/3] eos_repulsive_core   (needs data/W/df_W_train.extxyz from tier B for the"
  echo "        lower histogram panel; the upper EOS panel needs only tier A)"
  julia --project -t "${THREADS:-8}" eos_repulsive_core/eos_with_pair_hist.jl
  echo "  [3/3] thermal_expansion_vs_experiment"
  julia --project thermal_expansion_vs_experiment/plot_thermal_expansion_vs_experiment.jl
  ;;

reproduce)
  need_tierB
  bash "$REPO/constrained_optimization/run_pipeline.sh" constrain
  echo
  echo "When those finish:  bash run_all.sh verify"
  ;;

all)
  need_tierB
  bash "$REPO/constrained_optimization/run_pipeline.sh" all
  ;;

verify)
  julia --project "$REPO/constrained_optimization/verify/compare_all.jl"
  ;;

*)
  sed -n '2,15p' "$0"
  ;;
esac
