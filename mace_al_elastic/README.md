# Constraining the elastic constants of a trained MACE model

A trained, single-material MACE model for Al has its elastic constants and lattice constant put **exactly** on
target by refitting only its last-layer readout weights. The refit runs on the model's own training data
(energies and forces) as a constrained least-squares problem. Held-out accuracy is essentially unchanged.

```bash
bash run.sh replot      # the figure, from the published data in results/        (seconds, tier A only)
bash run.sh constrain   # re-derive θ on the published model                    (SLURM ~1 h, needs tier B)
bash run.sh compare     # before/after errors and C_ij for that θ                (SLURM ~10 min)
bash run.sh verify      # compare the rerun with results/
bash run.sh all         # retrain the model from scratch, then constrain + compare (SLURM ~7 h)
```

Reruns write to `repro_results/` and `repro_models/`. The published `results/` and `models/` are never overwritten.

## Result (`results/compare_elastic.{pdf,txt}`, `results/qp_elastic.txt`)

Test set: 3,000 random frames (seed 0) of `data/Al/manual_df_test_Al.xyz`, never used in training or in the fit.

| | E RMSE (meV/atom) | F RMSE (meV/Å) | a₀ (Å) | C11 | C12 | C44 | B (GPa) |
|---|---|---|---|---|---|---|---|
| MACE as trained | 12.03 | 50.6 | 4.0523 | 110.8 | 56.3 | 29.9 | 74.5 |
| elastic-constrained | 13.34 | 52.3 | **4.0400** | **116.4** | **64.7** | **30.9** | **82.0** |
| target | | | 4.04 | 116.3 | 64.8 | 30.9 | 82.0 |

The elastic constants above come from MACE's analytic stress (±0.5% strain) on the patched model, at each model's
own relaxed lattice constant. That's independent of the finite-difference rows used in the fit.

## The pieces

| step | script | what it does |
|---|---|---|
| model | `train.sh` | trains the small MACE (mace-torch 0.3.16, seed 1, CPU, float64) on `data/Al/subset_20_percent.extxyz` |
| 1 | `1_constraints.py` | finite-difference rows ∂D/∂a, ∂²D/∂ε² at a₀ = 4.04 Å, so that C_ij = (160.2/V)·row·θ |
| 2 | `2_design.py` | the readout basis D on the **whole training set** (1,579 frames) and the test sample; force normal equations GᵀG, Gᵀy_F from G = −∂D/∂r |
| 3 | `3_qp.jl` | the QP: MACE's loss (per-atom E-MSE + 0.1 × F-MSE) on the training set, subject to C11, C12, C44 within ±0.1% and P(a₀) = 0 |
| 4 | `4_compare.py` | before/after parity (energies and forces), error distributions, and C_ij by stress–strain |
| — | `lib.py` | the readout basis, θ ↔ model weights, strain helpers |

**The model.** MACE with 64×0e + 64×1o hidden irreps, 2 interaction layers, r_max 6 Å, max_L 1, correlation 3 and a
16-unit MLP readout, trained 400 epochs with stage two (SWA) from epoch 300.
- The model used throughout is the **stage-two** file, `models/Al_small_stagetwo.model`: validation E 12.6 meV/atom, F 63.6 meV/Å.
- MACE also writes a stage-one `Al_small.model` (validation E 43.0 meV/atom). It isn't used.
- The full resolved configuration is in `models/train_config.txt`, and the training log with its error tables in `models/train_log.txt`.

**The basis.** MACE's energy is exactly linear in the last weights of its two readouts:

  E = Σ E0 + D·θ,  D = Σ_atoms [h⁰ (64), σ(W₁h¹) (16), 1],  θ = [scale·w₀, scale·w₂, shift]

so a new θ is a new set of MACE weights; nothing is added to the model. The constant (shift) column is held
fixed. Both identities are asserted in `4_compare.py`.

**Why the fit uses forces.** The training set has 27,930 force components against 1,579 energies. With energies
alone, the 81-column problem is barely determined: the data Hessian spans about 13 decades, and the unconstrained
refit is unstable. With forces in MACE's own loss it's well posed (condition number 3.6e10, all directions kept).
`3_qp.jl` also prints the unconstrained refit (LS ≈ MACE: the trained readout is already optimal) and a w_F scan
showing a smooth energy/force trade-off.

## What "reproduced" means here

- **`replot`**: from `results/compare_data.npz`, exact.
- **`constrain` / `compare` on the published model**: the design is deterministic. The QP is well posed and solved
  to 1e-9, so θ and every reported number should match `results/` to solver tolerance (`bash run.sh verify`).
- **`train` / `all`**: same data, seed, settings and package versions (`requirements.txt`). Bit-identical weights
  aren't guaranteed across hardware or thread counts (floating-point reduction order). Compare the error tables
  against `models/train_log.txt`, and expect the constrained result to match statistically: test RMSEs within a
  few percent, and every constrained C_ij on target.

## Data (tier B, `scripts/fetch_data.sh`)

- `data/Al/subset_20_percent.extxyz`: 1,579 frames, exactly 20% of `manual_df_train_Al.extxyz`. It's the same
  training set as the paper's Al_12 ACE model.
- `data/Al/manual_df_test_Al.xyz`: the held-out test set.
- The design matrices (`repro_results/{D,E,GtG,Gty,fstats}_*.csv`) are rebuilt by `2_design.py` and aren't shipped.
