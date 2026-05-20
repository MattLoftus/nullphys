---
title: 'NullPhys: A Lean 4 library for formally verified null models in empirical research'
tags:
  - Lean 4
  - Mathlib
  - formal verification
  - statistical methodology
  - null models
  - permutation tests
authors:
  - name: Matthew Loftus
    orcid: 0009-0000-0000-0000
    affiliation: 1
affiliations:
  - name: Independent Researcher, Cedar Loop LLC
    index: 1
date: 20 May 2026
bibliography: paper.bib
---

# Summary

`NullPhys` is a Lean 4 + Mathlib library that formalizes the null models commonly
appearing in empirical hypothesis tests across physics, astronomy, machine learning,
and neuroscience. Each null model in the library is a record bundling three things:
a transformation on data, the statistical invariant the null preserves, and a
machine-checked proof that the transformation actually preserves that invariant.
Constructing a `NullModel` term without supplying the proof is impossible by the
type signature — unverified nulls are unforgeable.

Version 0.1 ships five foundational nulls:

| Module                       | Invariant preserved             | Theorem                       |
| ---------------------------- | ------------------------------- | ----------------------------- |
| `NullPhys.IdentityNull`      | the data itself                 | trivial                       |
| `NullPhys.UniformShuffle`    | label multiset                  | `preserves_labelMultiset`     |
| `NullPhys.BlockPermutation`  | per-block label multiset        | `preserves_perBlockMultiset`  |
| `NullPhys.MaslovSneppen`     | graph degree sequence           | `degreeSeq_applySwap`         |
| `NullPhys.MatchedSpectrum`   | per-frequency amplitude         | `preserves_amplitudeSpectrum` |

All theorems are kernel-checked under Lean 4 v4.30.0-rc2 + Mathlib v4.30.0-rc2.
The library contains no `sorry`s.

# Statement of need

Empirical papers routinely justify significance claims with phrases like "we used
a permutation test" or "we compared against degree-preserving random graphs" or
"the surrogate preserved the power spectrum." These statements are informal
guarantees about *what the null model conditions on*. The reader is asked to
trust that the implementation in the authors' analysis code actually preserves
what the methodology section claims it does. When this trust is misplaced, the
significance claim can be an artifact of the pipeline rather than a feature of
the data — a failure mode that has produced several recent retractions and
reanalysis disputes [@simmons2011; @gelman2014].

Existing Lean formalization libraries cover the *upstream* theory of statistical
learning: Rademacher complexity, McDiarmid's inequality, sub-Gaussian
concentration [@sonoda2026], symmetrization-based generalization bounds
[@rademacher2025], online false discovery rate control [@lordpp2024], and the
Probably Approximately Correct learning framework [@yuanhe2026]. None of these
covers the *downstream* methodology of specific null models invoked in empirical
papers. `NullPhys` fills that gap.

The intended user is an empirical researcher who wants their null-model assumption
to be kernel-checked rather than informally asserted. A planned companion package,
`nullphys-py`, will allow these verified implementations to be called from Python
analysis pipelines.

# Functionality

The core abstraction is the `NullModel` structure:

```lean
structure NullModel (Data Param Invariant : Type _) where
  apply : Param → Data → Data
  invariant : Data → Invariant
  preserves : ∀ (p : Param) (d : Data), invariant (apply p d) = invariant d
```

Each concrete null is a term of this type. The `preserves` field is the
fundamental theorem of the null. Because it is a field of the structure,
downstream consumers automatically get the invariance guarantee — they do
not have to look it up as a companion lemma.

Each null also ships `native_decide`-verified smoke tests on small concrete
samples, so that the executable behaviour can be inspected and trusted to
match the formal claim.

The harder formalizations in v0.1 are `MaslovSneppen` (the degree-preserving
double-edge swap from network science) and `MatchedSpectrum` (Fourier
amplitude-preserving phase rotation, the standard surrogate for time-series
significance testing). The Maslov–Sneppen proof proceeds by per-vertex
casework: for each of the four vertices touched by a swap, the swap
neighbourhood is expressed as `(old neighbourhood).erase x_out |>.insert x_in`,
and degree preservation reduces to `Finset` cardinality. For vertices outside
the swap, adjacency is unchanged. The MatchedSpectrum proof reduces to
`norm_mul` and Mathlib's `Complex.norm_exp_ofReal_mul_I`.

# Applications

`NullPhys` ships two demonstration applications in `examples/`, each
re-running a permutation-style significance test on real published data
using Python implementations of the nulls whose invariance properties are
certified by the corresponding Lean theorems.

**Exoplanet biosignatures (K2-18b DMS).** @madhusudhan2023 claimed a
$\sim$3$\sigma$ detection of dimethyl sulfide in the JWST transmission
spectrum of K2-18b — a contested biosignature claim subsequently rejected
on Bayesian grounds [@schmidt2025] and via independent retrievals in a
companion project. The `examples/k2_18b_dms.py` script rebuilds the
posterior-median base+CH4 forward model, computes chi-residuals, and tests
the chi² contribution from the 3.2–3.6 µm DMS window against
`MatchedSpectrum` and `UniformShuffle` null distributions. Both nulls
give $p \approx 0.7$ — the DMS-window chi² is in fact $\sim$0.6$\sigma$
*lower* than the null means. The NullPhys-certified frequentist test
corroborates the Bayesian rejection from an independent statistical
paradigm.

**Seismology (foreshock trivial-scalar).** A companion seismic-precursor
project reports that the trivial scalar "$\log_{10}$ Benioff energy in
the last five days of a 30-day window" discriminates pre-mainshock
windows from null windows at macro AUC = 0.779 across four leave-one-
region-out splits (California, Cascadia, Turkey, Italy) — beating an
elaborate template-bank apparatus and consistent with @trugman2019.
`examples/seismic_tls_blockperm.py` re-runs the permutation tests under
three NullPhys-certified nulls. `UniformShuffle` gives $z = +10.4$,
matching the published $z_\mathrm{iid} = +11.0$; `BlockPermutation` with
region-blocks gives $z = +11.2$ (label-balance-preserving null);
`BlockPermutation` with (region $\times$ 365-day) blocks gives $z = +9.5$,
comparable to the published 30-day circular-shift estimate of $z = +8.4$.
The signal is robust across all three structurally distinct nulls at
$z \gg 3$.

# Acknowledgements

`NullPhys` builds on Mathlib [@mathlib2020] and inherits its toolchain pinning
from the AutoMath project. The novelty audit consulted prior work in
@lordpp2024, @sonoda2026, and @physlean.

# References
