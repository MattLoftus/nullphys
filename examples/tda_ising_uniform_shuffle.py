"""NullPhys UniformShuffle on 2D Ising persistent homology.

The companion tda-phases project
(`~/workspace/tda-phases`) reports as result R3-3 (score 8.5) that
~94–96% of the H0 total-persistence signal in 2D Ising / Potts spin
models at criticality is **density-driven** — i.e. reproduced by a
shuffled-spins null model with matched magnetisation but destroyed
spatial structure. H1 features by contrast carry genuine topological
information. The shuffle is the canonical NullPhys.UniformShuffle:
random permutation of the spin labels across lattice sites, preserving
the multiset of spin values.

This example re-runs the H0-vs-H1 decomposition on a small Ising
ensemble at T=T_C, using a NullPhys-certified UniformShuffle implementation:

    1. Thermalise an L×L Ising lattice at T=T_C with Wolff cluster moves.
    2. For each saved configuration:
       a. Compute alpha-complex persistent homology of the majority-spin
          point cloud; extract total H0 and H1 persistence.
       b. Apply UniformShuffle N times; assert the spin multiset is
          preserved at every realisation (the operational mirror of
          `NullPhys.UniformShuffle.preserves_labelMultiset`).
       c. Recompute H0 and H1 PH on each shuffled lattice.
    3. Report `TP(H_d)_real` vs `TP(H_d)_shuf_mean` for d=0,1. The
       R3-3 expectation: H0 ratio ≈ 1 (density-driven, shuffled
       reproduces real), H1 ratio > 1 (topological, shuffled is lower).

Read-only on `~/workspace/tda-phases`. Outputs into `nullphys/examples/`.

Run with the tda-phases venv (gudhi + the project's Ising2D class):

    PYTHONPATH=~/workspace/tda-phases \\
        ~/workspace/tda-phases/.venv/bin/python3 \\
        ~/workspace/nullphys/examples/tda_ising_uniform_shuffle.py
"""
from __future__ import annotations

import json
import os
import sys
import time

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

TDA_PHASES_ROOT = os.path.expanduser("~/workspace/tda-phases")
if TDA_PHASES_ROOT not in sys.path:
    sys.path.insert(0, TDA_PHASES_ROOT)

from tda_phases.models import Ising2D
from tda_phases.filtrations import point_cloud_alpha, persistence_stats

L = 24
N_CONFIGS = 15
N_NULLS_PER_CONFIG = 10
THERMALIZE_STEPS = 500
SKIP_STEPS = 20
RNG_SEED = 20260520
OUT_DIR = os.path.dirname(os.path.abspath(__file__))


# ---------------------------------------------------------------------------
# NullPhys-certified UniformShuffle of an Ising lattice
# ---------------------------------------------------------------------------

def nullphys_uniform_shuffle(spins: np.ndarray,
                             rng: np.random.Generator) -> np.ndarray:
    """Random permutation of spin values on the L×L lattice.

    NullPhys Lean theorem certifying invariance:
        `NullPhys.UniformShuffle.preserves_labelMultiset`
    (Nullphys/UniformShuffle.lean) — reindexing a length-n sample by
    a permutation of `Fin n` preserves the multiset of values.

    Runtime assertion: after the permutation the count of +1 / −1
    spins must be identical to the input. If this ever fails, either
    the Python implementation is wrong or the Lean theorem is wrong;
    it never fails.
    """
    n_up_before = int((spins == +1).sum())
    n_down_before = int((spins == -1).sum())
    flat = spins.ravel().copy()
    rng.shuffle(flat)
    out = flat.reshape(spins.shape)
    assert int((out == +1).sum()) == n_up_before, (
        "NullPhys.UniformShuffle assertion failed: spin-up count changed."
    )
    assert int((out == -1).sum()) == n_down_before, (
        "NullPhys.UniformShuffle assertion failed: spin-down count changed."
    )
    return out


# ---------------------------------------------------------------------------
# H0 and H1 total persistence
# ---------------------------------------------------------------------------

def tp_h0_h1(spins: np.ndarray) -> tuple[float, float]:
    """Return (total_H0_persistence, total_H1_persistence) on the
    alpha complex of the majority-spin point cloud."""
    M = float(np.mean(spins))
    majority = +1 if M >= 0 else -1
    st = point_cloud_alpha(spins, target_spin=majority)
    if st is None:
        return 0.0, 0.0
    h0 = persistence_stats(st, dim=0)
    h1 = persistence_stats(st, dim=1)
    return float(h0["total_persistence"]), float(h1["total_persistence"])


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------

def main():
    print(f"Ising 2D L={L} @ T=T_C={Ising2D.T_C} — generating {N_CONFIGS} configs")
    rng_main = np.random.default_rng(RNG_SEED)
    ising = Ising2D(L=L, T=Ising2D.T_C, rng=rng_main)
    ising.thermalize(THERMALIZE_STEPS)

    real_h0 = []
    real_h1 = []
    null_h0_per_config = []
    null_h1_per_config = []
    densities = []

    t0 = time.time()
    for k in range(N_CONFIGS):
        for _ in range(SKIP_STEPS):
            ising.wolff_step()
        spins = ising.get_config().copy()
        densities.append(float(np.mean(spins == +1)))
        tp0_r, tp1_r = tp_h0_h1(spins)
        real_h0.append(tp0_r)
        real_h1.append(tp1_r)

        null0_list = []
        null1_list = []
        # Use a deterministic seed so the run is reproducible
        rng_null = np.random.default_rng(RNG_SEED + 1 + k)
        for j in range(N_NULLS_PER_CONFIG):
            shuf = nullphys_uniform_shuffle(spins, rng_null)
            tp0_n, tp1_n = tp_h0_h1(shuf)
            null0_list.append(tp0_n)
            null1_list.append(tp1_n)
        null_h0_per_config.append(float(np.mean(null0_list)))
        null_h1_per_config.append(float(np.mean(null1_list)))
        if (k + 1) % 5 == 0:
            print(f"  config {k + 1}/{N_CONFIGS} ({time.time() - t0:.1f}s)")

    real_h0 = np.array(real_h0)
    real_h1 = np.array(real_h1)
    null_h0 = np.array(null_h0_per_config)
    null_h1 = np.array(null_h1_per_config)

    # Per-config: ratio (real - shuf) / shuf, and Cohen-d-like effect
    def effect(real, null):
        if real.std() + null.std() == 0:
            return float("nan")
        s_pool = np.sqrt(0.5 * (real.var(ddof=1) + null.var(ddof=1)))
        return (real.mean() - null.mean()) / s_pool if s_pool > 0 else float("nan")

    d_h0 = effect(real_h0, null_h0)
    d_h1 = effect(real_h1, null_h1)
    ratio_h0 = real_h0.mean() / null_h0.mean() if null_h0.mean() > 0 else float("nan")
    ratio_h1 = real_h1.mean() / null_h1.mean() if null_h1.mean() > 0 else float("nan")

    print(f"\n=== Total H0 persistence (alpha complex, majority-spin) ===")
    print(f"  real mean = {real_h0.mean():.2f}  std = {real_h0.std(ddof=1):.2f}")
    print(f"  shuf mean = {null_h0.mean():.2f}  std = {null_h0.std(ddof=1):.2f}")
    print(f"  real/shuf = {ratio_h0:.3f}   effect = {d_h0:+.3f}")
    print(f"  → R3-3 expectation: density-driven, ratio ≈ 1, effect ≈ 0")

    print(f"\n=== Total H1 persistence (alpha complex, majority-spin) ===")
    print(f"  real mean = {real_h1.mean():.2f}  std = {real_h1.std(ddof=1):.2f}")
    print(f"  shuf mean = {null_h1.mean():.2f}  std = {null_h1.std(ddof=1):.2f}")
    print(f"  real/shuf = {ratio_h1:.3f}   effect = {d_h1:+.3f}")
    print(f"  → R3-3 expectation: topological, ratio > 1, effect > 0")

    print(f"\nMagnetization absolute mean: {np.mean(np.abs(2*np.array(densities) - 1)):.3f}")
    print(f"NullPhys assertions: {N_CONFIGS * N_NULLS_PER_CONFIG} "
          f"= {N_CONFIGS * N_NULLS_PER_CONFIG} uniform-shuffles all preserved spin multiset.")

    results = {
        "system": "2D Ising",
        "L": L,
        "T": Ising2D.T_C,
        "n_configs": N_CONFIGS,
        "n_nulls_per_config": N_NULLS_PER_CONFIG,
        "n_total_shuffles": int(N_CONFIGS * N_NULLS_PER_CONFIG),
        "rng_seed": RNG_SEED,
        "H0_real_mean": float(real_h0.mean()),
        "H0_real_std": float(real_h0.std(ddof=1)),
        "H0_null_mean": float(null_h0.mean()),
        "H0_null_std": float(null_h0.std(ddof=1)),
        "H0_ratio_real_over_null": ratio_h0,
        "H0_cohen_d": d_h0,
        "H1_real_mean": float(real_h1.mean()),
        "H1_real_std": float(real_h1.std(ddof=1)),
        "H1_null_mean": float(null_h1.mean()),
        "H1_null_std": float(null_h1.std(ddof=1)),
        "H1_ratio_real_over_null": ratio_h1,
        "H1_cohen_d": d_h1,
        "lean_theorem":
            "NullPhys.UniformShuffle.preserves_labelMultiset "
            "(Nullphys/UniformShuffle.lean) — reindexing a sample by a "
            "permutation preserves the multiset of values. Asserted "
            "at runtime after every shuffle; never failed.",
        "interpretation": (
            "Replication of tda-phases R3-3 density-vs-topology decomposition "
            "on a small Ising ensemble (L={}, T=T_C, n={} configs). H0 ratio "
            "near 1 → H0 PH is density-driven. H1 ratio > 1 → H1 PH carries "
            "genuine topological information beyond density. The Lean theorem "
            "certifies that the spin multiset is preserved by every "
            "UniformShuffle; we assert this at runtime over {} shuffles, all "
            "pass.".format(L, N_CONFIGS, N_CONFIGS * N_NULLS_PER_CONFIG)
        ),
    }

    out_json = os.path.join(OUT_DIR, "tda_ising_uniform_shuffle.json")
    with open(out_json, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nsaved {out_json}")

    fig, ax = plt.subplots(1, 2, figsize=(11, 5))
    for axi, (real, null, label, exp_eff) in enumerate([
        (real_h0, null_h0, "H0 total persistence", "density-driven (≈1)"),
        (real_h1, null_h1, "H1 total persistence", "topological (>1)"),
    ]):
        a = ax[axi]
        bins = np.linspace(min(real.min(), null.min()) * 0.95,
                           max(real.max(), null.max()) * 1.05, 16)
        a.hist(real, bins=bins, alpha=0.55, color="C0",
               label=f"real (n={len(real)})")
        a.hist(null, bins=bins, alpha=0.55, color="C3",
               label=f"NullPhys UniformShuffle null (mean per config, n={len(null)})")
        ratio = real.mean() / null.mean() if null.mean() > 0 else float("nan")
        a.set_xlabel("Total persistence")
        a.set_ylabel("count")
        a.set_title(f"{label}\nreal/null = {ratio:.3f} — {exp_eff}")
        a.legend(fontsize=8)
        a.grid(alpha=0.3)

    fig.suptitle(
        f"Ising L={L} @ T_C: real vs NullPhys-certified UniformShuffle null "
        f"(R3-3 decomposition)",
        fontsize=12
    )
    fig.tight_layout()
    out_png = os.path.join(OUT_DIR, "tda_ising_uniform_shuffle.png")
    fig.savefig(out_png, dpi=130)
    print(f"saved {out_png}")

    print("\n--- VERDICT ---")
    print(f"H0 real/null = {ratio_h0:.3f}  (R3-3: ≈1, density-driven)")
    print(f"H1 real/null = {ratio_h1:.3f}  (R3-3: >1, topological)")
    print(f"All {N_CONFIGS * N_NULLS_PER_CONFIG} NullPhys-certified UniformShuffles "
          f"preserved the spin multiset (Lean theorem operational mirror).")


if __name__ == "__main__":
    main()
