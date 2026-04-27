## Plan Filed

**Implementation plan:** `../../../../rustlab/dev/plans/em_requests_plan.md` (filed 2026-04-26).
**Action queue:** `../../../../rustlab/dev/plans/em_requests_queue.md` — execution-oriented companion with per-item commit references.

## Status (last updated 2026-04-26)

| § | Item | Status | Commit / Notes |
|---|---|---|---|
| §2.5 | rasterization masks (`rect_mask`, `disk_mask`, `polygon_mask`) | **shipped** | `5791ec0`. See `gallery/masks.md`. |
| §2.3 | sparse `spsolve` (Cholesky + LU + AMD ordering, hand-rolled pure Rust) | **shipped** | `6623496`, `e9283b7`, `5feef19`. See `gallery/sparse_solve.md`, `gallery/sparse_scaling.md`, `gallery/electrostatics.md`, `gallery/sparse_complex.md`. Per-phase plan in `dev/plans/sparse_solve_handroll.md`; perf in `perf/sparse_solve_phase1to4.md`. |
| §2.1 + §2.2 | Laplacian boundary conditions, 1-D / 3-D variants, `laplacian_eps_2d` | **shipped** | `26954a3`. See `gallery/laplacian_bc.md`, `gallery/dielectric.md`. |
| §2.4 | sparse `eigs(A, n)` and `eigs(A, B, n)` | **next** | Hand-rolled Lanczos + Arnoldi on top of the rustlab-core `SparseChol` / `SparseLU` from §2.3. |
| §4 | real-typed elem-ops (Option A pragmatic fix) | pending | |
| §2.7 | polar / log-axis plots | pending | |
| §2.6 Phase 1 | Yee + SC-PML scripted library | pending | curriculum-side, no upstream rustlab change |
| §2.6 Phase 2 | Yee + SC-PML native crate | blocked on graduation trigger | 3-D Yee / >5s assembly / second physics curriculum / language wall |

## Decisions, as actually applied

1. **§2.3 sparse solver:** **hand-rolled, pure Rust, in `rustlab-core`**, NOT `faer`. The original plan adopted `faer` (MIT-or-Apache-2.0); the user vetoed it post-plan as too large a library. `AGENTS.md` Rule 9 codifies the broader policy. The hand-rolled implementation hits all acceptance criteria — see `perf/sparse_solve_phase1to4.md`.
2. **§2.4 eigensolver:** hand-rolled Lanczos / Arnoldi on top of the rustlab-core `SparseChol` / `SparseLU` from §2.3 (not `faer` LU). Pure Rust only. Implicit restart and shift-invert deferred to a follow-up if curriculum problems hit convergence walls.
3. **§2.6 Yee + SC-PML:** two-phase as planned. Phase 1 = scripted library in `rustlab_em/lessons/_shared/em.r` (no upstream rustlab change). Phase 2 = upstream `rustlab-em` workspace crate, only if graduation triggers fire.
4. **§4 real-typed elem-ops:** Option A (4-line guard zeroing imag when both inputs were essentially real, ~50 LoC). Options B/C deferred to a separate plan.

**General policy:** no GPL/LGPL/AGPL/copyleft, no Fortran/C++ FFI, no large libraries for core algorithms. Pure-Rust MIT/Apache-2.0 hand-rolls are the default for core work. Codified as `AGENTS.md` Rule 9.

**Estimate vs actuals:** the original 6-8 week estimate assumed standard senior pace and a `faer`-based §2.3 wrapper. Actual ship pace was substantially faster — Items 1, 2, 3 fit into roughly one calendar day of focused work — because the hand-rolling was algorithmic-port work (Davis chapters 4, 6, 7) rather than greenfield design, and because `is_hermitian` / `is_spd_estimate` helpers from Item 2 served Item 3 directly. Item 4 (eigs) is expected to take similar time.

---

## Lessons Reviewed

This summary is built from a sweep across:
- `notebooks/0[1-3]*.md` and `lessons/0[1-3]*/*.r` — drafted lessons, where workarounds are observable.
- `notebooks/0[4-9]*.md`, `notebooks/1[0-4]*.md`, `dev/plans.md` — planned lessons, where the gaps will show up.
- `../rustlab/docs/quickref.md` and `../rustlab/docs/functions.md` — what is actually shipped.

---

## 1. Already Shipped — `Status:` Updates Needed

These features are in `rustlab/docs/quickref.md` and used by Lessons 01–03. The corresponding request files still say `Status: Proposed`.

| Feature | Used in | Request file | Action |
|---|---|---|---|
| `gradient`, `divergence`, `curl` (+ 3-D) | Lessons 01, 02, 03 | [`vector-calculus-operators.md`](vector-calculus-operators.md) | Mark **Landed** |
| `quiver`, `streamplot` | Lessons 01, 02, 03 | [`quiver-and-streamplot.md`](quiver-and-streamplot.md) | Mark **Landed** |
| `contour`, `contourf` | Lessons 01, 03 | [`contour-plots.md`](contour-plots.md) | Mark **Landed** |
| `laplacian_2d` (Dirichlet, 2-D), `ij2k`, `k2ij` | Lessons 05, 06, 10, 12 | [`laplacian-stencil-builder.md`](laplacian-stencil-builder.md) | Mark **Landed (partial)** — see §2.1 |

The priority table in [`README.md`](README.md) still calls items 1–3 "High — blocking 01–03"; update that table at the same time.

---

## 2. New Requests — Need Files

These are listed in `AGENTS.md §Rustlab Feature Recommendations` and `dev/plans.md §Rustlab Dependencies` but have no spec under `dev/rustlab/requests/`. Each one blocks at least one planned lesson.

### 2.1 `laplacian_2d` extensions — Neumann, periodic, 1-D, 3-D

**Origin:** Lessons 05, 06, 10, 12.
**Why:** `functions.md:1260` says "Neumann and periodic boundary conditions, along with 1-D and 3-D variants, are not implemented in v1." Lesson 06 (`vector_potential_2d.r`) wants Neumann for the open boundary. Lesson 12 (`waveguide_modes.r`) wants Neumann for TE-mode cutoffs. Lesson 11 (FDTD) wants periodic for Bloch-style infinite slabs.
**Scope:** Add a fourth argument to `laplacian_2d(nx, ny, dx, dy, bc)` accepting `"dirichlet"` (default), `"neumann"`, `"periodic"`. Add `laplacian_1d(nx, dx)` and `laplacian_3d(nx, ny, nz, dx, dy, dz)`.

### 2.2 Variable-coefficient Laplacian — `laplacian_eps_2d(eps_map, dx, dy)`

**Origin:** Lessons 05 (`dielectric_slab.r`), 06 (`iron_core_shielding.r`), 10.
**Why:** The flux-conservative discretization of $\nabla\!\cdot\!(\varepsilon\nabla V)=-\rho$ uses harmonic-mean half-cell coefficients. Hand-rolling this stencil is ~30 lines and the most error-prone code in the curriculum (sign and node-ordering bugs are easy). One builtin removes the entire class of bug.
**Scope:** Take an `ny×nx` material map, return an `(nx·ny)×(nx·ny)` sparse matrix using the same column-major convention as `laplacian_2d`. The same builder serves the magnetostatic $\nabla\!\cdot\!(\mu^{-1}\nabla A_z)$ form by passing $1/\mu$.

### 2.3 Real sparse solve — `spsolve` should stay sparse

**Origin:** Lessons 05, 06, 10, 12 — every numerical PDE.
**Why:** `functions.md:1247` says "Currently converts to dense internally for the solve — provided for API parity." A $100\times100$ Lesson 05 grid produces a $10^4\times10^4$ matrix; densifying it is ~800 MB. Lesson 12 cavity eigenproblems on a $200\times200$ cross-section won't run at all. This is the single biggest scaling blocker for the back half of the course.
**Scope:** Real LU (UMFPACK / KLU / equivalent) for general sparse matrices, with a Cholesky path for symmetric-positive-definite Laplacian assemblies. Keep the API exactly as today.

### 2.4 Generalized sparse eigensolver — `eigs(A, B, n)`

**Origin:** Lesson 12 (`waveguide_modes.r`, `cavity_resonances.r`).
**Why:** Only `eig(M)` exists (dense, all eigenvalues, no $B$). Waveguide cutoffs and cavity modes are exactly $A\phi=k_c^2 B\phi$ on a cross-section grid; a 200×200 grid produces a 40 000×40 000 problem where you want the lowest 4–10 eigenpairs. ARPACK-style shift-invert is the standard.
**Scope:** `eigs(A, n)` and `eigs(A, B, n)` returning the `n` smallest-magnitude (or `"sm"` / `"lm"` / numeric shift) eigenpairs as a tuple `[V, D]` where `V` is dense (cols are eigenvectors) and `D` is a diagonal sparse / vector of eigenvalues. Real and complex inputs.

### 2.5 Shape rasterization primitives — `rect_mask`, `disk_mask`, `polygon_mask`

**Origin:** Lesson 04 (the pivot lesson — every downstream solver consumes its arrays).
**Why:** Lesson 04 currently plans to inline these as user-space helpers. Tiny upstream surface would let the lesson focus on *composition* (boolean ops, material assignment, conformal area-weighted correction) rather than the rasterization mechanics, which are uninteresting bookkeeping.
**Scope:**
```
M = rect_mask(X, Y, x0, y0, w, h)
M = disk_mask(X, Y, xc, yc, r)
M = polygon_mask(X, Y, verts)        # verts is Nx2
```
All return `ny×nx` real matrices of `0.0` / `1.0` (compatible with logical-array boolean ops via `.*` and `1 - M`). 3-D analogues (`box_mask`, `ball_mask`) nice-to-have for Lesson 14 capstone but not blocking.

### 2.6 Yee-grid curl-curl operator with stretched-coordinate PML

**Origin:** Lesson 10 (FDFD).
**Why:** $\bigl(C^T M_\mu^{-1} C - \omega^2 M_\varepsilon\bigr)\vec e = i\omega\vec j$ is the central Lesson 10 assembly. Building the $C$ matrix and the SC-PML stretching factors is ~150 lines of lossy and EM-specific bookkeeping; without a builder, the lesson becomes about discretization rather than physics.
**Scope:** Open question whether this lives upstream or in a `rustlab_em`-side library. Filing a request file at minimum captures the proposed API:
```
[Ce, Ch] = yee_curl_2d(nx, ny, dx, dy)
[sx, sy] = scpml_stretch(nx, ny, npml, omega, sigma_max)
```
Recommend filing the spec, marking it `Status: Discussion` until the upstream-vs-library decision is made.

### 2.7 Polar and log-axis plots

**Origin:** Lessons 02 (rel-error vs $y/d$), 10 (frequency sweeps), 12 (radiation patterns), 13 (S-parameters in dB).
**Why:** No `polar`, `loglog`, `semilogx`, `semilogy` in `quickref.md`. Antenna far-field patterns (Hertzian dipole, half-wave dipole) are textbook polar plots; $|S_{11}|$ in dB across a 1–5 GHz sweep is a textbook semilog plot. Currently expressible only by manually transforming axes, which obscures the physics.
**Scope:** `polar(theta, r [, "title"])`, `loglog(x, y)`, `semilogx(x, y)`, `semilogy(x, y)`. Same backends and overlay semantics as `plot`.

---

## 3. Existing Requests — Still Relevant

### Animation export — [`animation-export.md`](animation-export.md)

Status: **Proposed**, still useful. Lessons 09, 11, 14 all have time as a first-class variable and the per-frame SVG-loop workaround won't scale to a polished site. No change needed; just confirms it should not be deprioritized.

---

## 4. Smaller Friction Points

### Real-result preservation in element-wise division

**Observed in:** `lessons/02-electrostatics-coulomb/point_charges.r:41-44`, `lessons/03-gauss-law-and-potential/potential_dipole.r:43-44`.

Three scripts already wrap field-component prints with `real(...)` because matrix `./` stores complex internally and leaks ~1e-11 imaginary noise even when both operands are real. Comment in `point_charges.r:41-42`:

> Wrap with real() because matrix `./` in rustlab stores complex internally; the imaginary part here is float-precision noise (~1e-11 relative).

This is friction every lesson hits. Worth a one-pager request: when both operands of `./` (or `.*`, `.^`) are real-typed, the result should be real-typed. Low priority, but visible in every drafted lesson.

---

## 5. Suggested Priority Order (Updated)

| # | Request | Blocks | Priority |
|---|---|---|---|
| 1 | Real `spsolve` (§2.3) | Lessons 05+ (every PDE) | **Critical** — scaling cliff |
| 2 | `laplacian_eps_2d` (§2.2) | Lessons 05, 06, 10 | **High** — variable-$\varepsilon$ is the point of L05 |
| 3 | `eigs(A, B, n)` (§2.4) | Lesson 12 | **High** — no analytic workaround |
| 4 | `rect_mask` / `disk_mask` / `polygon_mask` (§2.5) | Lesson 04 (pivot) | **High** — Lesson 04 is the gate to L05–14 |
| 5 | `laplacian_2d` BC extensions (§2.1) | Lessons 06, 11, 12 | **Medium** — ghost-row workaround works |
| 6 | Polar / log-axis plots (§2.7) | Lessons 12, 13 | **Medium** — physics readability |
| 7 | Yee curl-curl + SC-PML (§2.6) | Lesson 10 | **Medium** — may belong in rustlab_em |
| 8 | Animation export (existing) | Lessons 09, 11, 14 | **Low** — workaround exists |
| 9 | Real-typed `./` (§4) | Cosmetic across all lessons | **Low** |
