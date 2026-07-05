# Lesson 16: Smith Chart & Impedance Matching

Every RF and microwave engineer reads impedance matches off a **Smith chart** — the conformal map that turns "translate along a transmission line" into "rotate on a constant-$|\Gamma|$ circle." This lesson treats the chart as a *computation*: bilinear transform first, then synthesise real matching networks (L-match, single-stub, double-stub, $\lambda/4$ transformer) and read the resonant locus of the Lesson 14 patch antenna directly off the chart. The link between Lesson 13's algebra ($\Gamma$, VSWR, $S_{11}$) and the visual reasoning that drives practical antenna and amplifier design.

rustlab ships `smith(...)`, `marker(...)`, `smith_circle(...)`, and a tagged `sparameters` struct with `s2td(...)` for time-domain step / impulse response. Every example in this lesson uses those primitives — no hand-drawn chart geometry.

## Learning Objectives

- Read the Smith chart as the bilinear transform $\Gamma = (z-1)/(z+1)$, with constant-$r$ and constant-$x$ circles, $|\Gamma| = 1$ outer boundary, and the matched centre at $\Gamma = 0$.
- Trace $\Gamma_{\rm in}(d)$ along a lossless line — the canonical "constant-$|\Gamma|$ rotation" — and confirm the $\lambda/4$ impedance inversion as a single half-rotation.
- Synthesise **L-match** networks (closed-form, two solutions for $R_L < Z_0$) and trace the trajectory across the chart.
- Synthesise **single-stub** matches algorithmically: walk to $\text{Re}(y) = 1$, then cancel residual susceptance with a short-circuited stub.
- Synthesise **double-stub** matches at fixed spacing $d_{12}$; recognise the forbidden region $g_L > 1/\sin^2(\beta d_{12})$.
- Design a **$\lambda/4$ transformer** for real loads and quantify the $-10\,\text{dB}$ matching bandwidth.
- Package a synthetic $S_{11}(f)$ as an `sparameters` struct, render it with `smith(...)`, and recover its time-domain step response with `s2td(...)`.

## Background

Lesson 13 (transmission-line $\Gamma$, VSWR, $S_{11}$ extraction), Lesson 14 (patch-antenna FDTD; the headline use-case for the Smith locus). Algebraic prerequisites: complex arithmetic, the bilinear $\Gamma \leftrightarrow z$ map, $\tan$ / $\cot$ identities for short-/open-circuited stubs.

## The Bilinear Map

### Theory

The Smith chart is the unit-disk image of the right-half $Z$-plane under

$$\Gamma = \frac{z - 1}{z + 1}, \qquad z = \frac{Z}{Z_0}, \qquad z = \frac{1 + \Gamma}{1 - \Gamma}.$$

Four landmarks fix the geometry: $z=1 \to \Gamma = 0$ (matched, chart centre), $z=\infty \to \Gamma = +1$ (open, right edge), $z=0 \to \Gamma = -1$ (short, left edge), $z = j \to \Gamma = j$ (purely inductive, top edge). The unit circle $|\Gamma|=1$ is the entire boundary of passive loads. Lossless TL transformations preserve $|\Gamma|$ — they rotate clockwise (toward generator) by $2\beta d$.

Curves of constant normalised resistance, reactance, or conductance map to circles on the $\Gamma$-plane — the grid the chart is printed on:

- **constant-$r$ circles**: centre $r/(1+r)$ on the real axis, radius $1/(1+r)$; they nest toward $\Gamma = +1$ as $r \to \infty$.
- **constant-$x$ arcs**: centre $1 + j/x$, radius $1/\lvert x\rvert$; they spring from $\Gamma = +1$ and cross the constant-$r$ circles at right angles.
- **constant-$g$ circles** (admittance grid): the $\Gamma \to -\Gamma$ mirror of the constant-$r$ family, centre $-g/(1+g)$, radius $1/(1+g)$. The double-stub forbidden boundary below is the $g = 2$ member of this family.

**VSWR** is a one-number summary of mismatch:

$$\text{VSWR} = \frac{1 + |\Gamma|}{1 - |\Gamma|}.$$

A constant-VSWR contour is a single constant-$|\Gamma|$ circle.

### Example — Landmark points

`smith(...)` seeds the chart background; `marker(...)` drops labelled scatter points; `smith_circle(centre, radius, label)` overlays parametric circles for VSWR or stability contours.

```rustlab
clf;
Z0 = 50.0;
Z_match = Z0;          G_match = (Z_match - Z0) / (Z_match + Z0);     % → 0
Z_open  = 1e12;        G_open  = (Z_open  - Z0) / (Z_open  + Z0);     % → +1
Z_short = 0;           G_short = (Z_short - Z0) / (Z_short + Z0);     % → -1
Z_pure  = j * Z0;      G_pure  = (Z_pure  - Z0) / (Z_pure  + Z0);     % top edge

smith(G_match);
marker(G_match, "matched");
marker(G_open,  "open");
marker(G_short, "short");
marker(G_pure,  "Z = jZ_0");
title("Smith chart — canonical loads");
```

### Example — Constant-VSWR circles

```rustlab
clf;
smith(0);                                       % background only
hold on;
for k = [0.2, 0.5, 0.8]
  vswr = (1 + k) / (1 - k);
  smith_circle(0, k, sprintf("VSWR = %.2f", vswr));
end
hold off;
title("Constant-|Γ| circles → constant-VSWR contours");
```

## Translating Along a Lossless Line

### Theory

A lossless line of length $d$ rotates $\Gamma$ clockwise by $2\beta d$:

$$\Gamma(d) = \Gamma_L\,e^{-2 j \beta d}, \qquad |\Gamma(d)| = |\Gamma_L|.$$

This single identity does the heavy lifting in every matching-network synthesis below.

The input impedance looking into a lossless line of length $d$ terminated in $Z_L$ is

$$Z_{\rm in}(d) = Z_0\,\frac{Z_L + j Z_0 \tan(\beta d)}{Z_0 + j Z_L \tan(\beta d)}.$$

At $d = \lambda/4$, $\tan(\beta d) \to \infty$ and the expression collapses to $Z_0^2 / Z_L$ — the **quarter-wave inversion**. On the chart, a half-rotation ($2\beta d = \pi$) flips $\Gamma$ across the origin, sending a load below $Z_0$ to one above it.

### Example — Four loads on one chart

```rustlab
clf;
Z0 = 50.0;
Z_loads = [25.0, 100.0, 100 * j, 25 - 50 * j];
d_over_lambda = linspace(0, 0.5, 361);          % half-wavelength = full loop
beta_d        = 2 * pi * d_over_lambda;

hold on;
for k = 1:length(Z_loads)
  GL = (Z_loads(k) - Z0) / (Z_loads(k) + Z0);
  Gd = GL * exp(-2 * j * beta_d);
  smith(Gd);
end
hold off;
title("Γ(d) loci for four loads — constant-|Γ| rotation");
```

The $\lambda/4$ inversion as a single number:

```rustlab
ZL = 25.0;
GL = (ZL - Z0) / (ZL + Z0);                     % = -1/3
G_quarter = GL * exp(-2 * j * 2 * pi * 0.25);   % 2βd = π → flips sign
Z_quarter = Z0 * (1 + G_quarter) / (1 - G_quarter);
print(real(GL))                                 % -0.333
print(real(G_quarter))                          %  0.333
print(real(Z_quarter))                          %  100   Ω  (= Z_0²/Z_L)
```

## L-Section Matching

Two reactive elements (one series, one shunt) match any complex load to a real $Z_0$. The ordering is set by chart geometry. A series reactance walks the load along its constant-$r$ circle onto the unit-conductance ($g = 1$) circle (**series-then-shunt**); a shunt susceptance walks it along its constant-$g$ circle onto the unit-resistance ($r = 1$) circle (**shunt-then-series**). Series-first is *forced* only when $g_L > 1$ (the constant-$g$ circle then never reaches $r = 1$); shunt-first only when $r_L > 1$. The load $Z_L = 30 + j50$ has $r_L = 0.6$ and $g_L = 0.44$ — outside *both* unit circles — so **both** orderings match: the series-first pair computed below, plus two more shunt-first networks that Exercise 1 explores.

### Theory

For series-then-shunt, with series reactance $X$ and shunt susceptance $B$:

$$X + X_L = \pm\sqrt{R_L (Z_0 - R_L)}, \qquad B = \pm\,\frac{1}{Z_0}\sqrt{\frac{Z_0 - R_L}{R_L}},$$

with the **same** sign taken in both expressions (Pozar Eqs. 5.6a/b) — the worked example below confirms it: the $+$ branch gives $X + X_L = +24.49\,\Omega$ and $B_A = +0.0163\,\text{S}$.

The $\pm$ pair gives two distinct networks — typically one cap-cap and one cap-inductor. The signs of $X$ and $B$ pick capacitor vs. inductor on each leg.

### Example — $Z_L = 30 + j50\,\Omega$ at 1 GHz

```rustlab
clf;
Z0 = 50.0; f0 = 1e9; w0 = 2 * pi * f0;
ZL = 30 + j * 50;  R_L = real(ZL);  X_L = imag(ZL);

disc = sqrt(R_L * (Z0 - R_L));                  % 24.49
X_A  = +disc - X_L;                             % -25.5  (series C)
Zp_A = R_L + j * (X_L + X_A);
Yp_A = 1 / Zp_A;
B_A  = -imag(Yp_A);                             % +0.0163 (shunt C)

% Component values at 1 GHz: X<0 ⇒ series C, B>0 ⇒ shunt C.
C_series_pF = 1 / (w0 * abs(X_A)) * 1e12;
C_shunt_pF  = B_A / w0 * 1e12;
print(C_series_pF)                              % ≈ 6.24
print(C_shunt_pF)                               % ≈ 2.60

% Verify the final reflection coefficient is zero.
Yfinal = Yp_A + j * B_A;
Gfinal = (1 / Yfinal - Z0) / (1 / Yfinal + Z0);
print(abs(Gfinal))                              % ≈ 0  (machine ε)

% Trajectory: incremental series-X sweep, then incremental shunt-B sweep.
lams       = linspace(0, 1, 80);
Z_series   = R_L + j * (X_L + lams * X_A);
Gs_series  = (Z_series - Z0) ./ (Z_series + Z0);
Y_shunt    = Yp_A + j * lams * B_A;
Z_shunt    = 1 ./ Y_shunt;
Gs_shunt   = (Z_shunt - Z0) ./ (Z_shunt + Z0);

GL = (ZL - Z0) / (ZL + Z0);
smith(Gs_series);
hold on;
smith(Gs_shunt);
marker(GL,      "Z_L = 30 + j50");
marker((Zp_A - Z0) / (Zp_A + Z0), "after series-C");
marker(0,       "matched");
hold off;
title("L-match: series C (6.24 pF) → shunt C (2.60 pF)");
```

The second solution (sign flip on `disc`) gives series-C (2.14 pF) + shunt-L (9.75 nH); see `l_match_synthesis.rlab` for both.

## Single-Stub Matching

Algorithmic: walk a distance $d$ along the line until the normalised admittance has unit real part; cancel the residual susceptance with a shunt short-circuited stub of length $\ell$.

### Theory

With $\Gamma(d) = \Gamma_L\,e^{-2 j \beta d}$,

$$y(d) = \frac{1 - \Gamma(d)}{1 + \Gamma(d)}.$$

Pick the smallest $d$ where $\text{Re}(y(d)) = 1$ (two crossings per $\lambda/2$). The residual susceptance $b_d = \text{Im}(y(d))$ is cancelled by a stub of input admittance $y_{\rm stub} = -j\cot(\beta\ell)$:

$$\cot(\beta\ell) = b_d \quad\Longrightarrow\quad \frac{\ell}{\lambda} = \frac{\arctan(1/b_d)}{2\pi}.$$

Map negative values into the next half-period so $\ell > 0$.

### Example — $Z_L = 60 - j80\,\Omega$ (Pozar §5.2)

```rustlab
clf;
Z0 = 50.0;  c0 = 2.998e8;  f0 = 1e9;
lam0 = c0 / f0;  beta = 2 * pi / lam0;
ZL = 60 - j * 80;
GL = (ZL - Z0) / (ZL + Z0);

% Scan β d ∈ [0, π], find both crossings of Re(y(d)) = 1.
N    = 4001;
bds  = linspace(0, pi, N);
Gd   = GL * exp(-2 * j * bds);
yd   = (1 - Gd) ./ (1 + Gd);
res  = real(yd) - 1;
sgn  = sign(res);
diffs = sgn(2:N) - sgn(1:N-1);
hits = find(abs(diffs) > 0.5);
print(length(hits))                             % 2 crossings per loop
```

```rustlab
% Refine the first crossing and read out (d, ℓ).
k = hits(1);
t = res(k) / (res(k) - res(k + 1));
bd_sol  = bds(k) + t * (bds(k + 1) - bds(k));
d_over_lam = bd_sol / (2 * pi);
yd_sol  = (1 - GL * exp(-2 * j * bd_sol)) / (1 + GL * exp(-2 * j * bd_sol));
b_resid = imag(yd_sol);
bl      = atan(1 / b_resid);
if bl < 0;  bl = bl + pi;  end
l_over_lam = bl / (2 * pi);
print(d_over_lam)                               % ≈ 0.110
print(l_over_lam)                               % ≈ 0.095
```

The second crossing gives the alternate solution $(d, \ell) \approx (0.259\,\lambda,\, 0.405\,\lambda)$; both match perfectly at $f_0$ but differ in bandwidth and stub-loading sensitivity.

## Double-Stub Matching

Two shunt stubs at fixed spacing $d_{12}$ remove the variable-position constraint. The procedure costs one solvability check.

### Theory

The two stub susceptances are real-valued only when

$$g_L \,\le\, \frac{1}{\sin^2(\beta d_{12})}.$$

For $d_{12} = \lambda/8$ the threshold is $g_L \le 2$, where $g_L$ is the normalised conductance seen **at the plane of the first stub** — not a condition on $R_L$ directly. For a *purely resistive* load sitting at that plane it reduces to $R_L \ge Z_0/2$: such loads with $R_L < 25\,\Omega$ on a 50 Ω system can't be matched at this spacing. A complex load (or any line length between load and first stub) is judged by its conductance at the stub plane.

### Example — Solvable ($Z_L = 100 + j100\,\Omega$) vs. forbidden ($Z_L = 10\,\Omega$)

```rustlab
clf;
Z0 = 50.0;
beta_d12 = 2 * pi * (1 / 8);                    % d_12 = λ/8
g_forbidden = 1 / (sin(beta_d12)^2);
print(g_forbidden)                              % 2.0
```

`double_stub_match.rlab` runs the full root-finder and lands a Case-A load (g_L = 0.25, two real solutions) at the chart centre; Case-B (g_L = 5, in forbidden region) terminates with the load drawn inside the constant-$g = 2$ boundary circle.

```rustlab
% Forbidden-region boundary on the impedance chart.
clf;
ZL_b = 10.0;
G_L_b = (ZL_b - Z0) / (ZL_b + Z0);
smith(G_L_b);
g_thr = 2;
% constant-g circle from the Bilinear Map theory: centre −g/(1+g), radius 1/(1+g).
smith_circle(-g_thr / (g_thr + 1), 1 / (g_thr + 1), sprintf("forbidden g = %.0f", g_thr));
marker(G_L_b, "Z_L = 10 Ω (g_L = 5)");
marker(0,     "matched (unreachable)");
title("Double-stub match — load inside the forbidden region");
```

## Quarter-Wave Transformer

For a real load $Z_L$, a single $\lambda_0/4$ section of characteristic impedance $Z_T = \sqrt{Z_0 Z_L}$ matches it to $Z_0$ at the design frequency. Off-resonance the input impedance drifts; the $-10\,\text{dB}$ matching bandwidth quantifies how narrow this single-section transformer is.

### Theory

The input impedance of the transformer terminated in $Z_L$, as a function of electrical length $\beta L_t = \pi f / (2 f_0)$, is

$$Z_{\rm in}(f) = Z_T\,\frac{Z_L + j Z_T \tan(\beta L_t)}{Z_T + j Z_L \tan(\beta L_t)}, \qquad Z_{\rm in}(f_0) = \frac{Z_T^2}{Z_L} = Z_0.$$

Bandwidth shrinks as $|Z_L - Z_0|$ grows.

### Example — $Z_L = 100\,\Omega \to Z_0 = 50\,\Omega$ at 1 GHz

```rustlab
clf;
Z0 = 50.0;  Z_L = 100.0;  Z_T = sqrt(Z0 * Z_L);
c0 = 2.998e8;  f0 = 1e9;  L_t = (c0 / f0) / 4;
print(Z_T)                                      % 70.71 Ω

function Zin = qwt_zin(Z_T, Z_L, beta_Lt)
  t = sin(beta_Lt) / cos(beta_Lt);
  Zin = Z_T * (Z_L + j * Z_T * t) / (Z_T + j * Z_L * t);
end

fs   = linspace(0.2, 1.8, 801) * 1e9;
beta_Lt = 2 * pi * fs * L_t / c0;
Zin  = arrayfun(@(bL) qwt_zin(Z_T, Z_L, bL), beta_Lt);
G    = (Zin - Z0) ./ (Zin + Z0);

% −10 dB bandwidth.
in_band = abs(G) < 0.3162;
idx     = find(in_band);
print(fs(idx(1))         / 1e9)                 % lower edge
print(fs(idx(length(idx))) / 1e9)               % upper edge

smith(G);
marker(G(1),                       "f = 0.2 GHz");
marker(G(argmin(abs(fs - f0))),    "f = 1.0 GHz (matched)");
marker(G(length(G)),               "f = 1.8 GHz");
title("λ/4 transformer Γ locus");
```

A 2:1 $Z_L/Z_0$ mismatch is quite broadband — fractional BW of ~150%. Higher mismatches narrow rapidly; the multi-section Chebyshev transformer broadens it back at the cost of additional length.

## Patch Antenna on the Smith Chart

Lesson 14's capstone runs a 2-D FDTD of a microstrip patch and reports $|E_z(f)|$ at the feed probe — a spectral magnitude, not a port $S_{11}$. To turn that into a clean Smith picture we model the patch with the textbook narrow-band approximation

$$Z_{\rm in}(f) \approx \frac{R_0}{1 + jQ(f/f_0 - f_0/f)},$$

with $f_0 \approx 2.45\,\text{GHz}$, $Q \approx 30$ (typical FR-4 patch), and $R_0 = 40\,\Omega$ (well-tuned but slightly off the 50 Ω feed). The locus is the canonical "resonant loop" near the chart centre that every VNA datasheet shows.

### Theory

A 1-port `sparameters` struct from rustlab takes a Tensor3 of shape $(n_f, 1, 1)$ plus a real frequency vector. Once tagged, `smith(s)` renders the locus, and `s2td(s, 1, 1, "step")` recovers the time-domain step response by IFFT — the same impulse / step shape an oscilloscope would capture at the feed.

### Example — Synthetic resonant patch

```rustlab
clf;
Z0 = 50.0;
f0_p = 2.45e9;  Q_p = 30.0;  R0_p = 40.0;
fs = linspace(1.0, 5.0, 801) * 1e9;
Zin = R0_p ./ (1 + j * Q_p * (fs / f0_p - f0_p ./ fs));
G   = (Zin - Z0) ./ (Zin + Z0);

% Package as a 1-port sparameters struct.
N = length(fs);
S_tens = zeros3(N, 1, 1);
for k = 1:N
  S_tens(k, 1, 1) = G(k);
end
s_patch = sparameters(S_tens, fs, Z0);

% Resonance + −10 dB bandwidth read-out.
mag    = abs(G);
[mag_min, k_res] = min(mag);
print(fs(k_res) / 1e9)                          % ≈ 2.45 GHz
print(20 * log10(mag(k_res)))                   % ≈ −19 dB depth

% −10 dB band edges, linearly interpolated between the 5 MHz grid samples
% (reading raw grid points clips the band to ≈ 1.6%).
idx  = find(mag < 0.3162);
k1 = idx(1);  k2 = idx(length(idx));
f_lo = fs(k1-1) + (0.3162 - mag(k1-1)) / (mag(k1) - mag(k1-1)) * (fs(k1) - fs(k1-1));
f_hi = fs(k2)   + (0.3162 - mag(k2))   / (mag(k2+1) - mag(k2)) * (fs(k2+1) - fs(k2));
print((f_hi - f_lo) / fs(k_res) * 100)          % fractional BW ≈ 1.87%

smith(s_patch);
marker(G(1),     sprintf("f = %.1f GHz", fs(1) / 1e9));
marker(G(k_res), sprintf("resonance %.2f GHz", fs(k_res) / 1e9));
marker(G(N),     sprintf("f = %.1f GHz", fs(N) / 1e9));
title("Patch antenna S_{11}(f) on the Smith chart");
```

The step response is one call:

```rustlab
clf;
[t, y] = s2td(s_patch, 1, 1, "step");
plot(t * 1e9, y, "step response");
xlabel("t  (ns)");
ylabel("y_{step}(t)");
title("S_{11} step response via s2td — ring-down at the patch resonance");
```

The ring-down envelope decays at rate $\pi f_0 / Q \approx 0.26\,\text{ns}^{-1}$, consistent with a $Q = 30$ resonator at 2.45 GHz.

## Standalone Scripts

| Script | What it computes |
|---|---|
| `smith_chart.rlab` | Tour of `smith` / `marker` / `smith_circle`; landmark loads and constant-VSWR overlays |
| `tline_transformation.rlab` | $\Gamma(d)$ loci for four loads on one chart; explicit $\lambda/4$ inversion check |
| `l_match_synthesis.rlab` | Closed-form L-match (two solutions) for $Z_L = 30 + j50\,\Omega$ at 1 GHz; trajectory + component values |
| `single_stub_match.rlab` | Algorithmic shunt-stub tuner for $Z_L = 60 - j80\,\Omega$; both $(d, \ell)$ solutions; verify $\Gamma_{\rm in} = 0$ |
| `double_stub_match.rlab` | $d_{12} = \lambda/8$ tuner: solvable ($Z_L = 100 + j100$) vs. forbidden ($Z_L = 10$) |
| `quarter_wave_transformer.rlab` | $\lambda/4$ transformer for $Z_L = 100 \to Z_0 = 50$; frequency sweep + $-10\,\text{dB}$ BW |
| `patch_antenna_smith.rlab` | Synthetic patch $S_{11}(f)$ packaged as `sparameters`; Smith locus + `s2td` step response |

Run all seven with `make lesson-16`, or one at a time via `rustlab run lessons/16-smith-chart/<name>.rlab`.

## Expected Numerical Outputs Summary

| Quantity | Expected Value |
|---|---|
| $\lvert\Gamma_L\rvert$ for $Z_L = 30 + j50\,\Omega$ | $\approx 0.571$ |
| L-match Solution A | series-C $6.24\,\text{pF}$, shunt-C $2.60\,\text{pF}$ |
| L-match Solution B | series-C $2.14\,\text{pF}$, shunt-L $9.75\,\text{nH}$ |
| Single-stub $(d/\lambda,\, \ell/\lambda)$ for $Z_L = 60 - j80$ | $(0.110, 0.095)$ and $(0.259, 0.405)$ |
| Double-stub forbidden threshold ($d_{12} = \lambda/8$) | $g_L = 2$ |
| Double-stub Case A: $b_1$, $b_2$ | $b_1 \approx 0.589$, $b_2 \approx -1.65$ |
| $\lambda/4$ transformer $Z_T$ for $Z_L = 100$, $Z_0 = 50$ | $\sqrt{5000} \approx 70.71\,\Omega$ |
| $\lambda/4$ transformer fractional $-10\,\text{dB}$ BW | $\approx 156\,\%$ |
| Patch antenna resonance, $\lvert S_{11}\rvert$ at resonance | $2.45\,\text{GHz}$, $\approx -19\,\text{dB}$ |
| Patch antenna fractional $-10\,\text{dB}$ BW | $\approx 1.87\,\%$ (interpolated edges; raw 5 MHz grid points clip it to $\approx 1.6\,\%$) |

## Exercises

1. **L-match the other way.** Pick a load with $R_L > Z_0$ (e.g. $Z_L = 100 + j50\,\Omega$) and synthesise both shunt-first L-matches; verify on the chart that the load's constant-$g$ admittance circle now intersects the unit-resistance circle.
2. **Stub bandwidth comparison.** For the single-stub example, run both $(d, \ell)$ solutions through a $\pm 10\,\%$ frequency sweep and compare the matching bandwidth. One solution is reliably broader — which?
3. **Three-section Chebyshev transformer.** Replace the single $\lambda/4$ section in `quarter_wave_transformer.rlab` with a three-section equal-ripple Chebyshev transformer (Pozar §5.6). Verify the $-10\,\text{dB}$ bandwidth grows by a factor of $\sim 3$ for a 4:1 mismatch.
4. **Replumb the patch.** Modify `patch_antenna.rlab` (Lesson 14) to emit $S_{11}(f)$ — record both an incident-reference probe (open feed, no patch) and a step probe (patch present), take ratio of FFTs, save to a file or rebuild in this script. Re-run `patch_antenna_smith.rlab` against the FDTD-derived $S_{11}$ instead of the analytic surrogate. The locus shape should track the synthetic version near resonance and diverge in the wings.
5. **VSWR overlays on every matching example.** In each of the L-match / single-stub / double-stub / $\lambda/4$ scripts, overlay the constant-VSWR circle that bounds the matching tolerance you want (say VSWR $\le 1.5$). Use `smith_circle(0, gamma_max, "VSWR ≤ 1.5")` where $\Gamma_{\rm max} = (\text{VSWR} - 1)/(\text{VSWR} + 1)$.

## What's next

Lesson 17 is the magnetic dual of Lesson 15 (lumped capacitance): extract lumped inductance $L$ and mutual inductance $M$ from a Lesson 06–style vector-potential solve. With capacitance from L15 and inductance from L17, the curriculum's "C, L, R" triad sits on the same numerical footing — and combined with the Smith-chart synthesis here, you have every ingredient needed to design a real lumped matching network from solver output to schematic.
