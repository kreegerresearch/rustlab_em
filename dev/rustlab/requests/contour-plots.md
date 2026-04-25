# Request: `contour` and `contourf` for Scalar Fields

**Status**: Proposed
**Date**: 2026-04-22
**Origin**: `rustlab_em` Lessons 03, 04, 08

## Motivation

`imagesc` shows a scalar field as a colored heatmap, but equipotentials are fundamentally *lines* — the locus where $V(x, y) = c$ for a constant $c$. Overlaying equipotential contours on a quiver plot of the corresponding $\vec E = -\nabla V$ field is the canonical EM diagram that appears in every textbook.

## Proposed API

```
# Line contours
contour(X, Y, Z)                         # default 10 levels, auto-spaced
contour(X, Y, Z, nlevels)
contour(X, Y, Z, levels)                 # levels as an explicit vector
contour(X, Y, Z, "title")
contour(Z)                               # X, Y default to indices

# Filled contours (colored regions between level curves)
contourf(X, Y, Z)
contourf(X, Y, Z, nlevels)
contourf(X, Y, Z, levels)

# Overlay on existing figure (like hold on)
hold on
imagesc(X, Y, |E|, "viridis")
contour(X, Y, V, 20, "k")                # 20 black contour lines over the heatmap
hold off
```

## Semantics

- **Algorithm**: marching squares for each level. Stable, widely available reference implementations.
- **Colors**: default to single color (black) for line contours; default to a colormap for filled contours. Accept an optional color string argument that mirrors `plot`'s color spec.
- **Level placement**: automatic algorithm picks round-number levels (like MATLAB's default). Explicit levels always honored.
- **Label placement** (nice-to-have): text labels on contour lines at auto-chosen or user-supplied locations. Punt to a v2 if complex.

## Backends

- **Notebook (Plotly)**: `plotly.graph_objects.Contour` is a direct match. Filled vs line controlled by `contours.type` and `contours.showlabels`.
- **SVG/PNG (plotters)**: render marching-squares line segments; for `contourf`, fill polygons between adjacent level sets.
- **Viewer (egui)**: can ship as a no-op or flat fallback initially.

## Scope

`contour` (line) and `contourf` (filled) both essential. Label placement can ship later. Integration with `hold on` is required so contours can overlay heatmaps and quiver plots.

## References

- MATLAB [`contour`](https://www.mathworks.com/help/matlab/ref/contour.html), [`contourf`](https://www.mathworks.com/help/matlab/ref/contourf.html).
- Matplotlib [`contour`](https://matplotlib.org/stable/api/_as_gen/matplotlib.pyplot.contour.html).
- Plotly [Contour Plots](https://plotly.com/python/contour-plots/).
