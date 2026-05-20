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
