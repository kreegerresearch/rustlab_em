# Lesson 01: Vector Calculus & Fields

Maxwell's equations are statements about $\nabla$, $\nabla\cdot$, and $\nabla\times$. Before any physics, we need to compute these operators on grids and read meaning from the output. This lesson is pure mathematical machinery — gradient, divergence, curl on a 2-D grid, plus the divergence and Stokes' theorems verified numerically.

## Learning Objectives

- Compute gradient, divergence, and curl on 2D/3D uniform grids via central differences
- Interpret $\nabla f$, $\nabla\cdot\vec{F}$, $\nabla\times\vec{F}$ as slopes, sources/sinks, and rotation
- Verify the divergence theorem and Stokes' theorem numerically on simple test fields
- Recognize the geometric content of flux and circulation

## Background

Multivariable calculus: partial derivatives, line integrals, surface integrals. No prior physics assumed. Every later lesson assumes you can compute these operators on a grid.

## The Differential Operators

Three first-order differential operators generate all of vector calculus. Each takes a field on the left and returns a field on the right; the *domain* line records what kind. This section is pure reference — formal definitions, no computation. Every later section pairs `### Theory` (the math for one specific concept) with `### Example — <descriptor>` (a rustlab block computing it).

### 1. The Gradient Operator ($\nabla f$)

**Domain:** Scalar Field $\to$ Vector Field.

**Definition:** Represents the directional derivative that points in the direction of the greatest rate of increase of the scalar field.

**Mathematical Form (Cartesian):**

$$\nabla f = \frac{\partial f}{\partial x}\,\mathbf{i} + \frac{\partial f}{\partial y}\,\mathbf{j} + \frac{\partial f}{\partial z}\,\mathbf{k}$$

### 2. The Divergence Operator ($\nabla \cdot \mathbf{A}$)

**Domain:** Vector Field $\to$ Scalar Field.

**Definition:** Measures the net outward flux per unit volume at a point. Positive divergence marks a *source*; negative, a *sink*; zero, a *solenoidal* (incompressible) region.

**Mathematical Form (Cartesian):**

$$\nabla \cdot \mathbf{A} = \frac{\partial A_x}{\partial x} + \frac{\partial A_y}{\partial y} + \frac{\partial A_z}{\partial z}$$

### 3. The Curl Operator ($\nabla \times \mathbf{A}$)

**Domain:** Vector Field $\to$ Vector Field.

**Definition:** Measures the infinitesimal circulation of a vector field. It represents the rotation of the field at a given point.

**Mathematical Form (Cartesian):**

$$\nabla \times \mathbf{A} = \left( \frac{\partial A_z}{\partial y} - \frac{\partial A_y}{\partial z} \right) \mathbf{i} + \left( \frac{\partial A_x}{\partial z} - \frac{\partial A_z}{\partial x} \right) \mathbf{j} + \left( \frac{\partial A_y}{\partial x} - \frac{\partial A_x}{\partial y} \right) \mathbf{k}$$

In two dimensions where $\mathbf{A}$ has no $z$-component and no $z$-dependence, the $x$- and $y$-components vanish; only the $z$-component survives:

$$(\nabla\times\mathbf{A})_z = \frac{\partial A_y}{\partial x} - \frac{\partial A_x}{\partial y}.$$

## Setting Up the Grid

### Theory

Rustlab stores 2-D arrays in `[rows, cols]` = `[y, x]` order. `meshgrid(xs, ys)` returns matrices $X$ and $Y$ where $X(i, j) = xs(j)$ and $Y(i, j) = ys(i)$; every differential operator inherits this convention. Pick $\Delta x = \Delta y = 0.2$ on $[-2, 2]^2$ — a 21×21 grid that resolves a unit-width Gaussian comfortably without slowing the blocks below.

### Example — Build a 21×21 mesh

```rustlab
dx = 0.2;
dy = 0.2;
xs = -2:dx:2;
ys = -2:dy:2;
[X, Y] = meshgrid(xs, ys);
print(size(X))           % → [21, 21]
```

The center $(x, y) = (0, 0)$ is at index $(11, 11)$; the corner $(2, 2)$ is at $(21, 21)$.

## Gradient on a Grid

### Theory

Define $f(x, y) = \exp(-r^2/\sigma^2)$ with $\sigma = 1$. The analytic gradient is

$$\nabla f = -\frac{2}{\sigma^2}(x, y)\,f(x, y),$$

which vanishes at the peak ($r = 0$) and at large $r$, and peaks in magnitude on the inflection ring $r = \sigma/\sqrt{2} \approx 0.707$. Below we compute it numerically on the 21×21 grid and compare to these analytic landmarks.

### Example — Numerical gradient of a Gaussian bump

```rustlab
sigma = 1.0;
f = exp(-(X .^ 2 + Y .^ 2) / (sigma * sigma));
[fx, fy] = gradient(f, dx, dy);

print(fx(11, 11))        % ≈ 0    (center)
print(fy(11, 11))        % ≈ 0
print(fx(11, 15))        % ≈ -0.824 at (x=0.8, y=0)  (analytic: -0.844; ~2% stencil error at dx=0.2)
```

### Example — Gradient arrows on $f$ contours

Because $\nabla f$ is perpendicular to level sets, the arrows cross contours at right angles and point *uphill* toward the peak.

```rustlab
clf;
hold on;
contour(X, Y, f, 10, "k");
quiver(X, Y, fx, fy, "Gaussian f(x,y) with gradient arrows");
hold off;
```

### Example — Magnitude $|\nabla f|$ heatmap

The magnitude is largest on the inflection ring at $r = \sigma/\sqrt{2}$.

```rustlab
clf;
fmag = sqrt(fx .* fx + fy .* fy);
imagesc(fmag, "viridis");
title("|∇f|  —  peaks at r = σ/√2")
```

## Divergence on a Grid

### Theory

For $\vec F = (x, y)$, the analytic divergence is $\partial_x x + \partial_y y = 2$ — a uniform source density filling all space. Positive everywhere means field lines *begin* at every point. In Lesson 03 we identify $\nabla\cdot\vec E = \rho/\varepsilon_0$ and see that electric field lines begin and end only on charges.

### Example — Radial field $\vec F = (x, y)$ and its divergence

```rustlab
Ux = X;
Uy = Y;
divU = divergence(Ux, Uy, dx, dy);

print(divU(11, 11))      % ≈ 2  (interior)
print(divU(1, 1))        % ≈ 2  (boundary — one-sided stencil is exact for linear fields)
```

```rustlab
clf;
quiver(X, Y, Ux, Uy, "Radial field F = (x, y)")
```

```rustlab
clf;
imagesc(divU, "viridis");
title("∇·F for F = (x, y)  —  uniformly = 2")
```

## Curl on a Grid

### Theory

For $\vec F = (-y, x)$, the 2-D scalar curl is $\partial_x x - \partial_y(-y) = 1 + 1 = 2$. Every infinitesimal paddle wheel spins counterclockwise with angular velocity 1.

Drop a tiny paddle wheel at a point; the value of $\nabla\times\vec F$ there is twice the angular velocity the wheel picks up. Where $\nabla\times\vec F = 0$ the field is *irrotational* — the wheel translates without spinning. Later, $\nabla\times\vec E = -\partial\vec B/\partial t$ (Faraday) and $\nabla\times\vec B = \mu_0\vec J + \mu_0\varepsilon_0\,\partial\vec E/\partial t$ (Ampère–Maxwell) are the two most productive equations in all of physics.

### Example — Rotational field $\vec F = (-y, x)$ and its curl

```rustlab
Vx = -Y;
Vy = X;
divV  = divergence(Vx, Vy, dx, dy);
curlV = curl(Vx, Vy, dx, dy);

print(divV(11, 11))      % ≈ 0  (solenoidal)
print(curlV(11, 11))     % ≈ 2  (uniform rotation)
```

```rustlab
clf;
quiver(X, Y, Vx, Vy, "F = (-y, x)  —  pure rotation")
```

```rustlab
clf;
imagesc(curlV, "viridis");
title("(∇×F)_z for F = (-y, x)  —  uniformly = 2")
```

The two quivers (this one and the radial one above) look qualitatively similar — arrow length growing with distance — but the operators tell them apart immediately: radial is pure source, rotational is pure rotation.

## The Laplacian as a Composition

### Theory

Sanity check that the operators chain. For $V = x^2 + y^2$, $\nabla^2 V = \nabla\cdot(\nabla V) = 4$ everywhere. This is exactly the Laplacian operator that shows up in Poisson's equation $\nabla^2 V = -\rho/\varepsilon_0$ (Lesson 05) and the wave equation $\nabla^2\vec E = \mu_0\varepsilon_0\,\partial^2\vec E/\partial t^2$ (Lesson 09).

### Example — $\nabla^2(x^2 + y^2) = 4$

```rustlab
V = X .^ 2 + Y .^ 2;
[Vx2, Vy2] = gradient(V, dx, dy);
laplV = divergence(Vx2, Vy2, dx, dy);

print(laplV(11, 11))     % ≈ 4
```

## The Divergence Theorem

### Theory

For any nice region $V$ bounded by a closed surface $\partial V$,

$$\boxed{\oint_{\partial V}\vec F\cdot d\vec A = \int_V \nabla\cdot\vec F\, dV.}$$

*Total flux through the boundary equals the total source strength inside.* Coulomb's law, Gauss's law, and every charge-conservation statement in EM are instances of this. We do not verify it numerically here — Lesson 03 will, on a physical $\vec E$ field — but Exercise 2 below is the natural warm-up.

## Stokes' Theorem

### Theory

For any nice surface $S$ bounded by a closed curve $C$,

$$\boxed{\oint_C \vec F\cdot d\vec\ell = \int_S (\nabla\times\vec F)\cdot d\vec A.}$$

*Circulation around the loop equals total rotation through the enclosed surface.* Ampère's law and Faraday's law both have this form.

For $\vec F = (-y, x)$ we showed $(\nabla\times\vec F)_z = 2$. Pick the square $[-1, 1]^2$: enclosed area is $4$, so the right-hand side is $2 \cdot 4 = 8$. Below we compute both sides numerically and check they agree.

### Example — Line integral around the unit square

Compute the circulation edge by edge with `trapz`, counterclockwise.

```rustlab
a = 1.0;
N = 201;
xs_edge = linspace(-a, a, N);
unit    = ones(N);

% Bottom (y = -a):  F·dℓ = F_x dx = +a dx
I_bot = trapz(xs_edge, a * unit);

% Right  (x = +a):  F·dℓ = F_y dy = +a dy
I_rht = trapz(xs_edge, a * unit);

% Top    (y = +a), traversed right→left:  F_x = -a, flip sign for orientation
I_top = -trapz(xs_edge, -a * unit);

% Left   (x = -a), traversed top→bottom:  F_y = -a, flip sign for orientation
I_lft = -trapz(xs_edge, -a * unit);

circulation = I_bot + I_rht + I_top + I_lft;
print(circulation)       % ≈ 8
```

### Example — Surface integral of curl over the same square

Compute curl on a 41×41 grid over the same square and integrate by 2-D trapezoidal.

```rustlab
M = 41;
xs_grid = linspace(-a, a, M);
ys_grid = linspace(-a, a, M);
[Xs, Ys] = meshgrid(xs_grid, ys_grid);
curlF   = curl(-Ys, Xs, 2 * a / (M - 1), 2 * a / (M - 1));

row_int = zeros(M);
for i = 1:M
  row_int(i) = trapz(xs_grid, curlF(i, :));
end
surface_integral = trapz(ys_grid, row_int);
print(surface_integral)  % ≈ 8
```

Both expressions for the same physical quantity agree to within sub-percent discretization error — a direct numerical check of Stokes' theorem.

## Numerical Grid Convention

Rustlab's `gradient`, `divergence`, and `curl` use a 2nd-order central-difference stencil

$$\frac{\partial f}{\partial x}\bigg|_{i,j} \approx \frac{f_{i,\,j+1} - f_{i,\,j-1}}{2\,\Delta x}$$

in interior cells and a 2nd-order one-sided stencil at boundary cells, so the output keeps the input shape and stays accurate at the edges. Each axis must have length $\geq 3$. See `../rustlab/docs/quickref.md` for the full API.

## Standalone Scripts

For shell-based experimentation, three rustlab scripts in this directory reproduce the demos above as standalone programs:

| Script | What it computes |
|---|---|
| `gradient_field.rlab` | Gaussian bump gradient with quiver overlay; checks numerical vs analytic |
| `divergence_curl.rlab` | Radial and rotational fields side by side |
| `stokes_demo.rlab` | Square-loop circulation vs surface-integrated curl |

Run all three with `make lesson-01` from the repo root (or `rustlab run lessons/01-vector-calculus-and-fields/<name>.rlab` for one). Each writes SVGs to `outputs/` (gitignored).

## Expected Numerical Outputs Summary

| Variable | Expected Value |
|---|---|
| `size(X)` | `[21, 21]` |
| `fx(11, 11)` | ≈ 0 |
| `fy(11, 11)` | ≈ 0 |
| `fx(11, 15)` | ≈ −0.824 (analytic −0.844; ~2% discretization) |
| `divU(11, 11)` | ≈ 2 |
| `divU(1, 1)` | ≈ 2 |
| `divV(11, 11)` | ≈ 0 |
| `curlV(11, 11)` | ≈ 2 |
| `laplV(11, 11)` | ≈ 4 |
| `circulation` | ≈ 8 |
| `surface_integral` | ≈ 8 |

## Exercises

1. **Analytic gradient check.** In `gradient_field.rlab`, compute the analytic $\nabla f = -(2/\sigma^2)(x, y)\,f$ at every grid point and plot the pointwise error $|\nabla f_{\rm num} - \nabla f_{\rm ana}|$ as a heatmap. Where is the error largest? Why?
2. **Divergence theorem on the Gaussian.** Integrate $\nabla\cdot(\nabla f) = \nabla^2 f$ over the $[-2, 2]^2$ domain (2-D trapezoidal) and compare to the boundary flux $\oint_{\partial\Omega}\nabla f\cdot d\vec A$ via line integrals along the four edges.
3. **Saddle field.** Replace the rotational field in `divergence_curl.rlab` with $\vec F = (x, -y)$. Predict the divergence and curl analytically, then verify numerically.
4. **Loop shape independence.** In `stokes_demo.rlab`, swap the square for a circular loop of the same enclosed area and re-run. The circulation should match.
5. **3D warm-up.** Using `gradient3`, `divergence3`, and `curl3`, verify $\nabla^2 V = 6$ for $V = x^2 + y^2 + z^2$ on a 5×5×5 grid.

## What's next

Lesson 02 introduces the electric field from discrete charges — literally summing the contributions of individual point sources — and uses this lesson's machinery to plot $\vec E$ as a quiver field, draw equipotentials of $V$ as contours, and confirm numerically that $\vec E = -\nabla V$.
