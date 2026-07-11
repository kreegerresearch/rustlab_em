# Request: `smith_chart()` Background Helper

**Status**: **Landed** — shipped under a different API: `smith()` / `marker()` / `smith_circle()` (plus the wider S-parameter toolbox; see `rustlab docs smith`). The proposed `smith_chart()` / `smith_chart_load()` names were not used. All seven Lesson 16 scripts use the shipped API and hand-roll nothing.
**Date**: 2026-05-15
**Date landed**: 2026-05-17 (rustlab S-parameter toolbox, `dev/plans/closed/sparameters.md`)
**Origin**: `rustlab_em` Lesson 16 (planned) — Smith Chart & Impedance Matching

## Motivation

The Smith chart is the workhorse impedance-matching tool in RF engineering: a conformal map of the right-half complex impedance plane onto the unit disk in the reflection-coefficient plane. Every Smith-chart-using lesson script wants the same thing as background scaffolding — nested constant-resistance and constant-reactance circles, the outer unit circle, axis labels — before overlaying its own data (a load marker, a transformation arc, a frequency-swept $S_{11}$ locus).

Hand-rolling that scaffolding takes ~40 lines per script (parametric circle traces, label placement, aspect-ratio lock). Across the seven Lesson 16 scripts that's ~280 lines of repeated boilerplate. A single builtin reduces every script to its actual content.

This is **strictly optional**: the scripts can be written with the existing primitives (`plot`, `axis("equal")`, parametric `(cos t, sin t)`). The request is a convenience helper, not a missing capability.

## Proposed API

```rustlab
# Draw a clean Smith chart background on the current axes. Returns no value;
# operates by side effect on the active figure (like `grid` or `hold`).
smith_chart()                          # default: r ∈ {0.2, 0.5, 1, 2, 5}, x ∈ {±0.2, ±0.5, ±1, ±2, ±5}
smith_chart(z0)                        # normalise by reference impedance z0 (default 50)
smith_chart(z0, r_grid, x_grid)        # supply custom resistance / reactance values

# Convenience: combined chart + load marker in one call
smith_chart_load(Z_load, z0)           # background + a single Γ_L marker labeled "Z_load"
```

## Semantics

- **Geometry.** With normalised impedance $z = R + jX$, the reflection coefficient is $\Gamma = (z - 1)/(z + 1)$. The constant-$R$ family maps to circles of centre $(R/(R+1), 0)$ and radius $1/(R+1)$. The constant-$X$ family maps to circles of centre $(1, 1/X)$ and radius $1/|X|$ (only the portion inside the unit disk is on the chart).
- **Aspect ratio.** Lock to 1:1 via `axis("equal")` so the circles render as circles, not ellipses.
- **Render scope.** Only the portion of each circle inside $|\Gamma| \leq 1$ — i.e. clip to the unit disk. The outer unit circle itself is rendered as the chart boundary.
- **Annotations.** Label each constant-$R$ circle at its rightmost intercept on the real axis, and each constant-$X$ circle at the unit-circle crossing point. Standard convention: open-circuit at $\Gamma = +1$, short-circuit at $\Gamma = -1$, matched at $\Gamma = 0$.
- **Layering.** The background should sit *behind* any subsequent `plot()` calls (i.e. drawn first, with `hold on` implied so the user can overlay their data).

## Example Usage

```rustlab
# Lesson 16 single-stub match overlay
Z_load = 30 + 50j;
Z0     = 50;
Gamma_L = (Z_load - Z0) / (Z_load + Z0);

clf;
smith_chart(Z0);                                # background
hold on;
plot(real(Gamma_L), imag(Gamma_L), "Γ_L");      # load marker
# ... add transformation arcs, stub-position marker, final landing at origin ...
title("Single-stub match: 30 + 50j Ω → 50 Ω");
savefig("single_stub_match.svg");
```

Without the helper, the same script needs ~40 extra lines to draw the chart background by hand.

## Related Existing Builtins

- `axis("equal")` — already supports the aspect-ratio lock (shipped, 0.3.4).
- `polar()` — close cousin but parameterised over $(\theta, r)$, not over the bilinear-map geometry the Smith chart requires.
- `plot()` — handles the actual `(\text{Re}\Gamma, \text{Im}\Gamma)` traces the user overlays on top.

## Out-of-Scope

- Interactive cursor / pick-Γ-from-mouse — purely a renderer concern; not appropriate for a CLI tool.
- Y-Smith chart (admittance overlay rotated by 180°) — leave that to the user as a `smith_chart(Z0); rotate(pi);` follow-on, or as a separate `smith_chart_admittance()` if it becomes a recurring ask.
- Dual-axis $Z$ + $Y$ overlay — same; user can call both helpers in sequence.

## Implementation Sketch

Pure compositional drawing — no new numerical machinery, no sparse-matrix or FFT work. ~80 lines of Rust:

1. Take the resistance and reactance grids (defaults if not supplied).
2. For each constant-$R$ value, generate ~100 parametric points along the circle, clip to $|\Gamma| \leq 1$, emit a polyline to the current figure with low-opacity grey stroke.
3. Same for constant-$X$ circles (note: $X$ circles are arcs, not full circles within the chart).
4. Draw the outer unit circle as a solid polyline.
5. Draw the real-axis baseline ($X = 0$) as a slightly emphasised line.
6. Place text labels at the canonical positions.
7. Call `axis("equal")` and set the limits to $[-1.05, 1.05]$ on both axes.

## Priority

**Low.** Lesson 16 can ship without it; the scripts will be slightly more boilerplate-heavy but functionally identical. If a future rustlab release wants a "nice-to-have for RF tutorials," this is the obvious candidate.
