# Lesson Review Findings — 2026-07-09

Third full-curriculum pass (after the 2026-07-05 fix pass on branch `lesson-fixes-2026-07`), run by six
parallel review agents. Scope per the review request: (1) content correctness + simplicity,
(2) rustlab bugs, (3) rustlab improvement opportunities. All **73 lesson scripts were re-run — 73/73 pass**
(exit clean, no panics), and every Expected-Numerical-Outputs table was re-diffed against live prints.

Severity legend: **HIGH** = published claim/figure is wrong or an exercise is impossible as posed;
**MED** = misleading claim, stale number, or contradiction; **LOW** = clarity, stale comment, polish.

---

## Resolution status — 2026-07-11

The upstream asks from this pass landed in rustlab:

- **C1 (fft)** — landed *stronger than asked* in rustlab PR #28: `fft(x)` is now
  **length-preserving** (no silent pad at all; Bluestein path for non-power-of-two
  lengths), plus explicit `fft(x, n)` / `ifft(X, n)`; `ifft` accepts any length.
  The A1/L11 axis idiom `fs = (0:Nw-1)/(Nw*dt)` with `Nw = length(trace)` is now
  **correct as written** — no lesson code change needed.
- **C2–C7 + B3 + B4** — landed in rustlab PR #29: `ellipke(m)` (AGM, m = k²),
  `pin_dirichlet(A, b, mask_or_ks, vals) → [A, b]`, quiver 95th-percentile
  auto-scale + per-arrow clamp + `"normalized"` mode (decimation = stride
  indexing, documented), per-column `trapz(M)`/`trapz(x, M)`, `tic`/`toc`
  (bare-word forms work), deferred savefig-aware terminal warnings,
  `Tensor3(:)` flatten fix, and `rustlab run` exiting 1 on failure.
  ⚠ B4's fix makes D2 (`Makefile` `lesson-%` `|| true`) worth revisiting — CI
  can now gate on script failures.
- **A1** — L14 re-run against the fixed rustlab: the dominant peak prints
  **2.4438 GHz** (the 2.5 GHz drive carrier, within one bin — as §A1 predicted).
  `notebooks/14` + `book/14` prose and the Expected-Outputs row corrected, with a
  historical note on the old 3.6657 GHz figure. L11's printed values were already
  correct; its transmission SVG regenerates correctly on the next `make lesson-11`.
- **Housekeeping** — `smith-chart.md` → Landed (API-differs note),
  `animation-export.md` GIF wording refreshed, `laplacian-eps-3d.md` filed and
  L15's two phantom citations now point at it.
- **2026-07-11 fix pass (six parallel agents): everything below is now resolved.**
  - **A2** — biot_savart_loop NaN-masks cells within 1.5 cells of the wire (dipole
    pattern now visible: 1663 arrows vs 1); two-wires quiver subsampled 5× (SVG
    4.5 MB → 183 KB); vector_potential_2d synced to the snapped-geometry reference.
  - **A3** — L02/L03 overlays restructured into guaranteed-correct separate
    heatmap + explicit-level contour figures (L03 uses |V| clipped at 8 kV plus
    ±{0.5,1,2,4,8} kV lobes via antisymmetry); SVG-verified against analytic lobe
    extents. B1 itself is **no longer reproducible** post-#29 — including the exact
    51×51 case behind the broken committed figure.
  - **A4** — L12 narrative rewritten around the resolved spectrum (4.915211 GHz,
    stable for 4–60 requested modes, zero spread over 5 trials); cluster caution
    reframed as explicit Lanczos folklore.
  - **A5** — L10 Ex. 1 rewritten around the measured quantization floor
    (0.16245/0.0094642/0.010659; snapped-thickness transfer matrix reproduces it).
  - **A1 follow-on (L14 Ex. 1–2)** — salvaged via the ring-down route, verified:
    post-drive FFT shows a patch-dependent mode (4.10/3.92/3.55 GHz at
    50 mm/30 mm/no-patch); background subtraction demonstrably fails (no-patch box
    rings ~3000× harder); root cause identified — 2-D TMz supports no TEM-like
    patch mode; the sub-patch vertical half-wave scales 1/√εr (16.8/11.8/8.1 GHz
    measured at εr = 2.2/4.4/9.8 vs 16.9/11.9/8.0 predicted). Exercises rewritten
    around these numbers.
  - **Section E** — all per-lesson items applied across L01–L17.
  - **Adoption** — ellipke (3× L17), pin_dirichlet (L05 keeps one teaching
    walkthrough; L05/L07/L13/L15/L17 adopted — ~25 sites, net −140 lines in
    L15–17 alone), per-column trapz (L01), two-arg max (L11/L13), tic/toc (L11
    Ex. 1), Tensor3(:) direct flatten (L15), `.'` sweep, zeros() for the loglog
    workaround. All adoptions verified bit-/byte-identical output.
  - **D1/D2** — lesson GIFs untracked + `lessons/*/*.gif` gitignored; Makefile
    `lesson-%` is fail-fast (no more `|| true`), `make clean` covers GIFs.
  - **B/C leftovers filed upstream** — `dev/rustlab/requests/lesson-review-findings-2026-07-09.md`
    (contour signedness ✓confirmed live, loglog shape ✓confirmed, docs batch,
    polyfit/polyval, fractional masks), plus three NEW bugs found while fixing:
    subplot+imagesc renders only one panel; plot() series silently dropped under
    quiver (shipped stokes_loop.svg had no loop — fixed lesson-side with a
    contour-drawn loop); masked assignment `M(mask) = scalar` rejected.
  - **Verification** — all 73 scripts exit 0 under the fail-fast runner; book
    re-rendered; 17 orphaned content-hashed plots pruned; every Expected-Outputs
    table diffed against live prints.

---

## A. Headline findings (fix before merging/publishing)

### A1. HIGH — L14 capstone: the headline "3.6657 GHz" is the 2.5 GHz feed carrier, mislabeled by an FFT-axis bug

`lessons/14-capstone-device-simulation/patch_antenna.rlab:150-154,165`

rustlab's `fft` zero-pads to the next power of two (documented, `../rustlab/docs/functions.md:592-596`):
701 samples → 1024 bins. The script builds the frequency axis from the *unpadded* length
(`Nw = length(trace) = 701`), stretching every reported frequency by 1024/701 = 1.4608×.
Verified: rerunning the identical FDTD with the corrected axis (`Npad = length(Sp)`) puts the dominant
peak at **2.509 GHz** (amplitude identical, 4.4197) — i.e. the drive carrier, exactly as physics demands
for a source-dominated driven window. Everything anchored on 3.6657 GHz collapses:

- `notebooks/14-capstone-device-simulation.md:110` — the "matches neither 1.43 GHz nor 4.05 GHz" mystery paragraph (the corrected peak matches the feed; there is no mystery);
- `:142` Expected-table row; `:106` block-walkthrough step 7; `:44` "peaks at the frequencies the box responds to most strongly" (it peaks where the *source spectrum* peaks);
- Exercises 3/5 (`:151,153`) "dominant peak/resonance" framing.
- **Note:** the 2026-07-05 fix pass (dev/lesson-review-fixes.md items 1.3–1.5) took 3.6657 GHz as measured ground truth; the earlier 6000-step "3.6914 GHz" had the same wrong axis. The correct idiom is already in-repo: `lessons/13-.../s_parameters_tline.rlab` (post-padding `N_fft = length(F_inc)`).

Follow-on (HIGH): even with the corrected axis, **Exercises 1–2 remain unanswerable as posed** — full FDTD
reruns at 50 mm and 30 mm patch lengths show *no* local maximum above 1% of the dominant peak in
0.5–8 GHz, and the dominant-peak amplitude differs by only ~1e-5 relative between the two patch lengths.
The probe (5 cells from the driven column, driven the whole window) essentially records the source.
Plausible salvage (unverified): no-patch background subtraction and/or a long post-drive ring-down window.

Same bug class, second live instance (MED): `lessons/11-fdtd-simulation/fdtd_dispersive.rlab:133-135,143` —
transmission-spectrum axis built from `Nw = 1501` while `fft` returns 2048 bins; every plotted feature is
stretched 1.36× (a 3 GHz test tone plots at 4.035 GHz), so `fdtd_dispersive_transmission.svg` shows the
plasma edge ~36% above f_p while the title says "fp = 3 GHz". Printed values unaffected.

### A2. HIGH — L06: the Biot–Savart meridional quiver figure is broken in the published book

`notebooks/06-magnetostatics.md:79-86` + `lessons/06-magnetostatics/biot_savart_loop.rlab:57-61`

The 41-point grid over ±0.10 m places samples exactly at (±0.05, 0) — *on the wire*. The φ=0 source
segment lands 1.4e-17 m from grid node xs(31) → |B| = 1.63e24 T there. Quiver auto-scales to the longest
arrow, so every physical arrow (~1e-5 T) shrinks to ~1e-29 of a cell. The shipped
`loop_quiver.svg` **and** the committed `book/plots/06-magnetostatics/plot-1-4d9237b9.svg` show exactly
one arrow on an empty plot, while the prose says "arrows trace the familiar dipole-like pattern".
Fix: NaN-mask cells within ~1 cell of the wire (quiver skips NaN) or offset the grid (Nm=40 or ±0.099 m),
then re-render. Printed numbers are unaffected.

Related (MED): `notebooks/06-magnetostatics.md:296-300` + `vector_potential_2d.rlab:50-54` — the full-grid
150×150 quiver (22,500 arrows, 4.5 MB SVG) renders as near-empty noise for the same auto-scale reason
(near-wire cells ~25× mid-field). Subsample every ~5th cell, normalize lengths, or use `streamplot`.

### A3. HIGH — L02/L03: two committed overlay figures are broken by a rustlab `imagesc`+`contour` frame mismatch

- `book/plots/02-electrostatics-coulomb/plot-4-eb513fd3.svg` (notebook `:151-158`) — axis ticks + the 8
  contour lines occupy px 90–469 while the imagesc heatmap spans px 90–816 on its own index pitch:
  contours sit ~1.9× compressed left of the features they belong to.
- `book/plots/03-gauss-law-and-potential/plot-3-afbf5e76.svg` (notebook `:147-152`) — broken three ways:
  (a) same frame mismatch; (b) heatmap shows **|V|** (colorbar 0…4.49e4 for a ±44937 V field — sign lost);
  (c) 12 auto contour levels computed on |V| all land within r ≲ 7 mm of the singularity — the whole
  "equipotential" overlay is a 46×30 px knot at the center. The prose (`:129`) promises closed lobes either
  side of the V=0 bisector, which the figure cannot show. Even after an upstream fix, linear auto-levels of
  a 1/r² potential will cluster — pass explicit levels (e.g. ±{0.5, 1, 2, 4, 8} kV).

Root cause is upstream (see B1), but the *published book* figures are wrong today; the lesson-side fix is to
choose level sets / plotting idioms that survive, and re-render once B1 lands.

### A4. HIGH — L12: the "Lanczos unresolved-cluster" narrative is no longer reproducible

`notebooks/12-waveguides-and-radiation.md:128` + `:298` + `cavity_resonances.rlab:40-45`

The section's central caveat ("mode 4 prints 4.949 GHz, a Lanczos cluster artifact; over-requesting
`eigs(L_c, 60)` fixes it to 4.915") is dead: the shipped script prints **4.915211 GHz** (0.12% below TM31
analytic), deterministic across 5 trials, and *unchanged* for 60/20/8/6/4 requested modes. The committed
`book/12` shows captured output 4.91521 directly above prose claiming 4.949 — a published self-contradiction.
Likely cause: `eigs`'s Krylov-dimension floor `max(6n+10, 40)` always resolves this cluster now.
Also (MED): the general "request 4× more modes than needed — the curriculum-grade workaround Lanczos
demands" advice (`:28,46` + `waveguide_modes.rlab:33-37`) is undemonstrable on these problems —
`eigs(L, 6, "sm")` returns bit-identical cutoffs to `eigs(L, 30, "sm")`. Reframe as general lore or drop.

### A5. HIGH — L10: Exercise 1 is unpassable as posed

`notebooks/10-fdfd-frequency-domain.md:480` — "verify the AR ripple drops as Δx²" fails because the ripple
is dominated by AR-layer *thickness quantization* (`round(t_AR/dx)`, with t_AR/dx = cpl/5.657 never an
integer), not truncation error. Measured with an exact replica of the shipped solver: ripple at
λ/20, λ/40, λ/80 = 0.1624, 0.00946, **0.01066** — non-monotonic, λ/80 worse than λ/40 (Δx² predicts
0.038/0.0095/0.0024). The "peak narrows toward an ideal Lorentzian" sub-claim is also off (a single-layer
AR maximum is a broad quadratic peak, not a Lorentzian). Fix: snap t_AR to integer cells per resolution and
compare against the snapped design's transfer matrix, or reword around the quantization floor.

---

## B. rustlab bugs (new, none currently filed in dev/rustlab/requests/)

### B1. `hold on` + `imagesc` + `contour` overlay: mismatched coordinate frames (conditional)

Two committed book figures affected (A3). Minimal repro (L01–03 agent): off-center Gaussian bump at
(1, 0.5) → contour ring at tick position (1, 0.5), heatmap bright cells at a different pixel location in
both axes; ticks+contour adopt the data frame while imagesc paints cells at fixed index pitch from the
plot's left edge (heatmap px 90–816 vs tick frame 90–469 in L02 plot-4). **The bug is conditional**: the
L07–09 agent's independent scratch test (asymmetric bump, eddy-plate-style grid) found the same overlay
*aligned* to ~4 px. Both repros should go upstream so the trigger (grid shape / extent-vs-index-pitch) can
be triaged. Note `functions.md:2137` explicitly advertises this overlay pattern, and the Landed
`contour-plots.md` request's coordinate-aware `imagesc(X, Y, M)` variant was never shipped (only
index-based imagesc exists) — that gap is likely the root cause.

### B2. `contour` contours |Z|, not Z; negative levels silently draw nothing

`contour(X,Y,Z,[1.5])` on the plane Z=X draws mirrored lines at x=±1.5; `contour(X,Y,Z,[-1.0])` draws
nothing, silently. functions.md describes contour as levels of "a 2-D scalar field" with no magnitude
mention, and negative levels are legal per the docs. (`imagesc`'s magnitude behavior *is* documented but is
a sign-destroying divergence from MATLAB convention worth an upstream note — it is also ingredient (b) of
the broken L03 figure.)

### B3. `Tensor3(:)` flatten panics the interpreter

`T = reshape(1:24,2,3,4); v = T(:);` → `thread 'main' panicked … eval/mod.rs:1781:34: internal error:
entered unreachable code` (rustlab 0.3.6). Should be a clean error (or just work). Workarounds already live
in `lessons/15-lumped-capacitance/lumped_C_parallel_plate.rlab:121-122` and `MIM_capacitor_3d.rlab:91`.

### B4. `rustlab run` exits 0 on script failure

Both `error("…")` and runtime errors print `error: line N: …` but return exit code 0, so CI/Make cannot
gate on failures. (Compounded repo-side by `Makefile`'s `lesson-%` target ending in `|| true` — even with an
upstream fix, `make lesson-NN` can never fail; both ends need a change.)

### B5. `loglog`/`semilogx`/`semilogy` reject a 1×N matrix that `plot` accepts

"type error: … y must be a vector, got matrix" — verified side-by-side on identical input. This
inconsistency is what forced the `linspace(0,0,M_r)` workaround at `notebooks/05-poisson-laplace-bvp.md:456-459`.

### B6. Cosmetics / docs

- SVG tick label renders **-0.0**; `print` outputs `-0` for negative zero (captured in `book/03:208`).
- `set_default_axis` and `axis("xy")` are implemented + documented in functions.md but absent from
  quickref.md, whose header claims "if a function is not listed here, it is not implemented".
- Tensor3 first-axis slice `T(i,:,:)` **works** (returns Matrix) but is undocumented — quickref documents
  only the page slice `A(:,:,k)`. Unaware of it, two L15 scripts hand-roll double loops
  (`lumped_C_parallel_plate.rlab:183-188`, `MIM_capacitor_3d.rlab:138-143`).

---

## C. rustlab improvement candidates (checked against functions.md and existing requests)

1. **`fft(x, n)` explicit-length form + loud axis warning** — the silent zero-pad-to-power-of-2 diverges
   from MATLAB/NumPy length-preserving `fft`, and it caused two live bugs in this curriculum (A1, L11) that
   survived two prior review passes. Docs should pair every `fft` example with
   `fftfreq(length(X), sr)` / `length(fft(x))`. Strongest single upstream ask from this pass.
2. **`ellipke(m)` builtin** — a 15-line AGM implementation is duplicated verbatim in three L17 scripts
   (`mutual_inductance_coil_pair.rlab:41-57`, `inductance_transformer.rlab:30-40`, `finite_solenoid.rlab:22-32`).
3. **Dirichlet row-pin helper** — the ~14-line masked `pin`/`pin_cell` sparse row-pinning idiom recurs
   ~10× across L05(×3 notebook blocks + 3 scripts)/L06/L07/L13/L15(×5)/L17. Candidate:
   `pin_dirichlet(A, b, mask_or_ks, vals)` or a `mask` argument on the `laplacian_*` builders.
4. **`quiver` robustness** — auto-scale keys on the global max with no outlier robustness, no normalize
   mode, no decimation arg (functions.md:2169-2192); root enabler of A2. Percentile-based scaling, a
   `"normalized"` mode, or a density/subsample option would prevent silently-blank field plots.
5. **Matrix (per-column) `trapz`** — `trapz(x, M)` rejects matrices; forces a per-row loop in L01
   (`stokes_demo.rlab:48`, notebook `:254-258`) and complicates L02 Exercise 5 ("use trapz twice").
6. **`tic`/`toc` wall-clock timing** — L11 Exercise 1 says "time both versions" but rustlab has only
   `profile()` for named functions; either point the exercise at `profile()`/shell `time` or add tic/toc.
7. **savefig-aware suppression of terminal-render warnings** — "quiver/contour are not rendered to the
   terminal…" is emitted on every scripted non-TTY run even when `savefig` is the next statement; stderr
   noise in at least nine scripts across L01–03/L07.
8. **Fractional-coverage mask option** (`disk_mask(..., K)` → α map) — the K×K subgrid double loop in L04's
   conformal section exists only because mask builtins are binary (partly pedagogical here, so low).
9. **`polyfit`/`polyval`** — L05 hand-rolls a least-squares slope (`corner_singularity.rlab:86-92`) and says
   so in prose ("Hand-rolled least-squares slope").
10. **Docs: bare elementwise broadcasting** — `.*`/`+` broadcast row and column vectors against matrices on
    0.3.6 (verified both orientations) but implicit expansion is documented only for `min`/`max`; L11 carries
    9 `repmat` boilerplate calls (and prose claiming `repmat` is required) that could go once documented.

Housekeeping in `dev/rustlab/requests/`:
- `smith-chart.md` still says **Filed**, but the capability shipped (`smith`/`marker`/`smith_circle` in
  quickref; all seven L16 scripts use them and hand-roll nothing) — mark **Landed** (API differs from the
  proposed `smith_chart()`; note that).
- `animation-export.md` still says GIF export "deferred" with an ffmpeg workaround; `saveanim("*.gif")`
  works and is documented (functions.md:2301). L09's Background (`notebooks/09:15`) links to this stale file.
- `notebooks/15-lumped-capacitance.md:161,278` claims an "open upstream request" for `laplacian_eps_3d` —
  no such request exists anywhere; file it or reword.

---

## D. Repo hygiene

1. **`.gitignore` misses `lessons/*/*.gif`** (`.gitignore:4-5` covers svg/html/png only), so the five lesson
   GIFs are *tracked* and any rerun of a GIF-producing script dirties the tree with a nondeterministic
   binary diff. This pass left `lessons/09-em-waves/*.gif` (3) and `lessons/11-fdtd-simulation/*.gif` (2)
   modified — restore with `git restore`, then either gitignore them or accept churn.
2. **`Makefile` `lesson-%` target ends in `|| true`** — combined with B4, lesson runs can never fail CI.

---

## E. Per-lesson findings (everything not already in A–D)

### L01 — vector-calculus-and-fields — clean
- [LOW] `notebooks/01:270` — "See `../rustlab/docs/quickref.md`" is a dev-machine relative path, broken from
  the rendered book / GitHub.

### L02 — electrostatics-coulomb
- [MED] `notebooks/02:34` — "the singular cell ends up with a huge but finite value that quiver/imagesc clip
  visually" is false: at a charge's own cell the numerator (r−r₀) is zero, so E = **exactly 0** (verified;
  the *neighboring* cells, 2.25e6 V/m, set the scale). Same error at `:92` ("linear heatmap dominated by the
  singular pixel" — that pixel is 0; log10 there is −Inf, which imagesc clamps).
- [MED, stale] `notebooks/02:72-74` + `point_charges.rlab:41-42` — the "Matrix `./` stores complex
  internally with ~1e-11 imag noise; wrap prints with `real()`" story is dead on 0.3.6: imag part is
  exactly 0 on the lesson's own pipeline (upstream em_requests §4 shipped). The `real()` wrappers here and
  in L03 (`potential_dipole.rlab:43-44`, notebook `03:168-169`) are dead weight teaching a stale model.
- [LOW] `dipole_field.rlab:31` — comment "≈ exact value at y ≈ 0.01345 m" stale: ys(40) = 0.02406 m.
- [LOW] `notebooks/02:149` — "a dark ring along the perpendicular bisector": the low-|E| locus is a straight
  band, not a ring.

### L03 — gauss-law-and-potential
- (Figure findings in A3.) All numbers verified correct; all 5 exercises answerable.

### L04 — geometry-and-material-maps
- [MED] `conformal_disk.rlab:4-7` — script header still teaches the staircase-vs-conformal "O(h²) instead of
  O(h)" convergence story the notebook's corrected §Conformal (`:301`) and Ex. 4 (`:350`) explicitly disavow
  for the disk-area metric (fix 1.8 rewrote only the notebook).
- [LOW] `conformal_disk.rlab:55,58` — stale comments: `≈ 3.1414` vs printed 3.141668 (notebook says 3.1417);
  `≈ 1e-5` vs actual 2.39e-5.
- [LOW] `shape_rasterization.rlab:48-50` — `# ≈ 1.70` vs printed 1.6859 (0.83% undershoot, 4× the disk's).
- [LOW] `notebooks/04:179` — the "~2% sliver error" attribution is off: 2.04% belongs to `r_only` (bulk);
  the actual sliver `d_only` errs 1.61%, `both` −0.68%.
- [LOW] `notebooks/04:348` (Ex. 2) — "disk area minus triangle area" holds only for a triangle fully inside
  the disk; a typical Pac-Man mouth extends past the rim (say "minus the overlap area" or inscribe it).

### L05 — poisson-laplace-bvp
- [LOW] `notebooks/05:456-459` — even without the upstream B5 fix, the workaround can be
  `Es = zeros(M_r)` (already a true vector accepted by loglog); the `linspace(0,0,M_r)` + two-line comment
  can go. Same zero-vector idiom appears in L12 (`vswr_standing_wave.rlab:43`, `patch_antenna.rlab:95`,
  notebook `12:211-214` which claims a limitation that doesn't exist — `zeros(n)`+loop+`polar` runs clean).
- [LOW] `iterative_solvers.rlab:75` — "SOR @ 100 iters — already ≪ GS@1000" false as written: both print
  6.4306e-4 (the h² floor). Should read "matches GS@1000's floored error in 10× fewer sweeps".
- [LOW] `notebooks/05:68` + `laplace_2d.rlab:31` — `b_bc(:)'` uses the conjugating `'` for RHS shaping, the
  exact idiom behind the old L10 bug (harmless on real data, bad model). Also `J(:)'` in L06 and
  `notebooks/10:90` + `fdfd_pml_demo.rlab:40`. Use `.'` uniformly.
- [LOW, unverified] `notebooks/05:528` (Ex. 5) — β = 5π/4, 7π/4 wedges need 45° edges that exist only as
  staircase on this grid; each step is locally a 270° singular micro-corner, so the weak −1/5 fit may be
  noise-dominated. Add a hint (polygon_mask + finer grid; expect noisier fits).

### L06 — magnetostatics (see A2 for the two figure findings)
- [MED] `vector_potential_2d.rlab:8,56-63` — script not updated to the notebook's snapped-geometry
  reference (fix 3.20 hit only the notebook): script uses nominal d = 0.04 m → analytic −2.6966e-6 /
  "~12%", notebook/book use snapped d_act = 0.0417 m → −2.7798e-6 / "~14.5%". Two different published
  "analytic" values for the same comparison.
- [LOW] `notebooks/06:103` — "100 segments are enough" undersells: on-axis the segment sum is *exact for
  any N_seg* by symmetry (same argument as the L02 ring fix).
- [LOW] `notebooks/06:393-394,433` + `iron_core_shielding.rlab:11,79` — the "~5% at r = 7 cm" agreement
  uses the nominal-r reference while the sampled cell sits at snapped 7.11 cm; snap-consistent value is
  ~6.6%, mildly at odds with the lesson's own "read geometry off the grid" advice (the ~19% figure is
  robust either way).

### L07 — faraday-induction
- [LOW] `notebooks/07:100,103` — unused `rzs`/`dlz` allocations in the Biot–Savart block (the standalone
  script correctly omits them).
- [LOW] `notebooks/07:293` (Ex. 5) — P = (1/σ)∫|J|²dA omits plate thickness: with J in A/m² this is W/m;
  should be P = (t/σ)∫|J|²dA (cut-vs-uncut ratio unaffected).
- [LOW] `eddy_current_plate.rlab:3` — "grounded box" is imported electrostatics language; ψ is a stream
  function, the exterior ψ=0 pinning is not a conductor.
- [LOW] `eddy_current_plate.rlab:59-60` (notebook `:229-230`) — overlay renders in ij orientation (no
  `set_default_axis("xy")` unlike sibling lessons); self-consistent here but a fragile pattern to copy.

### L08 — maxwell-equations
- [MED] `notebooks/08:328` (Ex. 5) — as posed, disproves itself: E_y(x,y) = E0·cos(kx·x + ky·y) with
  in-plane k̂ is **not** transverse (E·k̂ = (ky/k)E_y ≠ 0, ∇·E ≠ 0). Use out-of-plane E_z (then B = k̂×E/c
  in-plane) or polarization (−ky, kx)/k.
- [LOW] `maxwell_consistency.rlab:10` — header sign slip: −(curl B)_y = **+**∂Bz/∂x, not −; code is correct.
- [LOW] `maxwell_consistency.rlab:60` — "peaks equal up to ω/c" → should be **c** (= ω/k).
- [LOW] `charge_conservation.rlab:33` — `# 0.886 pF` vs computed 0.885 pF.

### L09 — em-waves
- [MED] `notebooks/09:189-238` + `polarization.rlab:46-113` — no `axis("equal")` on the polarization-loci
  subplots or RCP-tip animation: identical ±1.2 ranges render 789×382 px, so "unit circles" are squashed
  ~2.1:1 and the "2:1 ellipse" reads ~4:1 — visually contradicting the text at `:214` and erasing the
  circle-vs-ellipse distinction the section teaches. `axis("equal")` per subplot verified to work in the
  0.3.6 SVG backend (379×382). [Unverified whether it carries through `frame()`/`saveanim` GIF frames.]
- [LOW] `notebooks/09:265,283-285` + `standing_wave.rlab:38-42` — the "numerical proof E(0,t)=0" multiplies
  by sin(0) — zero by construction; sum E_inc + E_refl at x=0 instead.
- [LOW] `notebooks/09:357` (Ex. 1) — "slope equals c to within the grid spacing Δx" compares velocity to
  length; say "to within the resolution set by Δx".
- [LOW] `notebooks/09:360` (Ex. 4) — "Phase mismatch standing wave" misnames a magnitude effect (Γ = −0.7
  keeps the PEC's 180° phase; only |Γ| < 1).
- [LOW] `notebooks/09:288` + `standing_wave.rlab:45` — "within (0, T/4)" excludes an endpoint that is used.
- [LOW] `notebooks/09:15` — Background links the stale `animation-export.md` (see C housekeeping).
- [LOW] `notebooks/09:123` + `plane_wave.rlab:71` — variable `Bz` actually holds c·B_z; rename or comment.

### L10 — fdfd-frequency-domain (see A5 for Ex. 1)
- [MED] `notebooks/10:34` — "SC-PML … makes the matrix complex symmetric (Aᵀ = A)" is false for this
  assembly: verified `nnz(A − transpose(A))` = 1536 (max asymmetric entry 8.4%) for the lesson's own
  `fdfd_tmz_pml_2d`. The 1/s_E row scaling breaks symmetry (a diagonal similarity by s_E restores it);
  lossy ε alone preserves it. Drop or qualify the claim ("spsolve routes to complex LU" stays true).
- [MED] `notebooks/10:483` (Ex. 4) — Q-from-FWHM fit impossible from the shipped 25 MHz-step sweep
  (FWHM ≈ 12.5 MHz → 1–2 samples on the peak); add a densify hint (`linspace(2.45e9, 2.55e9, 101)`).
- [LOW] `notebooks/10:58,62` (mirrored `lessons/_shared/em.rlab:18-20`) — co-located-vs-face-centred PML
  gap understated: measured ~630× (−47 dB vs −103 dB) at λ/12/npml=18, not "one to two orders of magnitude";
  "~80 dB" should be ~103–108 dB. Direction right, numbers not.
- [LOW] `notebooks/10:357` + `fdfd_resonator.rlab:63-65` — "parmap functions don't capture the surrounding
  workspace" overstates: snapshot-capturing lambdas work (verified bit-identical, avoids rebuilding the
  Laplacian 121×). Keep the explicit function for pedagogy, add a parenthetical.
- [LOW] `lessons/_shared/em.rlab:57-63` — `(v+abs(v))/2` clip predates the fixed `max(v, 0)`; simplify when
  next touched (doc item already Landed upstream).
- [LOW, informational] `lessons/_shared/em.rlab:139` (and `fdfd_1d_layers.rlab:93` solve_1d) — outer-wall
  boundary is effectively zero-Neumann (missing neighbour dropped from off-diagonal *and* diagonal), not the
  PEC a reader would assume behind the PML; harmless at −100 dB, worth one comment.

### L11 — fdtd-simulation (see A1 for the dispersive-axis bug)
- [LOW] `fdtd_tfsf_validation.rlab:38-41` — comment credits the "magic time step (S=1)" then sets
  S = 1/√2; the cancellation comes from the auxiliary 1-D grid (notebook explains it correctly).
- [LOW] `fdtd_tfsf_validation.rlab:168-174` — plot legend/title still say "analytic incident"; the reference
  is `Ez_aux` (fix 2.14 renamed the notebook + comments but missed the labels, which now contradict
  the adjacent comment at 149-153).
- [LOW] `fdtd_tfsf_validation.rlab:77-88` — aux 1-D grid has no ABC (hard source + implicit PEC): after
  ~step 130 of 600 the "incident" is a pulse bouncing in an aux cavity. Shipped measurements all remain
  valid; add one comment so Ex. 3 extenders don't get periodic re-illumination.
- [LOW] `notebooks/11:385` (Ex. 3) — implies the +x aux-grid TF/SF generalises to arbitrary angles; oblique
  needs speed-matched projection (Taflove ch. 5). Scope to 0°/90° or hint at the analytic-injection tradeoff.
- [LOW] `notebooks/11:227` — "below ω_p = 3 GHz" conflates ω and f (f_p = 3 GHz).
- [LOW] `notebooks/11:111,373` — the 0.335 reflected-ratio row is printed by nothing; add a `print()`
  (independently verified correct: 0.33523).
- [LOW] `fdtd_dispersive.rlab:127` — `%` comment in a `.rlab` (repo convention is `#`).

### L12 — waveguides-and-radiation (see A4)
- [MED] `notebooks/12:311` (Ex. 4) — "identify the resonance peak near L = 0.48λ" in an R_rad(L) sweep is
  unanswerable: input-referred R_rad is monotonic through 0.48λ (64.9/73.1/82.2 Ω at 0.48/0.50/0.52λ); the
  ~0.48λ resonance is a *reactance zero*, invisible in R_rad. Bonus: the prescribed sweep ends at L = 2λ
  where sin²(kL/2) = 0 → R prints 4.3e33.
- [LOW] `notebooks/12:128` — "within 0.07%" vs printed rel errs up to 0.0836%; say ≈0.09% or "within 0.1%".
- [LOW] `nf2ff_transform.rlab:21-22` — stale header claiming L14 applies this transform (the shipped
  capstone has no NF→FF call; fix 2.19 softened the notebook but missed this header).
- [LOW] `nf2ff_transform.rlab:84-86` — `hertzian_xyz` cites Balanis 4-26 but all three prefactors carry k¹
  where Balanis has k² (uniform 1/k on E and H together — patterns and printed numbers unaffected, absolute
  fields wrong if reused).
- [LOW] `hertzian_dipole.rlab:12-14,59-66` — header promises a numerical Poynting check but `P_rad_num`
  uses the closed-form 8π/3, not the trapz value computed at line 49 (the printed 5.06e-16 is an algebraic
  identity); also line 40 labels `abs(sinθ)` as `|F(θ)|²`.
- [LOW] `waveguide_modes.rlab:46-57,74-85` — first loop prints unlabeled quadruples; summary header
  advertises 4 columns but its loop prints unlabeled triples; two loops print overlapping data.

### L13 — transmission-lines-and-antennas
- [MED] `notebooks/13:500` (Ex. 3) — lossy-line hint "modify the V update by −R′Δt·I" is wrong physics and
  wrong units (R′ belongs in the *I* update: I ← I·(1 − R′Δt/L′) − (Δt/L′dz)ΔV; the V slot is shunt G′V;
  R′Δt·I has units V·s/m).
- [LOW] `telegrapher_propagation.rlab:138-140` — stale comments "~ source peak (Γ = +1)" / "~ peak/3" vs
  printed 0.527/0.1767 (fix 2.22 corrected the notebook, missed the script).
- [LOW] `telegrapher_propagation.rlab:48-52` — termination comment describes an implementation
  (one-way V-copy / I=0) the code doesn't use (load-current trick with Z_L = 50 / 1e12).
- [LOW] `s_parameters_tline.rlab:45-48` — "reproduces |Γ| … to machine precision" contradicts the measured
  0.12% and the script's own later "~0.1%" comment.
- [LOW] `vswr_standing_wave.rlab:67` + `notebooks/13:326` — hand-rolled `(a+b+|a−b|)/2` elementwise max;
  two-arg `max(V_env, av)` is now a shipped builtin (stale workaround, no upstream ask needed).

### L14 — capstone (see A1)
- [LOW] `patch_antenna.rlab:15` — header "5. Probe FFT → S_11 → Lesson 13" overstates (no S₁₁ computed;
  the notebook's table correctly says "probe-trace FFT (informal)").

### L15 — lumped-capacitance
- [MED] `notebooks/15:270` — Expected-table row "8 µm × 8 µm / 500 nm ≈ 3.8 fF" is stale: script prints
  **4.94 fF** (3.8 is the pre-fix dz = t_ox/3 value; the example block at `:187` was updated, table missed;
  baked into `book/15:311` too).
- [MED] `notebooks/15:275` (Ex. 1) — "confirm both methods tighten onto the Kirchhoff curve" contradicts
  the lesson's corrected framing (`:39,77`): the strip curve is a *lower bound* (≈1.28); refinement
  converges onto the true square-plate ≈1.56, *above* it. Also uses the "Kirchhoff" name dropped elsewhere.
- [LOW] `notebooks/15:177` (and `:35`) — "exactly the printed 3/4 = 0.760": 3/4 = 0.750; the plate term is
  exactly 3/4 and the extra ~1% is fringing — drop "exactly" from the printed value.
- [LOW] `lumped_C_parallel_plate.rlab:24-27,31,172` — header attributes the energy-method position to wall
  clipping while the notebook teaches the half-cell gap-deficit mechanism; legend still says "Kirchhoff
  (analytic)" (notebook plot now says "strip 2-D estimate (lower bound)"; also scripts-table `:250`);
  header says "printed in pF" but prints are fF.
- [LOW] `notebooks/15:264` — "1.41 … near the true ≈ 1.56" oversells (1.409 is closer to 1.28); "above the
  strip estimate" is the defensible claim (same phrase in script header `:27`).

### L16 — smith-chart — essentially clean (all 10 table rows verified; Pozar cross-checks pass)
- [LOW] `l_match_synthesis.rlab:38` — garbled editing-artifact comment ("… actually compute below").
- [LOW] `notebooks/16:126` (and `l_match_synthesis.rlab:13`) — "two more shunt-first networks that
  Exercise 1 explores" is a dangling pointer: Ex. 1 (`:415`) synthesises shunt-first matches for a
  *different* load (100 + j50), never 30 + j50's pair.

### L17 — lumped-inductance
- [MED] `notebooks/17:286` (Ex. 5) — not answerable with the toolkit: `finite_solenoid.rlab` is a free-space
  elliptic-kernel sum with no permeable-media representation, and the K-shift needs an axisymmetric
  ∇·(µ_r⁻¹∇) solve that neither the lesson nor rustlab provides (`laplacian_eps_2d` is Cartesian).
- [LOW] `notebooks/17:70` — "exact … 247.66 nH … to five digits" contradicts itself: exact value is
  247.669 nH → 247.67 at 5 sig figs (matches L_num); 247.66 is a truncation.
- [LOW] `ind_matrix_microstrip.rlab:122` — "reciprocity error → ~machine ε" vs printed 1.373e-7 (direct-
  solve noise, ~9 orders above ε); the table's "≲ 10⁻⁷" (`:272`) is also marginally exceeded.
- [LOW, informational] `notebooks/17` printing blocks — the captured prints echo hard-coded literals or
  arithmetic on them, so `book/17`'s text blocks attest self-consistency, not solver output.

---

## F. Verification notes

- **Numeric drift is essentially zero**: across all 17 lessons only the L15 3.8 fF table row (stale after a
  prior fix) and the L12 4.949 GHz narrative (A4) disagree with live output. Everything else — including
  L10's re-baked scattering numbers (1.20878/0.31804, independently cross-checked against a scipy Mie
  reference and shown converging), L13's S-parameters, L16's Pozar worked examples, and L17's elliptic-
  integral inductances (checked against scipy `ellipk`/`ellipe`) — matches to quoted precision.
- Agents cross-verified physics analytically (L08 edge-residual (kΔx)²/2 derivation, L09 polarization
  handedness conventions, L11 TF/SF face-correction signs vs Taflove, L12 NF→FF Love-current kernel,
  L16 L-match/stub/double-stub algebra vs Pozar, L17 transformer/Nagaoka relations) — all correct.
- L13 Ex. 2's rewritten quantitative claims were verified *by experiment* (S_cfl = 0.95 → |S11| drifts 2.0%
  high, energy 1.019): both "a few percent" and "no longer sums to 1" hold.
- Wall-time claims in L15/L17 headers (18 s / 9 s vs 21.7 s / 11.5 s measured) are machine-dependent; left alone.
