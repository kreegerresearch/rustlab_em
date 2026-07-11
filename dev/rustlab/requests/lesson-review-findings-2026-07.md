# Request: Upstream Findings from the 2026-07 Full-Curriculum Review

**Status**: **Landed** (all 5 actionable items resolved upstream, verified 2026-07-05; 1 item closed at triage)
**Date opened**: 2026-07-04
**Origin**: `rustlab_em` full 17-lesson audit (see `dev/lesson-review-fixes.md`); every item below was reproduced first-hand against rustlab 0.3.6 on 2026-07-04
**Scope**: doc corrections, one compat note, one small feature — no new solver machinery requested

The curriculum review turned up **no rustlab engine bugs** — `spsolve` (complex-symmetric verified), `.'`/`'` semantics, the vector-calculus operators, `eigs`, `trapz`, and FFT all behaved exactly as documented under independent re-derivation. The items below are documentation errors, one footgun that deserves a louder warning, one silent behavior change, and one parser nicety.

Check the box when an item lands and fill in its **Resolution** line (commit / doc section / "won't fix" + reason).

---

## Checklist

- [x] **1. `max(M1, M2)` mask-union recommendation contradicts the interpreter** *(doc bug or missing feature — pick one)*
- [x] **2. Harmonic-mean rationale in `laplacian_eps_2d` docs is physically wrong** *(doc bug)*
- [x] **3. `'` conjugating-transpose footgun needs a warning near the complex/`spsolve` examples** *(doc hazard)*
- [x] **4. Non-integer indexing became a hard error — undocumented behavior change** *(compat note)*
- [x] **5. Complex literals `2j` / `1+2j` don't parse, yet values print in that form** *(feature / round-trip inconsistency)*
- [x] **6. Neumann BC for `laplacian_2d`** — *closed at triage: already shipped.*

---

## 1. `max(M1, M2)` union recommendation vs. interpreter rejection

**Where**: `../rustlab/docs/functions.md` — the `polygon_mask` entry ("Compose masks with element-wise math: `.* M2` (intersection), `1 - M` (complement), **`max(M1, M2)` (union)**, `M1 .* (1 - M2)` (set difference)").

**Problem**: rustlab 0.3.6 rejects the two-matrix form outright:

```
error: type error: max: two-argument form is only defined for two scalars;
for an axis reduction use max(M, [], dim)
```

Lesson 04 already warns students *against* `max(M1, M2)` — so the curriculum and the upstream reference actively contradict each other on the canonical mask-union idiom.

**Fix (either)**:
- **(a) preferred** — implement element-wise two-matrix `max(A, B)` / `min(A, B)` (broadcast rules as for `+`); this is the MATLAB-familiar spelling and also what several lesson exercises would naturally reach for; or
- **(b) minimum** — correct the doc to a working union idiom, e.g. `(M1 + M2) > 0` or `1 - (1-M1).*(1-M2)`, and mirror the same wording in the `rect_mask`/`disk_mask` entries if they repeat it.

**Resolution**: resolved via **(a)** — elementwise two-matrix `max(A, B)`/`min(A, B)` implemented (verified 2026-07-05: `max([1,5;3,2], [4,1;2,6])` → `[4,5;3,6]`); `functions.md` now demos `max(M1, M2)  # elementwise — union of two 0/1 masks`, so the `polygon_mask` union recommendation is now correct as written. Follow-on: Lesson 04's "don't write `max(M1, M2)`" warning is now stale — lesson-side update queued in the fix pass.

---

## 2. Harmonic-mean rationale in the `laplacian_eps_2d` docs

**Where**: `../rustlab/docs/functions.md`, `laplacian_eps_2d` entry: "The harmonic mean is the physically correct face-coefficient choice for piecewise-uniform media — it preserves flux continuity across material interfaces (where arithmetic-mean discretizations introduce artificial sources)."

**Problem**: the justification is wrong (the *conclusion* — use the harmonic mean — is right). Any flux-conservative face-coefficient scheme preserves discrete $D_n$ continuity by construction, arithmetic mean included; no "artificial sources" appear. The real argument: between adjacent nodes the flux crosses two half-cells in series, and the harmonic mean is the exact series composition — it reproduces the piecewise-linear interface solution exactly when the interface lies on a face, whereas an arithmetic mean mis-weights the interface cell and leaves an **O(h) accuracy** error in capacitance / voltage division (~0.45 % on Lesson 05's grid), not a conservation failure.

Lesson 05 carried the same wording; it is being corrected there (item 2.6 of `dev/lesson-review-fixes.md`) — this request keeps the two references from drifting apart again.

**Fix**: replace the parenthetical with the series-composition/accuracy argument above.

**Resolution**: resolved — `functions.md` (`laplacian_eps_2d` entry) now reads "the harmonic mean is the exact series composition of the two half-cell coefficients … An arithmetic mean is equally flux-conservative but mis-weights the interface cell, leaving an O(h) accuracy error" (verified 2026-07-05).

---

## 3. `'` conjugating-transpose warning near complex/`spsolve` examples

**Where**: `../rustlab/docs/functions.md` / `quickref.md`, wherever `spsolve` RHS-shaping or complex workflows are shown.

**Problem**: postfix `'` is a **conjugating** transpose (MATLAB-compatible, documented, verified: `([1,3]+j*[2,-1])'` → `1−2j, 3+1j`; `.'` leaves values intact). The innocuous-looking RHS-shaping pattern

```
b = src(:)';        # WRONG for complex src — silently conjugates
b = src(:).';       # correct
```

flipped the incident-wave direction in Lesson 10's FDFD scattering demo and shipped physically wrong plots plus a wrong physical narrative for a full release cycle. Nothing errors; the result is just quietly wrong — the worst failure mode. `rustlab_em` is fixing its own copies (`fdfd_2d_tmz.rlab`, notebook 10, and the recommended pattern in `lessons/_shared/em.rlab`).

**Fix**: a short warning callout in the `spsolve` doc entry (and/or the transpose-operator entry): "shaping a complex RHS with `'` conjugates it — use `.'`". A lint in the interpreter is *not* requested — `'` on complex data is legitimate and common.

**Resolution**: resolved — `quickref.md` operator table now warns: "`'` Conjugate transpose — **conjugates complex values**; to reshape complex data use `.'` (e.g. `src(:).'`, not `src(:)'`)" (verified 2026-07-05).

---

## 4. Non-integer indexing: silent behavior change between versions

**Where**: interpreter indexing semantics; changelog/migration docs.

**Problem**: rustlab 0.3.6 hard-errors on fractional indices:

```
error: runtime error: index 10.5 is invalid (must be a positive integer)
```

An earlier interpreter version accepted them (flooring): Lesson 05's `dielectric_slab.rlab` (`nxd/2` = 10.5) ran cleanly when `book/05` was captured, and now crashes — the committed rendered output silently went stale with no signal until re-render. The new strictness is the *right* behavior; the gap is that the change appears in no changelog or migration note, so downstream script owners have no way to know a re-validation sweep is needed.

**Fix**: (a) add the change to the release notes / a migration section in the docs ("scripts relying on implicit index flooring must switch to `floor()`/`round()` or integer arithmetic — e.g. `(n + 1) / 2` for odd `n`"); (b) optional nicety: extend the error message with the same hint.

**Resolution**: resolved, both parts — new `CHANGELOG.md` with a 0.3.6 migration subsection ("previous releases silently floored fractional indices; scripts that relied on implicit flooring must round explicitly"), and the runtime error now appends "round a computed index explicitly with floor()/round(), or use integer arithmetic" (both verified 2026-07-05). Fractional indices still hard-error, as intended.

---

## 5. Complex numeric literals don't parse, but values print in literal-like form

**Where**: parser; display formatting.

**Problem**: MATLAB-style imaginary literals are rejected —

```
x = 2j;         # parse error: expected newline or EOF, got Ident("j")
x = 1 + 2j;     # parse error inside matrix literals too
x = 1 + 2*j;    # OK (builtin j) — prints as: 1+2j
```

— yet the printer renders complex values as `1+2j`, i.e. output does not round-trip as input. Hit within minutes of writing complex test code; every MATLAB-habituated user will trip on it once.

**Fix (either)**: support `<number>j` / `<number>i` literal suffixes in the lexer (preferred — also removes the "did someone shadow `j`?" hazard), **or** change complex display to the parseable `1 + 2*j` form. Low priority.

**Resolution**: resolved via the lexer route — `2j` parses standalone and inside matrix literals (verified 2026-07-05: `x = 2j` → `0+2j`; `v = [1 + 2j, 3 - 1j]` builds correctly and `'`/`.'` semantics are unchanged), so printed values now round-trip as input.

---

## 6. ~~Neumann BC option for `laplacian_2d`~~ — already shipped

**Closed at triage.** The review initially flagged that Lesson 12 computes only TM (Dirichlet) waveguide modes and assumed a Neumann capability gap. Verification against 0.3.6 shows the `bc` selector already supports it: `laplacian_2d(nx, ny, "neumann")` builds the expected operator (and `laplacian_1d`/`_3d`/`laplacian_eps_2d` document the same selector). No upstream action needed — the follow-up is lesson-side: Lesson 12 can add the TE-mode family (TE₁₀ at $c/2a$ = 3.75 GHz is the guide's true dominant mode) using the shipped selector. Tracked as an enhancement note in `dev/lesson-review-fixes.md` item 2.20.

**Resolution**: already shipped upstream (verified on 0.3.6, 2026-07-04); lesson-side adoption tracked in `dev/lesson-review-fixes.md`.
