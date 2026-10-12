"""
5. An independent check: the elastic constants of both models from matscipy's stress–strain fit on ASE Atoms
(ASE itself has no elasticity module).  Uses nothing from lib.py or the constraint rows — only the two
MACE checkpoints, an ASE cell relaxation, and matscipy.

  models/Al_small_stagetwo.model           MACE as trained
  models/Al_small_stagetwo_elastic.model   the same model with the refit readout weights (written by 4_compare.py)
Run: python3 5_elastic_matscipy.py [constrained.model]    → results/elastic_matscipy.txt (or beside the given model)
"""
import os
import sys

from ase.build import bulk
from ase.filters import FrechetCellFilter
from ase.optimize import BFGS
from ase.units import GPa
from mace.calculators import MACECalculator
from matscipy.elasticity import fit_elastic_constants

HERE = os.path.dirname(os.path.abspath(__file__))
constrained = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "models", "Al_small_stagetwo_elastic.model")
out = os.path.join(HERE, "results") if len(sys.argv) == 1 else os.path.dirname(os.path.abspath(constrained))

lines = []
for name, path in (("MACE", os.path.join(HERE, "models", "Al_small_stagetwo.model")), ("constrained", constrained)):
    atoms = bulk("Al", "fcc", a=4.05, cubic=True)
    atoms.calc = MACECalculator(model_paths=path, device="cpu", default_dtype="float64")
    BFGS(FrechetCellFilter(atoms, hydrostatic_strain=True), logfile=None).run(fmax=1e-6, steps=200)  # relax a0
    C, C_err = fit_elastic_constants(atoms, symmetry="cubic", N_steps=5, delta=1e-3, verbose=False)
    lines.append(f"{name:12s} a0 {atoms.cell[0, 0]:.4f} Å   C11 {C[0, 0] / GPa:6.1f}   C12 {C[0, 1] / GPa:6.1f}   "
                 f"C44 {C[3, 3] / GPa:6.1f} GPa   (fit error ≤ {C_err.max() / GPa:.2f} GPa)")
lines.append(f"{'target':12s} a0 4.0400 Å   C11  116.3   C12   64.8   C44   30.9 GPa")
print("\n".join(lines))
open(os.path.join(out, "elastic_matscipy.txt"), "w").write("\n".join(lines) + "\n")
