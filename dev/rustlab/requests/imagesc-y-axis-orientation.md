# Request / Bug: `imagesc` y-axis orientation inconsistent with axis labels

**Status**: Landed (2026-05-16, same-day round trip).
Phase 1 (label-only fix) shipped first; the preferred data-flip fix landed as `axis("xy")` / `axis("ij")` per-panel selectors plus `set_default_axis("xy" | "ij")` for whole-notebook preambles. Default convention remains `"ij"` (matrix-pixel) for back-compat; physics-y is one preamble call away. See `../../rustlab/docs/functions.md` §`axis`, §`set_default_axis`.

The curriculum dropped its `M(ny:-1:1, :)` workaround flips at all seven affected sites and now drops a single `set_default_axis("xy");` near the top of each affected file. L05 corner_singularity (the user-reported case) renders correctly without further intervention.

**Date**: 2026-05-16
**Origin**: `rustlab_em` Lesson 05 — `corner_singularity` example (visible user-facing report)
**Affected rustlab version**: 0.3.4 (tested), likely all earlier

## Symptom

`imagesc(M)` renders the matrix with **row 1 at the top of the plot** (image convention), but draws the y-axis tick labels **0 at the bottom and N at the top** (physics convention). The two conventions are inverted relative to each other: a data cell at matrix row 1 ends up plotted at the position where the y-axis label reads `N`, and a cell at row `N` ends up where the y-axis label reads `0`.

For physical data laid out via `[X, Y] = meshgrid(xs, ys)` with `ys` ascending — which is the documented convention — this means a feature at high physical `y` appears in the **bottom** half of the rendered plot, while the axis tick at that location reads a low value of `y`. The plot is upside-down relative to the labels it carries.

## Reproduction

```rustlab
% Asymmetric corner-marker matrix. Each corner has a distinct colour.
M = zeros(10, 10);
M(1, 1)   = 1;   % matrix index "top-left"
M(1, 10)  = 2;
M(10, 1)  = 3;
M(10, 10) = 4;   % matrix index "bottom-right"
imagesc(M, "viridis");
savefig("corners.svg");
```

Expected (consistent convention):
- `M(1, 1) = 1` at the corner whose y-axis tick reads `1`
- `M(10, 10) = 4` at the corner whose y-axis tick reads `10`

Observed in 0.3.4:
- `M(1, 1) = 1` at the **top-left** corner where the y-axis tick reads **10**
- `M(10, 10) = 4` at the **bottom-right** corner where the y-axis tick reads **0**

The labels and data point in opposite directions.

## Why It Matters

Physical scripts almost always set up coordinates with `ys = linspace(...)` ascending and `Y = meshgrid(..., ys)`. The mental model is: high y is "up", drawn at the top of the plot. `imagesc` violates this, silently flipping any field whose vertical structure isn't symmetric.

**User-visible report** that prompted this ticket: `rustlab_em/book/05-poisson-laplace-bvp.md`, "Example — Square conductor in a grounded box". The script places a `rect_mask(X, Y, 0.06, 0.06, 0.04, 0.04)` conductor — physically at the *upper-right* corner of the grounded box. `imagesc` of the mask shows the yellow square at the **bottom-right** of the plot, with the y-axis label there reading `0` (i.e. the bottom of the physical box). The lesson text and the rendered figure contradict each other.

Crucially, **`contour(X, Y, F)` already follows the correct (physics) convention**. So a hybrid plot — `imagesc(F); contour(X, Y, F)` overlaid on the same axes — shows the heatmap upside-down relative to the contour overlay. This is the most uncomfortable failure mode because it makes hand-drawn lines disagree with the colour fill on the same chart.

## Proposed Fix

Adopt the standard physics ("`axis xy`") convention for `imagesc`: flip the matrix vertically before rendering so that matrix row 1 ends up at the **bottom** of the plot — matching y-axis label 0 at the bottom, label N at the top, and matching the layout of `contour(X, Y, F)` for the same data.

Concretely: when rendering `imagesc(M)` of an `ny × nx` matrix, draw row `ny` at the top and row 1 at the bottom (equivalent to rendering `flipud(M)` under the current convention).

Alternative (less preferred, but at least consistent): switch `imagesc`'s y-axis tick labels so 0 sits at the top and N at the bottom (matrix "`axis ij`" convention). This matches the current data layout but is unusual for physical visualisations and would still disagree with `contour`'s default.

## Workaround Until Fixed

Reverse the rows before plotting:

```rustlab
ny = size(M, 1);
imagesc(M(ny:-1:1, :), "viridis");   % manual flipud
```

A shorter `flipud(M)` builtin would help; not strictly needed.

## Scope of Curriculum Impact (rustlab_em)

Approximately 30+ `imagesc` calls across Lessons 01, 03–14. In most cases the matrix is symmetric or the asymmetry is along the x-axis only, so the bug is invisible. Visibly broken plots (after audit):

- `notebooks/05-poisson-laplace-bvp.md` §"Square conductor in a grounded box" — user-reported
- `notebooks/05-poisson-laplace-bvp.md` §"Two finite plates inside a grounded box" — top plate appears at bottom and vice versa
- `lessons/05-poisson-laplace-bvp/dielectric_slab.rlab` — bottom-half dielectric drawn at top
- `lessons/05-poisson-laplace-bvp/corner_singularity.rlab` — same as notebook
- `lessons/14-capstone-device-simulation/patch_antenna.rlab` — substrate-on-bottom geometry inverts

All other cases (centred Gaussian bumps, symmetric cylinder scatterers, etc.) are invisible to the bug.

The rustlab_em side will apply the `M(ny:-1:1, :)` workaround to affected scripts until the upstream fix lands, at which point the workaround can be removed.

## Priority

**Medium-high.** Visually broken physical plots are confusing to learners and contradict accompanying prose. Not a numerical-correctness issue, but a UX issue that the curriculum can't fully paper over without per-script workarounds.
