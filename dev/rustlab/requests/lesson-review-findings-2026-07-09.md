# Upstream requests — 2026-07-09 lesson-review pass (remaining items)

**Status**: Filed (2026-07-11)

Companion to `rustlab_em/dev/lesson-review-findings-2026-07-09.md` (the third full-curriculum
review). The big asks from that pass already landed — length-preserving `fft` + `fft(x, n)`
(PR #28) and the `ellipke` / `pin_dirichlet` / `trapz(M)` / `tic`-`toc` / quiver-robustness /
`Tensor3(:)` / exit-code batch (PR #29). This file collects everything still open, re-verified
against the post-#29 build on 2026-07-11. Repro scripts referenced below were run with
`rustlab run`; SVG evidence quoted from the saved output.

---

## 1. BUG — `contour` draws levels of |Z| and silently drops negative levels

Re-verified post-#29. On `Z = X` over `meshgrid(linspace(-2,2,41), linspace(-2,2,41))`:

- `contour(X, Y, Z, [1.5])` draws **two** vertical lines — 41 segments at px 780 (data x = +1.5)
  and 41 at px 188 (data x = −1.5). A signed contour has exactly one, at x = +1.5.
- `contour(X, Y, Z, [-1.0])` draws **nothing** — the SVG contains only axes/tick polylines —
  with no warning.

`docs/functions.md` describes contour as levels of "a 2-D scalar field"; nothing licenses the
magnitude. Negative levels are legal per the docs and are the natural way to draw equipotentials
of a dipole (the exact use case that broke Lesson 03's figure). Ask: contour the *signed* field;
if the magnitude behavior is intentional, document it loudly and warn (don't silently no-op) on
all-negative level lists. Related: `imagesc`'s magnitude behavior *is* documented, but it is a
sign-destroying divergence from MATLAB convention worth a doc warning next to every example that
feeds it signed data.

## 2. BUG — `loglog` / `semilogx` / `semilogy` reject a 1×N matrix that `plot` accepts

Re-verified post-#29:

```
x = linspace(1, 10, 20)
y = ones(1, 20)        # Matrix(1x20)
plot(x, y)             # OK
loglog(x, y)           # type error: loglog: y must be a vector, got matrix
```

Same input, different verdicts. Ask: the log-axis wrappers should accept whatever `plot`
accepts (squeeze 1×N / N×1 matrices to vectors). This inconsistency forced the
`zeros(n)`-instead-of-expression workarounds in Lessons 05/12/13.

## 3. BUG (conditional, needs upstream triage) — `hold on` + `imagesc` + `contour` frame mismatch

Under the **pre-#28 build**, two committed rustlab_em book figures rendered with the contour +
tick frame occupying px 90–469 while the imagesc heatmap spanned px 90–816 on its own pitch
(contours ~1.9× compressed left of the features they annotate): see
`book/plots/02-electrostatics-coulomb/plot-4-eb513fd3.svg` and
`book/plots/03-gauss-law-and-potential/plot-3-afbf5e76.svg` in rustlab_em git history.

On the **current** build we could NOT reproduce, in four independent attempts: off-center
Gaussian bump on 31×61 and 81×161 grids; an asymmetric bump on the L07 eddy-plate grid under
`set_default_axis("xy")`; and — decisively — **the exact 51×51 L02 overlay that produced the
broken committed figure now renders aligned** (heatmap cells, contours, and tick frame all
px 90–469, where the broken figure had the heatmap at 90–816). Something in #24–#29 appears to
have fixed it. Keeping this row for awareness only; treat as fixed unless a regression shows
up. Note the Landed `contour-plots.md` request's coordinate-aware `imagesc(X, Y, M)` variant
was never shipped (only index-based `imagesc` exists) — closing that gap would remove the
two-frames-one-axes class of bug entirely.

## 3b. BUG — subplot containing an `imagesc` renders only one panel

Found 2026-07-11 while restructuring the Lesson 02 overlay: in a 1×2 `subplot` figure where
one panel is an `imagesc` and the other a `contour`, the saved SVG contains only ONE panel —
imagesc-first → only the heatmap appears; contour-first → only the contour. Repro:
`t_imagesc_contour_sub.rlab` (Gaussian bump; either ordering). Lesson-side workaround: two
separate figures.

## 3c. BUG — `plot()` line series silently dropped from figures containing a `quiver`

Found 2026-07-11: a `plot(x, y)` overlaid on a `quiver` (either call order, `hold on`) never
appears in the saved SVG — no warning. This had been silently degrading a published figure:
`stokes_loop.svg` shipped with no loop drawn over the vector field. Repro:
`t_quiver_plot.rlab`. Lesson-side workaround: draw the loop as a level-set `contour` over the
quiver (contour-over-quiver renders fine).

## 4. Cosmetics / docs (small, batchable)

- SVG tick labels can render **-0.0**, and `print` outputs `-0` for negative zero (example
  captured in rustlab_em `book/03-gauss-law-and-potential.md`, ~line 208).
- `set_default_axis` and `axis("xy")` are implemented and documented in `functions.md` but
  absent from `quickref.md`, whose header says "if a function is not listed here, it is not
  implemented".
- Tensor3 first-axis slice `T(i,:,:)` **works** (returns a Matrix) but is undocumented —
  quickref documents only the page slice `A(:,:,k)`. Two rustlab_em L15 scripts hand-roll
  double loops for want of it. Please document (or bless) the working form.
- **Document elementwise broadcasting.** `.*` and `+` broadcast row and column vectors against
  matrices on the current build (verified both orientations), but implicit expansion is
  documented only for `min`/`max`. Lesson 11 carries 9 `repmat` boilerplate calls we would
  happily delete once the behavior is contractual.

## 4b. BUG/FEATURE — logical-mask assignment `M(mask) = scalar` rejected

Found while fixing Lesson 06 (2026-07-11): `M(mask) = NaN` (mask a logical matrix the same
shape as `M`) fails with "type error: expected scalar, got matrix" — masked assignment
apparently isn't supported, so the lesson NaN-masks via an explicit double loop. Linear-index
reads `M(mask)` and the MATLAB-standard masked write are a natural pair; either support the
write or document the loop idiom.

## 5. FEATURE — `polyfit` / `polyval`

Lesson 05 hand-rolls a least-squares slope (`corner_singularity.rlab`) and apologizes for it in
prose. A basic `polyfit(x, y, n)` / `polyval(p, x)` pair covers convergence-order fits across
the whole curriculum (Lessons 04/05/10 all fit slopes on log-log data).

## 6. FEATURE (low) — fractional-coverage masks

`disk_mask` et al. are binary; Lesson 04's conformal section hand-rolls a K×K subgrid double
loop to get an area-fraction map. A `disk_mask(..., K)` → α-map option would remove it, but the
hand-rolled version is partly pedagogical here — low priority, file-and-forget.

---

| # | Item | Kind | Status |
|---|------|------|--------|
| 1 | contour signedness (|Z| mirroring; negative levels silently dropped) | bug | Open |
| 2 | loglog/semilog* vs plot vector-shape inconsistency | bug | Open |
| 3 | imagesc+contour overlay frame mismatch (not reproducible post-#29, incl. the originally-broken case) | fixed? | Verify+close |
| 3b | subplot with an `imagesc` panel renders only one panel | bug | Open |
| 3c | `plot()` series silently dropped when figure contains a `quiver` | bug | Open |
| 4 | −0.0 labels; quickref omissions (`set_default_axis`, `axis("xy")`, `T(i,:,:)`); document broadcasting | docs | Open |
| 4b | logical-mask assignment `M(mask) = scalar` rejected | bug/feature | Open |
| 5 | `polyfit` / `polyval` | feature | Open |
| 6 | fractional-coverage mask option | feature (low) | Open |
