# Lesson 14: Capstone — End-to-End Device Simulation

> **Status:** Planned — outline only. See [`dev/plans.md`](../../dev/plans.md#lesson-14--capstone--end-to-end-device-simulation).

## Learning Objectives

- Describe a 3D device as a stack of primitives + material assignments (Lesson 04)
- Run full-wave FDTD with a TF/SF source, dispersive material support, and split-field PML (Lesson 11)
- Drive a waveport and extract $S_{11}$ by mode-filtering and time-gating (Lesson 13)
- Apply the NF→FF transform to get the 3D gain pattern (Lesson 12)
- Validate the result against a published design

## Background

Every prior lesson. This is the capstone: it composes geometry + materials + FDTD + waveport + NF→FF into a single simulation pipeline — a working "mini Ansys" session.

## Theory

_To be written._ The lesson does not introduce new theory; it is a pipeline integration exercise. The device under test is a rectangular microstrip patch antenna at 2.45 GHz on FR-4 substrate with an inset microstrip feed.

## Simulations

| Script | What it simulates |
|---|---|
| `patch_antenna.r` | Single long script, clearly sectioned. (1) Build the geometry + material map as `Tensor3` arrays. (2) Choose $\Delta = \lambda_{\rm min}/20$ and CFL-limited $\Delta t$. (3) TF/SF-driven Gaussian pulse at the waveport plane, covering 1–5 GHz. (4) Run FDTD to steady-state decay. (5) Extract $S_{11}$ via waveport incident/reflected FFT. (6) Record tangential $\vec E$, $\vec H$ on a closed surface above the patch; NF→FF integrate for the 3D gain pattern. (7) Compare resonant frequency, $S_{11}$ depth, bandwidth, and gain pattern to a published design. |

## Exercises

_To be written._ Suggested extensions: dual-band design, dispersive substrate, cross-check with FDFD at a single frequency.
