# Constrained POPS for the elastic-constrained MACE model

A committee for the elastic-constrained MACE readout (`../results/theta_constrained_elastic.csv`). Every
member reproduces the mean model's elastic constants and lattice constant (C11, C12, C44 within ±0.1%,
zero pressure at a0 = 4.04 Å). An unconstrained POPS committee is built alongside for comparison. This
follows the ACE pipeline (`constrained_optimization/al12/02`–`03`), with the elastic windows in place of
its Born and phonon constraints, and reuses its sampler (`src/POPS/POPSRegression.jl`) unchanged. Nothing
outside this folder is written.

```bash
bash run.sh            # p1 → p1b → p2 → p3 → p4 + p5 on SLURM, about 1.5 h
bash run.sh replot     # the figures only, from results/eval_data.npz → results/repro_*.pdf (seconds, tier A)
python3 p6_maxdev_vs_error.py            # after run.sh: |error| vs the largest member deviation toward DFT
python3 p6_maxdev_vs_error.py --replot   # the same figures from results/maxdev_data.npz (seconds, tier A)
```

**Result.** The constraints remove the committee's uncertainty in the lattice constant and elastic constants
while keeping its uncertainty on held-out energies and forces.

| 100-member committee | a0 (Å) | C11 (GPa) | C12 (GPa) | C44 (GPa) | test E: RMSE/σ, in envelope | test F: RMSE/σ, in envelope |
| --- | --- | --- | --- | --- | --- | --- |
| constrained, about θc | 4.0400–4.0400 | 116.4–116.4 | 64.7–64.8 | 30.9–30.9 | 1.38, 94.2% | 2.01, 88.1% |
| unconstrained, about trained MACE | 4.037–4.074 | 86–129 | 48–66 | 18–43 | 1.30, 96.6% | 1.99, 89.1% |

Errors are those of each committee's reference model on the 3,000 held-out test frames (13.3 meV/atom and
52.3 meV/Å constrained; 12.0 meV/atom and 50.6 meV/Å for MACE). In both committees the spread is about half
the force error (RMSE/σ ≈ 2).

| step | script | what it does |
| --- | --- | --- |
| p1 | `p1_rows.py` | every training observation as a row: 1,579 per-atom energies and 27,930 force components (a = D/N or G = −∂D/∂r); the same for the 3,000-frame test sample |
| p1b | `p1b_export_csv.py` | the training rows as CSV for Julia |
| p2 | `p2_cloud.jl` | leverage of each row under the mean model's loss; the top 50%; one QP per kept row (below); the unconstrained cloud in closed form |
| p3 | `p3_sample.jl` | `hypercube` of each cloud's deltas; `rejection_sample_hypercube` with the elastic windows (constrained), `sample_hypercube` (unconstrained); seed 1234, 100 members |
| p4 | `p4_evaluate.py` | test-set UQ of each committee against its reference model (spread, min–max envelope coverage, calibration), and the relaxed a0 and C_ij of every member and both reference models |
| p5 | `p5_figures.py` | the figures, each a separate half-width PDF/PNG: parity (reference model ± committee σ, RMSE printed), uncertainty vs error, calibration, C_ij spread |
| p6 | `p6_maxdev_vs_error.py` | the reference model's \|error\| against the committee's largest deviation toward the DFT value, on linear axes; above the line = covered, which is the min–max envelope coverage of p4 |

**The cloud.** The loss is the mean model's, L(θ) = ½ Σᵣ wᵣ (yᵣ − aᵣ·θ)², with w = 1/n_E for energies and
w_F/n_F for force components (w_F = 0.1). The shift column stays at its trained value.
- **Constrained member for kept row r:** min L(θ) subject to aᵣ·θ = yᵣ exactly, C11, C12, C44 within ±0.1%
  of target, and |P(a0)| ≤ 10⁻³ GPa. That is the mean model's QP with one interpolation equality added.
- **How it's solved:** in z = S(θ − θc), in the eigenbasis of the scaled Hessian, as `../3_qp.jl` does. On
  the dense Hessian OSQP reports the problem dual infeasible. OSQP's rho schedule is pinned so reruns are
  deterministic.
- **Unconstrained member:** θᵣ = θ0 + H⁻¹aᵣ (yᵣ − aᵣ·θ0)/(aᵣᵀH⁻¹aᵣ), about MACE's trained readout weights θ0.
- **Reference models:** the constrained committee is judged against θc, the unconstrained one against θ0 (MACE as trained).
- **Which rows:** the top 50% by leverage hᵣ = wᵣ aᵣᵀH⁻¹aᵣ, as in the ACE pipeline.

**The committee.**
- **Constrained:** `hypercube` takes the PCA of the deltas Θ − θc, with bounds at the extreme projections.
  `rejection_sample_hypercube` then keeps proposals that satisfy the same windows as the members.
- **Unconstrained:** sampled without rejection, as the ACE naive ensemble.
- **Reproducibility:** rejection sampling has the prefix property, so the first 30 members of this
  100-member committee equal a 30-member run's.

Reruns write to `repro_results/` (`POPS_OUT`). The published run is `results/`, and it holds:
- `committee_{constrained,unconstrained}.csv`: 100 × 81, one member per row.
- `cloud.txt`, `sample.txt`, `uq_test.txt`, `cij_members.csv`, `eval_data.npz`, `maxdev_test.txt`, `maxdev_data.npz`.
- Figures (PDF and PNG each): `parity_{E,F}_{constrained,unconstrained}`, `uncertainty_vs_error_{E,F}_{constrained,unconstrained}`,
  `calibration_{E,F}`, `cij_spread`, `maxdev_vs_error_{E,F}_{constrained,unconstrained}`.
- `rows/` holds the rebuildable design rows (about 60 MB).
