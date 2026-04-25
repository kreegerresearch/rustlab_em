# Lesson 05: Poisson & Laplace — Boundary Value Problems

> **Status:** Planned — outline only. See [`dev/plans.md`](../../dev/plans.md#lesson-05--poisson--laplace--boundary-value-problems).

## Learning Objectives

- Derive the 5-point stencil for the 2D Laplacian in vacuum and the variable-coefficient stencil for $\nabla\!\cdot\!(\varepsilon\nabla V)$
- Solve Laplace/Poisson via iterative relaxation (Jacobi, Gauss-Seidel, SOR) *and* sparse direct solve
- Handle Dirichlet and Neumann boundary conditions on rectangular domains
- Recognize the field singularity at sharp conductor corners
- Solve a mixed-dielectric problem with a piecewise-constant $\varepsilon(x,y)$

## Background

Lessons 01–04. Linear algebra (sparse matrices, iterative solvers).

## Lesson Body

_To be written. When drafted, the body uses one H2 per concept, each split into `### Theory` (prose + math) and one or more `### Example — <descriptor>` (rustlab block paralleling a script below). See [Lesson 01](01-vector-calculus-and-fields.md) for the pattern._

Key equations: 5-point stencil $\nabla^2 V_{i,j} \approx h^{-2}(V_{i+1,j}+V_{i-1,j}+V_{i,j+1}+V_{i,j-1}-4V_{i,j})$; flux-conservative variable-$\varepsilon$ form; Jacobi/Gauss-Seidel/SOR convergence.

## Planned Scripts

| Script | What it simulates |
|---|---|
| `laplace_2d.r` | Unit square with $V=\sin(\pi x)$ on top; Jacobi/GS/SOR convergence comparison |
| `parallel_plate.r` | Capacitor inside a grounded box; fringing field at plate edges |
| `dielectric_slab.r` | Parallel plates with a half-gap $\varepsilon_r = 4$ slab; variable-coefficient stencil; verify series-capacitor formula |
| `coaxial_cable.r` | Inner/outer conductor; verify $V(r)=V_1\ln(b/r)/\ln(b/a)$ |
| `corner_singularity.r` | L-shaped conductor; $1/\sqrt r$ field near the re-entrant corner |

## Exercises

_To be written._
