"""
Training loss of this directory's MACE model against optimiser step, from MACE's own record of the run
(repro_train/results/Al_small_run-1_train.txt: one "opt" row per batch, one "eval" row per validation pass).

  training_loss.{pdf,png}   per-step training loss, its per-epoch mean and the validation loss (log scale).
                            The switch to MACE's stage-two loss weights and the epoch of the stage-two
                            checkpoint that was kept are read from repro_train/logs/Al_small_run-1.log and marked;
                            the loss is not comparable across the switch (the energy weight changes).
Run: python3 plot_training.py        → $OUT (default results/)
"""
import json
import os
import re

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
RUN = os.path.join(HERE, "repro_train")
OUT = os.environ.get("OUT", os.path.join(HERE, "results"))
os.makedirs(OUT, exist_ok=True)

rows = [json.loads(l) for l in open(os.path.join(RUN, "results", "Al_small_run-1_train.txt")) if l.strip()]
opt = [r for r in rows if r["mode"] == "opt"]
ev = [r for r in rows if r["mode"] == "eval"]
spe = sum(r["epoch"] == 0 for r in opt)                                   # optimiser steps per epoch
loss = np.array([r["loss"] for r in opt])
step = np.arange(1, len(loss) + 1)
ep = np.array([r["epoch"] for r in opt])
epochs = np.unique(ep)
ep_mean = np.array([loss[ep == e].mean() for e in epochs])
v_step = np.array([0 if r["epoch"] is None else (r["epoch"] + 1) * spe for r in ev])   # eval runs after its epoch
v_loss = np.array([r["loss"] for r in ev])

log = open(os.path.join(RUN, "logs", "Al_small_run-1.log")).read()
w1 = re.search(r"WeightedEnergyForcesLoss\(energy_weight=([\d.]+), forces_weight=([\d.]+)\)", log)
st2 = re.search(r"Stage Two \(after (\d+) epochs\).*?energy weight : ([\d.]+), forces weight : ([\d.]+)", log)
kept = re.search(r"Loaded Stage two model from epoch (\d+)", log)

plt.rcParams.update({"font.size": 12, "axes.labelsize": 12, "xtick.labelsize": 11, "ytick.labelsize": 11,
                     "legend.fontsize": 10})
fig, ax = plt.subplots(figsize=(7.08, 3.7))                              # full MLST text width (~510 pt)
ax.semilogy(step, loss, color="0.75", lw=0.4, rasterized=True, label="training loss, per step")
ax.semilogy((epochs + 1) * spe, ep_mean, color="C0", lw=1.4, label="training loss, epoch mean")
ax.semilogy(v_step, v_loss, "o", ms=3.5, color="C3", label="validation loss")
if st2:
    x2 = int(st2.group(1)) * spe
    ax.axvline(x2, color="k", ls="--", lw=0.9)
    ax.text(x2, 0.97, f" stage two: E:F weights {float(w1.group(1)):g}:{float(w1.group(2)):g} → "
            f"{float(st2.group(2)):g}:{float(st2.group(3)):g}", transform=ax.get_xaxis_transform(),
            va="top", ha="right", fontsize=9)
if kept:
    xk = (int(kept.group(1)) + 1) * spe
    ax.axvline(xk, color="k", ls=":", lw=0.9)
    ax.text(xk, 0.03, f" kept: epoch {kept.group(1)}", transform=ax.get_xaxis_transform(), va="bottom", fontsize=9)
ax.set_xlim(0, step[-1])
ax.set_xlabel("optimiser step")
ax.set_ylabel("MACE loss (weighted E + F)")
top = ax.secondary_xaxis("top", functions=(lambda s: s / spe, lambda e: e * spe))
top.set_xlabel("epoch")
fig.legend(*ax.get_legend_handles_labels(), frameon=False, loc="lower center", ncol=3)
fig.tight_layout(rect=(0, 0.07, 1, 1))
for ext in ("pdf", "png"):
    fig.savefig(os.path.join(OUT, f"training_loss.{ext}"), dpi=300)
print(f"{len(loss)} optimiser steps ({spe} per epoch, {len(epochs)} epochs), {len(ev)} validation passes; "
      f"stage two from epoch {st2.group(1) if st2 else '?'}, kept epoch {kept.group(1) if kept else '?'}")
print(f"final epoch-mean training loss {ep_mean[-1]:.4g}, final validation loss {v_loss[-1]:.4g} → {OUT}/training_loss.pdf/.png")
