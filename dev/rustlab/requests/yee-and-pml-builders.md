# Request: Yee-Grid Curl Operators and SC-PML Builders

**Status**: Discussion (Phase 1 implementation lives in
`rustlab_em/lessons/_shared/em.r` as a scripted library; upstream
rustlab implementation deferred until a graduation trigger fires —
see "Decision criteria" below).
**Date**: 2026-04-26
**Origin**: `rustlab_em` Lesson 10 (FDFD), Lesson 11 (FDTD), Lesson 13
(transmission lines and antennas), and the upstream-side em_requests
sweep §2.6.

## Background

Frequency-domain finite-difference electromagnetics (FDFD) solves the
vector wave equation discretized on a Yee staggered grid:

$$\bigl(C^T M_\mu^{-1} C - \omega^2 M_\varepsilon\bigr)\,\vec{e} = i\omega \vec{j}$$

The components of this assembly that don't currently ship as builtins
in rustlab:

- **`yee_curl_2d(nx, ny, dx, dy)`** — returns a sparse matrix `C`
  representing the discrete curl on a 2-D Yee grid. For 2-D TE and TM
  problems this comes in two flavours (`Ce` for the E-field grid,
  `Ch` for the H-field grid); on a uniform grid they are transposes of
  each other.
- **`scpml_stretch(nx, ny, npml, omega, sigma_max)`** — returns
  diagonal stretching factors `(s_x(i), s_y(j))` as length-`nx` and
  length-`ny` complex vectors. The stretching factors implement
  stretched-coordinate Perfectly Matched Layer (SC-PML) absorbing
  boundaries: `s = 1 + i·σ(x)/ω` inside the PML region, `1 + 0i` in
  the interior.

Once these two builders are available, the FDFD assembly is a
straightforward sparse algebra exercise in scripted rustlab.

## Why this is a "Discussion" entry

`AGENTS.md` Rule 9 requires core algorithms to be hand-rolled in pure
Rust. The Yee curl and SC-PML builders are EM-specific, however, and
adding them to upstream rustlab widens the scope of "DSP and matrix
algebra" to "computational physics in general". That's a curation
question for the rustlab maintainer, not a technical one.

**Two-phase approach:**

### Phase 1 — `rustlab_em` scripted library (recommended; no upstream change)

The Yee curl and SC-PML builders are *one-time assembly* steps, not
inner-loop kernels. They build a sparse matrix once at the start of an
FDFD/FDTD simulation; that matrix is then handed to `spsolve` /
`eigs` / `eig` which are already native Rust. Assembly time for a
100k-cell Yee matrix in scripted rustlab: roughly 1–5 seconds. In
native Rust: 50–200 ms. For a curriculum simulation that runs in the
solver for minutes, the assembly time is irrelevant.

**Phase 1 deliverables:**
- `rustlab_em/lessons/_shared/em.r` — scripted implementations of
  `yee_curl_2d` and `scpml_stretch`, importable via `run("../_shared/em.r")`.
- `rustlab_em/lessons/_shared/README.md` — documents the import pattern.
- This file (`yee-and-pml-builders.md`) — captures the API spec
  upstream so anyone can read the shape of the eventual upstream
  implementation.

### Phase 2 — upstream `rustlab-em` workspace crate (deferred)

If any of the **graduation triggers** fire, the EM builders graduate
to a native Rust crate `crates/rustlab-em` in the rustlab workspace,
gated behind a feature flag `em` (default-off — opt-in for users who
want EM-specific builders).

**Graduation triggers** (any one is sufficient):
1. Lesson 14 capstone needs 3-D Yee (`yee_curl_3d`); the scripted
   assembly cost scales 100× and starts to hurt the lesson's wall-clock.
2. Any individual lesson's Yee assembly takes >5 seconds end-to-end.
3. A second physics curriculum (controls, fluids, neutron transport,
   etc.) starts asking for similar finite-difference builders. At
   that point a shared `rustlab-physics`-style approach makes sense.
4. The scripted assembly hits a language-feature wall — e.g. needs
   sparse-matrix construction patterns that rustlab-script doesn't
   express well.

If Phase 2 is triggered: the new crate adopts the API spec from this
document. Pure Rust per `AGENTS.md` Rule 9; the SC-PML stretching
factor and Yee curl construction are roughly 700 LoC clean Rust.

## API spec (for both phases)

```
[Ce, Ch] = yee_curl_2d(nx, ny, dx, dy)
   Returns:
     Ce — sparse curl operator on the E-field grid
          (size 2*(nx-1)*(ny-1) × nx*ny for 2-D vector E with
           tangential components on the grid edges).
     Ch — sparse curl operator on the H-field grid
          (transpose of Ce on a uniform grid; explicitly returned
           because non-uniform extensions break the transpose
           relationship).
   Both are ComplexFloat sparse matrices.

[sx, sy] = scpml_stretch(nx, ny, npml, omega, sigma_max)
   Returns:
     sx — length-nx complex vector of x-direction stretching factors
     sy — length-ny complex vector of y-direction stretching factors
   Stretching factor profile:
     s(i) = 1 + j*sigma(i)/omega
   where sigma(i) ramps from 0 in the interior to sigma_max at the
   PML's outer edge via a polynomial profile (typically degree 3).

   For TE polarization: assemble the operator
     A = Cx_h * (1/eps_y) * Cx_e + Cy_h * (1/eps_x) * Cy_e
            - omega^2 * mu * I
   where Cx_h, Cy_h are the H-grid curl components and Cx_e, Cy_e are
   the E-grid components, with the SC-PML stretching factors applied
   to the spatial-difference operators.
```

## Reference

- Taflove & Hagness, *Computational Electrodynamics: The
  Finite-Difference Time-Domain Method*, 3rd ed. (2005), ch. 7
  (the FDFD chapter) and ch. 11 (PML).
- Rumpf, *Electromagnetic and Photonic Simulation for the Beginner*
  (2022), ch. 5 — has explicit per-cell formulas for the Yee curl
  and PML stretching factor that map directly onto sparse-matrix
  construction.

## Next steps

1. **Phase 1 (curriculum-side):** when Lesson 10 begins drafting,
   author `rustlab_em/lessons/_shared/em.r` with these two functions.
   This file (the spec) becomes the design contract.
2. **Phase 2 (upstream):** monitor the graduation triggers. If
   triggered, file an upstream PR adding `crates/rustlab-em` with
   the API in this document, behind feature flag `em`.

The decision to graduate is the rustlab maintainer's call. Until then,
the scripted approach is fully functional and curriculum-ready.
