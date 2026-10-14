#!/bin/bash
# fetch_data.sh — pull the tier-B archive and verify it against data/manifest.toml.
#
#   bash scripts/fetch_data.sh            # fetch, extract, verify
#   bash scripts/fetch_data.sh verify     # verify what is already on disk
#   bash scripts/fetch_data.sh --no-cache # skip the rebuildable caches (saves 443 MB)
#
# Tier B is 8.13 GB, dominated by the three design matrices.
# Tier A is already in the repository; you do not need this to run `run_all.sh replot`.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
URL=${TIERB_URL:-https://zenodo.org/records/PLACEHOLDER/files}
ARCHIVE=${ARCHIVE:-"$ROOT/tierB.tar"}
MODE=${1:-fetch}

verify() {
  python3 - "$ROOT" <<'PY'
import hashlib, sys, os, re
root = sys.argv[1]
txt = open(os.path.join(root, "data", "manifest.toml")).read()
ok = missing = bad = 0
for block in txt.split("[[file]]")[1:]:
    g = lambda k: (re.search(rf'^{k}\s*=\s*"?([^"\n]+)"?', block, re.M) or [None,None])[1]
    path, tier, want = g("path"), g("tier"), g("sha256")
    if tier != "B" or not want: continue
    full = os.path.join(root, path)
    if not os.path.exists(full):
        print(f"  MISSING  {path}"); missing += 1; continue
    h = hashlib.sha256()
    with open(full, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 22), b""): h.update(chunk)
    if h.hexdigest() == want: ok += 1
    else: print(f"  CORRUPT  {path}"); bad += 1
print(f"\n{ok} verified, {missing} missing, {bad} corrupt")
sys.exit(1 if bad else 0)
PY
}

case "$MODE" in
  verify) verify ;;
  *)
    echo "fetching tier B from $URL"
    echo "NOTE: the URL above is a placeholder until the archive is deposited."
    [ -f "$ARCHIVE" ] || curl -fL --progress-bar -o "$ARCHIVE" "$URL/tierB.tar"
    tar -xf "$ARCHIVE" -C "$ROOT"
    verify
    ;;
esac
