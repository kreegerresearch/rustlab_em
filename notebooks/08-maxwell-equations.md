# Lesson 08: Maxwell's Equations — The Complete Set

> **Status:** Planned — outline only. See [`dev/plans.md`](../../dev/plans.md#lesson-08--maxwells-equations--the-complete-set).

## Learning Objectives

- State the four Maxwell equations in differential and integral form, in vacuum and in matter
- Show why the displacement current is required for charge conservation
- Derive the Poynting vector $\vec S = \vec E\times\vec H$ as the energy flux density
- Verify energy conservation numerically for a simple geometry

## Background

Lessons 01–07.

## Lesson Body

_To be written. When drafted, the body uses one H2 per concept, each split into `### Theory` (prose + math) and one or more `### Example — <descriptor>` (rustlab block paralleling a script below). See [Lesson 01](01-vector-calculus-and-fields.md) for the pattern._

Key equations: the four Maxwell equations; $\partial u/\partial t + \nabla\cdot\vec S = -\vec J\cdot\vec E$.

## Planned Scripts

| Script | What it simulates |
|---|---|
| `maxwell_consistency.rlab` | Known plane-wave solution; all four equations verified numerically |
| `charge_conservation.rlab` | Capacitor current; displacement current closes the Ampère-loop |
| `poynting_flow.rlab` | Coaxial cable carrying DC; $\vec S$ in the dielectric; $\int\vec S\cdot d\vec A=IV$ |

## Exercises

_To be written._
