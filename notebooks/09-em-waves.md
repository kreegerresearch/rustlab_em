# Lesson 09: EM Wave Equation & Plane Waves

> **Status:** Planned — outline only. See [`dev/plans.md`](../../dev/plans.md#lesson-09--em-wave-equation--plane-waves).

## Learning Objectives

- Derive the wave equation from Maxwell in vacuum and show $c = 1/\sqrt{\mu_0\varepsilon_0}$
- Visualize plane-wave solutions: $\vec E \perp \vec B \perp \vec k$
- Characterize polarization states (linear, circular, elliptical) via the Jones vector
- Build a standing wave at a perfect-conductor boundary

## Background

Lessons 01–08.

## Theory

_To be written._ Key equations: $\nabla^2\vec E - \mu_0\varepsilon_0\,\partial^2\vec E/\partial t^2 = 0$; $\vec E(\vec r,t)=\vec E_0 e^{i(\vec k\cdot\vec r-\omega t)}$; $\vec B = \hat k\times\vec E/c$.

## Simulations

| Script | What it simulates |
|---|---|
| `plane_wave.r` | Snapshots of $E_y(x,t)$ and $B_z(x,t)$; verify $E/B = c$ |
| `polarization.r` | Jones-vector sweep; $\vec E$ tip traced in $y$-$z$ plane |
| `standing_wave.r` | Plane wave + perfect reflector; spatial node/antinode pattern |

## Exercises

_To be written._
