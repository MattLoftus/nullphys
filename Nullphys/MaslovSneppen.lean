import Mathlib.Data.Finset.Card
import Mathlib.Data.Finset.Filter
import Mathlib.Data.Finset.Image
import Mathlib.Data.Finset.Insert
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Fintype.Basic
import Mathlib.Logic.Basic
import Mathlib.Tactic.FinCases
import Mathlib.Tactic.Tauto
import Aesop
import Nullphys.Basic

/-!
# NullPhys.MaslovSneppen

The Maslov–Sneppen degree-preserving graph rewire null model. Given a simple
undirected loopless graph `G` on `Fin n` and a valid double-edge swap
certificate `(a, b, c, d)` — meaning `{a,b}` and `{c,d}` are edges, and
`{a,c}`, `{b,d}` are not — replace `{a,b}, {c,d}` with `{a,c}, {b,d}`.

The invariant: the degree of every vertex is preserved. This is the canonical
null for tests where the question is "is this network structure beyond what
its degree sequence forces?" — used in food-webs (Maslov & Sneppen 2002),
protein interaction networks, brain connectomes.

If the certificate is not a valid swap on `G`, `apply` returns `G` unchanged
(so the invariance theorem holds trivially in that branch). This sidesteps the
dependent-parameter API issue: `Param` does not depend on `Data`.
-/

namespace NullPhys.MaslovSneppen

variable {n : ℕ}

/-- A finite undirected loopless graph on `Fin n`. -/
structure FiniteGraph (n : ℕ) where
  Adj : Fin n → Fin n → Bool
  symm : ∀ u v, Adj u v = Adj v u
  loopless : ∀ v, Adj v v = false

/-- The degree of vertex `v`: number of `u` with `Adj v u = true`. -/
def degree (G : FiniteGraph n) (v : Fin n) : ℕ :=
  ((Finset.univ : Finset (Fin n)).filter (fun u => G.Adj v u = true)).card

/-- The degree sequence. -/
def degreeSeq (G : FiniteGraph n) : Fin n → ℕ := degree G

/-- A double-edge swap candidate, encoded as four vertices `(a, b, c, d)`. -/
abbrev Swap4 (n : ℕ) : Type := Fin n × Fin n × Fin n × Fin n

/-- A candidate is a valid swap on `G` iff `{a,b}` and `{c,d}` are edges,
    `a ≠ c`, `b ≠ d`, and `{a,c}`, `{b,d}` are not edges. -/
def IsValidSwap (G : FiniteGraph n) (s : Swap4 n) : Prop :=
  G.Adj s.1 s.2.1 = true ∧ G.Adj s.2.2.1 s.2.2.2 = true ∧
  s.1 ≠ s.2.2.1 ∧ s.2.1 ≠ s.2.2.2 ∧
  G.Adj s.1 s.2.2.1 = false ∧ G.Adj s.2.1 s.2.2.2 = false

instance (G : FiniteGraph n) (s : Swap4 n) : Decidable (IsValidSwap G s) := by
  unfold IsValidSwap; exact inferInstance

/-- All four vertices in a valid swap are pairwise distinct. -/
lemma swap_distinct {G : FiniteGraph n} {s : Swap4 n} (h : IsValidSwap G s) :
    s.1 ≠ s.2.1 ∧ s.2.2.1 ≠ s.2.2.2 ∧ s.1 ≠ s.2.2.2 ∧ s.2.1 ≠ s.2.2.1 := by
  obtain ⟨hab, hcd, hac, hbd, not_ac, not_bd⟩ := h
  refine ⟨?_, ?_, ?_, ?_⟩
  · intro heq; rw [← heq] at hab; rw [G.loopless] at hab; exact Bool.false_ne_true hab
  · intro heq; rw [← heq] at hcd; rw [G.loopless] at hcd; exact Bool.false_ne_true hcd
  · intro heq
    rw [G.symm] at not_ac
    rw [← heq] at hcd
    exact Bool.false_ne_true (not_ac.symm.trans hcd)
  · intro heq
    rw [← heq] at not_ac
    exact Bool.false_ne_true (not_ac.symm.trans hab)

/-- The swapped adjacency function: `{a,b}` and `{c,d}` become non-edges,
    `{a,c}` and `{b,d}` become edges, everything else unchanged. -/
def swappedAdj (s : Swap4 n) (G : FiniteGraph n) (u v : Fin n) : Bool :=
  if (u = s.1 ∧ v = s.2.1) ∨ (u = s.2.1 ∧ v = s.1) ∨
     (u = s.2.2.1 ∧ v = s.2.2.2) ∨ (u = s.2.2.2 ∧ v = s.2.2.1) then false
  else if (u = s.1 ∧ v = s.2.2.1) ∨ (u = s.2.2.1 ∧ v = s.1) ∨
          (u = s.2.1 ∧ v = s.2.2.2) ∨ (u = s.2.2.2 ∧ v = s.2.1) then true
  else G.Adj u v

/-- Symmetry of the swapped adjacency. -/
lemma swappedAdj_symm (s : Swap4 n) (G : FiniteGraph n) (u v : Fin n) :
    swappedAdj s G u v = swappedAdj s G v u := by
  unfold swappedAdj
  by_cases h_rem : (u = s.1 ∧ v = s.2.1) ∨ (u = s.2.1 ∧ v = s.1) ∨
                   (u = s.2.2.1 ∧ v = s.2.2.2) ∨ (u = s.2.2.2 ∧ v = s.2.2.1)
  · have h_rem' : (v = s.1 ∧ u = s.2.1) ∨ (v = s.2.1 ∧ u = s.1) ∨
                  (v = s.2.2.1 ∧ u = s.2.2.2) ∨ (v = s.2.2.2 ∧ u = s.2.2.1) := by
      rcases h_rem with ⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2⟩
      · exact Or.inr (Or.inl ⟨h2, h1⟩)
      · exact Or.inl ⟨h2, h1⟩
      · exact Or.inr (Or.inr (Or.inr ⟨h2, h1⟩))
      · exact Or.inr (Or.inr (Or.inl ⟨h2, h1⟩))
    rw [if_pos h_rem, if_pos h_rem']
  · have h_rem' : ¬((v = s.1 ∧ u = s.2.1) ∨ (v = s.2.1 ∧ u = s.1) ∨
                    (v = s.2.2.1 ∧ u = s.2.2.2) ∨ (v = s.2.2.2 ∧ u = s.2.2.1)) := by
      intro h
      apply h_rem
      rcases h with ⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2⟩
      · exact Or.inr (Or.inl ⟨h2, h1⟩)
      · exact Or.inl ⟨h2, h1⟩
      · exact Or.inr (Or.inr (Or.inr ⟨h2, h1⟩))
      · exact Or.inr (Or.inr (Or.inl ⟨h2, h1⟩))
    rw [if_neg h_rem, if_neg h_rem']
    by_cases h_add : (u = s.1 ∧ v = s.2.2.1) ∨ (u = s.2.2.1 ∧ v = s.1) ∨
                     (u = s.2.1 ∧ v = s.2.2.2) ∨ (u = s.2.2.2 ∧ v = s.2.1)
    · have h_add' : (v = s.1 ∧ u = s.2.2.1) ∨ (v = s.2.2.1 ∧ u = s.1) ∨
                    (v = s.2.1 ∧ u = s.2.2.2) ∨ (v = s.2.2.2 ∧ u = s.2.1) := by
        rcases h_add with ⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2⟩
        · exact Or.inr (Or.inl ⟨h2, h1⟩)
        · exact Or.inl ⟨h2, h1⟩
        · exact Or.inr (Or.inr (Or.inr ⟨h2, h1⟩))
        · exact Or.inr (Or.inr (Or.inl ⟨h2, h1⟩))
      rw [if_pos h_add, if_pos h_add']
    · have h_add' : ¬((v = s.1 ∧ u = s.2.2.1) ∨ (v = s.2.2.1 ∧ u = s.1) ∨
                      (v = s.2.1 ∧ u = s.2.2.2) ∨ (v = s.2.2.2 ∧ u = s.2.1)) := by
        intro h
        apply h_add
        rcases h with ⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2⟩
        · exact Or.inr (Or.inl ⟨h2, h1⟩)
        · exact Or.inl ⟨h2, h1⟩
        · exact Or.inr (Or.inr (Or.inr ⟨h2, h1⟩))
        · exact Or.inr (Or.inr (Or.inl ⟨h2, h1⟩))
      rw [if_neg h_add, if_neg h_add']
      exact G.symm u v

/-- The swap graph (well-defined when the swap is valid). -/
def swapGraph (G : FiniteGraph n) (s : Swap4 n) (h : IsValidSwap G s) : FiniteGraph n where
  Adj := swappedAdj s G
  symm := swappedAdj_symm s G
  loopless := fun v => by
    obtain ⟨hab_ne, hcd_ne, had_ne, hbc_ne⟩ := swap_distinct h
    obtain ⟨_, _, hac, hbd, _, _⟩ := h
    unfold swappedAdj
    have h1 : ¬ ((v = s.1 ∧ v = s.2.1) ∨ (v = s.2.1 ∧ v = s.1) ∨
                 (v = s.2.2.1 ∧ v = s.2.2.2) ∨ (v = s.2.2.2 ∧ v = s.2.2.1)) := by
      rintro (⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2⟩)
      · exact hab_ne (h1.symm.trans h2)
      · exact hab_ne (h2.symm.trans h1)
      · exact hcd_ne (h1.symm.trans h2)
      · exact hcd_ne (h2.symm.trans h1)
    rw [if_neg h1]
    have h2 : ¬ ((v = s.1 ∧ v = s.2.2.1) ∨ (v = s.2.2.1 ∧ v = s.1) ∨
                 (v = s.2.1 ∧ v = s.2.2.2) ∨ (v = s.2.2.2 ∧ v = s.2.1)) := by
      rintro (⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2⟩ | ⟨h1, h2⟩)
      · exact hac (h1.symm.trans h2)
      · exact hac (h2.symm.trans h1)
      · exact hbd (h1.symm.trans h2)
      · exact hbd (h2.symm.trans h1)
    rw [if_neg h2]
    exact G.loopless v

/-- Apply the swap if valid; otherwise return `G` unchanged. -/
def applySwap (G : FiniteGraph n) (s : Swap4 n) : FiniteGraph n :=
  if h : IsValidSwap G s then swapGraph G s h else G

/-! ### Degree preservation -/

/-- For `v ∉ {a, b, c, d}`, the swap leaves every adjacency `(v, u)` unchanged. -/
lemma swappedAdj_eq_of_v_notin (G : FiniteGraph n) (s : Swap4 n)
    (v : Fin n) (hv : v ≠ s.1 ∧ v ≠ s.2.1 ∧ v ≠ s.2.2.1 ∧ v ≠ s.2.2.2) (u : Fin n) :
    swappedAdj s G v u = G.Adj v u := by
  unfold swappedAdj
  obtain ⟨ha, hb, hc, hd⟩ := hv
  have h1 : ¬ ((v = s.1 ∧ u = s.2.1) ∨ (v = s.2.1 ∧ u = s.1) ∨
               (v = s.2.2.1 ∧ u = s.2.2.2) ∨ (v = s.2.2.2 ∧ u = s.2.2.1)) := by
    rintro (⟨h, _⟩ | ⟨h, _⟩ | ⟨h, _⟩ | ⟨h, _⟩)
    exacts [ha h, hb h, hc h, hd h]
  rw [if_neg h1]
  have h2 : ¬ ((v = s.1 ∧ u = s.2.2.1) ∨ (v = s.2.2.1 ∧ u = s.1) ∨
               (v = s.2.1 ∧ u = s.2.2.2) ∨ (v = s.2.2.2 ∧ u = s.2.1)) := by
    rintro (⟨h, _⟩ | ⟨h, _⟩ | ⟨h, _⟩ | ⟨h, _⟩)
    exacts [ha h, hc h, hb h, hd h]
  rw [if_neg h2]

/-- For `v ∉ {a, b, c, d}`, the degree is preserved trivially. -/
lemma degree_swap_eq_of_v_notin (G : FiniteGraph n) (s : Swap4 n) (h : IsValidSwap G s)
    (v : Fin n) (hv : v ≠ s.1 ∧ v ≠ s.2.1 ∧ v ≠ s.2.2.1 ∧ v ≠ s.2.2.2) :
    degree (swapGraph G s h) v = degree G v := by
  unfold degree
  congr 1
  ext u
  simp only [Finset.mem_filter, Finset.mem_univ, true_and]
  show (swappedAdj s G v u = true) ↔ (G.Adj v u = true)
  rw [swappedAdj_eq_of_v_notin G s v hv u]

/-- For `v = a`, the swap-neighborhood equals the `G`-neighborhood with `b` removed
    and `c` inserted. -/
private lemma neighborhood_swap_at_a {G : FiniteGraph n} {s : Swap4 n}
    (h : IsValidSwap G s) :
    (Finset.univ : Finset (Fin n)).filter (fun u => (swapGraph G s h).Adj s.1 u = true)
    = insert s.2.2.1
        (((Finset.univ : Finset (Fin n)).filter (fun u => G.Adj s.1 u = true)).erase s.2.1) := by
  have hh := h
  obtain ⟨hab_ne, hcd_ne, had_ne, hbc_ne⟩ := swap_distinct h
  obtain ⟨hab, hcd, hac, hbd, not_ac, not_bd⟩ := h
  ext u
  simp only [Finset.mem_filter, Finset.mem_insert, Finset.mem_erase, Finset.mem_univ, true_and]
  show ((swapGraph G s hh).Adj s.1 u = true) ↔ (u = s.2.2.1 ∨ (u ≠ s.2.1 ∧ G.Adj s.1 u = true))
  show (swappedAdj s G s.1 u = true) ↔ _
  unfold swappedAdj
  by_cases h1 : (s.1 = s.1 ∧ u = s.2.1) ∨ (s.1 = s.2.1 ∧ u = s.1) ∨
                (s.1 = s.2.2.1 ∧ u = s.2.2.2) ∨ (s.1 = s.2.2.2 ∧ u = s.2.2.1)
  · rw [if_pos h1]
    refine ⟨fun heq => absurd heq (by decide), ?_⟩
    rintro (h_uc | ⟨h_ub, h_adj⟩)
    · subst h_uc
      exfalso
      rcases h1 with ⟨_, h⟩ | ⟨h, _⟩ | ⟨_, h⟩ | ⟨h, _⟩
      · exact hbc_ne h.symm
      · exact hab_ne h
      · exact hcd_ne h
      · exact had_ne h
    · exfalso
      rcases h1 with ⟨_, h⟩ | ⟨h, _⟩ | ⟨h, _⟩ | ⟨h, _⟩
      · exact h_ub h
      · exact hab_ne h
      · exact hac h
      · exact had_ne h
  · rw [if_neg h1]
    by_cases h2 : (s.1 = s.1 ∧ u = s.2.2.1) ∨ (s.1 = s.2.2.1 ∧ u = s.1) ∨
                  (s.1 = s.2.1 ∧ u = s.2.2.2) ∨ (s.1 = s.2.2.2 ∧ u = s.2.1)
    · rw [if_pos h2]
      refine ⟨fun _ => ?_, fun _ => rfl⟩
      rcases h2 with ⟨_, h_uc⟩ | ⟨h, _⟩ | ⟨h, _⟩ | ⟨h, _⟩
      · left; exact h_uc
      · exact absurd h hac
      · exact absurd h hab_ne
      · exact absurd h had_ne
    · rw [if_neg h2]
      refine ⟨fun h_adj => ?_, ?_⟩
      · right
        refine ⟨?_, h_adj⟩
        intro h_ub; subst h_ub
        exact h1 (Or.inl ⟨rfl, rfl⟩)
      · rintro (h_uc | ⟨_, h_adj⟩)
        · exact absurd (Or.inl ⟨rfl, h_uc⟩) h2
        · exact h_adj

/-- For `v = b`, the swap-neighborhood equals the `G`-neighborhood with `a` removed
    and `d` inserted. -/
private lemma neighborhood_swap_at_b {G : FiniteGraph n} {s : Swap4 n}
    (h : IsValidSwap G s) :
    (Finset.univ : Finset (Fin n)).filter (fun u => (swapGraph G s h).Adj s.2.1 u = true)
    = insert s.2.2.2
        (((Finset.univ : Finset (Fin n)).filter (fun u => G.Adj s.2.1 u = true)).erase s.1) := by
  have hh := h
  obtain ⟨hab_ne, hcd_ne, had_ne, hbc_ne⟩ := swap_distinct h
  obtain ⟨hab, hcd, hac, hbd, not_ac, not_bd⟩ := h
  ext u
  simp only [Finset.mem_filter, Finset.mem_insert, Finset.mem_erase, Finset.mem_univ, true_and]
  show ((swapGraph G s hh).Adj s.2.1 u = true) ↔ (u = s.2.2.2 ∨ (u ≠ s.1 ∧ G.Adj s.2.1 u = true))
  show (swappedAdj s G s.2.1 u = true) ↔ _
  unfold swappedAdj
  by_cases h1 : (s.2.1 = s.1 ∧ u = s.2.1) ∨ (s.2.1 = s.2.1 ∧ u = s.1) ∨
                (s.2.1 = s.2.2.1 ∧ u = s.2.2.2) ∨ (s.2.1 = s.2.2.2 ∧ u = s.2.2.1)
  · rw [if_pos h1]
    refine ⟨fun heq => absurd heq (by decide), ?_⟩
    rintro (h_ud | ⟨h_ua, h_adj⟩)
    · subst h_ud
      exfalso
      rcases h1 with ⟨h, _⟩ | ⟨_, h⟩ | ⟨h, _⟩ | ⟨_, h⟩
      · exact hab_ne h.symm
      · exact had_ne h.symm
      · exact hbc_ne h
      · exact hcd_ne h.symm
    · exfalso
      rcases h1 with ⟨h, _⟩ | ⟨_, h⟩ | ⟨h, _⟩ | ⟨h, _⟩
      · exact hab_ne h.symm
      · exact h_ua h
      · exact hbc_ne h
      · exact hbd h
  · rw [if_neg h1]
    by_cases h2 : (s.2.1 = s.1 ∧ u = s.2.2.1) ∨ (s.2.1 = s.2.2.1 ∧ u = s.1) ∨
                  (s.2.1 = s.2.1 ∧ u = s.2.2.2) ∨ (s.2.1 = s.2.2.2 ∧ u = s.2.1)
    · rw [if_pos h2]
      refine ⟨fun _ => ?_, fun _ => rfl⟩
      rcases h2 with ⟨h, _⟩ | ⟨h, _⟩ | ⟨_, h_ud⟩ | ⟨h, _⟩
      · exact absurd h.symm hab_ne
      · exact absurd h hbc_ne
      · left; exact h_ud
      · exact absurd h hbd
    · rw [if_neg h2]
      refine ⟨fun h_adj => ?_, ?_⟩
      · right
        refine ⟨?_, h_adj⟩
        intro h_ua; subst h_ua
        exact h1 (Or.inr (Or.inl ⟨rfl, rfl⟩))
      · rintro (h_ud | ⟨_, h_adj⟩)
        · exact absurd (Or.inr (Or.inr (Or.inl ⟨rfl, h_ud⟩))) h2
        · exact h_adj

/-- For `v = c`, the swap-neighborhood equals the `G`-neighborhood with `d` removed
    and `a` inserted. -/
private lemma neighborhood_swap_at_c {G : FiniteGraph n} {s : Swap4 n}
    (h : IsValidSwap G s) :
    (Finset.univ : Finset (Fin n)).filter (fun u => (swapGraph G s h).Adj s.2.2.1 u = true)
    = insert s.1
        (((Finset.univ : Finset (Fin n)).filter (fun u => G.Adj s.2.2.1 u = true)).erase s.2.2.2) := by
  have hh := h
  obtain ⟨hab_ne, hcd_ne, had_ne, hbc_ne⟩ := swap_distinct h
  obtain ⟨hab, hcd, hac, hbd, not_ac, not_bd⟩ := h
  ext u
  simp only [Finset.mem_filter, Finset.mem_insert, Finset.mem_erase, Finset.mem_univ, true_and]
  show ((swapGraph G s hh).Adj s.2.2.1 u = true) ↔ (u = s.1 ∨ (u ≠ s.2.2.2 ∧ G.Adj s.2.2.1 u = true))
  show (swappedAdj s G s.2.2.1 u = true) ↔ _
  unfold swappedAdj
  by_cases h1 : (s.2.2.1 = s.1 ∧ u = s.2.1) ∨ (s.2.2.1 = s.2.1 ∧ u = s.1) ∨
                (s.2.2.1 = s.2.2.1 ∧ u = s.2.2.2) ∨ (s.2.2.1 = s.2.2.2 ∧ u = s.2.2.1)
  · rw [if_pos h1]
    refine ⟨fun heq => absurd heq (by decide), ?_⟩
    rintro (h_ua | ⟨h_ud, h_adj⟩)
    · subst h_ua
      exfalso
      rcases h1 with ⟨h, _⟩ | ⟨h, _⟩ | ⟨_, h⟩ | ⟨h, _⟩
      · exact hac h.symm
      · exact hbc_ne h.symm
      · exact had_ne h
      · exact hcd_ne h
    · exfalso
      rcases h1 with ⟨h, _⟩ | ⟨h, _⟩ | ⟨_, h⟩ | ⟨h, _⟩
      · exact hac h.symm
      · exact hbc_ne h.symm
      · exact h_ud h
      · exact hcd_ne h
  · rw [if_neg h1]
    by_cases h2 : (s.2.2.1 = s.1 ∧ u = s.2.2.1) ∨ (s.2.2.1 = s.2.2.1 ∧ u = s.1) ∨
                  (s.2.2.1 = s.2.1 ∧ u = s.2.2.2) ∨ (s.2.2.1 = s.2.2.2 ∧ u = s.2.1)
    · rw [if_pos h2]
      refine ⟨fun _ => ?_, fun _ => rfl⟩
      rcases h2 with ⟨h, _⟩ | ⟨_, h_ua⟩ | ⟨h, _⟩ | ⟨h, _⟩
      · exact absurd h.symm hac
      · left; exact h_ua
      · exact absurd h.symm hbc_ne
      · exact absurd h hcd_ne
    · rw [if_neg h2]
      refine ⟨fun h_adj => ?_, ?_⟩
      · right
        refine ⟨?_, h_adj⟩
        intro h_ud; subst h_ud
        exact h1 (Or.inr (Or.inr (Or.inl ⟨rfl, rfl⟩)))
      · rintro (h_ua | ⟨_, h_adj⟩)
        · exact absurd (Or.inr (Or.inl ⟨rfl, h_ua⟩)) h2
        · exact h_adj

/-- For `v = d`, the swap-neighborhood equals the `G`-neighborhood with `c` removed
    and `b` inserted. -/
private lemma neighborhood_swap_at_d {G : FiniteGraph n} {s : Swap4 n}
    (h : IsValidSwap G s) :
    (Finset.univ : Finset (Fin n)).filter (fun u => (swapGraph G s h).Adj s.2.2.2 u = true)
    = insert s.2.1
        (((Finset.univ : Finset (Fin n)).filter (fun u => G.Adj s.2.2.2 u = true)).erase s.2.2.1) := by
  have hh := h
  obtain ⟨hab_ne, hcd_ne, had_ne, hbc_ne⟩ := swap_distinct h
  obtain ⟨hab, hcd, hac, hbd, not_ac, not_bd⟩ := h
  ext u
  simp only [Finset.mem_filter, Finset.mem_insert, Finset.mem_erase, Finset.mem_univ, true_and]
  show ((swapGraph G s hh).Adj s.2.2.2 u = true) ↔ (u = s.2.1 ∨ (u ≠ s.2.2.1 ∧ G.Adj s.2.2.2 u = true))
  show (swappedAdj s G s.2.2.2 u = true) ↔ _
  unfold swappedAdj
  by_cases h1 : (s.2.2.2 = s.1 ∧ u = s.2.1) ∨ (s.2.2.2 = s.2.1 ∧ u = s.1) ∨
                (s.2.2.2 = s.2.2.1 ∧ u = s.2.2.2) ∨ (s.2.2.2 = s.2.2.2 ∧ u = s.2.2.1)
  · rw [if_pos h1]
    refine ⟨fun heq => absurd heq (by decide), ?_⟩
    rintro (h_ub | ⟨h_uc, h_adj⟩)
    · subst h_ub
      exfalso
      rcases h1 with ⟨h, _⟩ | ⟨h, _⟩ | ⟨h, _⟩ | ⟨_, h⟩
      · exact had_ne h.symm
      · exact hbd h.symm
      · exact hcd_ne h.symm
      · exact hbc_ne h
    · exfalso
      rcases h1 with ⟨h, _⟩ | ⟨h, _⟩ | ⟨h, _⟩ | ⟨_, h⟩
      · exact had_ne h.symm
      · exact hbd h.symm
      · exact hcd_ne h.symm
      · exact h_uc h
  · rw [if_neg h1]
    by_cases h2 : (s.2.2.2 = s.1 ∧ u = s.2.2.1) ∨ (s.2.2.2 = s.2.2.1 ∧ u = s.1) ∨
                  (s.2.2.2 = s.2.1 ∧ u = s.2.2.2) ∨ (s.2.2.2 = s.2.2.2 ∧ u = s.2.1)
    · rw [if_pos h2]
      refine ⟨fun _ => ?_, fun _ => rfl⟩
      rcases h2 with ⟨h, _⟩ | ⟨h, _⟩ | ⟨h, _⟩ | ⟨_, h_ub⟩
      · exact absurd h.symm had_ne
      · exact absurd h.symm hcd_ne
      · exact absurd h.symm hbd
      · left; exact h_ub
    · rw [if_neg h2]
      refine ⟨fun h_adj => ?_, ?_⟩
      · right
        refine ⟨?_, h_adj⟩
        intro h_uc; subst h_uc
        exact h1 (Or.inr (Or.inr (Or.inr ⟨rfl, rfl⟩)))
      · rintro (h_ub | ⟨_, h_adj⟩)
        · exact absurd (Or.inr (Or.inr (Or.inr ⟨rfl, h_ub⟩))) h2
        · exact h_adj

/-- The fundamental theorem of Maslov–Sneppen: a valid double-edge swap
    preserves the degree of every vertex. -/
theorem degree_swap_eq (G : FiniteGraph n) (s : Swap4 n) (h : IsValidSwap G s) (v : Fin n) :
    degree (swapGraph G s h) v = degree G v := by
  have hh := h  -- preserve a copy; the next line destructures
  obtain ⟨hab_ne, hcd_ne, had_ne, hbc_ne⟩ := swap_distinct h
  obtain ⟨hab, hcd, hac, hbd, not_ac, not_bd⟩ := h
  by_cases hva : v = s.1
  · subst hva
    unfold degree
    rw [neighborhood_swap_at_a hh]
    have hb_in : s.2.1 ∈ (Finset.univ : Finset (Fin n)).filter (fun u => G.Adj s.1 u = true) := by
      simp [Finset.mem_filter, hab]
    have hc_notin_erase : s.2.2.1 ∉ ((Finset.univ : Finset (Fin n)).filter
        (fun u => G.Adj s.1 u = true)).erase s.2.1 := by
      simp [Finset.mem_erase, Finset.mem_filter, not_ac]
    rw [Finset.card_insert_of_notMem hc_notin_erase,
        Finset.card_erase_of_mem hb_in]
    have hpos : ((Finset.univ : Finset (Fin n)).filter (fun u => G.Adj s.1 u = true)).card > 0 :=
      Finset.card_pos.mpr ⟨s.2.1, hb_in⟩
    omega
  by_cases hvb : v = s.2.1
  · subst hvb
    unfold degree
    rw [neighborhood_swap_at_b hh]
    have ha_in : s.1 ∈ (Finset.univ : Finset (Fin n)).filter (fun u => G.Adj s.2.1 u = true) := by
      simp [Finset.mem_filter]; rw [G.symm]; exact hab
    have hd_notin_erase : s.2.2.2 ∉ ((Finset.univ : Finset (Fin n)).filter
        (fun u => G.Adj s.2.1 u = true)).erase s.1 := by
      simp [Finset.mem_erase, Finset.mem_filter, not_bd]
    rw [Finset.card_insert_of_notMem hd_notin_erase,
        Finset.card_erase_of_mem ha_in]
    have hpos : ((Finset.univ : Finset (Fin n)).filter (fun u => G.Adj s.2.1 u = true)).card > 0 :=
      Finset.card_pos.mpr ⟨s.1, ha_in⟩
    omega
  by_cases hvc : v = s.2.2.1
  · subst hvc
    unfold degree
    rw [neighborhood_swap_at_c hh]
    have hd_in : s.2.2.2 ∈ (Finset.univ : Finset (Fin n)).filter
        (fun u => G.Adj s.2.2.1 u = true) := by
      simp [Finset.mem_filter, hcd]
    have ha_notin_erase : s.1 ∉ ((Finset.univ : Finset (Fin n)).filter
        (fun u => G.Adj s.2.2.1 u = true)).erase s.2.2.2 := by
      simp [Finset.mem_erase, Finset.mem_filter]
      intro _; rw [G.symm]; exact not_ac
    rw [Finset.card_insert_of_notMem ha_notin_erase,
        Finset.card_erase_of_mem hd_in]
    have hpos : ((Finset.univ : Finset (Fin n)).filter (fun u => G.Adj s.2.2.1 u = true)).card > 0 :=
      Finset.card_pos.mpr ⟨s.2.2.2, hd_in⟩
    omega
  by_cases hvd : v = s.2.2.2
  · subst hvd
    unfold degree
    rw [neighborhood_swap_at_d hh]
    have hc_in : s.2.2.1 ∈ (Finset.univ : Finset (Fin n)).filter
        (fun u => G.Adj s.2.2.2 u = true) := by
      simp [Finset.mem_filter]; rw [G.symm]; exact hcd
    have hb_notin_erase : s.2.1 ∉ ((Finset.univ : Finset (Fin n)).filter
        (fun u => G.Adj s.2.2.2 u = true)).erase s.2.2.1 := by
      simp [Finset.mem_erase, Finset.mem_filter]
      intro _; rw [G.symm]; exact not_bd
    rw [Finset.card_insert_of_notMem hb_notin_erase,
        Finset.card_erase_of_mem hc_in]
    have hpos : ((Finset.univ : Finset (Fin n)).filter (fun u => G.Adj s.2.2.2 u = true)).card > 0 :=
      Finset.card_pos.mpr ⟨s.2.2.1, hc_in⟩
    omega
  exact degree_swap_eq_of_v_notin G s hh v ⟨hva, hvb, hvc, hvd⟩

theorem degreeSeq_applySwap (G : FiniteGraph n) (s : Swap4 n) :
    degreeSeq (applySwap G s) = degreeSeq G := by
  unfold applySwap
  split_ifs with h
  · funext v; exact degree_swap_eq G s h v
  · rfl

/-- The Maslov–Sneppen single-swap null packaged as a `NullModel`. -/
def model (n : ℕ) :
    NullPhys.NullModel (FiniteGraph n) (Swap4 n) (Fin n → ℕ) where
  apply := fun s G => applySwap G s
  invariant := degreeSeq
  preserves := fun s G => degreeSeq_applySwap G s

/-! ### Smoke tests -/

namespace SmokeTest

/-- The 4-cycle on `Fin 4`: edges `{0,1}, {1,2}, {2,3}, {3,0}`. -/
def cycle4Adj (u v : Fin 4) : Bool :=
  (u.val = 0 ∧ v.val = 1) ∨ (u.val = 1 ∧ v.val = 0) ∨
  (u.val = 1 ∧ v.val = 2) ∨ (u.val = 2 ∧ v.val = 1) ∨
  (u.val = 2 ∧ v.val = 3) ∨ (u.val = 3 ∧ v.val = 2) ∨
  (u.val = 3 ∧ v.val = 0) ∨ (u.val = 0 ∧ v.val = 3)

def cycle4 : FiniteGraph 4 where
  Adj := cycle4Adj
  symm := by decide
  loopless := by decide

/-- The "diagonal swap" on the 4-cycle: swap `{0,1}, {2,3}` to `{0,2}, {1,3}`. -/
def diagSwap : Swap4 4 := (⟨0, by decide⟩, ⟨1, by decide⟩, ⟨2, by decide⟩, ⟨3, by decide⟩)

example : IsValidSwap cycle4 diagSwap := by decide

/-- Theorem-level smoke: the diagonal swap preserves the degree sequence. -/
example : degreeSeq (applySwap cycle4 diagSwap) = degreeSeq cycle4 :=
  degreeSeq_applySwap cycle4 diagSwap

/-- Computational smoke test via `native_decide`. -/
example : degreeSeq (applySwap cycle4 diagSwap) = degreeSeq cycle4 := by
  funext v; fin_cases v <;> native_decide

end SmokeTest

end NullPhys.MaslovSneppen
