# Lesson 14: Capstone — End-to-End Device Simulation

Every prior lesson built one piece of a mini-Ansys pipeline: geometry primitives (Lesson 04), static and frequency-domain solvers (Lessons 05, 10), full-wave time domain (Lesson 11), modal and far-field analysis (Lesson 12), transmission lines and ports (Lesson 13). This capstone composes all of them into a single end-to-end script that takes a layered antenna geometry, runs FDTD with a pulsed feed, and reads the resonant frequencies and field pattern off a single time-series.

The classic 3-D device target — a rectangular patch antenna on FR-4 at 2.45 GHz — is sized for a desktop CST run, not for an interpreted-rustlab demo. We instead build the **2-D side-view cross-section** of a related device: an air half-space above a substrate-on-ground-plane stack with a metal patch on top, driven by a pulsed feed in the substrate. (The patch we simulate is deliberately oversized to 50 mm rather than the $\approx 30\,\text{mm}$ a 2.45 GHz design would use — the caveat under *The Capstone Loop* explains why.) The 2-D problem captures every algorithmic step (geometry → ε map → PEC mask → FDTD → port-trace → FFT) while staying under a minute of run time. The *From 2-D to 3-D* section at the end of this lesson explains exactly which lines would grow into 3-D Tensor3 calls for a production simulation.

## Learning Objectives

- Compose a layered geometry as a stack of $\varepsilon_r$, $\mu_r$, and PEC masks on a single (ny, nx) grid
- Run a 2-D Yee FDTD with a Gaussian-modulated pulse feed and absorbing strips
- Record a port-probe time trace and FFT it to expose resonant frequencies
- Recognise the natural extension to 3-D Tensor3 arrays, TF/SF + Bérenger PML, and NF→FF — all curriculum tools, applied once more

## Background

Lessons 04 (geometry / material maps), 09 (animations via `frame()`/`saveanim()`), 11 (FDTD core), 12 (radiation), 13 (transmission-line port and the probe-trace FFT pattern). The 2-D Yee step is reused verbatim from `fdtd_2d_scattering.rlab` with `ε_r(x, y)` from a layered material map.

## Device Under Test

A side-view of a microstrip patch antenna:

| Layer | y cells | Material |
|---|---|---|
| Air above patch | $y \in (y_{\rm top}, n_y]$ | $\varepsilon_r = 1$ |
| Patch (top metal) | row $y_{\rm top}$, columns $x_{\rm lo}..x_{\rm hi}$ | PEC ($E_z = 0$) |
| Substrate | $y \in (y_g, y_{\rm top}]$ | $\varepsilon_r = 4.4$ (FR-4) |
| Ground plane | row $y_g$ | PEC, full-width |
| Air below | $y \in [1, y_g)$ | $\varepsilon_r = 1$ |

A 1-column **feed** sits at $x = x_{\rm lo}$ (the left edge of the patch), driving $E_z$ between the ground plane and the patch underside with a Gaussian-modulated CW pulse centred at 2.5 GHz. The cross-section is bounded laterally by absorbing strips (cubic-σ bulk loss); the top and bottom rows of the grid are hard (PEC-like) boundaries, so radiated leakage *does* reflect within the simulation window — weak compared with the energy the feed pumps under the patch, but enough that the truncation shapes the driven-response spectrum the probe records (see the discussion under Expected Numerical Outputs).

## The Capstone Loop

### Theory

The four pieces compose like this:

1. **Material map.** Lesson 04's recipe: start with $\varepsilon_r(i, j) = 1$, fill a band of cells with $4.4$ for the FR-4 substrate, and set a `pec_mask(i, j) = 1` on the ground row and patch row. The Yee step multiplies $E_z$ by $(1 - \text{pec\_mask})$ after each E update — a one-line enforcement of the perfect-conductor condition.

2. **Yee FDTD core.** Lesson 11's leapfrog updates $H_x$, $H_y$, $E_z$ on a staggered grid. The per-cell $\varepsilon_r$ coefficient enters as a precomputed `cE_map(i, j) = \Delta t / (\varepsilon_0\varepsilon_r(i,j)\Delta x)`. Bulk-loss absorbing strips at the lateral edges suppress reflection without a full Bérenger PML — adequate for a 900-step run.

3. **Pulsed feed.** A Gaussian-modulated $\sin(\omega_0 t)$ in a 1-column column of the substrate. The pulse's frequency content roughly covers 1–4 GHz (a $\tau = 0.4$ ns Gaussian envelope on a 2.5 GHz carrier) so a single run probes the patch across its operating band.

4. **Port-trace FFT.** A probe a few cells off the feed column, just above the ground plane, records $E_z(t)$. Over this 900-step run the source is still driving the structure for most of the window, so the trace is the **driven response** of the truncated 2-D box, not a clean free decay (a true ring-down would need a much longer run windowed well after the drive ends). Its Fourier transform peaks at the frequencies the box responds to most strongly — which, as the caveat below the script walkthrough shows, is *not* simply the patch's design resonance.

### Example — Microstrip patch on FR-4

```rustlab
clf;
set_default_axis("xy");        % physics y-axis: ground at the bottom of the panel
mu0_c  = 4 * pi * 1e-7;
eps0_c = 8.854187817e-12;
c0_c   = 1 / sqrt(mu0_c * eps0_c);

nx_c = 121; ny_c = 51;
dx_c = 1.0e-3; dy_c = dx_c;
S_c  = 0.7;
dt_c = S_c * dx_c / c0_c;

% Geometry rows — same grid as patch_antenna.rlab
y_g_c   = 8;
y_top_c = 14;
x_lo_c  = 35;
x_hi_c  = 85;

% ε map (FR-4 substrate)
eps_r = ones(ny_c, nx_c);
for j = 1:nx_c
  for i = y_g_c+1:y_top_c
    eps_r(i, j) = 4.4;
  end
end

% PEC mask (ground + patch rows)
pec_mask = zeros(ny_c, nx_c);
for j = 1:nx_c
  pec_mask(y_g_c, j) = 1;
end
for j = x_lo_c:x_hi_c
  pec_mask(y_top_c, j) = 1;
end

imagesc(eps_r + 5 * pec_mask, "viridis");
title("Patch geometry: substrate (4.4) + metal (PEC, drawn at 6.4)");
xlabel("x cell");
ylabel("y cell")
```

The geometry snapshot shows the substrate band (mid-yellow) sandwiched between the full-width ground plane below it and the shorter patch stripe on top — with `set_default_axis("xy")` the y axis points up, so row 1 is the bottom of the panel, exactly as in the standalone script. The colour scale stacks the PEC value on top of the dielectric ε so both regions stay visible.

The remaining cells of the loop — the Yee update, the source injection, the PEC enforcement, the probe storage, the animation frame, and the post-FFT peak finding — together form the script `patch_antenna.rlab`. Rather than embed the whole 100-line loop here, we walk through its block structure:

```text
1. Initialise zero E_z, H_x, H_y matrices.
2. Precompute cE_map = dt / (eps0 * eps_r * dx)         ← Lesson 04 material map
3. Build absorbing-strip σ_x(j) for x ∈ [1..absorb_w] ∪ [nx-absorb_w+1..nx]
4. For each time step:
     a. H_x, H_y leapfrog updates                       ← Lesson 11 Yee
     b. E_z leapfrog with damp = 1/(1 + dt σ_x/(2 ε0))
     c. Add Gaussian-modulated pulse at feed column     ← Lesson 13 feed
     d. Enforce E_z = 0 on ground + patch via mask
     e. Record probe E_z(t) a few cells off the feed column ← Lesson 11 + 13 trace
     f. Every 40 steps, frame() the field for animation ← Lesson 09 animation
5. saveanim("patch_antenna_animation.gif")
6. FFT the driven probe trace (steps 200–900) → spectrum           ← Lesson 13 FFT pattern
7. Identify the dominant peak in the spectrum (see caveat below).
8. Plot the spectrum, the time trace, and the final |E_z| heatmap.
```

The standalone script that implements this pattern is `patch_antenna.rlab`. Run it with `make lesson-14`; its 900-step animation lands in well under a minute of interpreted-rustlab wall time. **One honest caveat about reading the result.** The patch here is deliberately oversized: at 50 mm its textbook $\lambda/2$ mode $f_{\rm res} = c_0 / (2 L_{\rm patch}\sqrt{\varepsilon_{\rm eff}})$ sits near $1.43\,\text{GHz}$, well below the 2.5 GHz feed band (a 2.45 GHz design patch would be the $\approx 30\,\text{mm}$ of the table above). We keep it large on purpose so the weakly-excited patch mode stays cleanly separated from the driven-response feature for the diagnostic in Exercises 1–2. The dominant peak the script actually prints is $\approx 3.67\,\text{GHz}$ (3.6657 GHz) — and it is a broad, low-$Q$ feature of the **driven** response, not a sharp resonance. It matches neither the patch's $1.43\,\text{GHz}$ half-wave mode nor the $\approx 4.05\,\text{GHz}$ estimate for a vertical half-wave of the $\approx 37$ mm air column between the patch and the hard top boundary. The tell-tale that it is *not* a patch resonance is that it does not shift when you sweep the patch length or the substrate $\varepsilon_r$ — Exercise 1's length sweep is exactly that diagnostic, separating a true patch mode (which scales as $1/L_{\rm patch}$) from this fixed driven-response peak.

## From 2-D to 3-D — What Would Change

The 2-D capstone is a faithful reduction of the 3-D problem to its essentials. To grow it into a real patch-antenna simulation:

| Step | 2-D this script | 3-D production |
|---|---|---|
| Grid | `Ez(ny, nx)` matrices | `Ez(ny, nx, nz)` Tensor3, same for $H_x, H_y, H_z$ |
| Material map | `eps_r(i, j)` matrix | `eps_r(i, j, k)` Tensor3 with `rect_mask` slabs |
| Feed | 1-column source between ground and patch | TF/SF box on a coax-feed port plane |
| Boundary | absorbing strips on $x$ edges | full Bérenger split-field PML on all six faces |
| $S_{11}$ | probe-trace FFT (informal) | mode-filtered waveport + time-gating + FFT |
| Far field | probe field above the patch | NF→FF surface integral on a closed box ([Lesson 12 Ex. 5](12-waveguides-and-radiation.md#exercises)) |

Every element on the right is a tool the curriculum already covered. The 3-D step is a *scale-up*, not a new physics or algorithm.

## Standalone Script

| Script | What it computes |
|---|---|
| `patch_antenna.rlab` | 2-D side-view FDTD of an FR-4 microstrip patch with a pulsed feed; animated; spectrum of the feed-probe trace |

Run it with `make lesson-14`, or directly via `rustlab run lessons/14-capstone-device-simulation/patch_antenna.rlab`.

## Expected Numerical Outputs Summary

| Quantity | Expected Value |
|---|---|
| Substrate $\varepsilon_r$ (FR-4) | 4.4 |
| Patch length $L$ for a 2.45 GHz design | $\lambda_0/(2\sqrt{\varepsilon_{\rm eff}}) \sim 30\,\text{mm}$ |
| Simulated patch length (this script) | $50\,\text{mm}$ — deliberately oversized so the patch $\lambda/2$ mode ($\approx 1.43\,\text{GHz}$) is well below the 2.5 GHz feed band; see the caveat below |
| 2-D dominant spectral peak, this geometry | $\approx 3.67\,\text{GHz}$ (printed 3.6657 GHz) — a broad, low-$Q$ feature of the **driven** response, *not* the patch's $\lambda/2$ mode ($\approx 1.43\,\text{GHz}$) and *not* the $\approx 4.05\,\text{GHz}$ air-column estimate either. It stays fixed under patch-length and $\varepsilon_r$ sweeps (Exercises 1–2) — the diagnostic that it is not a patch resonance |
| Pulse half-width $\tau$ | $\approx 0.4\,\text{ns}$ |
| Time-step ($S = 0.7$ Courant) | $\sim 2.34\,\text{ps}$ ($\Delta x = 1$ mm) |
| Total simulation time | $\sim 2.1\,\text{ns}$ (900 steps × $\Delta t$) |

## Exercises

1. **Patch length sweep — is the dominant peak a patch mode?** Rerun the script for $L_{\rm patch} \in \{20, 30, 40, 50\}\,\text{mm}$ (change `x_hi - x_lo`) and plot the dominant FFT-peak frequency vs $L_{\rm patch}$. You will find it barely moves — direct evidence the dominant peak is *not* the patch's $\lambda/2$ mode, which should scale as $1/L_{\rm patch}$. Then hunt for a *secondary* peak that *does* track $1/L_{\rm patch}$: that weaker feature is the patch mode, sitting well below the driven-response peak.
2. **Substrate sweep and mode isolation.** Repeat with $\varepsilon_r \in \{2.2, 4.4, 9.8\}$ (Rogers / FR-4 / alumina). The dominant peak again stays essentially fixed, confirming it is a driven-response feature of the truncated box rather than a patch resonance. To *isolate* the true patch mode, try any of: (a) subtract a no-patch reference run (delete the patch row) so only patch-dependent features survive in the difference spectrum; (b) lengthen the run to several thousand steps and FFT only the post-drive window; (c) move the probe farther from the feed. Verify that the surviving patch-dependent peak scales as $1/\sqrt{\varepsilon_{\rm eff}}$.
3. **Inset feed.** Move the feed column from the patch's left edge inward by a few cells. Track the dominant peak's amplitude as a function of inset distance — this is how real designs match the patch's input impedance to 50 Ω.
4. **3-D port-trace.** Build a 3-D Tensor3 version of the material map using `rect_mask` slabs (Lesson 04). Don't run the full FDTD — just verify the geometry slices look correct in three orthogonal `imagesc` views (xz, xy, yz).
5. **NF→FF on the 2-D run.** At the dominant resonance, take the steady-state $E_z$ on a horizontal line just above the patch, FFT it along $x$ (the aperture), and interpret the resulting $|\tilde E_z(k_x)|$ as the angular pattern $|F(\theta)|$ via $k_x = k_0\sin\theta$. Plot in polar; compare to a textbook patch radiation pattern.

## Looking Back

The first fourteen lessons span:

- **Lessons 01–03**: vector calculus on grids, electrostatic superposition, Gauss / potential
- **Lesson 04**: geometry primitives — the CAD layer every later solver consumes
- **Lessons 05–07**: numerical PDEs (Poisson, magnetostatics, Faraday)
- **Lesson 08**: Maxwell's equations as a closed self-consistent system
- **Lesson 09**: plane waves, polarisation, standing waves
- **Lessons 10–11**: the two full-wave solvers (FDFD and FDTD)
- **Lesson 12**: modal eigenproblems and far-field radiation
- **Lesson 13**: transmission lines and S-parameters
- **Lesson 14**: composition — this capstone

Beyond the capstone, Lessons 15–17 extend the arc from fields to circuits: lumped capacitance extraction (Lesson 15), Smith-chart impedance matching (Lesson 16), and lumped inductance extraction (Lesson 17).

Every script in this curriculum sits in `lessons/<id>-<name>/` as a runnable artefact; every notebook in `notebooks/<id>-<name>.md` documents the physics with interleaved theory and example. The rendered curriculum is at `book/`. The two upstream-feature requests we filed and saw landed — animation export (`frame()`/`saveanim()`) and the SC-PML helpers in `lessons/_shared/em.rlab` — close the loop on the original "what rustlab needs to support the curriculum" survey from `dev/rustlab/requests/em_requests.md`. The remaining 3-D Yee + SC-PML graduation to native Rust waits on the triggers documented in [`yee-and-pml-builders.md`](../dev/rustlab/requests/yee-and-pml-builders.md); until then, the scripted library is the curriculum-side answer.
