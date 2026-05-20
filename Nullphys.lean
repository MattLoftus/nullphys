import Nullphys.Basic
import Nullphys.IdentityNull
import Nullphys.UniformShuffle
import Nullphys.BlockPermutation
import Nullphys.MaslovSneppen
import Nullphys.MatchedSpectrum

/-!
# NullPhys

A Lean 4 library formally verifying null models commonly used in empirical
papers (physics, astronomy, ML, neuroscience). Each null model carries a
proof that it preserves its stated statistical invariant.

The v0.1 modules:

* `NullPhys.NullModel`        — the structure
* `NullPhys.IdentityNull`     — sanity check
* `NullPhys.UniformShuffle`   — multiset-preserving permutation of labels
-/
