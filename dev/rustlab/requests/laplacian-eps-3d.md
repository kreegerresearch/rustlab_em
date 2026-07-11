# Request: `laplacian_eps_3d` — Variable-Permittivity 3-D Laplacian

**Status**: Filed
**Date**: 2026-07-10
**Origin**: `rustlab_em` Lesson 15 (lumped capacitance — MIM dielectric stacks), Lesson 17 Ex. 5 (axisymmetric analogue noted below)

## Motivation

rustlab ships `laplacian_eps_2d(eps_map, dx, dy, bc)` — the flux-conservative
variable-coefficient operator `∇·(ε∇)` with harmonic-mean half-cell face
coefficients — but only in 2-D. Lesson 15's thin-film MIM capacitor with a
**two-layer dielectric stack** (ε_r,1 = 25 / ε_r,2 = 4) currently has to
choose between:

- a 2-D cross-section approximation via `laplacian_eps_2d`, or
- a hand-rolled variable-ε 3-D stencil (Exercise 4 asks students to build
  exactly this).

A true 3-D `∇·(ε∇V) = 0` solve is the physically-correct operator for
multi-dielectric stacks; the series-capacitor identity 1/C = 1/C₁ + 1/C₂
is the natural validation.

## Proposed API

```
A = laplacian_eps_3d(eps_map, dx, dy, dz)
A = laplacian_eps_3d(eps_map, dx, dy, dz, bc)   # bc = "dirichlet" | "neumann" | "periodic"
```

- `eps_map` — a 3-D tensor (`zeros3` shape, axis 0 = y, axis 1 = x,
  axis 2 = z) of relative permittivities, real or complex (lossy media).
- Face coefficients: harmonic mean of the two adjacent cell ε values on
  each of the six faces (the direct 3-D analogue of `laplacian_eps_2d`).
- Node ordering: the existing `ijk2k` column-major convention, matching
  `laplacian_3d`, with the `Identity` ordering hint set.
- Anisotropic spacings `dx ≠ dy ≠ dz` are required (thin-gap MIM grids).

## Validation cases

1. Uniform `eps_map` → matches `eps * laplacian_3d(...)` entrywise.
2. Two-layer stack between pinned plates (`pin_dirichlet`) → extracted C
   satisfies 1/C = 1/C₁ + 1/C₂ to discretisation accuracy.
3. Complex ε → operator entries complex, solve still passes `spsolve`.

## Related (out of scope here)

Lesson 17 Ex. 5 also notes there is no axisymmetric `∇·(μ_r⁻¹∇)` path —
cylindrical-coordinate variants would be a separate request.
