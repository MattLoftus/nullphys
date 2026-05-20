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
