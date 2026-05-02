# Rustlab Feature Requests — from `rustlab_em`

This directory holds standalone proposals for features that the `rustlab_em` curriculum wants from the upstream rustlab project. Each file is a self-contained request: motivation, proposed API, semantics, and references.

These are **requests**, not implementations — `rustlab_em` scripts work around missing features locally and note the workaround. When a request lands upstream, update the lesson scripts to use the builtin and mark the corresponding request file as `Status: Landed`.

## Priority Order (from `rustlab_em`'s perspective)

| # | File | Blocks | Status |
|---|------|--------|--------|
| 1 | [`vector-calculus-operators.md`](vector-calculus-operators.md) | Lessons 01, 02, 03, 07, 08 | **Landed** |
| 2 | [`quiver-and-streamplot.md`](quiver-and-streamplot.md) | Lessons 01, 02, 03, 04, 05 | **Landed** |
| 3 | [`contour-plots.md`](contour-plots.md) | Lessons 03, 04, 08 | **Landed** |
| 4 | [`laplacian-stencil-builder.md`](laplacian-stencil-builder.md) | Lesson 04 (pivot lesson) | **Landed and extended** (BC selector + 1-D / 3-D / eps variants in `26954a3`) |
| 5 | [`animation-export.md`](animation-export.md) | Lessons 08, 09, 11 | **Landed** (Option A Plotly HTML; Option B GIF deferred) |

All five original requests have landed. The follow-on sweep — additional rustlab features identified during the curriculum draft — lives in [`em_requests.md`](em_requests.md), which has its own per-§ status table.

Recent post-`em_requests` additions:

| File | Topic | Status |
|------|-------|--------|
| [`rlab-extension-handler-log.md`](rlab-extension-handler-log.md) | rustlab CLI announces itself as the `.rlab` handler at script start (post `.r` → `.rlab` migration) | **Proposed** |

For the upstream rustlab implementation perspective, see:
- [`../../../../rustlab/dev/plans/em_requests_plan.md`](../../../../rustlab/dev/plans/em_requests_plan.md) — the reference plan
- [`../../../../rustlab/dev/plans/em_requests_queue.md`](../../../../rustlab/dev/plans/em_requests_queue.md) — the action queue with per-item commit references
