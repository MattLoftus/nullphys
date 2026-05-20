import Mathlib.Data.Fintype.Perm
import Mathlib.Data.Multiset.Basic
import Mathlib.Data.Multiset.Fintype
import Mathlib.Logic.Equiv.Defs
import Mathlib.Logic.Equiv.Fin.Basic
import Nullphys.Basic

/-!
# NullPhys.UniformShuffle

The uniform label-shuffle null model. A *sample* of length `n` over `α` is a
function `Sample α n := Fin n → α` (equivalently, an `n`-tuple of `α`-valued
labels indexed by position). The null acts on a sample by reindexing through
a permutation `σ ∈ S_n`; it preserves the multiset of label values.

This is the canonical null for tests where the question is "are values
associated with positions in a non-random way?" — e.g. randomization tests
in psychology, label-permutation in cross-validation significance testing,
shuffled-control sanity checks.

What this null does NOT preserve: any positional structure. Two values
that were adjacent in the original sample are not guaranteed to remain
adjacent. For position-sensitive nulls, see `BlockPermutation` (v0.2).
-/

namespace NullPhys.UniformShuffle

variable {α : Type _} {n : ℕ}

/-- A sample of length `n` over `α`: a function from positions to values. -/
abbrev Sample (α : Type _) (n : ℕ) : Type _ := Fin n → α

/-- Apply the uniform shuffle null with permutation `σ`: reindex the sample. -/
def apply (σ : Equiv.Perm (Fin n)) (s : Sample α n) : Sample α n := s ∘ σ

/-- The multiset of label values in a sample. This is the invariant the null
    preserves: shuffling labels across positions cannot change the bag of
    label values that appear. -/
def labelMultiset (s : Sample α n) : Multiset α :=
  (Finset.univ : Finset (Fin n)).val.map s

/-- The fundamental theorem of UniformShuffle: reindexing a sample by a
    permutation preserves the multiset of label values. -/
theorem preserves_labelMultiset (σ : Equiv.Perm (Fin n)) (s : Sample α n) :
    labelMultiset (apply σ s) = labelMultiset s := by
  unfold labelMultiset apply
  show Multiset.map (s ∘ ⇑σ) Finset.univ.val = Multiset.map s Finset.univ.val
  rw [← Multiset.map_map]
  congr 1
  -- Remaining: Multiset.map σ Finset.univ.val = Finset.univ.val
  rw [show Multiset.map (⇑σ) (Finset.univ : Finset (Fin n)).val
        = ((Finset.univ : Finset (Fin n)).map σ.toEmbedding).val
        from (Finset.map_val σ.toEmbedding Finset.univ).symm,
      Finset.map_univ_equiv]

/-- The uniform-shuffle null packaged as a `NullModel`. -/
def model (α : Type _) (n : ℕ) :
    NullPhys.NullModel (Sample α n) (Equiv.Perm (Fin n)) (Multiset α) where
  apply := apply
  invariant := labelMultiset
  preserves := preserves_labelMultiset

/-! ### Smoke tests -/

namespace SmokeTest

/-- Sample `[10, 20, 30]` as `Fin 3 → Nat`. -/
def s : Sample Nat 3 := ![10, 20, 30]

/-- The swap permutation `0 ↔ 1`. -/
def swap01 : Equiv.Perm (Fin 3) := Equiv.swap (0 : Fin 3) (1 : Fin 3)

/-- Smoke test: the swap preserves the label multiset (via the theorem). -/
example : labelMultiset (apply swap01 s) = labelMultiset s :=
  preserves_labelMultiset swap01 s

/-- Computational smoke test: native_decide actually evaluates both sides. -/
example : labelMultiset (apply swap01 s) = labelMultiset s := by native_decide

end SmokeTest

end NullPhys.UniformShuffle
