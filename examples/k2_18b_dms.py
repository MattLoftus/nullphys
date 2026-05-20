"""NullPhys frequentist verification of the K2-18b DMS rejection.

The JWST-biosignatures project (this repo) already rejects the K2-18b DMS
claim via Bayesian model comparison: BF(DMS | base, K2-18b, phys-priors)
≈ -1.17 on both Madhusudhan and Schmidt reductions. This script provides
an *independent frequentist* cross-check using the NullPhys-verified
matched-spectrum surrogate.

Procedure
---------
1. Load K2-18b spectrum (NIRSpec G395H native portion, which covers the
   ~3.4 µm DMS C-H stretching window the original claim relied on).
2. Load posterior-median parameters from `exp_round_a2_k2_18b_phys`.
3. Rebuild the base species (M2023_SPECIES, no DMS) forward model and
   evaluate it at those medians.
4. Compute residuals (data - model) in units of uncertainty.
5. Apply two null models N=1000 times each:
   - MatchedSpectrum (phase rotation): preserves the amplitude spectrum,
     so the residual auto-correlation is matched. NullPhys reference:
     `NullPhys.MatchedSpectrum.preserves_amplitudeSpectrum`.
   - UniformShuffle (random label permutation): preserves only the
     multiset of residual values. NullPhys reference:
     `NullPhys.UniformShuffle.preserves_labelMultiset`.
6. Test statistic T = sum of squared residuals inside the DMS window
   (3.2–3.6 µm). Under "no DMS, residuals are colored noise", T is
   distributed per the null. p-value = fraction of nulls ≥ T_real.

Both Lean theorems guarantee that the null preserves what it claims to —
the empirical implementation here in numpy reproduces those nulls.

Usage
-----
    cd ~/workspace/jwst-biosignatures && source venv/bin/activate
    python scripts/nullphys_k2_18b_dms.py
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.opacities import apply_standard_defaults
from src.data import load_spectrum
from src.retrieval import RetrievalConfig, K2_18b_Retrieval, M2023_SPECIES

DMS_WINDOW_UM = (3.2, 3.6)
N_REALIZATIONS = 1000
RNG_SEED = 20260520


# ---------------------------------------------------------------------------
# NullPhys-certified null models (Python implementations of the Lean theorems)
# ---------------------------------------------------------------------------

def matched_spectrum_null(residuals: np.ndarray, n_realizations: int,
                          rng: np.random.Generator) -> np.ndarray:
    """Phase-randomization surrogate; preserves amplitude spectrum.

    NullPhys theorem: ``NullPhys.MatchedSpectrum.preserves_amplitudeSpectrum``
    (Nullphys/MatchedSpectrum.lean). The Lean kernel verifies that the
    per-frequency norm of the complex DFT is unchanged by per-frequency
    phase rotation. This function implements that rotation in numpy,
    with Hermitian symmetry to keep the inverse-FFT real.
    """
    N = len(residuals)
    fft = np.fft.fft(residuals)
    amplitudes = np.abs(fft)

    nulls = np.empty((n_realizations, N))
    for i in range(n_realizations):
        # Hermitian-symmetric random phases so the IFFT is real.
        if N % 2 == 0:
            half = N // 2
            phases = np.zeros(N)
            phases[1:half] = rng.uniform(-np.pi, np.pi, half - 1)
            phases[half + 1:] = -phases[1:half][::-1]
            # phases[0] and phases[N/2] stay 0 (DC and Nyquist real)
        else:
            half = (N - 1) // 2
            phases = np.zeros(N)
            phases[1:half + 1] = rng.uniform(-np.pi, np.pi, half)
            phases[half + 1:] = -phases[1:half + 1][::-1]
        rotated = amplitudes * np.exp(1j * phases)
        # The amplitudes already encode the original phases of (DC,Nyquist),
        # which are real; multiplying by exp(i*0)=1 leaves them real.
        nulls[i] = np.fft.ifft(rotated).real

    return nulls


def uniform_shuffle_null(residuals: np.ndarray, n_realizations: int,
                         rng: np.random.Generator) -> np.ndarray:
    """Random permutation of residual values across wavelengths.

    NullPhys theorem: ``NullPhys.UniformShuffle.preserves_labelMultiset``
    (Nullphys/UniformShuffle.lean). The Lean kernel verifies that
    reindexing a sample by a permutation of `Fin n` preserves the
    multiset of values.
    """
    N = len(residuals)
    nulls = np.empty((n_realizations, N))
    for i in range(n_realizations):
        nulls[i] = rng.permutation(residuals)
    return nulls


# ---------------------------------------------------------------------------
# Test statistic
# ---------------------------------------------------------------------------

def dms_window_chi2(residuals: np.ndarray, wavelengths: np.ndarray,
                    window_um: tuple[float, float]) -> float:
    """Sum of squared (chi-)residuals inside the DMS window."""
    mask = (wavelengths >= window_um[0]) & (wavelengths <= window_um[1])
    return float(np.sum(residuals[mask] ** 2))


# ---------------------------------------------------------------------------
# Main pipeline
# ---------------------------------------------------------------------------

def load_base_medians(exp_dir: str, mode: str = "veryhigh") -> dict[str, float]:
    f = f"experiments/{exp_dir}/round_a2_{mode}_summary.json"
    if not os.path.exists(f):
        raise FileNotFoundError(f)
    r = json.load(open(f))
    return {p: v["p50"] for p, v in r["params"].items()}, float(r["logz"])


def main():
    apply_standard_defaults()
    out_dir = os.path.join(os.path.dirname(os.path.dirname(
        os.path.abspath(__file__))), "papers", "figures")
    os.makedirs(out_dir, exist_ok=True)

    print("Loading K2-18b spectrum + base retrieval medians …")
    spec = load_spectrum("K2-18b")
    medians_base, logz_base = load_base_medians("exp_round_a2_k2_18b_phys")
    print(f"  N data = {len(spec.wavelength)}, log Z (base, phys) = {logz_base:.2f}")

    print("Rebuilding base species forward model at posterior medians …")
    wl_lo = max(0.3, spec.wavelength_min - 0.1)
    wl_hi = min(50.0, spec.wavelength_max + 0.1)
    cfg = RetrievalConfig(species=M2023_SPECIES, target="K2-18b",
                          wavelength_boundaries=(wl_lo, wl_hi))
    ret = K2_18b_Retrieval(cfg, spec)
    t0 = time.time()
    y_base = ret.forward(medians_base)
    print(f"  forward eval in {time.time() - t0:.1f}s")

    # Mask out-of-band model points (rare, but safe).
    valid = np.isfinite(y_base) & np.isfinite(spec.transit_depth) & np.isfinite(spec.sigma)
    wl = spec.wavelength[valid]
    chi_resid = (spec.transit_depth[valid] - y_base[valid]) / spec.sigma[valid]
    N = len(chi_resid)
    print(f"  N valid residuals = {N}")
    print(f"  WL range = {wl.min():.2f}–{wl.max():.2f} µm, "
          f"DMS window {DMS_WINDOW_UM[0]}–{DMS_WINDOW_UM[1]} µm "
          f"({((wl >= DMS_WINDOW_UM[0]) & (wl <= DMS_WINDOW_UM[1])).sum()} points)")

    # Real-data test statistic.
    T_real = dms_window_chi2(chi_resid, wl, DMS_WINDOW_UM)
    print(f"\nReal T (sum chi² in DMS window) = {T_real:.2f}")

    rng = np.random.default_rng(RNG_SEED)

    print(f"\nMatchedSpectrum null (N={N_REALIZATIONS}) …")
    t0 = time.time()
    ms_nulls = matched_spectrum_null(chi_resid, N_REALIZATIONS, rng)
    print(f"  generated in {time.time() - t0:.1f}s")
    T_ms = np.array([dms_window_chi2(n, wl, DMS_WINDOW_UM) for n in ms_nulls])

    rng2 = np.random.default_rng(RNG_SEED + 1)
    print(f"UniformShuffle null (N={N_REALIZATIONS}) …")
    t0 = time.time()
    us_nulls = uniform_shuffle_null(chi_resid, N_REALIZATIONS, rng2)
    print(f"  generated in {time.time() - t0:.1f}s")
    T_us = np.array([dms_window_chi2(n, wl, DMS_WINDOW_UM) for n in us_nulls])

    # p-values: 1-sided, fraction of nulls ≥ T_real.
    p_ms = (T_ms >= T_real).mean()
    p_us = (T_us >= T_real).mean()

    print(f"\np-value (MatchedSpectrum) = {p_ms:.4f}  "
          f"(null mean = {T_ms.mean():.2f}, std = {T_ms.std():.2f})")
    print(f"p-value (UniformShuffle)  = {p_us:.4f}  "
          f"(null mean = {T_us.mean():.2f}, std = {T_us.std():.2f})")

    results = {
        "target": "K2-18b",
        "n_data": int(N),
        "wl_range_um": [float(wl.min()), float(wl.max())],
        "dms_window_um": list(DMS_WINDOW_UM),
        "n_points_in_window": int(((wl >= DMS_WINDOW_UM[0])
                                   & (wl <= DMS_WINDOW_UM[1])).sum()),
        "T_real": float(T_real),
        "MatchedSpectrum": {
            "n_realizations": N_REALIZATIONS,
            "p_value": float(p_ms),
            "null_mean": float(T_ms.mean()),
            "null_std": float(T_ms.std()),
            "T_real_z": float((T_real - T_ms.mean()) / T_ms.std()),
            "lean_theorem":
                "NullPhys.MatchedSpectrum.preserves_amplitudeSpectrum",
        },
        "UniformShuffle": {
            "n_realizations": N_REALIZATIONS,
            "p_value": float(p_us),
            "null_mean": float(T_us.mean()),
            "null_std": float(T_us.std()),
            "T_real_z": float((T_real - T_us.mean()) / T_us.std()),
            "lean_theorem":
                "NullPhys.UniformShuffle.preserves_labelMultiset",
        },
        "logz_base_phys": logz_base,
        "rng_seed": RNG_SEED,
        "interpretation": (
            "p-value < 0.05 from either null indicates DMS-window "
            "residual variance is unusually high beyond what the null "
            "permits. p-value >= 0.05 corroborates the Bayesian rejection."
        ),
    }

    json_out = os.path.join(out_dir, "nullphys_k2_18b_dms.json")
    with open(json_out, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nsaved {json_out}")

    # Plot: residuals + null distributions of T
    fig, axes = plt.subplots(2, 1, figsize=(10, 8))

    ax = axes[0]
    in_window = (wl >= DMS_WINDOW_UM[0]) & (wl <= DMS_WINDOW_UM[1])
    ax.axvspan(*DMS_WINDOW_UM, color="C1", alpha=0.15, label="DMS window")
    ax.plot(wl, chi_resid, "o-", ms=4, lw=1, color="C0",
            label="(data − base+CH4) / σ")
    ax.axhline(0, color="k", lw=0.5, alpha=0.5)
    ax.set_xlabel("Wavelength [µm]")
    ax.set_ylabel("Chi-residual")
    ax.set_title("K2-18b chi-residuals against base species model (phys priors)")
    ax.legend()
    ax.grid(alpha=0.3)

    ax = axes[1]
    bins = np.linspace(min(T_ms.min(), T_us.min(), T_real) * 0.95,
                       max(T_ms.max(), T_us.max(), T_real) * 1.05, 50)
    ax.hist(T_ms, bins=bins, alpha=0.5, color="C2",
            label=f"MatchedSpectrum null, p={p_ms:.3f}")
    ax.hist(T_us, bins=bins, alpha=0.5, color="C3",
            label=f"UniformShuffle null, p={p_us:.3f}")
    ax.axvline(T_real, color="k", lw=2, label=f"T_real = {T_real:.1f}")
    ax.set_xlabel("T = sum chi² in DMS window")
    ax.set_ylabel("count")
    ax.set_title("Null distributions of test statistic T "
                 f"(N={N_REALIZATIONS} each)")
    ax.legend()
    ax.grid(alpha=0.3)

    fig.tight_layout()
    png_out = os.path.join(out_dir, "nullphys_k2_18b_dms.png")
    fig.savefig(png_out, dpi=130)
    print(f"saved {png_out}")

    print("\n--- VERDICT ---")
    print(f"MatchedSpectrum p = {p_ms:.4f}: " +
          ("DMS-window concentration significant" if p_ms < 0.05
           else "no excess concentration — corroborates Bayesian no-DMS"))
    print(f"UniformShuffle  p = {p_us:.4f}: " +
          ("DMS-window concentration significant" if p_us < 0.05
           else "no excess concentration — corroborates Bayesian no-DMS"))


if __name__ == "__main__":
    main()
