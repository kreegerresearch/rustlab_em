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
| 5 | [`animation-export.md`](animation-export.md) | Lessons 08, 09, 11 | **Landed** (Option A Plotly HTML; Option B GIF landed later — `saveanim("*.gif")`) |

All five original requests have landed. The follow-on sweep — additional rustlab features identified during the curriculum draft — lives in [`em_requests.md`](em_requests.md), which has its own per-§ status table.

Recent post-`em_requests` additions:

| File | Topic | Status |
|------|-------|--------|
| [`rlab-extension-handler-log.md`](rlab-extension-handler-log.md) | rustlab CLI announces itself as the `.rlab` handler at script start (post `.r` → `.rlab` migration) | **Landed** (`ef460bc`, same-day turnaround) |
| [`imagesc-y-axis-orientation.md`](imagesc-y-axis-orientation.md) | `axis("xy")` / `set_default_axis` row-orientation control for `imagesc` | **Landed** (2026-05-16) |
| [`yee-and-pml-builders.md`](yee-and-pml-builders.md) | Yee-grid + SC-PML builders | **Phase 1 Landed** (2026-05-09, scripted library in `lessons/_shared/em.rlab`) |
| [`smith-chart.md`](smith-chart.md) | Smith-chart background/plotting | **Landed** (as `smith()` / `marker()` / `smith_circle()` — API differs from proposal) |
| [`laplacian-eps-3d.md`](laplacian-eps-3d.md) | `laplacian_eps_3d` variable-coefficient 3-D builder (L15 MIM capacitor) | Filed |
| [`lesson-review-findings-2026-07.md`](lesson-review-findings-2026-07.md) | 2026-07 curriculum-audit findings: 2 doc bugs (`max(M1,M2)` union idiom, harmonic-mean rationale), `'` conjugate-transpose warning, fractional-index migration note, complex literals; per-item checkboxes | **Landed** (all 5 actionable items resolved 2026-07-05; 1 closed at triage — Neumann `bc` already shipped) |
| [`lesson-review-findings-2026-07-09.md`](lesson-review-findings-2026-07-09.md) | Third-pass leftovers: contour signedness bug, loglog/semilog* shape inconsistency, conditional overlay-frame triage, docs batch (−0.0, quickref omissions, broadcasting), `polyfit`/`polyval`, fractional masks. (The pass's big asks — length-preserving `fft`, `ellipke`, `pin_dirichlet`, `trapz(M)`, `tic`/`toc`, quiver robustness, `Tensor3(:)`, exit codes — landed in PRs #28/#29 before filing.) | Filed (2026-07-11) |

For the upstream rustlab implementation perspective, see:
- [`../../../../rustlab/dev/plans/em_requests_plan.md`](../../../../rustlab/dev/plans/em_requests_plan.md) — the reference plan
- [`../../../../rustlab/dev/plans/em_requests_queue.md`](../../../../rustlab/dev/plans/em_requests_queue.md) — the action queue with per-item commit references
