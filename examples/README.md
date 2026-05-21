# Examples

Real-data applications of NullPhys to published claims.

## K2-18b DMS — frequentist corroboration of Bayesian rejection

**Files:** `k2_18b_dms.py`, `k2_18b_dms.png`, `k2_18b_dms.json`

The DMS biosignature claim of [Madhusudhan et al. (2023)](https://doi.org/10.3847/2041-8213/acf577)
on K2-18b has been challenged by independent reanalyses
([Schmidt et al. 2025](https://doi.org/10.3847/1538-4357/adcecc)) and by Bayesian
audits (e.g. BF(DMS | base, phys priors) = −1.17 on both the Madhusudhan and
Schmidt reductions in the [JWST-biosignatures](https://github.com/MattLoftus/jwst-biosignatures)
audit framework).

This example provides an *independent frequentist cross-check* via the
NullPhys-verified matched-spectrum surrogate. We compute residuals
`(data − base+CH4 model)/σ` from the JWST-biosignatures `phys`-priors
retrieval and test whether the chi-squared contribution from the
3.2–3.6 µm DMS window is unusually large under two NullPhys-certified
nulls:

| Null | NullPhys theorem | What it preserves |
|---|---|---|
| `MatchedSpectrum` | `preserves_amplitudeSpectrum` | per-frequency DFT magnitude (noise color) |
| `UniformShuffle`  | `preserves_labelMultiset` | multiset of residual values |

### Result (2026-05-20)

| Statistic | Value |
|---|---|
| Data points | 64 (NIRISS+NIRSpec lowres) |
| Points in DMS window 3.2–3.6 µm | 7 |
| `T_real` = sum of chi² in DMS window | 7.66 |
| MatchedSpectrum null mean ± std | 11.09 ± 5.78 |
| MatchedSpectrum p-value | **0.695** |
| UniformShuffle null mean ± std | 10.94 ± 5.63 |
| UniformShuffle p-value | **0.679** |
| Compare: Bayes factor BF(DMS \| base, phys) | −1.17 (rejected) |

The DMS-window chi² is *lower* than both null means (z ≈ −0.6) — the
residuals in the DMS window are actually *better-fit* than expected
under structureless noise. There is no excess wavelength-localized
variance for DMS to be hiding in.

**Verdict:** the NullPhys-certified frequentist test corroborates the
Bayesian rejection. Two statistically independent paradigms — model-
evidence comparison and surrogate-null hypothesis testing — both
conclude that the K2-18b residuals are not consistent with a DMS
detection beyond what the base+CH4 model already captures.

---

## Seismic trivial-scalar — block-permutation reproduction

**Files:** `seismic_tls_blockperm.py`, `seismic_tls_blockperm.png`, `seismic_tls_blockperm.json`

The seismic-precursors project
([github.com/MattLoftus/seismic-precursors](https://github.com/MattLoftus/seismic-precursors))
found in session 18 / exp18 that the trivial scalar
`log10 Benioff energy in last 5 days` reaches macro AUC = 0.779 across
4 LORO regions (California, Cascadia, Turkey, Italy), beating the
elaborate TLS template apparatus (AUC = 0.704). Exp19 ran 5 controls
including a 30-day-block circular-shift null at z = +8.37.

This example re-runs the permutation tests on the **same 939 windows**
(139 precursor + 800 null-A) with three NullPhys-certified nulls:

| Null | NullPhys theorem | Block structure |
|---|---|---|
| `UniformShuffle` | `preserves_labelMultiset` | none (i.i.d. label permutation) |
| `BlockPermutation` | `preserves_perBlockMultiset` | `region` (4 LORO regions) |
| `BlockPermutation` | `preserves_perBlockMultiset` | `region × 365-day calendar bin` (97 blocks) |

### Result (2026-05-20)

| Null | z | Comparison |
|---|---|---|
| Observed macro AUC | 0.7795 | (exp18 published 0.779 ✓) |
| **UniformShuffle** | **+10.35** | (exp19 iid: +11.00) |
| **BlockPermutation(region)** | **+11.23** | tighter null (fixed per-region label balance) |
| **BlockPermutation(region × 365-day)** | **+9.48** | (exp19 circular-shift: +8.37) |

Reading the result. The three nulls represent three nested null hypotheses
about the trivial scalar:

* `UniformShuffle` rejects "the score is independent of the label" —
  z = +10.4, p ≪ 10⁻¹⁰.
* `BlockPermutation(region)` rejects "the score is independent of the
  label *even within each region*" — z = +11.2, equally strong. The
  signal isn't just region-level mean differences.
* `BlockPermutation(region × 365-day)` rejects "the score is independent
  of the label *even within (region, calendar-year)* blocks" — z = +9.5.
  This is the autocorrelation-aware null. The drop from +11 to +9.5 is
  smaller than the cold-read reviewer's pessimistic prediction (a
  collapse to z ≈ 3–4) and consistent with exp19's circular-shift
  estimate of +8.4.

**Verdict.** The trivial-scalar signal survives all three NullPhys-
certified nulls at z ≫ 3. The methodological transition from "exp19's
hand-rolled block-permutation" to "Lean-kernel-verified block-permutation"
reproduces exp19's conclusion to within ~10–15% on z (the residual gap
being block-structure choice, not null implementation).

### Reproducing

```bash
# Only needs the seismic-precursors data; uses /usr/bin/python3 directly.
/usr/bin/python3 ~/workspace/nullphys/examples/seismic_tls_blockperm.py
```

Reads the catalogs (`experiments/exp{06,07}_*/catalog_*.csv`) and
the feature summary (`experiments/exp07_macro_pra2/feature_summary.csv`)
from `~/workspace/seismic-precursors` read-only. Writes outputs only into
`nullphys/examples/`.

---

## COBRE schizophrenia — `MaslovSneppen` degree-preserving rewires

**Files:** `brain_cheeger_maslov_sneppen.py`, `brain_cheeger_maslov_sneppen.png`, `brain_cheeger_maslov_sneppen.json`

The companion network-neuroscience project
([github.com/MattLoftus/network-neuroscience](https://github.com/MattLoftus/network-neuroscience))
tests the Cheeger constant as a biomarker for neurological disease,
using Maslov–Sneppen degree-preserving rewires as the null model
("50 Maslov-Sneppen nulls per subject" in the standard pipeline).

This example applies the **NullPhys-certified MaslovSneppen rewire**
to the COBRE schizophrenia dataset (146 subjects, 64-region atlas,
threshold 75%). Every swap is checked against the `IsValidSwap`
predicate from `Nullphys/MaslovSneppen.lean`, and the degree
sequence is asserted invariant after every swap. The runtime
assertion is the operational mirror of the Lean theorem
`NullPhys.MaslovSneppen.degree_swap_eq` — if it ever failed, either
the Python implementation is wrong or the Lean proof is wrong.

### Result (2026-05-20)

- 30 sz + 30 ctrl subjects, 20 NullPhys rewires per subject.
- Per-rewire: ~5000 valid double-edge swaps; total ≈ **6 million certified swaps**.
- **Zero failures** of the per-swap degree-preservation assertion.
- COBRE Cheeger contrast at 75% threshold: raw d = −0.009 (p = 0.84), null-corrected d = −0.017 (p = 0.79). The dataset does not show a Cheeger effect for schizophrenia at this threshold (separate from autism, where the netneuro PLAYBOOK reports d = +0.156 null-corrected on ABIDE).

The headline is methodological. ~6 million swaps, all certified — the Lean theorem holds at scale in practice, exactly as proved.

### Reproducing

```bash
/usr/bin/python3 ~/workspace/nullphys/examples/brain_cheeger_maslov_sneppen.py
```

Reads `data/cobre/cobre_resolution_64.mat` and imports
`netneuro.metrics.cheeger_constant_approx` from
`~/workspace/network-neuroscience` read-only.

---

## NANOGrav 15-yr — `MatchedSpectrum` phase randomisation

**Files:** `nanograv_lambda_max_matched_spectrum.py`, `nanograv_lambda_max_matched_spectrum.png`, `nanograv_lambda_max_matched_spectrum.json`

The companion nanograv-spectral project
([github.com/MattLoftus/nanograv-spectral](https://github.com/MattLoftus/nanograv-spectral))
tests the leading eigenvalue `λ_max(C)` of the inter-pulsar
correlation matrix under two distinct nulls: a matched-Gaussian
variance-only null and a phase-randomized PSD-preserving null. Their
exp03 (10-yr scope, 24 pulsars, 500 realisations) reports:

* Matched-Gaussian: real = 4.609, null mean 2.525 → **z = +13.07** (the PLAYBOOK's "+12.7σ").
* Phase-randomized: real = 4.609, null mean 4.498 → **z = +0.22**.

This example replicates the phase-randomized variant on the **same
24-pulsar subset** using a NullPhys-certified `MatchedSpectrum`
implementation (per-pulsar rFFT phase rotation with Hermitian
symmetry; Lean theorem
`NullPhys.MatchedSpectrum.preserves_amplitudeSpectrum` certifies the
per-frequency norm invariance).

### Result (2026-05-20)

| Quantity | Value | Published |
|---|---|---|
| λ_max(C) (real) | 4.532 | 4.609 |
| Null mean | 4.508 | 4.498 |
| Null std (N=100 ours / 500 published) | 0.403 | 0.495 |
| **z** | **+0.06** | **+0.22** |

Mine matches the published phase-randomized z within sampling noise.
The +12.7σ headline in the project PLAYBOOK is the matched-Gaussian
null, which is a *different* null model and is **not** what NullPhys
v0.1 formalises — matched-Gaussian destroys the per-pulsar PSD, while
NullPhys's `MatchedSpectrum` preserves it.

### Reproducing

```bash
/usr/bin/python3 ~/workspace/nullphys/examples/nanograv_lambda_max_matched_spectrum.py
```

Reads `experiments/exp02_lesson_32_baseline/results.npz` (R, S matrices)
and `experiments/exp03_round_b/results_10yr.npz` (10-yr pulsar list +
published null distributions) from `~/workspace/nanograv-spectral`
read-only.

---

## 2D Ising at criticality — `UniformShuffle` density-vs-topology decomposition

**Files:** `tda_ising_uniform_shuffle.py`, `tda_ising_uniform_shuffle.png`, `tda_ising_uniform_shuffle.json`

The companion tda-phases project
([github.com/MattLoftus/tda-phases](https://github.com/MattLoftus/tda-phases))
result R3-3 (score 8.5) reports that **~94–96% of the H0
total-persistence signal in 2D Ising at T_C is density-driven** — a
shuffled-spins null reproduces it. H1 features by contrast carry
genuine topological information.

This example re-runs the H0-vs-H1 decomposition on a small Ising
ensemble (L=24, T=T_C, 15 configs, 10 NullPhys shuffles per config)
using the NullPhys-certified UniformShuffle. Every shuffle is asserted
post-hoc to preserve the spin multiset — the operational mirror of the
Lean theorem `NullPhys.UniformShuffle.preserves_labelMultiset`.

### Result (2026-05-20)

| Statistic | real | NullPhys shuffle null | ratio |
|---|---|---|---|
| H0 total persistence | 123.4 ± 8.0 | 123.1 ± 8.7 | **1.002** — density-driven |
| H1 total persistence | 112.1 ± 8.7 | 108.4 ± 10.1 | **1.034** — topological |

R3-3 finding qualitatively reproduces at small L: H0 ratio ≈ 1
(matches the published 94–96% density-driven), H1 ratio > 1 (genuine
topological signal). 150 NullPhys shuffles, **zero multiset
preservation failures**.

### Reproducing

```bash
PYTHONPATH=~/workspace/tda-phases \
    ~/workspace/tda-phases/.venv/bin/python3 \
    ~/workspace/nullphys/examples/tda_ising_uniform_shuffle.py
```

Imports `tda_phases.models.Ising2D` and
`tda_phases.filtrations.{point_cloud_alpha,persistence_stats}` from
`~/workspace/tda-phases` read-only. Outputs into `nullphys/examples/`.

### Reproducing

```bash
# Requires the JWST-biosignatures venv for petitRADTRANS and the
# K2-18b posterior medians.
cd ~/workspace/jwst-biosignatures && source venv/bin/activate
python ~/workspace/nullphys/examples/k2_18b_dms.py
```

The script writes `papers/figures/nullphys_k2_18b_dms.{png,json}` (in the
JWST-biosignatures repo) and the same files are mirrored into
`nullphys/examples/`. Both the Python implementation of `MatchedSpectrum`
phase rotation and the `UniformShuffle` permutation in the script are
covered by Lean theorems in `Nullphys/MatchedSpectrum.lean` and
`Nullphys/UniformShuffle.lean` respectively — those theorems guarantee
that what numpy is doing here is what the methodology claims it does.
