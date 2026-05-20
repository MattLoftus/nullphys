import Mathlib.Data.Multiset.Basic
import Mathlib.Logic.Equiv.Defs

/-!
# NullPhys.NullModel

The fundamental abstraction of NullPhys: a *null model* is a parameter-driven
transformation of data that preserves some statistical invariant. The invariant
is the property null samples must share with the original — it is what we
*condition on* when computing a null distribution.

Every concrete null model in the library is a term of `NullModel Data Param Invariant`,
and ships with a `preserves` proof certifying that the invariant really is invariant.
The proof is the whole point: it is the formal-verification version of the prose
sentence "this null preserves X."
-/

namespace NullPhys

/-- A null model on data of type `Data`, parameterized by `Param`, preserving
    the invariant computed by `invariant : Data → Invariant`. -/
structure NullModel (Data Param Invariant : Type _) where
  /-- Apply the null transformation with the given parameter. -/
  apply : Param → Data → Data
  /-- The statistical invariant that the null preserves. -/
  invariant : Data → Invariant
  /-- The fundamental theorem: applying the null leaves the invariant unchanged. -/
  preserves : ∀ (p : Param) (d : Data), invariant (apply p d) = invariant d

/-- Convenience: the invariant computed on a null sample equals the invariant on
    the original. This is just `preserves` repackaged for ergonomics. -/
theorem NullModel.invariant_apply {Data Param Invariant : Type _}
    (M : NullModel Data Param Invariant) (p : Param) (d : Data) :
    M.invariant (M.apply p d) = M.invariant d :=
  M.preserves p d

end NullPhys
