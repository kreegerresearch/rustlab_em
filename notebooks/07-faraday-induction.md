# Lesson 07: Faraday's Law & Induction

> **Status:** Planned — outline only. See [`dev/plans.md`](../../dev/plans.md#lesson-07--faradays-law--induction).

## Learning Objectives

- State Faraday's law in both integral and differential forms
- Compute induced EMF for simple geometries (loop in changing $\vec B$; moving conductor)
- Derive self- and mutual inductance as geometric constants
- Simulate eddy currents in a thin conducting plate via a quasi-static approximation

## Background

Lessons 01–06.

## Lesson Body

_To be written. When drafted, the body uses one H2 per concept, each split into `### Theory` (prose + math) and one or more `### Example — <descriptor>` (rustlab block paralleling a script below). See [Lesson 01](01-vector-calculus-and-fields.md) for the pattern._

Key equations: $\oint\vec E\cdot d\vec\ell = -d\Phi_B/dt$; $\nabla\times\vec E = -\partial\vec B/\partial t$; $L=\Phi_B/I$.

## Planned Scripts

| Script | What it simulates |
|---|---|
| `induced_emf.r` | Loop in sinusoidal $\vec B(t)$; plot $\Phi(t)$ and $\varepsilon(t)$ |
| `mutual_inductance.r` | Two concentric loops; numerical $M$ via flux integral |
| `eddy_current_plate.r` | Thin disk in time-varying uniform $\vec B$; 2D Laplace on the stream function |

## Exercises

_To be written._
