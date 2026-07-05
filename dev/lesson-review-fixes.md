# Lesson Review — Fix Plan

**Status:** **EXECUTED 2026-07-05** on branch `lesson-fixes-2026-07` — all ~90 items applied by six parallel implementation agents, verified, and re-rendered (acceptance checklist below all green). Originally: ready to execute. **Baseline:** commit `6176414` (main, clean tree), rustlab 0.3.6.
**Provenance:** full second-pass review of all 17 lessons (2026-07-04) by six parallel deep-review agents. Every physics claim below was verified analytically or by actually running the shipped scripts / independent replicas; the two highest-impact code findings (L05 crash, L10 conjugate-transpose) were additionally re-confirmed by hand against rustlab 0.3.6. Line numbers refer to the baseline commit — **re-locate by the quoted text before editing** and apply multiple edits to one file bottom-up so line numbers stay valid.

## Severity inventory

| Lesson | Critical | Moderate | Minor | Overall verdict |
|---|---|---|---|---|
| 01 Vector Calculus | – | – | 3 | Clean physics; small claim/parity fixes |
| 02 Electrostatics | – | 3 | 2 | Correct core; one false exercise claim, missing derivation |
| 03 Gauss & Potential | – | – | 3 | Strongest of 01–03 |
| 04 Geometry & Materials | 1 | 2 | 5 | Convergence-rate story is wrong; Ex. 4 unpassable |
| 05 Poisson/Laplace BVP | 1 | 4 | 7 | **Code crashes on rustlab 0.3.6**; several wrong explanations |
| 06 Magnetostatics | – | 2 | 3 | Solid; consistency/cross-ref fixes |
| 07 Faraday | – | 2 | 5 | Fortuitous-agreement claim; false corner-physics exercise |
| 08 Maxwell | – | – | 6 | Strongest of 06–08 |
| 09 EM Waves | – | – | 3 | Clean |
| 10 FDFD | 2 | 2 | 5 | **Conjugation bug corrupts 2-D scattering demo + narrative** |
| 11 FDTD | – | 4 | 5 | Core algorithms exact; several stale/wrong quantitative claims |
| 12 Waveguides & Radiation | – | 3 | 4 | Excellent numerics; overpromises L14; TE-mode gap |
| 13 T-lines & S-params | 1 | 3 | 5 | Stale FFT-bias claim now false; Ex. 2 built on it |
| 14 Capstone | 2 | 2 | 2 | Central spectral story fails verification; Ex. 1–2 unsolvable |
| 15 Capacitance | – | 3 | 3 | Misdiagnosed mechanisms (bond-pad off-by-one, Kirchhoff label) |
| 16 Smith Chart | – | 2 | 4 | Numerically flawless; missing circle equations |
| 17 Inductance | – | 2 | 6 | Correct numbers; two wrong explanations; zero live prints |

## How to execute

Repo mechanics (see `AGENTS.md` for full conventions):

- Edit **only** `notebooks/<slug>.md` (lesson text + notebook code) and `lessons/<slug>/*.rlab` (standalone scripts). Never hand-edit `book/` — it is generated.
- `make notebooks` re-renders **all** notebooks into `book/` (runs every code block; deterministic). `make notebooks-check` fails if `book/` drifted. `make lesson-NN` runs one lesson's `.rlab` scripts. `rustlab run <file.rlab>` runs one script.
- Math escaping: `$...$` inline, `$$` blocks on their own paragraph line; **inside Markdown tables use `\lvert…\rvert`, never raw `|` or `\|`** inside `$...$`.
- Notebook code comments use `%`; standalone `.rlab` comments use `#`.
- **Whenever a code change alters printed output or a plot**: re-run the script, then update (a) the notebook's inline prose numbers, (b) its Expected Numerical Outputs table, and (c) any script header comments — to the **actual new printed values**, not the predictions in this plan. Predictions below labelled "expect ≈" came from verified replicas but the canonical value is whatever the run prints.
- Commit `notebooks/`, `lessons/`, and regenerated `book/` together. Suggested commit granularity: one commit per phase (or per lesson within Phase 2/3).

**Phase order matters:**

- **Phase 0 — Unblock the render pipeline (L05).** `make notebooks` currently produces 3 error blocks for lesson 05 (the committed `book/05` was captured under an older, index-flooring interpreter). Nothing else can be safely regenerated until this is fixed.
- **Phase 1 — Critical fixes** (L10, L14, L13, L04). Code bugs + the narratives built on their wrong outputs.
- **Phase 2 — Moderate accuracy/mechanism fixes** (all lessons). Prose-dominant; a few small code edits.
- **Phase 3 — Minor polish** (stale comments, rendering, objectives, clarity).
- **Phase 4 — Regenerate, verify, sync docs, file upstream notes.**

---

## Phase 0 — L05: restore runnability (CRITICAL)

### 0.1 Fractional matrix indices crash rustlab 0.3.6
- Files: `notebooks/05-poisson-laplace-bvp.md:325,337-348,362` and `lessons/05-poisson-laplace-bvp/dielectric_slab.rlab:62,71-90`.
- Problem: the dielectric-slab section indexes with `nxd/2` = 10.5, `nyd/4` = 20.25, `3*nyd/4` = 60.75. Confirmed: `rustlab run lessons/05-poisson-laplace-bvp/dielectric_slab.rlab` → `error: line 62: runtime error: index 10.5 is invalid (must be a positive integer)`; re-rendering notebook 05 yields "19 code blocks, 8 plots, 3 errors" (V(y) plot, field/D-continuity, and capacitance blocks all fail).
- Fix: replace with integer indices in **both** files: `j_mid = (nxd + 1) / 2` (= 11 for nxd = 21), `i_diel = 21` (y = 2.5 mm exactly), `i_air = 61` (y = 7.5 mm exactly). In the script also fix lines 62, 71–72, and every `nxd / 2` use at 73–79 and 87.
- Verify: `rustlab run lessons/05-poisson-laplace-bvp/dielectric_slab.rlab` exits clean; `make notebooks` reports 0 errors for lesson 05; diff `book/05-poisson-laplace-bvp.md` — captured values should match the previously committed ones (E ratio 4.000, E_diel 39.70223, D continuity to 7 digits, C_num within 1% of C_an 1.4167e-9) since the old interpreter floored the same indices. If values shift, update the notebook's inline claims and table to the new prints.

---

## Phase 1 — Critical accuracy fixes

### L10 FDFD (2 critical)

**1.1 Conjugate-transpose bug corrupts the 2-D scattering solve**
- Files: `notebooks/10-fdfd-frequency-domain.md:300` and `lessons/10-fdfd-frequency-domain/fdfd_2d_tmz.rlab:67`; also `lessons/_shared/em.rlab:35`.
- Problem: `b_2 = src_2(:)'` — rustlab's postfix `'` is a **conjugating** transpose (confirmed by direct test on 0.3.6: `([1,3]+j*[2,-1])'` → `1−2j, 3+1j`; `.'` leaves values intact). Conjugating the complex scattered-field source makes the solver compute the response to a **−x**-travelling incident wave while `E_tot = E_inc_2 + E_scat` adds the **+x** one. Both rendered plots (Re E_tot, |E_scat|) are physically wrong. Evidence: shipped script prints forward/backward/±y probes 0.318/1.209/0.318/0.318; an exact independent replica of the same operator gives 1.234/0.308/0.283/0.273; an independent 2-D Mie series gives 1.403/0.394/0.325 at the same 1.5λ probes. The correct total field has a real shadow (mean |E_tot| behind ≈ 0.51 vs ≈ 1.03 in front); the buggy one doesn't.
- Fix: change to `b_2 = src_2(:).';` in both notebook and script. In `lessons/_shared/em.rlab:35`, change the recommended pattern `spsolve(A, -j * omega * mu0 * J(:)')` to `.'` as well (currently only harmless because that J is real).
- Verify: run `lessons/10-fdfd-frequency-domain/fdfd_2d_tmz.rlab`; expect the forward probe to become the largest (≈ 1.2, backward ≈ 0.3). Update the notebook's probe numbers and Expected table rows to the actual new prints, and regenerate plots via `make notebooks`.

**1.2 "Back-scatter brighter than forward-scatter, consistent with Mie" is wrong physics**
- File: `notebooks/10-fdfd-frequency-domain.md:319`.
- Problem: narrates the bug from 1.1 as physics. For εr = 4, R = 0.4λ₀ TMz (ka ≈ 2.5) the Mie far-field forward/backward amplitude ratio is ≈ 3.15 — forward-dominant. Mie values: |F(0)| = 5.29 vs |F(π)| = 1.68.
- Fix (after 1.1): rewrite as "the forward-scatter (shadow-forming beam) is ~3–4× brighter than the back-scatter, consistent with the 2-D Mie series", and re-describe the two plots accordingly (shadow behind the cylinder in |E_tot|; forward lobe in |E_scat|).

### L14 Capstone (2 critical)

Facts established by re-running `patch_antenna.rlab` (use them as ground truth for the rewrite; re-confirm any number you print into the book):
- 900-step run: dominant peak 3.6657 GHz (matches shipped book).
- `n_step = 6000` only: dominant peak 3.6914 GHz with 74 MHz bins; **no** local maximum near 4.12 GHz above 5% of the peak anywhere in 0.5–6 GHz.
- No high-Q ring-down exists: probe envelope falls 0.35 → 0.0018 within ~300 steps of source end; a pure post-source window's spectrum is noise (max 0.02 vs 53.8).
- Patch-length sweep (50/30/20 mm): dominant peak 3.6657 GHz in **all three** (amplitudes 52.5428/52.5423/52.5421). εr sweep (2.2/4.4/9.8): peak 3.6657 GHz in all three (amplitudes 25.9/52.5/121.8).
- Timing: t₀ = 3τ = 1.2 ns ≈ step 514; source significant ~0.2–2.2 ns; the "skip 200 steps" window (0.47–2.10 ns) lies almost entirely **during** the drive; probe row `i_probe = y_g+2` is a cell the source injects into.

**1.3 The "which peak is which" caveat paragraph fails on every checkable claim**
- File: `notebooks/14-capstone-device-simulation.md:110,141` (and the related table row).
- Problem: the story (high-Q box mode → 6000 steps resolve "4.12 GHz" → 0.61 GHz bins alias it to 3.67 GHz) is contradicted by the facts above; the 4.13 GHz feature is one line of a ~0.89 GHz windowing comb in a mid-decay window, not a resonance; fine bins keep the peak at ≈ 3.69 GHz.
- Fix: rewrite the paragraph and the table row around the reproducible facts: the dominant peak is a **broad, low-Q ≈ 3.7 GHz feature of the driven response**; it does not match the 4.05 GHz air-column prediction; delete the "high-Q", "4.12 GHz", and bin-quantisation claims. Keep the (correct) arithmetic that the patch half-wave mode would sit at ≈ 1.43 GHz and the air-column estimate at ≈ 4.05 GHz.

**1.4 Exercises 1–2 are unsolvable as written**
- File: `notebooks/14-capstone-device-simulation.md:148-149`.
- Problem: they ask students to watch the dominant FFT peak scale as 1/L_patch and 1/√ε_eff, but the sweeps above show the dominant peak does not move at all (Ex. 1 also contradicts line 110's own "box modes don't move with L_patch").
- Fix: re-scope both: (Ex. 1) "verify the dominant peak does **not** move with L_patch — evidence it is not a patch mode — then hunt for a secondary peak that does"; (Ex. 2) same pattern for εr, and/or prescribe a measurement that can isolate the patch mode: move the probe several columns away from `j_feed` (it currently sits in the driven column), subtract a no-patch reference run, lengthen the run and window after the drive.

**1.5 (moderate, same rewrite) Driven-response mislabelled as free decay**
- Files: `notebooks/14-capstone-device-simulation.md:44,105`; `lessons/14-capstone-device-simulation/patch_antenna.rlab:89,120,147`.
- Problem: "After the source pulse subsides, the trace is the free decay… FFT the probe trace (skipping the first 200 steps)" — skipping 200 steps does not skip the source (see timing facts), and the probe is inside the driven column.
- Fix: state that the 900-step window is the **driven** response (or lengthen the run and window after ~step 1000 for true decay), and move the probe a few columns off `j_feed` (then re-run and update every captured number).

**1.6 (moderate, same rewrite) Unexplained 50 mm patch vs "2.45 GHz on FR-4" design**
- File: `notebooks/14-capstone-device-simulation.md:5,110,140`.
- Problem: the lesson tables a ~30 mm design length for 2.45 GHz but simulates a 50 mm patch (half-wave ≈ 1.43 GHz) with a 2.5 GHz feed, never explaining the mismatch. c₀/(2·0.05·√4.4) = 1.43 GHz; λ₀/(2√4.4) at 2.45 GHz = 29.2 mm.
- Fix: either add one sentence justifying the deliberate oversizing, or resize the patch to ~30 mm so geometry, feed, and design frequency agree (resizing changes all captured numbers — re-run and re-capture).

### L13 Transmission lines (1 critical)

**1.7 S-parameter FFT-bias claim is stale and now false**
- Files: `notebooks/13-transmission-lines-and-antennas.md:374,495`; `lessons/13-transmission-lines-and-antennas/s_parameters_tline.rlab:144-147`.
- Problem: notebook claims the single-bin FFT estimate is "biased … substantially (it does not conserve energy)" and Exercise 2 says FFT values are only "within ~10%". Running the shipped script: FFT gives |S11| = 0.33374, |S21| = 0.94267 (0.12%/0.015% error; energy sum 1.000000) — *better* than the time-domain peak ratio (0.33461/0.94371; energy 1.0026). The prose predates the magic-time-step change (`S_cfl = 1.0`, commit a6ccc4d), which makes pulses shape-exact — as the script's own header (lines 45–48) says, so the script contradicts itself internally.
- Fix: rewrite notebook line 374: the FFT single-bin estimate matches to ~0.1% *because* of the magic time step; the time-domain peak ratio carries the small ~0.3% bias. Rewrite Exercise 2 (line 495) to break the magic condition deliberately (rerun at S = 0.95, watch dispersion bias appear, then taper the junction). Delete the stale "~ few % bias" comment at script lines 144–147.

### L04 Geometry (1 critical)

**1.8 Staircase-vs-conformal convergence-rate story is false; Exercise 4 unpassable**
- File: `notebooks/04-geometry-and-material-maps.md:299,345`.
- Problem: "staircase error decays as O(h) while the conformal error decays as O(h²)" and Ex. 4's "verify slopes ≈ −1 and ≈ −2" are false for the disk-area metric the lesson measures. A K×K midpoint-subsampled α map is mathematically identical to a staircase mask on a K×-finer grid, so both curves have the **same** log-log slope, only offset by ≈ K². Measured staircase relative errors at N = {50,100,200,400}: {2.26e−3, 4.33e−3, 1.98e−3, 7.86e−5} — non-monotonic, fitted slope ≈ −1.55; conformal ≈ −1.32. The area error is a fluctuating lattice-point-count (Gauss-circle) error ~h^1.5, and the summary-table "≈ 100× better" is actually 83×.
- Fix: rewrite line 299: staircase error is *bounded* by O(h) but fluctuates in sign/magnitude for pure area counts (typically ~h^1.5); the K = 8 conformal map is equivalent to an 8×-finer staircase, hence the observed ~64–80× ≈ K² gain. Rewrite Exercise 4: either (i) average |error| over ~50 random disk-centre offsets before fitting slopes, or (ii) drop the −1/−2 targets and ask the student to verify the conformal error stays 1–2 orders below staircase at every N and explain why via the h/K equivalence. Add a pointer that a clean O(h) demonstration needs a *solver* quantity (Lesson 05/13 capacitance). Fix the summary-table row ("≈ 100×" → "≈ 83×" or "nearly two orders of magnitude").

---

## Phase 2 — Moderate accuracy & mechanism fixes

### L02 Electrostatics
- **2.1** `notebooks/02-electrostatics-coulomb.md:252,294` — Ring "err ≲ 1e-3 V/m at Nseg = 360" is wrong: on-axis the discrete ring sum is exact by symmetry for **any** Nseg (every segment equidistant from an axial point); the book prints 8.7e-11. The standalone script `ring_of_charge.rlab:8-11,43` already states the exactness, contradicting the notebook. Fix comment + table entry: "≈ 1e-10 V/m (machine precision — exact for any Nseg on-axis; segment count matters only off-axis, cf. Exercise 4)".
- **2.2** `notebooks/02-electrostatics-coulomb.md:302` — Exercise 5's claim that the d-dependent part of the 2-D grid energy "tracks −k_e q²/d" is wrong: the exact z = 0-plane cross term is −k_e q²/**d²** (J/m, verified analytically in elliptic coordinates and numerically), and naive grid summation is dominated by a non-converging near-charge artifact 3+ orders above the true value. Fix: reword to ask for the cross term ε₀∬E₁·E₂ dA with cells within a few Δ of each charge masked, converging to −k_e q²/d² ("the in-plane slice of the 3-D −k_e q²/d law") — or drop the quantitative claim and ask only for sign and trend as d shrinks.
- **2.3** `notebooks/02-electrostatics-coulomb.md:161-173` — The centerpiece far-field dipole formula is asserted with zero derivation, yet objective line 9 says "Derive and verify" and Exercise 2 requires the multipole technique. Fix: insert a 3–4 line derivation: expand V = k_e q(1/r₊ − 1/r₋) with r∓ ≈ r ∓ (d/2)cosθ to first order in d/r → V ≈ k_e p·r̂/r², then E = −∇V (components E_x = k_e p(2x²−y²)/r⁵, E_y = 3k_e p xy/r⁵ are already correct).

### L04 Geometry
- **2.4** `notebooks/04-geometry-and-material-maps.md:260` — "exact at interfaces normal to a grid axis and converges as O(h²) at diagonal ones" is wrong: with exact coverage fractions the α-weighted cell sum reproduces areas exactly for **any** orientation; orientation affects *solver* error, not coverage arithmetic. Fix: replace with "the α-weighted cell sum reproduces areas exactly, up to the accuracy of the α estimate itself; orientation affects the *solver* error at the interface — which is why the tangential/normal averaging rule below matters."
- **2.5** `notebooks/04-geometry-and-material-maps.md:262` — "O(K⁻²) approximation to the true coverage" overstates midpoint sampling on a discontinuous indicator; worst-case per-cell α error is O(1/K) (typically ~K^−1.5). Fix: "an O(1/K) worst-case (typically better) approximation".

### L05 Poisson BVP
- **2.6** `notebooks/05-poisson-laplace-bvp.md:260-264` — Harmonic-mean justification is wrong: *any* flux-conservative face-coefficient scheme (arithmetic mean included) preserves discrete D_n continuity; the lesson's own D-continuity check would pass either way. The real point is accuracy: the harmonic mean is the exact series composition of two half-cells (exact for a face-aligned interface); arithmetic mis-weights it, leaving an O(h) error (≈ 0.45% here). Fix: rewrite accordingly; delete "artificial sources" and "breaks that exactly". (Same wording exists upstream — see item 4.4.)
- **2.7** `notebooks/05-poisson-laplace-bvp.md:242,250,508` — The 48-vs-50 V/m mid-gap gap is ~entirely plate-row grid snapping (plates land at y = ±0.010396 m → gap 0.020792 m → V₀/gap = 48.095; computed 48.0895 matches to 0.01%). Fix: either switch to ny = nx = 99 so plates land exactly at ±0.01 m (then re-capture; mid-gap prints ≈ 50), or add one sentence explaining the snap and correct the table row's interpretation.
- **2.8** `notebooks/05-poisson-laplace-bvp.md:521,161` — Exercise 3's expected fringing "(typically 10–20% above 1-D at w/d ~ 3)" is ~3× off: the actual flux integral on this geometry gives +55% (verified, contour-independent), ≈ 40% genuine fringing (Palmer at w/d = 3 → 1.42) plus ~10% coupling to the nearby grounded box. Fix: change to "≈ 50–60% above the 1-D value for this geometry — roughly 40% genuine fringing (cf. Palmer's formula) plus ~10% coupling to the grounded box", and soften line 161's "box … doesn't affect the result" to "close enough that it still adds ~10% to the plate charge".
- **2.9** `notebooks/05-poisson-laplace-bvp.md:484` — "refining the grid pushes the fit closer to −0.33" is not robust: with the same cell-index fit window the slope goes −0.378 (100²) → −0.315 (200²) → −0.287 (400²); with a fixed physical window it moves *away* (→ −0.42, the true continuum slope over that non-asymptotic window). Fix: replace with a sentence that the fitted exponent is sensitive to the fit window and the one-cell r-origin ambiguity, scattering ≈ −0.29…−0.42 around the true −1/3 on 100–400² grids; recovering it sharply needs h → 0 *and* a window pushed to smaller physical r. Keep the qualitative-robustness conclusion.

### L06 Magnetostatics
- **2.10** `notebooks/06-magnetostatics.md:11,418` — Objective and scripts table promise "exterior shielding" that the lesson body correctly disclaims (line 408; exterior samples ≥ bare-wire references). Fix: objective bullet 5 → "…observe flux concentration, and see why exterior shielding requires an applied external field (Exercise 5)"; scripts-table cell → "flux concentration + bare-wire exterior check".
- **2.11** `notebooks/06-magnetostatics.md:316` — Dangling cross-ref: "Exercise 4 walks through the convergence study" but Exercise 4 is the solenoid-via-Poisson problem. Fix: delete the pointer ("Both errors shrink under grid refinement.") or append a convergence sub-task to an exercise.

### L07 Faraday
- **2.12** `notebooks/07-faraday-induction.md:144,147` — The "within ~0.5%" M_num-vs-formula agreement is a fortuitous cancellation: exact M (elliptic) = 8.017e-9 H; the 41×41 quadrature is −1.0% and the small-a/b formula −1.5% (its (3/8)(a/b)² = 1.5% first correction); refining the grid *worsens* the match to the formula (8.025e-9 at 161², 1.6% off) while converging to exact. Fix: rewrite the sentence per these numbers (grid refinement converges M_num to the exact value; only shrinking a/b tightens agreement with the formula); update the line-144 code comment.
- **2.13** `notebooks/07-faraday-induction.md:290` — Exercise 4 asks students to verify J "pinches at the corners — the same effect [as] Lesson 05", but for ∇²ψ = const with ψ = 0 on a square, |J| → 0 at interior 90° corners (Prandtl torsion analogy; max at edge midpoints). Fix: reword to "verify |J| goes to zero at the corners and peaks at the edge midpoints — the *opposite* of Lesson 05's re-entrant-corner enhancement, because these are interior 90° corners."

### L11 FDTD
- **2.14** `notebooks/11-fdtd-simulation.md:329` + `lessons/11-fdtd-simulation/fdtd_tfsf_validation.rlab:152` — "matches the analytic incident to ~10⁻¹⁵" is mislabelled: the script compares against the **auxiliary 1-D grid** (`Ez_aux`), not the analytic wave (vs analytic the residual is the ~10⁻³–10⁻⁴ dispersion error). Fix: "matches the auxiliary-grid incident to round-off (~10⁻¹⁵)"; fix the script's stale `# → ~ 1e-2 or smaller (dispersion-limited)` comment (actual: round-off, aux-grid comparison).
- **2.15** `notebooks/11-fdtd-simulation.md:300,377,386` — "near-unity"/"→ 1" transmission above ω_p is wrong for these parameters: measured ratio 0.634 at 5 GHz (CW analytic |T| ≈ 0.75; γ = 2π×1 GHz keeps the film lossy). Fix: either state "jumps from ~0.2 to ~0.6–0.7 (residual damping γ and index mismatch keep it below 1)" in all three places, or reduce γ to ~2π×0.1 GHz in the code so "near unity" is honest (then re-run and re-capture all dispersive-section numbers).
- **2.16** `notebooks/11-fdtd-simulation.md:375` — Outputs-table row "2-D PEC shadow depth … ~ 0.03" is printed by nothing (script `fdtd_2d_scattering.rlab` has no `print()` at all) and depends on unstated probe/normalization choices (replica: 0.023 absolute, 0.010 normalized). Fix: add a lee probe + lit-window measurement with `print()` to the script (define probe cell and window) and align the table row with the actual print — or delete the row.
- **2.17** `notebooks/11-fdtd-simulation.md:359` — Rendering: raw `|` in `$|t_1 t_2|$` inside the scripts table splits the cell. Fix: `$\lvert t_1 t_2\rvert$`.

### L12 Waveguides & Radiation
- **2.18** `notebooks/12-waveguides-and-radiation.md:254` + `lessons/12-waveguides-and-radiation/nf2ff_transform.rlab:42-43` — Near-field term magnitudes at kr ≈ π/2 are misnormalized: relative to the radiating term they are 1/kr = 0.637 and 1/(kr)² = 0.405, i.e. ≈ 64% and ≈ 41%, not "40% and 26%". Fix in both files.
- **2.19** `notebooks/12-waveguides-and-radiation.md:250,274,284,309` — Four claims that L14 *uses/reuses* the NF→FF kernel for a gain pattern; the shipped capstone has no NF→FF call and no gain pattern (its 2-D→3-D table lists NF→FF only as the 3-D production step). Fix: soften all four to conditional/future ("the transform a 3-D production version of the capstone would apply — see L14's 2-D→3-D table").
- **2.20** `notebooks/12-waveguides-and-radiation.md:22-43` — TE modes never mentioned; a student can misread TM₁₁ 7.071 GHz as the guide's lowest cutoff, when TE₁₀ = c/2a = 3.75 GHz is dominant. Fix: add 1–2 sentences in the Example intro: TE modes satisfy a Neumann BC; this lesson solves the TM (Dirichlet) family only; the guide's true dominant mode is TE₁₀ at 3.75 GHz. Note: `laplacian_2d(nx, ny, "neumann")` **is shipped** (verified on 0.3.6) — so either mention it as the door to the TE family or add an optional exercise computing TE modes with it; do not claim the capability is missing.

### L13 Transmission lines
- **2.21** `notebooks/13-transmission-lines-and-antennas.md:116` — "error drops like h²" is wrong for the staircased coax: measured C′ errors 11.05%/6.59%/3.38% at nx = 61/121/241 — O(h), staircase-dominated. Fix: "drops roughly like $h$ — the first-order staircase boundary error dominates the second-order stencil (11% → 6.6% → 3.4% at 61/121/241 cells)".
- **2.22** `notebooks/13-transmission-lines-and-antennas.md:260-263,483-485` — "reflected amplitude ≈ source peak" (and "≈ source peak / 3") don't match prints (0.527, 0.1767 vs nominal source peak 1.0); the launched-pulse amplitude ≈ 0.527 is never printed. Fix: reword comments/table rows to "≈ 0.53 = launched-pulse amplitude (soft source injects ≈ half its nominal peak)" and "≈ 0.18 ≈ incident/3" — or print an incident-pulse reference from a long-line run.
- **2.23** `notebooks/13-transmission-lines-and-antennas.md:502` — What's-next promises L14 uses waveport S₁₁ + NF→FF; it doesn't (same as 2.19). Fix: "…a pulsed feed and probe-trace FFT built from this lesson's port machinery; the full waveport-S₁₁ and NF→FF steps are mapped out as the 3-D extension."

### L15 Capacitance
- **2.24** `notebooks/15-lumped-capacitance.md:204` + `lessons/15-lumped-capacitance/parasitic_bondpad.rlab:95-106,16-19` — Bond-pad undershoot is misdiagnosed as a "Gauss pillbox" artifact; the dominant cause is a pin-spacing off-by-one: `dz = t_ox/3` with pins at kk = 6 and kk = 10 → discrete gap 4·dz = 1.33·t_ox vs the ideal-baseline t_ox, i.e. plate term = 0.75·C_ideal (this predicts the observed ratios 0.862/0.834 at 500 nm and explains why 1500 nm also sits below ideal). Fix: set `dz = t_ox/4` (pin-to-pin = t_ox, matching the MIM convention), re-run the script, regenerate `bondpad_C_sweep.svg`, and rewrite the notebook paragraph (drop the pillbox explanation; re-derive the fringing statement from the new numbers — the old "9% fringing" is contaminated).
- **2.25** `notebooks/15-lumped-capacitance.md:39,53-57,260-261` — The "Kirchhoff (analytic)" fringing reference is the 2-D strip correction applied once to a **square** plate; the proper square-plate (Palmer) form applies it for both edge pairs (1.283 vs 1.283² = 1.646; published square-plate numerics ≈ 1.56). The "C_Gauss overshoots Kirchhoff by ~10%" claim flips sign against the proper reference. Fix: either switch the analytic curve to the Palmer product form and re-word the bracketing claim, or relabel the curve "strip (2-D) fringing estimate — lower bound for a square plate" and soften lines 39/261.
- **2.26** `notebooks/15-lumped-capacitance.md:27,35,177` vs `lessons/15-lumped-capacitance/lumped_C_parallel_plate.rlab:109-120` and `MIM_capacitor_3d.rlab:96-103` — Three mutually inconsistent explanations of the energy-method undershoot; none matches the code (parallel-plate script sums E² over **all** cells; MIM includes the layers the text says it excludes). The true mechanism: the cell-centred ε-weighted sum covers only 3dz of the 4dz pin-to-pin gap (half a cell missing at each plate face) → ≈ 3/4, matching the printed 0.7597. Fix: adopt that single story in Theory (line 27/35) and the MIM text (line 177), and either mask conductor cells in `lumped_C_parallel_plate.rlab` to match the Theory text or amend the text to describe what the script does.

### L16 Smith chart
- **2.27** `notebooks/16-smith-chart.md:9,21-33,258` — Constant-r/constant-x circle equations are promised (Objective 1) and needed (line 258 uses the constant-g formula with centre −2/3, radius 1/3) but never taught. Fix: add to the Bilinear Map theory: constant-r circles centre r/(1+r), radius 1/(1+r); constant-x arcs centre 1 + j/x, radius 1/\lvert x\rvert; via the Γ → −Γ admittance mirror, constant-g circles centre −g/(1+g), radius 1/(1+g); reference this at line 258.
- **2.28** `lessons/16-smith-chart/l_match_synthesis.rlab:8-11` (+ clause at `notebooks/16-smith-chart.md:116`) — "When R_L < Z_0 … only the series-then-shunt ordering works" is false for Z_L = 30+j50: g_L = 0.441 < 1 so shunt-first also matches (b₁² = g−g² = 0.2466 > 0; four networks total). Correct rule: series-first is *forced* only for g_L > 1, shunt-first only for r_L > 1; loads outside both unit circles admit both orderings. Fix script comment; add one clause in the notebook: "(for loads outside both unit circles, like this one, shunt-first yields two more solutions — Exercise 1 explores it)".

### L17 Inductance
- **2.29** `notebooks/17-lumped-inductance.md:69` — The 1.2% loop-L shortfall is attributed to grid resolution, but the flux integral is essentially exact: it reproduces the exact coplanar-loop mutual M(R, R−a) = 247.66 nH to 5 digits (elliptic: k² = 0.999898, K = 5.9815, E = 1.00028); the gap is the O(a/R) truncation of the asymptotic ln(8R/a)−2 formula (250.79 nH). Line 140 already says "the flux integration is essentially perfect" — contradiction. Fix: replace line 69's clause with the asymptotic-truncation explanation.
- **2.30** `notebooks/17-lumped-inductance.md:242` — "the inductance diverges" at full plunger insertion is false: at x = ℓ, L = μ₀μ_r N²A/ℓ ≈ 158 mH (finite) and F ≈ 0.79 N (finite); divergence needs μ_r → ∞. Fix: "…the inductance climbs toward its μ_r-times-larger core-filled value and the force scales like μ_r² near full insertion — a solenoid valve 'snaps' shut."

---

## Phase 3 — Minor polish

### L01
- **3.1** `notebooks/01-vector-calculus-and-fields.md:282` — "Each writes SVGs to `outputs/`" is false (scripts save next to themselves; AGENTS.md:106) and "in this directory" is wrong from the rendered book page. Fix: "SVGs land next to each script in `lessons/01-vector-calculus-and-fields/` and are gitignored"; same "this directory" phrase in L02:272.
- **3.2** `notebooks/01-vector-calculus-and-fields.md:9` — Objective promises numerical verification of the divergence theorem; the body defers it (line 203) to Exercise 2. Fix: "Verify Stokes' theorem numerically on a simple test field (the divergence theorem is Exercise 2 and returns as Gauss's law in Lesson 03)".
- **3.3** `notebooks/01-vector-calculus-and-fields.md:262` — "agree to within sub-percent discretization error": both sides print exactly 8 (linear field → curl stencil and trapz are exact). Fix: "agree to machine precision here — every discrete operation is exact for this linear field; a field with spatially varying curl (Exercise 4) exposes genuine discretization error."

### L02
- **3.4** `notebooks/02-electrostatics-coulomb.md:203` — "under 1.5%" → exact value is 1.504% at y/d = 5. Fix: "≈ 1.5%".
- **3.5** `notebooks/02-electrostatics-coulomb.md:209` — Field-line density ∝ |E| is a 3-D rule no planar diagram can satisfy; caveat blames only seeding. Fix: append "(a 3-D property; no flat 2-D drawing of a 3-D field can encode it exactly — and streamplot's uniform seeding doesn't try)".

### L03
- **3.6** `lessons/03-gauss-law-and-potential/gauss_sphere.rlab:26` — Comment `# ≈ 0 (linear in r near origin)` vs actual 71.9 V/m. Fix: `# ≈ 71.9 V/m (small — grows linearly in r near the origin)`.
- **3.7** `notebooks/03-gauss-law-and-potential.md:129` — "closed loops surrounding each charge" mismatches the plotted ideal point-dipole potential (lobes pinch at the origin; no separated charges). Fix: "closed lobes on either side of the V = 0 bisector, pinching together at the point dipole at the origin (the two-charge version, with loops around each charge, is Exercise 5)".
- **3.8** `notebooks/03-gauss-law-and-potential.md:8-9` — Objectives overstate the body (cylindrical symmetry is exercises-only; the point-charge sum is Exercise 5). Fix: reword to "spherical and planar symmetry in the lesson (cylindrical in the exercises)" and "Compute the dipole potential on a grid and recover E = −∇V numerically (the general point-charge sum is Exercise 5)".

### L04
- **3.9** `lessons/04-geometry-and-material-maps/shape_rasterization.rlab:33` — "overshoots" → "undershoots" (3.135 < π).
- **3.10** `notebooks/04-geometry-and-material-maps.md:87` — Undershoot mechanism reads as general but the sign is grid-dependent (same mask overshoots at N = 50/100/400). Fix: add "on this particular grid — at other resolutions the same mask can overshoot; the sign of the staircase error is haphazard."
- **3.11** `notebooks/04-geometry-and-material-maps.md:91` — "An equilateral triangle" isn't (sides 2.000/1.972/1.972). Fix: "a nearly equilateral triangle" (or move the apex to (0, −0.7+√3)).
- **3.12** `notebooks/04-geometry-and-material-maps.md:174-176,327-338` — Three region-area prints (≈ 0.380/0.201/0.583) missing from the outputs table and lack analytic references (0.3728/0.1982/0.5872; segment area 0.25·cos⁻¹(0.4) − 0.2√0.21). Fix: add the three rows with analytic values + a parenthetical that thin overlap slivers rasterize with larger relative error (up to ~2%).

### L05
- **3.13** `notebooks/05-poisson-laplace-bvp.md:110-116` + `lessons/05-poisson-laplace-bvp/iterative_solvers.rlab:5-8,63` — Off-by-one in spectral-radius formulas: for N interior points, ρ_J = cos(π/(N+1)) (not cos(π/N)); ω_opt = 2/(1+sin(π/21)) = 1.7406 (script computes 1.7295). Fix formulas (or state "N = points per side including boundary"); Exercise 2's formula too.
- **3.14** `notebooks/05-poisson-laplace-bvp.md:206` — `ij2k` used ~20× but never defined. Fix: one sentence at first use: "`ij2k(i, j, ny)` maps grid indices to the column-major flat index k = (j−1)·ny + i used by `laplacian_2d`; note the third argument is `ny`."
- **3.15** `notebooks/05-poisson-laplace-bvp.md:339,353-364,514` — The ≈1% C gap and E_diel = 39.70 are exactly the half-cell interface offset (interface at face y = 4.9375 mm → exact E_diel = 39.7022, matching the print to 6 digits). Fix: add one sentence; change the table row to "0.7% below analytic — set by the half-cell interface offset."
- **3.16** `notebooks/05-poisson-laplace-bvp.md:235` — Block comment promises a flux integral the block doesn't do. Fix: "Recover the field; the actual flux-integral C is Exercise 3."
- **3.17** `notebooks/05-poisson-laplace-bvp.md:276-284` — Silent switch from interior-only grid convention to boundary-inclusive nodes. Fix: one sentence: "this time the grid *includes* the plate rows, so the Dirichlet values are pinned as rows rather than moved to the RHS."
- **3.18** `notebooks/05-poisson-laplace-bvp.md:498-515` — Outputs table omits the printed `C_1d ≈ 2.66e-11 F/m` (line 247). Fix: add the row.
- **3.19** `notebooks/05-poisson-laplace-bvp.md:201-219,303-317,407-419` — The ~15-line pinning loop appears 3× nearly verbatim. Fix: keep the first fully commented; compress the later two with "same pinning idiom as the parallel-plate block".

### L06
- **3.20** `notebooks/06-magnetostatics.md:303-316,430` — The "~12%" two-wire error mixes discretization with grid snapping (wires snap to x = ±0.020861; snapped-geometry reference −2.78e-6 T → true numerical error ≈ 14.5%; sample column sits ~1 mm off the midline). Fix: compute the analytic reference from actual grid coordinates (`d_act = xs(j_pos) - xs(j_neg)`) and update the percentage, or add a sentence noting the snap.
- **3.21** `notebooks/06-magnetostatics.md:11` — LaTeX inside a code span renders literally: `` `laplacian_eps_2d(1/\mu_r, \cdot)` ``. Fix: put the math outside the backticks or write `laplacian_eps_2d(inv_mu, dx, dy)`.
- **3.22** `notebooks/06-magnetostatics.md:234` — "trades a vector field for a vector field that satisfies a Poisson equation" is a tautology. Fix: "trades the Biot–Savart *integral* for a potential A that satisfies a Poisson equation".

### L07
- **3.23** `notebooks/07-faraday-induction.md:258,261,283` — "near r = 0 both go to zero" / table "≈ 0" vs printed 40606 A/m² (sampled at r ≈ 1.4 mm where σḂr/2 = 4.06e4 — the print matches the ramp). Fix table row: "≈ 4.1×10⁴ A/m² (= σḂr/2 at the sampled r ≈ 1.4 mm; → 0 as r → 0)" and adjust prose.
- **3.24** `notebooks/07-faraday-induction.md:147` — "Reciprocity is built into the formula": the flux-integral definition isn't manifestly symmetric. Fix: "guaranteed by the underlying Neumann double-integral form (not obvious from the flux integral we compute)".
- **3.25** `notebooks/07-faraday-induction.md:153-167` — Imposed-Ḃ approximation never stated. Fix: add after the three bullets: "We take B_z as the *imposed* field only — the eddy currents' own field is neglected, valid when the field changes slowly compared with the magnetic diffusion time μ₀σtR/4 (~1 ms for a mm-thick copper disk)."
- **3.26** `notebooks/07-faraday-induction.md:261` — "The drift of these eddies into a conductor…" is garbled. Fix: "These same eddies, driven in a solid iron core, are why transformer cores must be laminated: …".
- **3.27** `notebooks/07-faraday-induction.md:288-289` — Exercises 2–3 need hints (Ex. 2's swapped integration has the singular ring inside the disk; Ex. 3 needs the 2πρ dρ dz volume element). Fix: add "use a finer grid near the ring or integrate A_φ around the outer loop" and "work in the (ρ,z) half-plane with volume element 2πρ dρ dz".

### L08
- **3.28** `lessons/08-maxwell-equations/maxwell_consistency.rlab:64` — Comment `# ≈ (k dx)^2 / 6` vs printed 3.0795e-3 = (kΔx)²/2. Fix: `# ≈ (k dx)^2 / 2 — one-sided edge stencils dominate; interior errors cancel`.
- **3.29** `notebooks/08-maxwell-equations.md:310` — `\|…\|` renders as norm bars for an absolute value. Fix: `$\max\lvert I_{\rm wire}-I_{\rm disp}\rvert/I_0$`.
- **3.30** `notebooks/08-maxwell-equations.md:3` — μ₀ε₀ ∂E/∂t called "the displacement current" (units T/m). Fix: "μ₀ times the displacement-current density ε₀ ∂E/∂t".
- **3.31** `notebooks/08-maxwell-equations.md:94` — "within 10⁻⁴ of I₀" vs printed 1.6449e-4. Fix: "within 2×10⁻⁴" (or quote 1.6×10⁻⁴).
- **3.32** `notebooks/08-maxwell-equations.md:7,32-35` — Objective promises all four integral forms; only two shown. Fix: add ∮B·dA = 0 and ∮E·dℓ = −dΦ_B/dt at line 33, or soften the objective.
- **3.33** `notebooks/08-maxwell-equations.md:230,234` — Poynting theorem stated with vacuum u but applied to a coax dielectric. Fix: state u = ½(E·D + B·H) with the vacuum form as the special case.

### L09
- **3.34** `notebooks/09-em-waves.md:265` — "four artefacts" but the notebook makes three (envelope-only SVG is script-only). Fix: "three artefacts" or attribute the envelope figure to the standalone script.
- **3.35** `notebooks/09-em-waves.md:348-349` — `\|E_0\|/\|B_0\|` → `\lvert…\rvert` (consistency with line 353 and AGENTS.md).
- **3.36** `notebooks/09-em-waves.md:261` — "plows into the metal at the same instant the electric field cancels" misstates a spatial fact as temporal. Fix: "…right where the electric field is forced to zero: the B-antinode sits on the E-node at the surface."

### L10
- **3.37** `notebooks/10-fdfd-frequency-domain.md:10` — Objective promises "~80 dB attenuation against an analytic test case" that is never measured (only the cardinal-symmetry print, which line 133 itself disclaims). Fix: reword to match ("check assembly symmetry and see hard-wall vs PML fields") or add a quantitative check (compare |E_pml| along a radius to √(2/(πkr)) decay, or measure residual reflection vs a bigger-grid reference as L11 does). *(moderate — do not skip)*
- **3.38** `notebooks/10-fdfd-frequency-domain.md:425,439` — Raw `|` in `$|E|$` and `$|R|=1/3$` inside tables. Fix: `\lvert…\rvert`. *(moderate — breaks GitHub rendering)*
- **3.39** `notebooks/10-fdfd-frequency-domain.md:269` — Promises three plots incl. |E_total|; notebook has two. Fix: drop the clause or add the block.
- **3.40** `notebooks/10-fdfd-frequency-domain.md:95` + `fdfd_pml_demo.rlab:49` — Regularization `(1 - 1e-12*j)` is a (negligible) gain under e^{−iωt}, contradicting the loss-sign section at line 329. Fix: `(1 + 1e-12*j)` in both.
- **3.41** `notebooks/10-fdfd-frequency-domain.md:32` — TEz "same scalar form with ε↔μ" holds only for homogeneous ε. Fix: add "in piecewise-uniform regions" or cite ∇·(ε⁻¹∇H_z) + k₀²μ_r H_z = 0.
- **3.42** `notebooks/10-fdfd-frequency-domain.md:419` — Half of 25 MHz is 0.5% at 2.5 GHz, not 1%. Fix: "about 0.5%" (or keep 1% for the full step).
- **3.43** `notebooks/10-fdfd-frequency-domain.md:3` — "The four full-wave equations from Lesson 09" → Lesson 08.

### L11
- **3.44** `notebooks/11-fdtd-simulation.md:53` — H3 title "600-cell run with λ ≈ 30 cm pulse": the source is a baseband Gaussian (spatial 1/e half-width ≈ 12 mm); no 30 cm wavelength exists. Fix: "Example — 600-cell run, ~12 mm Gaussian pulse through an ε_r = 4 slab".
- **3.45** `lessons/11-fdtd-simulation/fdtd_dispersive.rlab:59-61,20-21` — Stale header: "Gaussian pulse centred on 8 GHz … straddles ω_p (10 GHz)" vs actual f_mod = 2 GHz, f_p = 3 GHz; and Drude gold ω_p/2π ≈ 2.18 **PHz**, not THz. Fix both.
- **3.46** `lessons/11-fdtd-simulation/fdtd_2d_scattering.rlab:19` — "top and bottom are simply too far away to reflect within the run length" is false (round trip ≈ 40 steps ≪ 200). Fix: say the edge diffraction is weak and tolerated, not absent.
- **3.47** `notebooks/11-fdtd-simulation.md:51` — The delayed-copy boundary is the S=1 limit of Mur's first-order ABC, not the full Mur. Fix: "the S=1 limit of Mur's first-order ABC (a one-step-delayed copy)" — the 0.5% figure matches (1−S)/(1+S).
- **3.48** `notebooks/11-fdtd-simulation.md:335` + `fdtd_pml_depth.rlab:79,83-86` — (a) State R_target = 10⁻⁸ explicitly instead of "−80 dB" (amplitude vs power ambiguity); (b) acknowledge the script's co-located σ* (not face-centred, the choice L10 warns about) as a contributor to the 0.16/0.073/0.026 residuals, not just "the discretised cubic ramp".

### L12
- **3.49** `notebooks/12-waveguides-and-radiation.md:133` vs `:248` — Unflagged time-convention switch (e^{−iωt} for Hertzian section; NF→FF integral assumes e^{+jωt}). Fix: add the script's parenthetical "(e^{+jωt} time convention, so outgoing waves carry e^{−jkr})" at line 248.
- **3.50** `lessons/12-waveguides-and-radiation/half_wave_dipole.rlab:16,68` — Stale comments: pattern error "~1e-4 to 1e-3" (actual print 6.78e-6) and "matches … to ~0.01 Ω" (actual 0.051). Fix: "~ 7e-6" and "~ 0.05 Ω (the η₀-convention offset)".
- **3.51** `lessons/12-waveguides-and-radiation/hertzian_dipole.rlab:11` — Garbled header "P_rad ≈ 80π²(dℓ/λ)² |I₀|²/2 / η₀^{-1}". Fix: drop the "/ η₀^{-1}" suffix.
- **3.52** `notebooks/12-waveguides-and-radiation.md:28` — LaTeX inside code span: `` `eigs(L, 4 n_{\rm wanted})` ``. Fix: `` `eigs(L, 4*n_wanted, "sm")` ``.

### L13
- **3.53** `notebooks/13-transmission-lines-and-antennas.md:468,486` — Raw `|` in `$|V(z)|$` and `$|V|_{env}$` inside tables (breaks GitHub rendering). Fix: `\lvert…\rvert`.
- **3.54** `notebooks/13-transmission-lines-and-antennas.md:470` — `\|z\|` → `\lvert z\rvert` in the dipole current formula.
- **3.55** `lessons/13-transmission-lines-and-antennas/telegrapher_propagation.rlab:41` — Dead `n_step = 1200;` (function uses 780). Fix: delete or set to 780.
- **3.56** `lessons/13-transmission-lines-and-antennas/coax_impedance.rlab:12-13` — Garbled header derivation. Fix: "L' = μ₀ε₀/C'  ⇒  Z₀ = √(L'/C') = √(μ₀ε₀)/C'".
- **3.57** `lessons/13-transmission-lines-and-antennas/twin_wire_impedance.rlab:9` — "box edge sits ~5d from the wire pair" → box is 5d *wide* (edge ≈ 2d from nearest wire). Fix comment.
- **3.58** `notebooks/13-transmission-lines-and-antennas.md:199-214` — `run_tline` silently re-declares eleven constants. Fix: one comment ("rustlab functions see only their own scope — re-declare the line constants here") or pass as arguments.

### L14
- **3.59** `notebooks/14-capstone-device-simulation.md:22-28` — Table symbol y_sub vs code `y_top`; substrate interval should be (y_g, y_top] (code fills inclusive). Fix both.
- **3.60** `notebooks/14-capstone-device-simulation.md:5` — "The notebook at the end of the lesson explains…" → "the *From 2-D to 3-D* section at the end of this lesson".

### L15
- **3.61** `notebooks/15-lumped-capacitance.md:27` — Garbled sentence about gradient3's one-sided stencil. Fix: "inside a perfect conductor E = 0; any nonzero E that gradient3's one-sided stencil reports there is a discretisation artifact, not physics."
- **3.62** `notebooks/15-lumped-capacitance.md:173` — Comment "≈ 1.008" vs printed 1.00723. Fix: "≈ 1.007".
- **3.63** `notebooks/15-lumped-capacitance.md:121` — C₁₁ saturation explanation conflates Maxwell C₁₁ with mutual-convention c₁₀ (c₁₀ *rises* 81.94 → 89.45 pF/m while C₁₁ falls). Fix: "C₁₁ = c₁₀ + c₁₂ levels off because the coupling contribution c₁₂ vanishes while the cap-to-ground recovers as the neighbour stops shielding the ground plane."

### L16
- **3.64** `lessons/16-smith-chart/patch_antenna_smith.rlab:10,34` — "(series RLC sketch)" mislabels the **parallel** (anti-resonant) form R₀/(1+jQ(f/f₀−f₀/f)). Fix both comments: "parallel-RLC (anti-resonant) sketch".
- **3.65** `lessons/16-smith-chart/tline_transformation.rlab:18,66` — Stale loads header ("short, matched, …" vs actual [25, 100, 100j, 25−j50]) and hard-coded VSWR 4.0 for 25−j50 (true 4.27). Fix header; compute `vswrs = (1+abs(GL))./(1-abs(GL))` instead of hard-coding.
- **3.66** `notebooks/16-smith-chart.md:21-65,69-75,233` — Template drift: Bilinear Map lacks `### Theory` and packs two distinct examples under one H3; the line-translation display equation sits above its `### Theory`; the double-stub Theory defines t = tan(βd₁₂) and never uses it. Fix: add `### Theory`, split out `### Example — Constant-VSWR circles`, move the Γ(d) identity under Theory, delete or use t.
- **3.67** `lessons/16-smith-chart/smith_chart.rlab:6-7` — "constant-r circles run vertically, constant-x circles run horizontally" misdescribes the geometry. Fix: "constant-r circles nest toward Γ = +1 along the real axis; constant-x arcs meet them at right angles."

### L17
- **3.68** `notebooks/17-lumped-inductance.md` (whole file) — No notebook block contains `print()`, so `book/17` attests nothing (template requires the outputs table to reflect captured prints). Fix: add one small printing block per section (e.g. `print(L_num / L_ana)`, `print(max_rel_err)`, `print(Vr(4))`), re-render, and confirm the printed values match the hard-coded prose (agents verified the prose numbers are currently correct — if a print disagrees, trust the print and update the prose).
- **3.69** `notebooks/17-lumped-inductance.md:223-230,242` + `lessons/17-lumped-inductance/tunable_L_force.rlab` — State I₀ = 1 A (the mN values depend on it) and add one sentence that this example validates the FD-force machinery against a *circuit model* (the "machine-precision agreement" is by construction; the field-solve version is L15's `tunable_C_force` pattern).
- **3.70** `notebooks/17-lumped-inductance.md:207` — Wheeler's error vs exact Nagaoka is ≈ 0.2% here (K = 0.5255/0.6884 vs Wheeler 0.5263/0.6897), not "roughly 1%"; the 2.7% residual is dominated by the discrete 12-turn winding. Fix the parenthetical accordingly.
- **3.71** `notebooks/17-lumped-inductance.md:9,265` vs `lessons/17-lumped-inductance/mutual_inductance_coil_pair.rlab:11,97` — Inconsistent elliptic-validation tolerance (≲10⁻⁶ vs "<0.1%" vs "<1e-3"). Fix: run the script, quote the actual printed max relative error in all places.
- **3.72** `lessons/17-lumped-inductance/inductance_transformer.rlab:79-80` — Stale comments "# 24 primary turns"/"# 48 secondary turns" (code yields 96/192; notebook is right). Fix comments.
- **3.73** `notebooks/17-lumped-inductance.md:22` — Flux linkage written with ∮ (closed-surface flux of B ≡ 0). Fix: λ = ∫_S B·dA over the open surface spanning the loop.

---

## Phase 4 — Regenerate, verify, sync

1. **Run every touched script**: `make lesson-NN` for NN ∈ {03,04,05,08,10,11,12,13,14,15,16,17} — all must exit clean.
2. **Full re-render**: `make notebooks` — expect **0 errors** across all 17 notebooks. Then `make notebooks-check` must pass (idempotent second render).
3. **Review the `book/` diff lesson-by-lesson**: for L05, L10, L14, L15 (and L11/L17 if code changed) confirm the newly captured numbers/plots match the updated prose and Expected tables; everywhere else the book text should change only where the notebook prose changed.
4. **Sync `AGENTS.md`**: the L14 roadmap row "geometry → material map → FDTD → S₁₁ + gain pattern" oversells the shipped capstone (it produces neither an S₁₁ curve nor a gain pattern). Reword to "…FDTD → resonance spectrum (S₁₁ + gain mapped as the 3-D extension)". Check `dev/plans.md` for the same overstatement.
5. **Upstream notes: already filed** — `dev/rustlab/requests/lesson-review-findings-2026-07.md` (2026-07-04) consolidates all upstream items with checkboxes: `max(M1, M2)` doc contradiction, harmonic-mean doc misexplanation (mirror of item 2.6), `'` conjugating-transpose warning, fractional-index migration note, complex-literal parsing. Do not re-file; do NOT edit `../rustlab`.
6. **Commit** source + book together per the phase/lesson granularity above. Do not force-push.

### Acceptance checklist (all verified 2026-07-05)
- [x] `rustlab run lessons/05-poisson-laplace-bvp/dielectric_slab.rlab` exits clean (values match previously committed book — solve is x-independent)
- [x] `make notebooks` reports 0 errors; `make notebooks-check` passes (render verified deterministic; 16 orphaned content-hashed plot files pruned)
- [x] `lessons/10-fdfd-frequency-domain/fdfd_2d_tmz.rlab` prints forward > backward probe (measured 1.20878 vs 0.31804 — exact mirror of the buggy values; forward/back ≈ 3.8, Mie-consistent)
- [x] L14 notebook contains no "4.12 GHz", "high-Q box mode", or bin-quantisation claims (grep = 0); Ex. 1–2 re-scoped and consistent with the moved probe (peak 3.6657 GHz probe-independent, amplitude 52.5→4.4)
- [x] L13 notebook/script no longer claim the FFT S-parameter estimate is substantially biased (grep = 0; measured FFT 0.12%/0.015% vs time-domain 0.38%/0.10%)
- [x] L04 Exercise 4 no longer demands −1/−2 slopes from the disk-area sweep (grep = 0; rewritten around measured 83× ratio)
- [x] No raw `|` or `\|` remains inside `$...$` in any notebook table (per-lesson agent verification; known offenders in L08/09/10/11/13 all fixed)
- [x] `book/17-lumped-inductance.md` now contains 6 captured ```text blocks (was 0)
- [x] AGENTS.md L14 row updated + dev/plans.md L14 shipped-scope note added (upstream request file `dev/rustlab/requests/lesson-review-findings-2026-07.md` fully **Landed** 2026-07-05)
