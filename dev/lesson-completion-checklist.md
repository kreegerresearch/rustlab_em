# Lesson Completion Checklist

**Purpose.** Every lesson in `dev/plans.md` is currently marked **Drafted** — meaning the notebook, scripts, and rendered `book/` output all exist, but no lesson has had a finalisation pass. This file is a hand-off so any agent can pick up a lesson, see exactly what has been verified and what remains, and finish it without re-discovering the state.

**Last full audit:** 2026-06-07 (after L17 merged). Re-run the verification commands below before trusting the checkmarks — they reflect the audit date, not necessarily HEAD.

**Review pass:** 2026-06-07 — a 17-lesson parallel review verified every script's live output against its Expected-Outputs table and baked numbers, plus a prose/equation scan. Fixes landed on branch `feat/build-out-drafts` (commit `cc159a5`): factor-of-2 (L02), factor-of-10 (L06), unit (L03 45 kV), direction (L04 under/overshoot), formula (L10), and ~half a dozen prose/claim corrections across L02–L16. L01/L05/L08/L09/L17 were clean. **All 17 lessons are now numeric-verified and prose-reviewed.** The remaining work is only the two cross-cutting doc fixes below + promoting the `dev/plans.md` status.

---

## How this repo is structured (recap)

- `notebooks/<NN>-<slug>.md` — the **only** file a human edits per lesson (source of truth for prose + code).
- `lessons/<NN>-<slug>/*.rlab` — standalone runnable scripts, parallel to the notebook's code blocks.
- `book/<NN>-<slug>.md` + `book/plots/<NN>-<slug>/*.svg` — **generated** by `make notebooks`. Never edit by hand.

After editing a notebook, run `make notebooks` and commit the source **and** the regenerated `book/` files together.

## Verification commands

```bash
make lesson-NN        # run every .rlab in one lesson (e.g. make lesson-11); look for "error:" / "panic"
make notebooks        # re-render all book/<slug>.md + plots from notebooks/
make notebooks-check  # CI guard: fails if book/ drifted from sources (run after make notebooks)
```

## Definition of Done (per lesson)

A lesson is **Done** (ready to promote past "Drafted") when all of these hold:

1. [ ] All scripts named in the lesson's `### Scripts` block in `dev/plans.md` exist under `lessons/<slug>/`.
2. [ ] `make lesson-NN` runs every script with **no** `error:`/`panic` output.
3. [ ] `make notebooks` renders the lesson with no error text in `book/<slug>.md`.
4. [ ] Every standalone script is showcased by a `### Example — …` block **with a rendered figure or `print()` output** in the notebook (not merely listed in the Standalone Scripts table).
5. [ ] Standard H2 sections present: Learning Objectives, Background, Standalone Scripts, Expected Numerical Outputs Summary, Exercises, What's next. (Capstone L14 is intentionally exempt from Standalone Scripts / What's next — confirm with the author.)
6. [ ] **Expected Numerical Outputs Summary** values match what the current scripts actually print (re-run and diff — this has **not** been done for any lesson yet).
7. [ ] One prose/equation review pass (units stated, equations derived, variables named — per `AGENTS.md` style rules).
8. [ ] Status bumped in `dev/plans.md` and `AGENTS.md` from `Drafted` → a new `Reviewed`/`Final` state (status vocabulary TBD — see cross-cutting tasks).

---

## Status summary (as of 2026-06-07)

Legend: ✅ done/verified · ⚠️ gap · — n/a

| L | Title | scripts run | book renders | script→example coverage | std sections | numeric table verified | review pass |
|---|-------|:--:|:--:|:--:|:--:|:--:|:--:|
| 01 | Vector Calculus & Fields | ✅ | ✅ | ✅ 3/3 (10 ex) | ✅ | ☐ | ☐ |
| 02 | Electrostatics & Coulomb | ✅ | ✅ | ✅ 3/3 | ✅ | ☐ | ☐ |
| 03 | Gauss & Potential | ✅ | ✅ | ✅ 3/3 | ✅ | ☐ | ☐ |
| 04 | Geometry & Material Maps | ✅ | ✅ | ✅ 4/4 | ✅ | ☐ | ☐ |
| 05 | Poisson/Laplace BVP | ✅ | ✅ | ✅ 5/5 | ✅ | ☐ | ☐ |
| 06 | Magnetostatics | ✅ | ✅ | ✅ 5/5 | ✅ | ☐ | ☐ |
| 07 | Faraday & Induction | ✅ | ✅ | ✅ 3/3 | ✅ | ☐ | ☐ |
| 08 | Maxwell's Equations | ✅ | ✅ | ✅ 3/3 | ✅ | ☐ | ☐ |
| 09 | EM Waves | ✅ | ✅ | ✅ 3/3 (3 plots) | ✅ | ☐ | ☐ |
| 10 | FDFD | ✅ | ✅ | ✅ 4/4 | ✅ | ☐ | ☐ |
| 11 | FDTD | ✅ | ✅ | ✅ all 5 (TF/SF + PML added) | ✅ | ☐ | ☐ |
| 12 | Waveguides & Radiation | ✅ | ✅ | ✅ all 5 (NF→FF added) | ✅ | ☐ | ☐ |
| 13 | Transmission Lines & Antennas | ✅ | ✅ | ✅ all 7 (4 antenna/S-param added) | ✅ | ☐ | ☐ |
| 14 | Capstone | ✅ | ✅ | — 1 script | ⚠️ no Standalone/What's-next | ☐ | ☐ |
| 15 | Lumped Capacitance | ✅ | ✅ | ✅ 6/6 | ✅ | ☐ | ☐ |
| 16 | Smith Chart | ✅ | ✅ | ✅ 7/7 | ✅ | ☐ | ☐ |
| 17 | Lumped Inductance | ✅ | ✅ | ✅ 6/6 | ✅ | ☐ | ☐ |

**Mechanically, all 17 lessons pass** (scripts run, books render). The remaining work is the numeric-table + review pass (DoD items 6–7) on every lesson.

---

## Priority work queue

### ✅ DONE (2026-06-07, branch `feat/build-out-drafts`) — script→example coverage gaps closed
- **L13** — added worked examples for the four shipped scripts: `twin_wire_impedance` (Z₀ vs cosh⁻¹), `s_parameters_tline` (|S11|=0.335 / |S21|=0.944 time-domain; FFT bias documented), `dipole_standing_wave` (cos kz to ~1e-16), `radiation_resistance` (73.08 Ω). Commit `29784c3`.
- **L11** — added `fdtd_tfsf_validation` (scattered zone ~1.5e-15 vs unit incident) and `fdtd_pml_depth` (reflection 0.160/0.073/0.026 at d=4/8/16). Commit `0d85bcf`.
- **L12** — added `nf2ff_transform` worked section (sin θ recovered to ~1.5%, equatorial flatness ~6%); gave the existing cavity-resonance blocks an `### Example` header. Commit `f91b35a`. *Note: the cavity blocks were already present and working — the earlier "3 ex / 5 scripts" count missed them because they lacked an `### Example` header, not because they were absent.*

All three now showcase every standalone script. Orphaned plot SVGs from earlier renders were cleaned up in the same commits.

### L14 — Capstone (no build-out needed)
Re-checked: L14 **already has** a "Standalone Script" (singular) section and a "Looking Back" closer — the earlier flag was a plural-vs-singular grep false positive. It is an intentional single-script capstone and is structurally complete. Only the numeric-table + review pass remains (DoD 6–7).

---

## Per-lesson review tasks (the "complete" lessons)

For **L01–L10, L15, L16, L17** the structure is complete. Each still needs, before promotion past Drafted:

- [ ] **Numeric-table check** — re-run the scripts, diff the printed values against the lesson's *Expected Numerical Outputs Summary* table; fix any drift. (Not done for any lesson.)
- [ ] **Review pass** — prose/equation/units sanity per `AGENTS.md` style rules; confirm exercises are answerable from the lesson.

(L15/L16/L17 were authored most recently with baked-in verified numbers, so their numeric tables are most likely already accurate — still worth a confirming re-run.)

---

## Cross-cutting tasks (not lesson-specific)

- [x] **`AGENTS.md` roadmap table** — *done 2026-06-08.* Extended to all 17 lessons, statuses corrected to `Reviewed`, and a pointer added naming `dev/plans.md` as the authoritative source.
- [x] **Post-Drafted status defined** — *done 2026-06-08.* `dev/plans.md` now documents Planned → Drafted → `Reviewed`, and all 17 lessons are marked `Reviewed`.
- [x] **Stale `lu`/`solve` references** — *done 2026-06-08.* The cached factor handles `lu(A)`/`solve(F,b)` shipped in rustlab 0.3.6; L15's Theory prose, exercise 2, and `cap_matrix_microstrip.rlab` header now say so (cross-linked to L17), and `dev/rustlab/requests/em_requests.md` §2.3 notes the follow-on.
- [ ] **Optional: smith-chart builtin** — `dev/rustlab/requests/smith-chart.md` is still open; L16 hand-rolls the background. Not blocking.

---

## Suggested order of attack

1. ~~L13 / L11 / L12 example blocks~~ — **done** 2026-06-07 (branch `feat/build-out-drafts`). Every standalone script across all 17 lessons now has a worked example.
2. ~~Cross-cutting doc fixes~~ — **done** 2026-06-08: `AGENTS.md` roadmap sync, L15 `lu/solve` note, and `dev/plans.md` status bump to `Reviewed`.
3. ~~Numeric-table + review pass across all 17~~ — **done** 2026-06-07 (commit `cc159a5`). Every lesson is numeric-verified and prose-reviewed; all found errors fixed.
4. **Curriculum is content-complete and reviewed.** Only the optional smith-chart builtin (non-blocking) remains open.
