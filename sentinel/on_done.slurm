#!/bin/bash
#SBATCH --job-name=repro_sentinel
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --time=00:30:00
#SBATCH --output=sentinel/repro_sentinel_%j.log
# Runs once every rerun job has left the queue (afterany, so it fires even if some failed).
# Writes a standing summary so the result survives any interactive session ending.
set -uo pipefail
REPO=${REPO:-$SLURM_SUBMIT_DIR}
cd "$REPO"
{
  echo "# Rerun finished $(date)"; echo
  echo "## Job outcomes"
  sacct -j "${WATCH_JOBS}" -X -n -o JobID%12,JobName%26,State%18,Elapsed
  echo; echo "## Verify"
  julia --project constrained_optimization/verify/compare_all.jl 2>&1 | grep -E '^\||passed'
  echo; echo "## NPT summaries"
  for d in repro_npt_multivolume_softest repro_npt_thermal_expansion_naive_worst_member \
           repro_e2e_npt_multivolume_softest repro_e2e_npt_thermal_expansion_naive_worst_member; do
    echo "### $d"
    grep -v '^#' "models/Al_12_4_6A_2_/results/$d/thermal_expansion_summary.csv" 2>/dev/null || echo "(none)"
  done
} > sentinel/RERUN_DONE.md 2>&1
echo "wrote $REPO/sentinel/RERUN_DONE.md"
