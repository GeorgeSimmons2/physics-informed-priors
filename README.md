# Physics-Informed Priors for MLIPs with UQ — reproduction repository

Everything behind the figures in the paper: the fitted models, the constrained parameters,
the code that produced them, and the code that turns them into the figures.

```bash
git clone <this repo> && cd physics-informed-priors-repro
julia --project -e 'using Pkg; Pkg.instantiate()'
bash run_all.sh replot          # every figure, from the committed parameters
```

That works on a fresh clone with nothing else fetched. To go further and **re-derive** the
parameters rather than replot them:

```bash
bash scripts/fetch_data.sh      # the design matrices and datasets (~7.9 GB)
bash run_all.sh reproduce       # re-solve every constrained optimisation
bash run_all.sh verify          # what matched, and how closely
```

## What is in the paper, and what made it

| figure | folder | the parameters behind it | their producer |
|---|---|---|---|
| Phonon bands, 2×2 | `bands_four_panel/` | Al_12 naive + constrained committees; Al_16 pinned ensembles | `constrained_optimization/al12/`, `al16/` |
| W equation of state | `eos_repulsive_core/` | `positive_core_constrained_parameters.csv` | `constrained_optimization/w/01_positive_core_qp.jl` |
| Thermal expansion a(T) | `thermal_expansion_vs_experiment/` | the multi-volume and a_eq committees, then NPT | `npt_trajectories/` |

Each folder has its own README covering the figure's construction and its caveats.
`constrained_optimization/README.md` is the one to read first — it documents the whole
chain, what "reproduced" means at each stage, and two provenance failures it exists to fix.

## The data is in two tiers

`data/manifest.toml` lists every input with its SHA-256, its size, its tier, and the script
that produces it.

- **Tier A (~23 MB, committed here.)** Everything needed to rebuild every figure from saved
  parameters: the three fitted models *without* their design matrices, every θ vector, the
  serialised band curves, the NPT summaries.
- **Tier B (~7.9 GB, fetched.)** Everything needed to re-derive those parameters: the three
  design matrices (7.4 GB of it), the 73k-member constrained cloud, the cached Hessians, and
  the DFT training and test sets. `scripts/fetch_data.sh` pulls and checksums it;
  `scripts/fetch_data.sh verify` re-checks what is already on disk.

The DFT datasets are marked `producer = "external"`: they cannot be regenerated from this
repository. Everything else can.

## Reproducibility is not uniform, and the repo says so

Three mechanisms sit in this pipeline with genuinely different reproducibility. `run_all.sh
verify` reports a tier per quantity rather than one pass/fail:

- **`exact`** — no QP in the member path (a seeded draw, or a closed-form rank-one
  correction). Must match bit-for-bit.
- **`converged`** — one well-posed QP. The iterate path may differ; the optimum does not.
  Measured at 9.1e-3 on a full rerun of the constrained mean model.
- **`statistical`** — a cutting-plane cascade of up to ~1600 added rows. Individual members
  and their order are **not** reproducible; the distribution is. Compared at 4.5σ of
  sampling noise, never member to member. **Never quote a member index.**

Two specific traps are documented where they bite, and worth knowing before reusing any of
this machinery:

- `sample_hypercube` draws `U = rand(N, d)` and takes member *i* from **row** *i*, so a
  committee is only reproducible at the same `N_MEMBERS` — a fixed seed is not enough.
- `OSQP.setup!` defaults `adaptive_rho_interval` to 0, which derives the rho schedule from
  measured wall-clock time. Every solve here pins it (`RHO_INTERVAL`, default 25).

## Layout

```
src/                        the ACEWorkflow package
constrained_optimization/   the parameter-producing stages, and the verifier
npt_trajectories/           constrain → MD → figure, for the thermal expansion figure
bands_four_panel/           the 2×2 phonon figure
eos_repulsive_core/         the W equation-of-state figure
thermal_expansion_vs_experiment/   a(T) against Wilson 1941
models/                     tier A committed; A.csv fetched
data/manifest.toml          every input: path, sha256, size, tier, producer
scripts/fetch_data.sh       pull and verify tier B
run_all.sh                  replot | reproduce | all | verify
```

Julia 1.11.8; `Manifest.toml` pins every dependency and should not be regenerated.
The SLURM scripts assume a cluster with `hmem` and `compute` partitions — adjust the
`#SBATCH` headers, not the Julia.
