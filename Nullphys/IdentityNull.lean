import Nullphys.Basic

/-!
# NullPhys.IdentityNull

The identity null model: data passes through unchanged. The invariant is the
data itself, and it is trivially preserved.

This null exists as a sanity check for the `NullModel` API: if you can build it,
your typeclass plumbing works. It is also a useful baseline in benchmarks:
"is the test discriminating better than doing nothing?"
-/

namespace NullPhys.IdentityNull

/-- The identity null on `Data`, parameterized by `Unit`. -/
def model (Data : Type _) : NullPhys.NullModel Data Unit Data where
  apply _ d := d
  invariant d := d
  preserves _ _ := rfl

@[simp] theorem apply_eq (Data : Type _) (p : Unit) (d : Data) :
    (model Data).apply p d = d := rfl

@[simp] theorem invariant_eq (Data : Type _) (d : Data) :
    (model Data).invariant d = d := rfl

/-- Smoke test: applying the identity null is the identity on the data. -/
example : (model Nat).apply () 42 = 42 := by native_decide

/-- Smoke test: the invariant of the identity null on a list is the list itself. -/
example : (model (List Nat)).invariant [1, 2, 3] = [1, 2, 3] := by native_decide

end NullPhys.IdentityNull
