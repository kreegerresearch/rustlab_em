# Request: `laplacian_2d` Sparse Stencil Builder

**Status**: Landed and extended. Phase 1: `laplacian_2d` shipped early-2026-04. Phase 2 (em_requests.md §2.1+§2.2): `laplacian_2d` extended with `bc` selector (`"dirichlet"|"neumann"|"periodic"`), plus new `laplacian_1d`, `laplacian_3d`, and `laplacian_eps_2d` — shipped in commit `26954a3` (2026-04-26). See `gallery/laplacian_bc.md` and `gallery/dielectric.md` for notebooks.
**Date**: 2026-04-22
**Origin**: `rustlab_em` Lessons 04, 06, 10

## Motivation

The 5-point Laplacian stencil is the single most-reused object in numerical PDE work. Students assembling it from `spdiags` for the $n^{\text{th}}$ time isn't teaching them anything new. A single builtin that returns the sparse matrix $L$ such that $LV \approx \nabla^2 V$ makes the *physics* the center of attention.

This one builtin unlocks: Poisson/Laplace BVP (Lesson 04), quasi-static eddy-current flow functions (Lesson 06), waveguide eigenmode problems (Lesson 10), and the interior stencil for any FD elliptic solver.

## Proposed API

```
# 2D Laplacian on a uniform grid — returns sparse (nx*ny) × (nx*ny) matrix
L = laplacian_2d(nx, ny, dx, dy)
L = laplacian_2d(nx, ny)                # dx = dy = 1
L = laplacian_2d(nx, ny, dx, dy, bc)    # bc is a struct/string: "dirichlet", "neumann", "periodic"

# 1D convenience
L = laplacian_1d(nx, dx)

# 3D version (nice-to-have; FDTD manages its own stencils)
L = laplacian_3d(nx, ny, nz, dx, dy, dz)
```

## Semantics

- **Node ordering**: natural lexicographic row-major: `V(i, j)` → linear index `(i-1)*nx + j`. Document this convention clearly; it is the single most error-prone detail.
- **Boundary conditions**:
  - `"dirichlet"` (default) — stencil entries at boundary rows assume $V = 0$ outside. Users who want Dirichlet at nonzero values must put those in the right-hand-side vector.
  - `"neumann"` — ghost nodes implement $\partial V/\partial n = 0$; equivalent to reflecting the stencil at the boundary.
  - `"periodic"` — wrap around.
- **Return type**: sparse matrix compatible with `spsolve(L, b)`.
- **Sign**: $L$ approximates $+\nabla^2$ (same sign as the differential operator). Poisson $\nabla^2 V = -\rho/\varepsilon_0$ solves as `V = spsolve(L, -rho/eps0)`.

## Companion Utilities

A small amount of sugar would go a long way:

```
# Convert between flat and (i, j) coordinates (given nx, ny)
k = ij2k(i, j, nx)
[i, j] = k2ij(k, nx)

# Reshape between flat vector and 2D matrix (already possible via reshape; just document the convention)
V_grid = reshape(V_flat, ny, nx)
V_flat = V_grid(:)
```

## Scope

Minimal first version: 2D Dirichlet `laplacian_2d(nx, ny, dx, dy)`. Neumann and periodic can ship later. This unblocks Lesson 04 entirely.

## Alternatives Considered

- **Hand-written stencils with `spdiags`**: 10–15 lines that students reimplement every time. Works but tedious.
- **Helmholtz / biharmonic / ... as separate builders**: premature. Start with the Laplacian and see what real use-cases emerge.

## References

- SciPy [`scipy.sparse.diags`](https://docs.scipy.org/doc/scipy/reference/generated/scipy.sparse.diags.html) — similar low-level construction.
- MATLAB [`delsq`](https://www.mathworks.com/help/matlab/ref/delsq.html) — discrete Laplacian on arbitrary domain masks; relevant for non-rectangular geometries.
