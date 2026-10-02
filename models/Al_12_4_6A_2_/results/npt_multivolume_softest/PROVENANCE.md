# npt_multivolume_softest — what produced these trajectories

**Parameter vector**: `theta_used.csv` (copied here; 91 coefficients, coefficient
space, directly usable with `set_linear_parameters!` / `min_freq_stable`).

## Identity, verified three ways

| evidence | result |
|---|---|
| `thermal_expansion_summary.csv` header | `npt_member=softest  committee=bandpath_undotted_multivolume` |
| header per-volume min omega `0.3607 0.2597 0.1503 0.2554 0.1997 0.1905` | matches `npt_candidates.csv` row `softest,18,0.1503` exactly |
| byte comparison | `theta_used.csv` == `bandpath_undotted_multivolume/committee_rejection.csv` **row 18**, max abs diff = 0.0 |

So: **member 18 of the multi-volume constrained rejection committee**, the softest
member of that committee by worst-case min omega over the six volumes
(+0.1503 THz at a = 1.04*a_eq).

## Source

- committee: `../bandpath_undotted_multivolume/` (SLURM job 5997446, COMPLETED 21 min)
  - 30 members, rejection-sampled under Born + a_eq band + phonon positivity at
    a in a_eq*{1.00, 1.02, 1.04, 1.06, 1.08, 1.10}, N_cell = 4, dense Gamma->K
  - 13.3% acceptance; 0/30 unstable at any volume
- MD: `scripts/uq/npt_multivolume_member_Al_12_4_6A_2.jl` with `npt_member = :softest`
  (SLURM job 5997448, COMPLETED 4 h 27 min)
  - NPT 0 Pa, Langevin + MonteCarloBarostat, 4x4x4 FCC (256 atoms),
    dt = 1 fs, 10,000 equilibration + 20,000 production steps, logged every 50
  - T = 300, 500, 700, 900 K

## Result

FCC survived at 300 / 500 / 700 K (mean coordination 11.99 / 11.85 / 11.51) and was
lost at 900 K (9.12). alpha = 26.3e-6 /K fitted on the three FCC points only.
Note a(900 K) = 4.3121 A = 1.066*a_eq lies INSIDE the constrained range and its
phonons are positive (+0.208 THz), so the 900 K transition is finite-amplitude,
not a harmonic instability.

Frame layout in each `T*/md_trajectory.extxyz`: 601 frames, step 0..30000 stride 50.
Production = step >= 10000 (401 frames). Box is cubic and changes per frame under
the barostat, so any pair analysis must use each frame's own `cell`.
