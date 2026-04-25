# Rustlab Feature Requests — from `rustlab_em`

This directory holds standalone proposals for features that the `rustlab_em` curriculum wants from the upstream rustlab project. Each file is a self-contained request: motivation, proposed API, semantics, and references.

These are **requests**, not implementations — `rustlab_em` scripts work around missing features locally and note the workaround. When a request lands upstream, update the lesson scripts to use the builtin and mark the corresponding request file as `Status: Landed`.

## Priority Order (from `rustlab_em`'s perspective)

| # | File | Blocks | Priority |
|---|------|--------|----------|
| 1 | [`vector-calculus-operators.md`](vector-calculus-operators.md) | Lessons 01, 02, 03, 07, 08 | **High** — every lesson |
| 2 | [`quiver-and-streamplot.md`](quiver-and-streamplot.md) | Lessons 01, 02, 03, 04, 05 | **High** — how physicists look at fields |
| 3 | [`contour-plots.md`](contour-plots.md) | Lessons 03, 04, 08 | **High** — equipotentials |
| 4 | [`laplacian-stencil-builder.md`](laplacian-stencil-builder.md) | Lesson 04 (pivot lesson) | **Medium** — `spdiags` workaround exists |
| 5 | [`animation-export.md`](animation-export.md) | Lessons 08, 09 | **Low** — per-frame SVG loop workaround exists |

Lessons 01–03 are blocked on items 1–3 being at least usable. Lesson 04 unlocks everything downstream and is blocked on items 1 and 3 (item 4 is sugar). Lessons 05–10 reuse the same infrastructure.
