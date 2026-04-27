# Request: `quiver` and `streamplot` for 2D Vector Fields

**Status**: Landed (`quiver` and `streamplot` shipped — verified in `rustlab/docs/quickref.md`, used by Lessons 01-03)
**Date**: 2026-04-22
**Origin**: `rustlab_em` Lessons 01, 02, 03, 04, 05

## Motivation

A physicist's first instinct on seeing any vector field is to draw it — arrows at sample points (quiver) or continuous streamlines that follow the field (streamplot). Rustlab currently has `plot`, `surf`, `imagesc`, and `stem` for scalars, but nothing for 2D vector fields. Every EM lesson needs this.

## Proposed API

### `quiver`

```
quiver(X, Y, U, V)                    # X, Y, U, V all same-shape matrices (from meshgrid + field eval)
quiver(X, Y, U, V, scale)             # arrow length multiplier (default: auto-scale to ~1 cell)
quiver(X, Y, U, V, "title")
quiver(U, V)                          # X, Y default to 1:nx, 1:ny
```

Renders across all backends (notebook Plotly, SVG/PNG via `savefig`, viewer). Plotly has no native quiver; one implementation path is `plotly.figure_factory.create_quiver`-style — emit many small line segments + triangular arrowheads as `scatter` traces. For SVG/PNG via plotters, draw line+polygon arrows directly.

### `streamplot`

```
streamplot(X, Y, U, V)                      # streamlines seeded on a default grid
streamplot(X, Y, U, V, density)             # density ≈ seeds per unit area (MATLAB convention)
streamplot(X, Y, U, V, "title")
streamplot(X, Y, U, V, seeds)               # custom seed points: Nx2 matrix of (x, y)
```

Integrate streamlines via RK4 forward and backward from each seed point, clipping at the domain boundary. Plot as many thin `plot` traces with arrowheads at midpoints.

## Semantics

- Arrow **color**: uniform by default; an optional `quiver(..., C)` where `C` is a same-shape scalar field maps colors to magnitude.
- Auto-scaling: `quiver` shrinks arrow lengths so no arrow is longer than the nearest-neighbor cell distance — matches MATLAB behavior.
- Clip at NaN: treat NaN entries in U or V as holes (skip).

## Scope

Minimal first version: `quiver(X, Y, U, V)` and `streamplot(X, Y, U, V)` in 2D. Both backends (notebook + savefig) must work. 3D quiver is not needed for this course.

## References

- MATLAB [`quiver`](https://www.mathworks.com/help/matlab/ref/quiver.html), [`streamline`](https://www.mathworks.com/help/matlab/ref/streamline.html).
- Matplotlib [`quiver`](https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.quiver.html), [`streamplot`](https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.streamplot.html).
