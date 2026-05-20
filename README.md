# NullPhys

**Lean 4 + Mathlib library for formally verifying null models used in empirical claims.**

Every null model in this library carries a machine-checked proof that it preserves
its stated statistical invariant. The proof is the whole point: it is the
formal-verification version of the prose sentence "this null preserves X."

[![Lean Action CI](https://github.com/MattLoftus/nullphys/actions/workflows/lean_action_ci.yml/badge.svg)](https://github.com/MattLoftus/nullphys/actions/workflows/lean_action_ci.yml)

## v0.1 modules

| Module | Data | Parameter | Invariant | Theorem |
|---|---|---|---|---|
| `NullPhys.IdentityNull` | any `Data` | `Unit` | `Data` itself | trivial (`rfl`) |
| `NullPhys.UniformShuffle` | `Fin n → α` | `Equiv.Perm (Fin n)` | `Multiset α` | `preserves_labelMultiset` |
| `NullPhys.BlockPermutation` | `Fin n → α` (with block assignment `Fin n → β`) | block-respecting `Equiv.Perm (Fin n)` | `β → Multiset α` | `preserves_perBlockMultiset` |
| `NullPhys.MaslovSneppen` | `FiniteGraph n` (Bool adjacency) | `Swap4 n` (4-vertex candidate) | `Fin n → ℕ` (degree sequence) | `degreeSeq_applySwap` (built on `degree_swap_eq`) |
| `NullPhys.MatchedSpectrum` | `Fin n → ℂ` (Fourier coefficients) | `Fin n → ℝ` (phases) | `Fin n → ℝ` (amplitude spectrum) | `preserves_amplitudeSpectrum` |

Every module ships a `model : NullPhys.NullModel Data Param Invariant` term packaging the
transformation and its invariance proof. The proof is a *field* of the structure, not a
companion lemma — you cannot construct a `NullModel` without supplying it. Unverified
nulls are unforgeable.

## Quickstart

```lean
import Nullphys.UniformShuffle

open NullPhys.UniformShuffle

-- A sample of length 3 over Nat.
def s : Sample Nat 3 := ![10, 20, 30]

-- A permutation (swap positions 0 and 1).
def σ : Equiv.Perm (Fin 3) := Equiv.swap 0 1

-- The null sample.
#eval apply σ s -- ![20, 10, 30] (as Fin 3 → Nat)

-- The proved invariant: shuffling preserves the multiset of labels.
example : labelMultiset (apply σ s) = labelMultiset s :=
  preserves_labelMultiset σ s
```

The `preserves_labelMultiset` theorem is *machine-checked* — Lean's kernel has
verified it. Any code that consumes a `NullPhys.NullModel` value gets the
invariance guarantee for free.

## Build

Requires [`elan`](https://github.com/leanprover/elan) (Lean version manager).
The toolchain is pinned in `lean-toolchain`; Lake will fetch the right Lean
automatically.

```bash
lake exe cache get   # fetch prebuilt Mathlib (avoids ~30 min compile)
lake build
```

Tested on Lean 4 v4.30.0-rc2 + Mathlib v4.30.0-rc2.

## Why

Strict null-model discipline distinguishes good empirical claims from
artifacts of the analysis pipeline. A typical research paper's "we used a
permutation test to establish significance" is informal — the reader trusts
that the permutation preserves what the test assumes it preserves.

NullPhys turns that trust into a kernel-checked proof.

The closest existing formalizations cover the *upstream* theory of statistical
learning:

- **LORD++** (Springer et al., ~855 lines) — online false discovery rate in Lean.
- **Sonoda et al.** (arXiv:2602.02285, Feb 2026, ~30k lines) — Rademacher
  complexity, McDiarmid's inequality, sub-Gaussian and Gaussian Lipschitz
  results in Lean.
- **arXiv:2503.19605** — Lean Rademacher generalization bound (symmetrization).
- **YuanheZ/lean-stat-learning-theory** — first comprehensive Lean 4 SLT library.
- **PhysLean** — physics theorems but explicitly not methodology.

None of these formalize the *specific* null models cited in empirical papers.
NullPhys fills that gap.

## Citing

```bibtex
@software{nullphys2026,
  author  = {Loftus, Matthew},
  title   = {{NullPhys}: A {Lean~4} library for formally verified null models},
  year    = {2026},
  url     = {https://github.com/MattLoftus/nullphys}
}
```

## License

Apache License 2.0 — see [LICENSE](LICENSE).
