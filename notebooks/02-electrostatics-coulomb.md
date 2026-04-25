# Lesson 02: Electrostatics & Coulomb's Law

> **Status:** Planned — outline only. See [`dev/plans.md`](../../dev/plans.md#lesson-02--electrostatics--coulombs-law).

## Learning Objectives

- Compute $\vec E$ from an arbitrary set of point charges by direct superposition
- Draw field lines via streamline integration from seed points
- Derive and plot the dipole far-field in the $r \gg d$ limit
- Recognize how symmetry simplifies field calculations (ring, infinite line)

## Background

Lesson 01 (vector calculus). Basic 3D geometry.

## Theory

_To be written._ Key equations: $\vec E(\vec r) = (4\pi\varepsilon_0)^{-1}\sum_i q_i(\vec r-\vec r_i)/|\vec r-\vec r_i|^3$.

## Simulations

| Script | What it simulates |
|---|---|
| `point_charges.r` | Dipole and quadrupole fields; quiver + $|\vec E|$ heatmap |
| `dipole_field.r` | Exact superposition vs far-field dipole formula; error vs $r/d$ |
| `ring_of_charge.r` | On-axis field of a charged ring; closed-form comparison |

## Exercises

_To be written._
