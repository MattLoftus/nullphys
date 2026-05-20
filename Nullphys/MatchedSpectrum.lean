import Mathlib.Analysis.Complex.Basic
import Mathlib.Analysis.Complex.Trigonometric
import Nullphys.Basic

/-!
# NullPhys.MatchedSpectrum

The matched-spectrum surrogate null. Given a complex frequency-domain sample
`xhat : Fin n → ℂ` (the Fourier coefficients of a time series) and a tuple of
phase angles `φ : Fin n → ℝ` (one per frequency), the null acts by rotating
each coefficient: `xhat_k ↦ xhat_k · exp(i φ_k)`.

The invariant is the *amplitude spectrum* `k ↦ ‖xhat_k‖` (equivalently the
power spectrum `k ↦ ‖xhat_k‖²`, since norms are non-negative). Phase rotation
preserves the modulus.

This is the canonical null for time-series tests where the question is "is the
signal more structured than its power-spectrum allows?" — used in EEG/MEG
significance testing, climate time series, financial returns. To get an
inverse-FFTed real-valued surrogate one also has to enforce Hermitian
symmetry (`φ_{n-k} = -φ_k`); the present formulation works on complex
spectra directly and leaves time-domain reconstruction to the caller.
-/

namespace NullPhys.MatchedSpectrum

variable {n : ℕ}

/-- A frequency-domain sample: complex Fourier coefficients indexed by `Fin n`. -/
abbrev FreqSample (n : ℕ) : Type := Fin n → ℂ

/-- A per-frequency phase shift in radians. -/
abbrev PhaseShift (n : ℕ) : Type := Fin n → ℝ

/-- Apply phase randomization: rotate each Fourier coefficient. -/
noncomputable def apply (φ : PhaseShift n) (xhat : FreqSample n) : FreqSample n :=
  fun k => xhat k * Complex.exp ((φ k : ℂ) * Complex.I)

/-- The amplitude spectrum: per-frequency magnitude. -/
noncomputable def amplitudeSpectrum (xhat : FreqSample n) : Fin n → ℝ :=
  fun k => ‖xhat k‖

/-- The fundamental theorem of MatchedSpectrum: phase rotation preserves the
    amplitude spectrum. -/
theorem preserves_amplitudeSpectrum (φ : PhaseShift n) (xhat : FreqSample n) :
    amplitudeSpectrum (apply φ xhat) = amplitudeSpectrum xhat := by
  funext k
  unfold amplitudeSpectrum apply
  rw [norm_mul, Complex.norm_exp_ofReal_mul_I, mul_one]

/-- The matched-spectrum null packaged as a `NullModel`. -/
noncomputable def model (n : ℕ) :
    NullPhys.NullModel (FreqSample n) (PhaseShift n) (Fin n → ℝ) where
  apply := apply
  invariant := amplitudeSpectrum
  preserves := preserves_amplitudeSpectrum

/-! ### Smoke tests

We cannot use `native_decide` here because ℂ/ℝ are not computable in Lean,
but the theorem-level smoke test confirms the API. -/

namespace SmokeTest

/-- A fixed frequency-domain sample on `Fin 3`. -/
def xhat : FreqSample 3 := fun k =>
  match k with
  | ⟨0, _⟩ => (1 : ℂ) + 2 * Complex.I
  | ⟨1, _⟩ => (3 : ℂ) + 4 * Complex.I
  | _      => (5 : ℂ) + 6 * Complex.I

/-- A fixed phase shift. -/
def φ : PhaseShift 3 := fun k =>
  match k with
  | ⟨0, _⟩ => 1.0
  | ⟨1, _⟩ => 2.0
  | _      => 3.0

/-- Theorem-level smoke test: the phase rotation preserves the amplitude
    spectrum. -/
example : amplitudeSpectrum (apply φ xhat) = amplitudeSpectrum xhat :=
  preserves_amplitudeSpectrum φ xhat

end SmokeTest

end NullPhys.MatchedSpectrum
