# Lesson 03: Gauss's Law & Electric Potential

> **Status:** Planned — outline only. See [`dev/plans.md`](../../dev/plans.md#lesson-03--gausss-law--electric-potential).

## Learning Objectives

- State Gauss's law in both integral and differential forms
- Use symmetry to derive $\vec E$ for spherically, cylindrically, and planar-symmetric charges
- Compute $V(\vec r)$ and recover $\vec E = -\nabla V$ numerically
- Plot equipotential contours alongside field-line streamlines

## Background

Lessons 01–02.

## Lesson Body

_To be written. When drafted, the body uses one H2 per concept, each split into `### Theory` (prose + math) and one or more `### Example — <descriptor>` (rustlab block paralleling a script below). See [Lesson 01](01-vector-calculus-and-fields.md) for the pattern._

Key equations: $\oint\vec E\cdot d\vec A = Q_{\rm enc}/\varepsilon_0$; $\nabla\cdot\vec E = \rho/\varepsilon_0$; $\vec E = -\nabla V$.

## Planned Scripts

| Script | What it simulates |
|---|---|
| `gauss_sphere.r` | Uniform spherical charge; $E_r(r)$ and $V(r)$ inside/outside |
| `potential_dipole.r` | Dipole potential heatmap + equipotential contours + $-\nabla V$ quiver |
| `capacitor_1d.r` | 1D parallel-plate capacitor from Gauss; $C = \varepsilon_0 A/d$ |

## Exercises

_To be written._
