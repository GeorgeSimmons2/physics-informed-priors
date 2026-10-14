# mace_al_elastic_ch16: what differs from ../mace_al_elastic

A new, smaller MACE: **16 channels** (hidden irreps 16x0e + 16x1o instead of 64x0e + 64x1o), every other
training setting unchanged (seed 1, 400 epochs, SWA from 300, float64), trained into models/; and the
lattice-constant target **4.032 Å** (Straumanis & Woodard, Acta Cryst. A27, 549 (1971)). The readout basis
has 16 + 16 + 1 = 33 columns instead of 81. plot_training.py draws the training loss against optimiser step.

Run everything with `TRAIN=1 bash rerun.sh` (with `FORCE=1`, since it writes over the run published here); all outputs stay in this directory. The diff:

```diff
diff -ru -x results -x repro_results -x rows -x logs -x models -x __pycache__ -x repro_models -x repro_train -x '*.md' -x rerun.sh -x plot_training.py mace_al_elastic/4_compare.py mace_al_elastic_ch16/4_compare.py
--- mace_al_elastic/4_compare.py	2026-10-12 10:36:40.907448683 +0100
+++ mace_al_elastic_ch16/4_compare.py	2026-10-14 15:39:12.877181812 +0100
@@ -75,7 +75,7 @@
          f"{'':8s} {'a0 (Å)':>8s} " + " ".join(f"{k:>7s}" for k in KEYS) + "   (GPa, stress–strain at own a0)"]
 for m in ("before", "after"):
     lines.append(f"{m:8s} {C[m]['a0']:8.4f} " + " ".join(f"{C[m][k]:7.1f}" for k in KEYS))
-lines.append(f"{'target':8s} {4.04:8.4f} " + " ".join(f"{TARGET[k]:7.1f}" for k in KEYS))
+lines.append(f"{'target':8s} {4.032:8.4f} " + " ".join(f"{TARGET[k]:7.1f}" for k in KEYS))
 txt = "\n".join(lines)
 print(txt)
 open(os.path.join(DIR, f"{PREFIX}compare_elastic.txt"), "w").write(txt + "\n")
diff -ru -x results -x repro_results -x rows -x logs -x models -x __pycache__ -x repro_models -x repro_train -x '*.md' -x rerun.sh -x plot_training.py mace_al_elastic/5_elastic_matscipy.py mace_al_elastic_ch16/5_elastic_matscipy.py
--- mace_al_elastic/5_elastic_matscipy.py	2026-10-12 10:36:40.909448693 +0100
+++ mace_al_elastic_ch16/5_elastic_matscipy.py	2026-10-14 12:34:07.984038230 +0100
@@ -29,6 +29,6 @@
     C, C_err = fit_elastic_constants(atoms, symmetry="cubic", N_steps=5, delta=1e-3, verbose=False)
     lines.append(f"{name:12s} a0 {atoms.cell[0, 0]:.4f} Å   C11 {C[0, 0] / GPa:6.1f}   C12 {C[0, 1] / GPa:6.1f}   "
                  f"C44 {C[3, 3] / GPa:6.1f} GPa   (fit error ≤ {C_err.max() / GPa:.2f} GPa)")
-lines.append(f"{'target':12s} a0 4.0400 Å   C11  116.3   C12   64.8   C44   30.9 GPa")
+lines.append(f"{'target':12s} a0 4.0320 Å   C11  116.3   C12   64.8   C44   30.9 GPa")
 print("\n".join(lines))
 open(os.path.join(out, "elastic_matscipy.txt"), "w").write("\n".join(lines) + "\n")
diff -ru -x results -x repro_results -x rows -x logs -x models -x __pycache__ -x repro_models -x repro_train -x '*.md' -x rerun.sh -x plot_training.py mace_al_elastic/lib.py mace_al_elastic_ch16/lib.py
--- mace_al_elastic/lib.py	2026-10-10 23:51:56.939494303 +0100
+++ mace_al_elastic_ch16/lib.py	2026-10-14 12:34:07.979038205 +0100
@@ -9,7 +9,7 @@
 θ = [scale·w₀, scale·w₂, shift] are the trained readout weights (θ0).  Everything up to D is frozen.
 Changing θ is a change of MACE's own weights: patched_calc(θ) writes θ back into the model.
 
-Env: MODEL_FILE (published models/Al_small_stagetwo.model), OUT (repro_results/), A0 (4.04 Å), THREADS
+Env: MODEL_FILE (published models/Al_small_stagetwo.model), OUT (repro_results/), A0 (4.032 Å), THREADS
 """
 import os
 
@@ -28,7 +28,7 @@
 # Targets: the paper's Al elastic constants (GPa), and the lattice constant (Å) at which they apply.
 C_TARGET = {"C11": 116.3, "C12": 64.8, "C44": 30.9}
 B_TARGET = (C_TARGET["C11"] + 2 * C_TARGET["C12"]) / 3
-A0 = float(os.environ.get("A0", 4.04))
+A0 = float(os.environ.get("A0", 4.032))
 
 
 def load_calc():
diff -ru -x results -x repro_results -x rows -x logs -x models -x __pycache__ -x repro_models -x repro_train -x '*.md' -x rerun.sh -x plot_training.py mace_al_elastic/pops/p5_figures.py mace_al_elastic_ch16/pops/p5_figures.py
--- mace_al_elastic/pops/p5_figures.py	2026-10-13 13:50:01.948023387 +0100
+++ mace_al_elastic_ch16/pops/p5_figures.py	2026-10-14 12:34:07.986038240 +0100
@@ -94,7 +94,7 @@
 TOL = 1e-3
 fig, axes = plt.subplots(2, 2, figsize=(W, W))
 rng = np.random.default_rng(0)
-for ax, (n, key, ref) in zip(axes.flat, ((2, "$a_0$ (Å)", 4.04), (3, "$C_{11}$ (GPa)", 116.3),
+for ax, (n, key, ref) in zip(axes.flat, ((2, "$a_0$ (Å)", 4.032), (3, "$C_{11}$ (GPa)", 116.3),
                                        (4, "$C_{12}$ (GPa)", 64.8), (5, "$C_{44}$ (GPa)", 30.9))):
     for j, name in enumerate(COL):
         m = (cij[:, 0] == j) & (cij[:, 1] >= 0)
diff -ru -x results -x repro_results -x rows -x logs -x models -x __pycache__ -x repro_models -x repro_train -x '*.md' -x rerun.sh -x plot_training.py mace_al_elastic/train.sh mace_al_elastic_ch16/train.sh
--- mace_al_elastic/train.sh	2026-10-10 23:51:56.986494541 +0100
+++ mace_al_elastic_ch16/train.sh	2026-10-14 12:34:07.992038270 +0100
@@ -15,15 +15,15 @@
 D=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
 DATA=$(cd "$D/../data/Al" && pwd)/subset_20_percent.extxyz
 [ -f "$DATA" ] || { echo "missing $DATA — fetch tier B (scripts/fetch_data.sh)"; exit 1; }
-mkdir -p "$D/repro_models" "$D/repro_train" "$D/logs"
+mkdir -p "$D/models" "$D/repro_train" "$D/logs"
 CMD="cd $D/repro_train && OMP_NUM_THREADS=16 python3 -m mace.cli.run_train \
   --name Al_small --train_file $DATA --valid_fraction 0.05 --seed 1 \
   --energy_key dft_energy --forces_key dft_forces --E0s average \
-  --model MACE --hidden_irreps '64x0e + 64x1o' --r_max 6.0 --num_interactions 2 --max_L 1 \
+  --model MACE --hidden_irreps '16x0e + 16x1o' --r_max 6.0 --num_interactions 2 --max_L 1 \
   --correlation 3 --MLP_irreps 16x0e \
   --batch_size 16 --max_num_epochs 400 --patience 50 --eval_interval 5 --ema --swa \
   --default_dtype float64 --device cpu --save_cpu \
-  --model_dir $D/repro_models --checkpoints_dir $D/repro_train/checkpoints \
+  --model_dir $D/models --checkpoints_dir $D/repro_train/checkpoints \
   --results_dir $D/repro_train/results --log_dir $D/repro_train/logs"
 if [ "${LOCAL:-0}" = 1 ]; then
     bash -c "$CMD"
```
