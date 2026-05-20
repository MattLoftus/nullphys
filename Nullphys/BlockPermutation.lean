import Mathlib.Data.Finset.Card
import Mathlib.Data.Finset.Filter
import Mathlib.Data.Finset.Image
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Multiset.Basic
import Mathlib.Logic.Equiv.Defs
import Nullphys.Basic

/-!
# NullPhys.BlockPermutation

The block-permutation null. Generalization of `UniformShuffle`: positions are
partitioned into blocks by a block-assignment function `block : Fin n → β`,
and the null is restricted to permutations that respect that block structure
(i.e. send each block to itself).

The invariant is the *per-block multiset*: for each block `b : β`, the
multiset of values at positions in block `b` is preserved. This is the
canonical null for tests where within-group exchangeability holds but
across-group exchangeability does not — e.g. randomization tests with
stratification, paired samples, or time-series block bootstraps.

`UniformShuffle` is the special case `β = Unit` (one block).
-/

namespace NullPhys.BlockPermutation

variable {α : Type _} {β : Type _} [DecidableEq β] {n : ℕ}

/-- A sample of length `n` over `α`: a function from positions to values. -/
abbrev Sample (α : Type _) (n : ℕ) : Type _ := Fin n → α

/-- A block assignment: a function from positions to block labels. -/
abbrev Block (n : ℕ) (β : Type _) : Type _ := Fin n → β

/-- A permutation of positions that respects the block assignment: it sends
    each position to one with the same block label. Equivalently, it acts
    as a permutation within each block. -/
structure BlockedPerm (block : Block n β) where
  perm : Equiv.Perm (Fin n)
  preserves_block : ∀ i, block (perm i) = block i

/-- Apply a blocked permutation to a sample by reindexing. -/
def apply {block : Block n β} (σ : BlockedPerm block) (s : Sample α n) : Sample α n :=
  s ∘ σ.perm

/-- The multiset of values at positions belonging to block `b`. This is
    indexed by block label; the full invariant is the function
    `b ↦ blockMultiset block s b`. -/
def perBlockMultiset (block : Block n β) (s : Sample α n) : β → Multiset α :=
  fun b => ((Finset.univ : Finset (Fin n)).filter (fun j => block j = b)).val.map s

/-- The fundamental theorem of `BlockPermutation`: a block-respecting
    permutation preserves the per-block multiset for every block. -/
theorem preserves_perBlockMultiset
    {block : Block n β} (σ : BlockedPerm block) (s : Sample α n) :
    perBlockMultiset block (apply σ s) = perBlockMultiset block s := by
  funext b
  unfold perBlockMultiset apply
  show Multiset.map (s ∘ ⇑σ.perm)
         ((Finset.univ : Finset (Fin n)).filter (fun j => block j = b)).val
       = Multiset.map s
         ((Finset.univ : Finset (Fin n)).filter (fun j => block j = b)).val
  rw [show (s ∘ ⇑σ.perm) = s ∘ (⇑σ.perm) from rfl, ← Multiset.map_map]
  congr 1
  -- Goal: Multiset.map σ.perm (filter (block · = b) univ).val
  --     = (filter (block · = b) univ).val
  -- Strategy: prove the Finset equation S.map σ.toEmbedding = S, then
  -- take `.val` of both sides via Finset.map_val.
  set S : Finset (Fin n) := (Finset.univ : Finset (Fin n)).filter (fun j => block j = b) with hS
  have h_subset : S.map σ.perm.toEmbedding ⊆ S := by
    intro x hx
    simp only [hS, Finset.mem_map, Finset.mem_filter, Finset.mem_univ, true_and,
               Equiv.coe_toEmbedding] at hx
    obtain ⟨y, hy_block, rfl⟩ := hx
    simp only [hS, Finset.mem_filter, Finset.mem_univ, true_and]
    rw [σ.preserves_block]; exact hy_block
  have h_card : (S.map σ.perm.toEmbedding).card = S.card :=
    Finset.card_map σ.perm.toEmbedding
  have h_eq : S.map σ.perm.toEmbedding = S :=
    Finset.eq_of_subset_of_card_le h_subset h_card.ge
  have := congrArg Finset.val h_eq
  rwa [Finset.map_val] at this

/-- The block-permutation null packaged as a `NullModel`. -/
def model (α : Type _) (n : ℕ) {β : Type _} [DecidableEq β] (block : Block n β) :
    NullPhys.NullModel (Sample α n) (BlockedPerm block) (β → Multiset α) where
  apply := apply
  invariant := perBlockMultiset block
  preserves := preserves_perBlockMultiset

/-! ### Smoke tests -/

namespace SmokeTest

/-- A length-4 sample with values `[10, 20, 30, 40]`. -/
def s : Sample Nat 4 := ![10, 20, 30, 40]

/-- Block assignment: positions 0,1 → block `false`; positions 2,3 → block `true`. -/
def block : Block 4 Bool := ![false, false, true, true]

/-- Swap permutation `0 ↔ 1` — within-block (block `false`). -/
def swap01 : Equiv.Perm (Fin 4) := Equiv.swap (0 : Fin 4) (1 : Fin 4)

/-- The within-block swap as a `BlockedPerm`. -/
def bp : BlockedPerm block where
  perm := swap01
  preserves_block := by native_decide

/-- Theorem-level smoke test. -/
example : perBlockMultiset block (apply bp s) = perBlockMultiset block s :=
  preserves_perBlockMultiset bp s

/-- Computational smoke test via `native_decide`. -/
example : perBlockMultiset block (apply bp s) = perBlockMultiset block s := by
  funext b
  cases b <;> native_decide

end SmokeTest

end NullPhys.BlockPermutation
