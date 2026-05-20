# NullPhys Playbook

## Current Architecture (2026-05-19)

| Layer | Status | Where |
|---|---|---|
| Toolchain | Lean 4 v4.30.0-rc2 + Mathlib v4.30.0-rc2 (matches AutoMath) | `lean-toolchain`, `lakefile.toml` |
| `NullModel` structure | Built ✓ | `Nullphys/Basic.lean` |
| `IdentityNull` | Built ✓ (2 `native_decide` smoke tests) | `Nullphys/IdentityNull.lean` |
| `UniformShuffle` | Built ✓ (`preserves_labelMultiset`, 1 `native_decide` smoke) | `Nullphys/UniformShuffle.lean` |
| `BlockPermutation` | Built ✓ (`preserves_perBlockMultiset`, 1 `native_decide` smoke) | `Nullphys/BlockPermutation.lean` |
| `MaslovSneppen` | Built ✓ (`degree_swap_eq` + `degreeSeq_applySwap`, 1 `native_decide` smoke) | `Nullphys/MaslovSneppen.lean` |
| `MatchedSpectrum` | Built ✓ (`preserves_amplitudeSpectrum`, theorem-level smoke) | `Nullphys/MatchedSpectrum.lean` |
| Capstone paper | Not started | — |

`lake build` passes (1839 jobs). All 5 nulls of v0.1 shipped with proved invariance theorems. Zero `sorry`s.

## Mission

Lean-checked library of null models commonly used in empirical claims
(physics, astronomy, ML, neuroscience). v0.1 ships 5 foundational nulls.
v1.0 ships a capstone paper: a Lean-verified re-test of one published
3–5σ claim where the methodology is what's questioned.

## Why this bridge works

- **Lean 4 stack already running.** AutoMath project pins v4.30.0-rc2; NullPhys mirrors it.
- **Null-model discipline is the distinguishing skill.** Cross-project Lesson #7 ("trivial baselines BEFORE elaborate methodology") — and seismic-precursors session 18 proved this with TLS vs scalar Benioff.
- **Almost nobody on Earth combines Lean 4 fluency + empirical-methodology fluency.** Compounding is high: every future empirical project of mine reuses the formalized null suite.

## Roadmap

### v0.1 — Foundation (COMPLETE 2026-05-19)

- [x] `NullModel` structure with `apply` / `invariant` / `preserves` API
- [x] `IdentityNull` — sanity check
- [x] `UniformShuffle` — multiset-preserving permutation of labels
- [x] `BlockPermutation` — per-block multiset preserved under block-respecting permutation
- [x] `MaslovSneppen` — degree-preserving graph rewire (hardest combinatorial proof; ~480 lines)
- [x] `MatchedSpectrum` — phase rotation preserves amplitude spectrum (sidesteps FFT via direct frequency-domain formulation)

### v0.1.1 — Publication readiness (2026-05-20)

- [x] LICENSE (Apache 2.0)
- [x] README polished with quickstart + all 5 module table + prior-work citations
- [x] CITATION.cff (GitHub citation standard)
- [x] CI workflow tightened (`use-mathlib-cache: true`)
- [x] JOSS paper draft (`paper.md` + `paper.bib`)
- [ ] Push to GitHub (`MattLoftus/nullphys`) — awaiting user approval
- [ ] JOSS submission

### v0.2 — Wiring

- [ ] `nullphys-py` bridge: Python wrapper that calls the Lean-verified implementation from Jupyter
- [ ] Reference-dataset test suite: each null reproduces a published null distribution to 3+ sig figs on a canonical dataset
- [ ] Documentation site (Verso or doc-gen4)

### v1.0 — Capstone paper

- [ ] Pick target: **K2-18b DMS (Madhusudhan 2023)** (recommended; JWST framework already at hand in `~/workspace/jwst-biosignatures`), or seismic-precursor TLS detector (self-applied), or one HCP-brain-network claim
- [ ] Pre-register hypothesis, null model, decision rule before retrieval runs
- [ ] State the test in Lean: "Given priors P, likelihood L, null N, Algorithm A computes marginal log-evidence; *theorem:* A is correct"
- [ ] Run formally-verified test on real data
- [ ] Cold-read score (independent subagent) before submission
- [ ] Submit to arXiv stat.ML + cross-list cs.LO; venue candidates: NeurIPS Reproducibility Track, Annals of Applied Statistics, JOSS (library), Statistical Science

## Design decisions (v0.1)

### Sample representation: `Fin n → α`, not `Vector α n`

`Sample α n := Fin n → α` avoids the `Mathlib.Vector` vs core `Vector`
ambiguity that's still settling in v4.30, and makes the multiset-preservation
proof a one-liner (`← Multiset.map_map` + `Finset.map_univ_equiv`).

### `NullModel` is a structure, not a class

Different null models preserve *different* invariants (multiset for
shuffle, degree sequence for Maslov–Sneppen, power spectrum for matched
spectrum). A class would require unifying all of these under one
`Invariant` type. A structure parameterized by `Invariant` is cleaner.

### `preserves` is a field of the structure, not a separate theorem

You can't construct a `NullModel` without supplying the preservation proof.
This makes the API *unforgeable*: a downstream user cannot pass off an
unverified null as verified.

## Risks (from kickoff)

- **Mathlib's measure-theoretic probability is growing.** Continuous-distribution surrogates may require dependent random variables Mathlib handles awkwardly. Mitigate: formalize discrete analogues first.
- **K2-18b is a moving target.** Multiple groups will publish reanalyses in 2026. If scooped on the result, the Lean library itself is still the unique contribution.
- **Lean 4 discrete FFT may be incomplete in Mathlib.** Mitigate: ship 4 nulls in v0.1 if `MatchedSpectrum` blocks.

## Time budget

- v0.1 (5 nulls + invariance proofs): 1–2 weeks CC time; calendar 3–6 weeks.
- Capstone paper: 1–2 weeks CC time; calendar 4–8 weeks.

## Methodology guardrails

- **Library tests itself.** Every null must reproduce a published-paper null distribution to 3+ sig figs on a canonical dataset.
- **Capstone is pre-registered** before any retrieval runs.
- **Cold-read scoring** before submission. If subagent scores <7.0 cold-read, reframe as methods note.
- **Novelty re-check** before submission (mandatory per CLAUDE.md).

## Novelty audit (2026-05-19)

Per RESEARCH_LEARNINGS #126 (crowded-room test, reverse: not crowded yet, but the room is filling).

- LORD++ (855 lines, online FDR in Lean) — methodological precedent, complements rather than competes.
- Sonoda et al. arXiv:2602.02285 (Feb 2026, 30,000 lines Lean 4 SLT in 500 hours Opus-4.5 wall time) — upstream theory (Rademacher, McDiarmid, sub-Gaussian, Gaussian Lipschitz), not downstream methodology. Sets the operating tempo.
- arXiv:2503.19605 — Lean Rademacher generalization bound (symmetrization).
- YuanheZ/lean-stat-learning-theory — first comprehensive Lean 4 SLT library.
- arXiv:2511.06701 — "Structural Enforcement of Statistical Rigor in AI-Driven Discovery" (Haskell + LORD++ Lean).
- PhysLean — physics theorems but explicitly not methodology.
- Mathlib has no random graphs.

None formalize "the null model used in *this specific published 3-5σ claim*" — the unique capstone angle.

**Window-closing risk: 6 months.** Move fast.

## Changelog

### 2026-05-20 — Session 2 (publication readiness)

- LICENSE (Apache 2.0) added
- README rewritten: full 5-module table, quickstart example, prior-work citations, build instructions, citation block, license note
- CITATION.cff added (GitHub citation standard)
- CI workflow tightened: scoped to `main` for push triggers + Mathlib cache enabled
- JOSS paper draft: `paper.md` (~500 words, summary + statement of need + functionality) and `paper.bib` (11 references including Mathlib, Sonoda et al., LORD++, Maslov-Sneppen 2002, Theiler 1992)
- All publication-ready artifacts in place; library is push-to-GitHub-and-submit-to-JOSS ready (awaiting user approval to push)
- `lake build` still passes (1839 jobs)

### 2026-05-19 — Session 1 (kickoff + full v0.1 in one session)

- Created repo, `lake init`, toolchain → v4.30.0-rc2, Mathlib dependency.
- `NullModel` structure defined.
- `IdentityNull` shipped with `native_decide` smoke tests.
- `UniformShuffle` shipped: `preserves_labelMultiset` proved via `Multiset.map_map` + `Finset.map_univ_equiv`, plus `native_decide` smoke on `Fin 3 → Nat`.
- `BlockPermutation` shipped: generalizes UniformShuffle to a partition; `preserves_perBlockMultiset` proved via Finset-image-is-a-subset-with-equal-cardinality argument. `native_decide` smoke on 4-element 2-block sample.
- `MaslovSneppen` shipped (the hard one): `FiniteGraph` data type, `IsValidSwap` predicate, `swapGraph` constructor proven symmetric and loopless, and the main `degree_swap_eq` theorem proved by case analysis on `v ∈ {a,b,c,d}` vs `v ∉ {a,b,c,d}`. Each of the four in-set cases gets its own `neighborhood_swap_at_X` lemma computing the swap-neighborhood as `insert x_in ((G-neighborhood).erase x_out)`, and the out-set case uses a direct unchanged-adjacency lemma. `native_decide` smoke on the diagonal swap of a 4-cycle.
- `MatchedSpectrum` shipped: direct frequency-domain formulation avoids the discrete-FFT-in-Mathlib risk noted in the kickoff. Phase rotation `xhat_k ↦ xhat_k · exp(i φ_k)` preserves amplitude spectrum, proved in 4 lines via `norm_mul` + `Complex.norm_exp_ofReal_mul_I`. Noncomputable (ℂ/ℝ not decidable), so theorem-level smoke only.
- `lake build` passes (1839 jobs). Zero `sorry`s across the library.
- PLAYBOOK + README written and updated.

**Time to v0.1:** ~1 session (significantly faster than the kickoff's 1–2 weeks CC estimate). Bottleneck was `MaslovSneppen` proof — three rounds of iteration on the per-vertex casework. The shortcut for `MatchedSpectrum` (work in frequency domain directly, leave DFT to the caller) sidestepped what was flagged as the biggest risk.
