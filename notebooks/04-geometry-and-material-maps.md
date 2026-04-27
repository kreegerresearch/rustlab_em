# Lesson 04: Geometry & Material Maps

Lessons 01–03 worked in vacuum: the only "geometry" was a list of point charges, and every formula was evaluated analytically on a coordinate grid. Real devices are different. A capacitor is a *region* of dielectric sandwiched between two *regions* of conductor; an antenna is a metallic *shape* deposited on a *substrate*. Every numerical solver from Lesson 05 onward consumes spatial arrays — $\varepsilon(x,y)$, $\mu(x,y)$, $\sigma(x,y)$ — that say *what material is at each grid cell*. This lesson builds the toolkit that turns a drawing into those arrays.

The trick is that drawing has two parts that decouple cleanly: **rasterizing** geometric primitives into 0/1 masks, and **composing** masks into a material map. Each is short and mechanical. Treating them as a separate lesson is what lets every later solver focus on physics rather than masking.

## Learning Objectives

- Rasterize rectangles, disks, and polygons into binary masks on a uniform grid
- Compose shapes via boolean set operations (union, intersection, complement, difference) using element-wise math
- Assign material properties ($\varepsilon_r$, $\mu_r$, $\sigma$) per region and produce synchronized spatial arrays
- Recognize the staircase error at curved boundaries and apply an area-weighted conformal correction
- Read a layered material map as the input format every grid-based solver expects

## Background

Lessons 01–03 (gradient, divergence, the meshgrid convention). Comfort reading rustlab broadcasting — every operation in this lesson is element-wise on `ny × nx` arrays.

## The Grid Convention

Every primitive in this lesson takes coordinate matrices `X`, `Y` from `meshgrid` and returns an `ny × nx` real-valued mask. Rows index $y$, columns index $x$ — the same convention used by `imagesc`, `contour`, `gradient`, and every later solver.

```rustlab
N      = 200;
[X, Y] = meshgrid(linspace(-1.5, 1.5, N), linspace(-1.5, 1.5, N));
dx     = 3.0 / (N - 1);
dy     = dx;
print(size(X))     % [200, 200] — rows = y, cols = x
print(dx)          % 0.01507... m on this grid
```

Throughout the lesson coordinates are in metres. Holding `X, Y, dx, dy` constant across blocks lets every shape land on the same canvas.

## Rasterizing Primitives

### Theory

A *rasterization* turns a continuous geometric description (a rectangle, a disk, a polygon) into a discrete mask $M(i,j) \in \{0, 1\}$ on the grid. The mask is the indicator function of the shape evaluated at the grid points:

$$M(i, j) = \mathbb{1}\bigl[(X(i,j),\,Y(i,j)) \in S\bigr].$$

Three primitives cover the bulk of EM device geometry:

- **Rectangle**: $S = [x_0, x_0+w] \times [y_0, y_0+h]$, axis-aligned.
- **Disk**: $S = \{(x,y) : (x-x_c)^2 + (y-y_c)^2 \le r^2\}$.
- **Polygon**: $S$ bounded by an ordered vertex list, tested via even-odd ray casting (PNPOLY).

The masks are intentionally binary, *not* anti-aliased — partial coverage is a separate concern handled later by conformal weighting, and keeping the primitives binary keeps the boolean composition rules clean.

### Example — Rectangle

A 1.0 m wide, 0.6 m tall block in the lower-right quadrant:

```rustlab
clf;
R = rect_mask(X, Y, -0.5, -0.4, 1.0, 0.6);
imagesc(R, "viridis");
title("rect_mask: lower-left (-0.5, -0.4), 1.0 × 0.6")
```

```rustlab
% Sanity check: the area should equal w·h = 0.60 m².
print(sum(sum(R)) * dx * dy)        % ≈ 0.60
```

### Example — Disk

A unit disk at the origin. Integrating its mask should approximate $\pi r^2 = \pi$ — we'll use this same disk in the conformal-weighting section to quantify the staircase error.

```rustlab
clf;
D = disk_mask(X, Y, 0.0, 0.0, 1.0);
imagesc(D, "viridis");
title("disk_mask: centre (0, 0), radius 1.0")
```

```rustlab
print(sum(sum(D)) * dx * dy)        % ≈ 3.135 (overshoots π by ≈ 0.2 %)
print(pi)                            % 3.14159...
```

The overshoot is the staircase artefact: `disk_mask` is *closed* (the boundary cells are included), and on a 200-cell grid the rim is a few cells thick.

### Example — Polygon

An equilateral triangle, vertices given as an `N × 2` matrix:

```rustlab
clf;
verts = [-1.0, -0.7;
          1.0, -0.7;
          0.0,  1.0];
T = polygon_mask(X, Y, verts);
imagesc(T, "viridis");
title("polygon_mask: triangle (-1,-0.7)-(1,-0.7)-(0,1)")
```

The polygon is implicitly closed — an edge runs from the last vertex back to the first. Concave and self-intersecting polygons work the same way; PNPOLY's even-odd rule does the right thing.

## Boolean Composition

### Theory

Because the masks are 0/1 valued, set operations are arithmetic on matrices — no separate boolean type, no logical-array gymnastics. The four standard operations:

| Set operation                      | Mask expression               |
|------------------------------------|-------------------------------|
| Intersection $M_1 \cap M_2$        | `M1 .* M2`                    |
| Complement $\overline{M}$          | `1 - M`                       |
| Union $M_1 \cup M_2$               | `M1 + M2 - M1 .* M2`          |
| Difference $M_1 \setminus M_2$     | `M1 .* (1 - M2)`              |

The union form is *inclusion-exclusion*: add the two indicators and subtract the overlap so cells in both regions don't get counted twice. (Don't write `max(M1, M2)` — `max` in rustlab takes a scalar argument and won't broadcast over matrices.)

These four primitives cover every multi-region geometry the rest of the curriculum needs.

### Example — Annulus by difference

An annulus is a large disk minus a small concentric one — the canonical use of $M_1 \setminus M_2$:

```rustlab
clf;
D_outer = disk_mask(X, Y, 0.0, 0.0, 1.0);
D_inner = disk_mask(X, Y, 0.0, 0.0, 0.5);
A_ring  = D_outer .* (1 - D_inner);
imagesc(A_ring, "viridis");
title("Annulus: D_outer .* (1 - D_inner)")
```

```rustlab
% Area should be π(R² - r²) = π(1 - 0.25) ≈ 2.356 m².
print(sum(sum(A_ring)) * dx * dy)   % ≈ 2.351 (staircase undershoot)
print(pi * (1 - 0.25))              % 2.35619...
```

### Example — C-shape by union plus difference

A C-shape combines two operations: take a rectangle, drill a smaller rectangle out of one side. Composing primitives this way scales to arbitrary complexity without ever leaving element-wise math.

```rustlab
clf;
R_block = rect_mask(X, Y, -0.8, -0.6, 1.6, 1.2);
R_bite  = rect_mask(X, Y, -0.4, -0.3, 1.2, 0.6);
C_shape = R_block .* (1 - R_bite);
imagesc(C_shape, "viridis");
title("C-shape: R_block .* (1 - R_bite)")
```

### Example — Two overlapping shapes as integer-coded regions

To visualise multiple regions in one image, encode each region with a distinct integer ID. The rule "each region gets its own integer" generalises directly to the material-map idiom in the next section. Pick a rect and a disk that overlap but neither contains the other, so all three derived regions have visible area:

```rustlab
clf;
R = rect_mask(X, Y, -0.6, -0.6, 1.2, 0.8);
D = disk_mask(X, Y,  0.0,  0.0, 0.5);

both    = R .* D;
r_only  = R .* (1 - D);
d_only  = D .* (1 - R);

% 0 = outside both, 1 = R only, 2 = D only, 3 = R ∩ D
regions = 1 * r_only + 2 * d_only + 3 * both;
imagesc(regions, "viridis");
title("Region IDs: 0 outside, 1 = R only, 2 = D only, 3 = R ∩ D")
```

```rustlab
print(sum(sum(r_only)) * dx * dy)   % rect minus the disk overlap   ≈ 0.380
print(sum(sum(d_only)) * dx * dy)   % disk minus the rect overlap   ≈ 0.201
print(sum(sum(both))   * dx * dy)   % the lens-shaped intersection  ≈ 0.583
```

## From Masks to Material Maps

### Theory

A *material map* is a dense scalar array — one number per grid cell — that the solver indexes when assembling its stencil. For electrostatics that array is $\varepsilon_r(i,j)$; for magnetostatics it's $\mu_r(i,j)$; for full-wave it's a triple $(\varepsilon_r, \mu_r, \sigma)$.

There are two equivalent ways to build it from masks. The **disjoint-sum** form assumes regions don't overlap (or that the user has already taken differences):

$$\varepsilon_r(i,j) = \sum_k M_k(i,j)\,\varepsilon_{r,k} + M_{\rm bg}(i,j)\,\varepsilon_{r,\rm bg}, \qquad M_{\rm bg} = 1 - \bigvee_k M_k.$$

The **layered overwrite** form lets later layers replace earlier ones — the canonical idiom is

$$\varepsilon_r \leftarrow \varepsilon_r\cdot(1 - M_{\rm layer}) + \varepsilon_{r,\rm layer}\cdot M_{\rm layer},$$

applied in deposition order. This matches how a physical device is built (substrate first, metallisation on top, vias punched through) and removes the bookkeeping needed to keep regions disjoint.

Either way the output is a real-valued `ny × nx` array that drops directly into Lesson 05's variable-coefficient Laplacian, Lesson 10's FDFD Maxwell assembly, and Lesson 11's FDTD update equations.

### Example — Air + FR-4 block + copper disk

A toy device: vacuum background, a rectangular FR-4 substrate ($\varepsilon_r = 4.4$), and a copper disk ($\sigma = 5.8\times10^7$ S/m, treated as a perfect conductor in static problems). Build all three material arrays at once using the layered idiom.

```rustlab
clf;
% Geometry
substrate = rect_mask(X, Y, -1.2, -0.3, 2.4, 0.6);
metal     = disk_mask(X, Y, 0.4, 0.0, 0.25);

% Material parameters (SI; relative units for ε_r and μ_r)
eps_air = 1.0;     mu_air = 1.0;   sig_air = 0.0;
eps_sub = 4.4;     mu_sub = 1.0;   sig_sub = 0.0;
eps_met = 1.0;     mu_met = 1.0;   sig_met = 5.8e7;

% Layered overwrite: start in vacuum, drop the substrate, then the metal.
eps_r =       eps_air * ones(N, N);
eps_r = eps_r .* (1 - substrate) + eps_sub * substrate;
eps_r = eps_r .* (1 - metal)     + eps_met * metal;

mu_r  =        mu_air * ones(N, N);
mu_r  = mu_r  .* (1 - substrate) + mu_sub  * substrate;
mu_r  = mu_r  .* (1 - metal)     + mu_met  * metal;

sigma =       sig_air * ones(N, N);
sigma = sigma .* (1 - substrate) + sig_sub * substrate;
sigma = sigma .* (1 - metal)     + sig_met * metal;

imagesc(eps_r, "viridis");
title("ε_r(x, y): air = 1, FR-4 = 4.4, copper disk overwrites substrate")
```

```rustlab
% Spot-check the three regions by sampling one cell from each.
% Indexing: row = y-index, col = x-index, both 1-based.
% Disk centre (x=0.4, y=0)        → row 100, col 128.
% Substrate-only (x=-1.0, y=0)    → row 100, col  34.
% Air (x=0, y=1.0, above the slab) → row 167, col 100.
print(eps_r(100, 128))      % copper disk cell — overwrote substrate → 1.0
print(eps_r(100,  34))      % substrate cell, away from disk → 4.4
print(eps_r(167, 100))      % air cell, above substrate → 1.0
print(sigma(100, 128))      % copper conductivity → 5.8e7
print(sigma(100,  34))      % substrate (lossless dielectric) → 0
```

The three arrays `eps_r`, `mu_r`, `sigma` are now ready to be passed into any solver from Lesson 05 onward — they share the same shape, the same grid, and the same material assignments. Adding a new region (say, a second metal trace) is one more line: build a mask, overwrite each of the three arrays.

```rustlab
clf;
imagesc(sigma, "viridis");
title("σ(x, y): zero everywhere except the copper disk")
```

## Conformal Area Weighting at Curved Boundaries

### Theory

A binary mask resolves a curved boundary as a staircase: every cell is either fully inside or fully outside, regardless of how much of the cell the shape actually covers. For a smooth interface this introduces an $O(h)$ error in any quantity computed from the mask — capacitance, mode frequency, scattering cross-section — even though the interior of the solver may be $O(h^2)$ accurate. The bulk and the boundary converge at different rates.

The fix is **area-weighted conformal coverage**. For each grid cell, replace the binary indicator with the *fraction* $\alpha(i,j) \in [0,1]$ of that cell's area that lies inside the shape. The cell-averaged material property becomes a linear blend:

$$\bar\varepsilon_r(i,j) = \alpha(i,j)\,\varepsilon_{r,\rm in} + (1-\alpha(i,j))\,\varepsilon_{r,\rm out}.$$

For interfaces normal to a grid axis this is exact; for diagonal interfaces it converges as $O(h^2)$, matching the bulk solver. The fractional-coverage map $\alpha$ is the same data structure as a mask, just with values in $[0, 1]$ instead of $\{0, 1\}$ — every later solver consumes it without modification.

The simplest way to compute $\alpha$ is by **subgrid sampling**: evaluate the indicator at $K \times K$ sub-points per cell and average. This gives an $O(K^{-2})$ approximation to the true coverage with $K^2 \times$ the work of a single rasterization — usually $K = 4$ or $8$ is plenty, and it's a one-time preprocessing cost.

### Example — Subgrid coverage for a unit disk

Build $\alpha(i,j)$ for the unit disk using $K = 8$ sub-samples per cell. Compare the area implied by the staircase mask, the conformal $\alpha$ map, and the analytic value $\pi$.

```rustlab
clf;
D_unit = disk_mask(X, Y, 0.0, 0.0, 1.0);
K      = 8;
alpha  = zeros(N, N);
for di = 1:K
  for dj = 1:K
    % Sub-sample offset within each cell, in (-0.5, 0.5) cell units.
    ox = (dj - 0.5) / K - 0.5;
    oy = (di - 0.5) / K - 0.5;
    Xs = X + ox * dx;
    Ys = Y + oy * dy;
    alpha = alpha + disk_mask(Xs, Ys, 0.0, 0.0, 1.0);
  end
end
alpha = alpha / (K * K);
imagesc(alpha, "viridis");
title("Conformal α(x, y) for unit disk (K = 8 subsamples)")
```

```rustlab
A_stair = sum(sum(D_unit)) * dx * dy;    % from the binary mask
A_conf  = sum(sum(alpha))  * dx * dy;    % from the α map
A_true  = pi;                             % analytic
print(A_stair)                            % ≈ 3.135  — staircase overshoot
print(A_conf)                             % ≈ 3.1417 — conformal, far closer
print(A_true)                             % 3.14159...
print(abs(A_stair - A_true) / A_true)     % staircase relative error ≈ 2e-3
print(abs(A_conf  - A_true) / A_true)     % conformal relative error ≈ 2e-5
```

The conformal error on this single grid is already two orders of magnitude smaller. A grid-refinement sweep (Exercise 4) shows the staircase error decays as $O(h)$ while the conformal error decays as $O(h^2)$ — exactly the rate every interior stencil in this curriculum aspires to.

### Example — Where the correction matters

The difference $\alpha - M$ is supported only on the rim of the disk — the cells the boundary passes through. Visualising it shows exactly where the staircase mask is wrong:

```rustlab
clf;
delta = alpha - D_unit;
imagesc(delta, "viridis");
title("α - M: nonzero only on the disk's rim")
```

For a shape with no curved boundaries (a rectangle aligned to the axes, say), $\alpha = M$ everywhere — there is nothing to correct. The conformal pass is purely a curved-boundary fix.

## Standalone Scripts

| Script | What it builds |
|---|---|
| `shape_rasterization.r` | One mask of each kind (rect, disk, polygon); area sanity checks |
| `boolean_regions.r` | Annulus by difference, C-shape, integer-coded two-shape regions |
| `material_map_2d.r` | Air + FR-4 block + copper disk → synchronized $\varepsilon_r$, $\mu_r$, $\sigma$ |
| `conformal_disk.r` | Subgrid $\alpha$ map for a unit disk; staircase vs conformal area error |

Run all four with `make lesson-04`, or one at a time via `rustlab run lessons/04-geometry-and-material-maps/<name>.r`. Each writes SVGs next to itself; artefacts are gitignored.

## Expected Numerical Outputs Summary

| Variable | Expected Value |
|---|---|
| `size(X)` | `[200, 200]` |
| `dx` | $\approx 0.01508$ m |
| Rectangle area | $\approx 0.60$ m² |
| Disk area (staircase) | $\approx 3.135$ m² (≈ 0.2 % over $\pi$) |
| Annulus area (staircase) | $\approx 2.351$ m² (analytic $\pi(1 - 0.25) = 2.356$) |
| `eps_r` in copper cell | $1.0$ (metal overwrote substrate) |
| `eps_r` in substrate cell | $4.4$ |
| `sigma` in copper cell | $5.8 \times 10^7$ S/m |
| Disk area (conformal, $K=8$) | $\approx 3.1414$ (≈ $10^{-5}$ relative error) |
| Conformal-vs-staircase error ratio | $\approx 100\times$ better |

## Exercises

1. **Star polygon.** Build a 5-pointed star by listing 10 vertices that alternate between an outer radius $R = 1$ and an inner radius $r = 0.4$ at angles $\theta_k = 2\pi k / 10$. Pass the result to `polygon_mask` and confirm the rasterized area is close to the analytic value $5 r R \sin(2\pi/10)$.
2. **Pac-Man via subtraction.** Take a unit disk centred at the origin and remove a triangular "mouth" using `polygon_mask`. Verify that the resulting area is the disk area minus the triangle area, up to staircase error.
3. **Three-material map.** Extend the air / FR-4 / copper example to a four-region device: add a second dielectric ($\varepsilon_r = 11.7$, silicon) somewhere in the substrate. Use the layered idiom and verify by sampling one cell from each region.
4. **Convergence study.** Repeat the unit-disk area calculation at $N \in \{50, 100, 200, 400\}$. Plot the staircase error and the conformal ($K = 8$) error on a log-log plot and fit slopes; verify that the staircase slope is $\approx -1$ and the conformal slope is $\approx -2$.
5. **Anisotropic material map.** A diagonal anisotropic dielectric is described by two arrays $\varepsilon_{r,xx}(x,y)$ and $\varepsilon_{r,yy}(x,y)$ rather than one. Build a device whose substrate has $\varepsilon_{r,xx} = 4.4$ and $\varepsilon_{r,yy} = 6.0$ (a uniaxial liquid-crystal model) and confirm both maps are nonzero only inside the substrate region.

## What's next

Lesson 05 is the first numerical PDE: solve $\nabla\cdot(\varepsilon\nabla V) = -\rho$ on a grid with mixed Dirichlet/Neumann boundaries, using the variable-coefficient Laplacian builder `laplacian_eps_2d`. The $\varepsilon$ map it consumes is exactly the one we just built. Every static, frequency-domain, and time-domain solver from Lesson 05 onward is a different operator on top of the same material-map data structure — Lesson 04 is the last lesson where the geometry and the physics can be treated separately.
