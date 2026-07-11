# rustlab_em — Lesson Plan

A detailed outline of the 14-lesson curriculum. Each entry lists the physics covered, key equations, the rustlab scripts to write, and what students should see in each output. The plan is dense enough that an agent picking up any lesson can implement it directly.

The curriculum targets a "mini Ansys" endpoint: given arbitrary geometry plus material assignments (dielectrics, metals, magnetic materials), produce static fields, frequency-domain responses, time-domain waves, $S$-parameters, and radiation patterns. Lessons 1–3 set up the math and static physics. Lesson 4 introduces the geometry/material-map toolkit that every later solver consumes. Lessons 5–9 cover the physics (statics through Maxwell and waves). Lessons 10–11 are the two full-wave PDE solvers (frequency- and time-domain). Lessons 12–13 add modal analysis, radiation, and $S$-parameter extraction. Lesson 14 is an end-to-end capstone.

---

## Curriculum Overview

| # | Title | Status |
|---|-------|--------|
| 01 | Vector Calculus & Fields | Reviewed |
| 02 | Electrostatics & Coulomb's Law | Reviewed |
| 03 | Gauss's Law & Electric Potential | Reviewed |
| 04 | Geometry & Material Maps | Reviewed |
| 05 | Poisson & Laplace BVP — Dielectrics & Conductors | Reviewed |
| 06 | Magnetostatics & Vector Potential | Reviewed |
| 07 | Faraday's Law & Induction | Reviewed |
| 08 | Maxwell's Equations | Reviewed |
| 09 | EM Wave Equation & Plane Waves | Reviewed |
| 10 | FDFD — Frequency-Domain Maxwell Solver | Reviewed |
| 11 | FDTD — Time-Domain, Dispersive Materials, PML | Reviewed |
| 12 | Waveguides, Cavity Eigenmodes & Radiation | Reviewed |
| 13 | Transmission Lines, S-Parameters & Antennas | Reviewed |
| 14 | Capstone — End-to-End Device Simulation | Reviewed |
| 15 | Lumped Capacitance Extraction | Reviewed |
| 16 | Smith Chart & Impedance Matching | Reviewed |
| 17 | Lumped Inductance Extraction | Reviewed |

**Status vocabulary:** *Planned* → outlined only; *Drafted* → notebook + scripts written and rendering clean; *Reviewed* → drafted **and** numeric-verified against live script output with a prose/equation pass (the 2026-06 review, see `dev/lesson-completion-checklist.md`). All 17 lessons are currently *Reviewed*.

**Build order:** Lessons 01–14 are a strictly sequential arc that ends at the patch-antenna capstone. Lessons 15–17 are **post-capstone applied-engineering extensions** that depend on the existing toolkit but are *not* prerequisites for each other:

- L15 (capacitance extraction) builds on L05 / L13's Laplace solver.
- L16 (Smith chart) builds on L13's transmission-line + S-parameter machinery.
- L17 (inductance extraction) is the magnetic dual of L15, built on L06's vector-potential solver.

Lessons 04 (geometry/material toolkit) and 05 (first numerical PDE) remain the structural pivots of the core arc. Lessons 10 and 11 are the two full-wave solvers; Lesson 14 composes everything.

**Units:** SI throughout. $\varepsilon_0 = 8.854\times10^{-12}$ F/m, $\mu_0 = 4\pi\times10^{-7}$ H/m, $c = 2.998\times10^8$ m/s, $\eta_0 = \sqrt{\mu_0/\varepsilon_0} \approx 376.73\,\Omega$. Scale to dimensionless coordinates inside scripts when it simplifies conditioning; note the scaling in the header.

---

## Lesson 01 — Vector Calculus & Fields

**Motivation:** Maxwell's equations are statements about $\nabla\cdot$, $\nabla\times$, and $\nabla$. Before touching physics, students need to compute these operators on discrete grids and see what they do to real fields.

### Learning Objectives
- Compute gradient, divergence, and curl on 2D/3D uniform grids via central differences
- Interpret $\nabla f$, $\nabla\cdot\vec{F}$, $\nabla\times\vec{F}$ as slopes, sources/sinks, and rotation
- Verify the divergence theorem and Stokes' theorem numerically
- Recognize the geometric content of flux and circulation

### Key Equations
$$\nabla f = \left(\frac{\partial f}{\partial x}, \frac{\partial f}{\partial y}, \frac{\partial f}{\partial z}\right), \quad \nabla\cdot\vec{F} = \frac{\partial F_x}{\partial x} + \frac{\partial F_y}{\partial y} + \frac{\partial F_z}{\partial z}, \quad \nabla\times\vec{F} = \left|\begin{matrix}\hat x & \hat y & \hat z \\ \partial_x & \partial_y & \partial_z \\ F_x & F_y & F_z\end{matrix}\right|$$

$$\oint_{\partial V}\vec{F}\cdot d\vec{A} = \int_V (\nabla\cdot\vec{F})\, dV, \quad \oint_C \vec{F}\cdot d\vec\ell = \int_S (\nabla\times\vec{F})\cdot d\vec A$$

### Scripts
- `gradient_field.rlab` — compute $\nabla f$ for a Gaussian bump; quiver-plot the gradient arrows overlaid on the contour of $f$.
- `divergence_curl.rlab` — two canonical fields side-by-side. Radial $\vec F = (x, y)$ has $\nabla\cdot\vec F = 2$ everywhere and $\nabla\times\vec F = 0$. Rotational $\vec F = (-y, x)$ has $\nabla\cdot\vec F = 0$ and $\nabla\times\vec F = 2\hat z$. Plot both quiver fields alongside `imagesc` of div and curl.
- `stokes_demo.rlab` — pick a vector field with nonzero curl; compute $\oint \vec F\cdot d\vec\ell$ around a square loop via trapezoidal line integral; compare to the surface integral of $\nabla\times\vec F$ inside. Agreement to a few percent at moderate grid resolution.

---

## Lesson 02 — Electrostatics & Coulomb's Law

**Motivation:** The electric field is defined operationally via $\vec F = q\vec E$ and Coulomb's inverse-square law. Before Gauss and Poisson, students should see fields literally added up from charges.

### Learning Objectives
- Compute $\vec E$ from an arbitrary set of point charges by direct superposition
- Draw field lines via streamline integration from start points on a small sphere
- Derive and plot the dipole field in the $r \gg d$ limit
- Recognize how symmetry simplifies field calculation (ring, infinite line)

### Key Equations
$$\vec{E}(\vec r) = \frac{1}{4\pi\varepsilon_0}\sum_i \frac{q_i (\vec r - \vec r_i)}{|\vec r - \vec r_i|^3}$$

Dipole far-field ($r \gg d$), $\vec p = qd\hat z$:
$$\vec E_{\rm dip}(\vec r) = \frac{1}{4\pi\varepsilon_0}\frac{3(\vec p\cdot\hat r)\hat r - \vec p}{r^3}$$

### Scripts
- `point_charges.rlab` — two-charge (dipole) and four-charge (quadrupole) configurations. Quiver plot of $\vec E$ on a 2D slice; `imagesc` of $|\vec E|$ in log scale.
- `dipole_field.rlab` — compare exact superposition of $\pm q$ pair with the far-field expression above; show percent error vs $r/d$.
- `ring_of_charge.rlab` — axial $\vec E$ of a uniformly charged ring by numerical integration; recover the well-known closed-form $E_z(z) = qz/(4\pi\varepsilon_0(z^2+R^2)^{3/2})$.

---

## Lesson 03 — Gauss's Law & Electric Potential

**Motivation:** The integral form reveals symmetry; the differential form $\nabla\cdot\vec E = \rho/\varepsilon_0$ sets up Poisson's equation. The potential $V$ is a scalar that replaces a vector field — a huge simplification.

### Learning Objectives
- State Gauss's law in both integral and differential forms
- Use symmetry to derive $\vec E$ for spherically, cylindrically, and planar-symmetric charges
- Compute $V(\vec r) = -\int^\vec r \vec E\cdot d\vec\ell$ and recover $\vec E = -\nabla V$ numerically
- Plot equipotential contours alongside field-line streamlines

### Key Equations
$$\oint_{\partial V}\vec E\cdot d\vec A = \frac{Q_{\rm enc}}{\varepsilon_0}, \qquad \nabla\cdot\vec E = \frac{\rho}{\varepsilon_0}$$

$$V(\vec r) = \frac{1}{4\pi\varepsilon_0}\sum_i\frac{q_i}{|\vec r - \vec r_i|}, \qquad \vec E = -\nabla V$$

### Scripts
- `gauss_sphere.rlab` — uniform spherical charge. Plot $E_r(r)$ and $V(r)$ across the surface; verify the linear-inside, $1/r^2$-outside structure.
- `potential_dipole.rlab` — dipole potential $V \propto \cos\theta/r^2$; heatmap plus contour overlay of equipotentials; quiver overlay of $-\nabla V$.
- `capacitor_1d.rlab` — 1D parallel-plate capacitor from Gauss's law; uniform $\vec E$ between plates, zero outside; relate to capacitance $C = \varepsilon_0 A/d$.

---

## Lesson 04 — Geometry & Material Maps

**Motivation:** Every later solver — Poisson, FDFD, FDTD — consumes spatial arrays of $\varepsilon(x,y,z)$, $\mu(x,y,z)$, $\sigma(x,y,z)$ that describe the problem. This lesson is the CAD/preprocessor layer: how to turn a drawing of a device into those arrays. Treating it as a first-class topic is what lets later lessons focus on physics instead of masking logic.

### Learning Objectives
- Rasterize geometric primitives (rectangle, disk, polygon, half-space) into boolean masks on a uniform grid
- Compose shapes via boolean set operations (union, intersection, difference) to build complex regions
- Assign material properties ($\varepsilon_r$, $\mu_r$, $\sigma$) per region to produce spatial arrays
- Understand the "staircase error" at curved boundaries and apply a simple conformal area-weighted correction to the $\varepsilon$ map
- Extend cleanly to 3D via `Tensor3` material arrays

### Key Concepts

A **region mask** is a boolean array $M(i,j)$ indicating which grid cells belong to a geometric primitive. Boolean ops compose complex regions:

- Union: $M_A \lor M_B$
- Intersection: $M_A \land M_B$
- Difference: $M_A \land \lnot M_B$

A **material map** is a dense scalar array derived from the masks:
$$\varepsilon_r(i,j) = \sum_k M_k(i,j)\cdot \varepsilon_{r,k} + M_{\rm bg}(i,j)\cdot \varepsilon_{r,\rm bg}$$
where $M_{\rm bg} = \lnot\bigvee_k M_k$ is the background and the sum is disjoint.

**Staircase vs conformal:** a straight rasterization assigns each cell to one material. A **conformal area-weighted** correction computes the *fraction* of each cell covered by a primitive and blends materials proportionally. For interfaces normal to a grid axis this is nearly exact; for diagonal interfaces it still beats pure staircase.

### Scripts

- `shape_rasterization.rlab` — Build `rect_mask(X, Y, x0, y0, w, h)`, `disk_mask(X, Y, xc, yc, r)`, `polygon_mask(X, Y, verts)` as helper functions (inline, since they may not be in upstream rustlab yet). Display each as an `imagesc` to confirm the boundary placement.
- `boolean_regions.rlab` — Compose three primitives with union, intersection, and difference to build a C-shape, an annulus, and a "Pac-Man" region. Plot all three.
- `material_map_2d.rlab` — Take a configuration (air background, a rectangular dielectric block with $\varepsilon_r = 4.4$, a metallic disk with $\sigma = 5.8\times10^7$) and produce three synchronized arrays `eps`, `mu`, `sigma`. `imagesc` each with a discrete colormap.
- `conformal_disk.rlab` — Compare staircase vs area-weighted $\varepsilon$ map for a dielectric disk. Plot the difference. For a quantitative check, solve the disk's electrostatic capacitance via Lesson 05's solver using both maps and compare to the analytic coaxial answer — the conformal version converges faster with grid resolution.

### What Students Learn

By the end, students can take a "drawing" — a list of primitives with materials — and produce the arrays needed by any grid-based solver downstream. The lesson also teaches *why* solver accuracy at curved boundaries is a separate concern from solver accuracy in the bulk.

---

## Lesson 05 — Poisson & Laplace — Boundary Value Problems

**Motivation:** Real electrostatics problems do not have analytic solutions. The finite-difference discretization of the Poisson equation on a grid, combined with fixed-potential boundary conditions and a material map from Lesson 04, is the bread-and-butter of numerical EM.

### Learning Objectives
- Derive the 5-point stencil for the 2D Laplacian in vacuum and the variable-coefficient stencil for $\nabla\!\cdot\!(\varepsilon\nabla V)$
- Set up and solve Laplace/Poisson via iterative relaxation (Jacobi, Gauss-Seidel, SOR)
- Set up the same problem as a sparse linear system $A\vec v = \vec b$ and solve with `spsolve`
- Handle Dirichlet and Neumann boundary conditions on rectangular domains
- Recognize the field singularity at sharp conductor corners
- Solve a mixed-dielectric problem with a piecewise-constant $\varepsilon(x,y)$

### Key Equations

5-point stencil on a uniform grid $h$ (vacuum):
$$\nabla^2 V_{i,j} \approx \frac{V_{i+1,j} + V_{i-1,j} + V_{i,j+1} + V_{i,j-1} - 4V_{i,j}}{h^2} = -\frac{\rho_{i,j}}{\varepsilon_0}$$

Variable-$\varepsilon$ form (flux-conservative discretization, for $\nabla\!\cdot\!(\varepsilon\nabla V) = -\rho$):
$$\tfrac{1}{h^2}\!\left[\varepsilon_{i+\tfrac12,j}(V_{i+1,j}\!-\!V_{i,j}) - \varepsilon_{i-\tfrac12,j}(V_{i,j}\!-\!V_{i-1,j}) + \varepsilon_{i,j+\tfrac12}(V_{i,j+1}\!-\!V_{i,j}) - \varepsilon_{i,j-\tfrac12}(V_{i,j}\!-\!V_{i,j-1})\right] = -\rho_{i,j}$$

Jacobi update (Laplace, $\rho=0$):
$$V_{i,j}^{(k+1)} = \tfrac{1}{4}(V_{i+1,j}^{(k)} + V_{i-1,j}^{(k)} + V_{i,j+1}^{(k)} + V_{i,j-1}^{(k)})$$

SOR with relaxation $\omega \in (1, 2)$:
$$V_{i,j}^{(k+1)} = (1-\omega)V_{i,j}^{(k)} + \omega V_{i,j}^{\rm GS}$$

### Scripts
- `laplace_2d.rlab` — Laplace's equation on a unit square with $V = \sin(\pi x)$ on the top edge, 0 on the others. Sparse-direct `spsolve` against the analytic separation-of-variables solution.
- `iterative_solvers.rlab` — Same Laplace problem solved by Jacobi, Gauss–Seidel, and SOR; plot residual histories side by side to expose the convergence-rate gap that motivates SOR (and ultimately direct solvers).
- `parallel_plate.rlab` — two conducting plates inside a grounded box; solve Poisson with charge on the plates set via fixed-$V$ boundary. Extract $\vec E = -\nabla V$ and show fringing fields at the plate edges.
- `dielectric_slab.rlab` — parallel-plate capacitor with a dielectric slab ($\varepsilon_r = 4$) filling half the gap. Use the variable-coefficient stencil. Verify the field drop by $\varepsilon_r$ inside the slab and continuity of $D_n$ at the interface; compute $C$ and compare to the analytic series-capacitor result $C = \varepsilon_0 A /(d_1 + d_2/\varepsilon_r)$.
- `corner_singularity.rlab` — L-shaped conductor in a box; log-log fit recovers the $r^{-1/3}$ field exponent at the re-entrant corner.

Coaxial geometry is intentionally deferred to Lesson 13's `coax_impedance.rlab`, where the same 2D Laplace solve produces $C'$ and $Z_0$ alongside the magnetostatic counterpart.

---

## Lesson 06 — Magnetostatics & Vector Potential

**Motivation:** Switching from static charges to steady currents. Biot-Savart is the magnetic analogue of Coulomb superposition. But just as Poisson replaced Coulomb summation for complex geometries, the vector-potential BVP $\nabla^2\vec{A} = -\mu_0\vec{J}$ replaces Biot-Savart when materials (iron cores, permeable shells) or complex wire shapes make the integral impractical.

### Learning Objectives
- Integrate the Biot-Savart law numerically over an arbitrary current path
- Use Ampère's law to derive $\vec B$ for wire/solenoid/toroid geometries
- Compute and plot the field of a Helmholtz coil pair; explore uniformity
- Solve the magnetic vector-potential BVP $\nabla^2\vec{A} = -\mu_0\vec{J}$ on a grid and recover $\vec B = \nabla\times\vec A$
- Handle piecewise-constant $\mu_r$ regions (e.g., iron cores) via the variable-coefficient form

### Key Equations
$$\vec B(\vec r) = \frac{\mu_0 I}{4\pi}\int \frac{d\vec\ell\times (\vec r - \vec r')}{|\vec r - \vec r'|^3}$$

$$\oint \vec B\cdot d\vec\ell = \mu_0 I_{\rm enc}$$

Circular loop on-axis: $B_z(z) = \mu_0 I R^2/[2(R^2+z^2)^{3/2}]$. Solenoid: $B_z = \mu_0 n I$ (interior).

Vector-potential Poisson (Coulomb gauge, componentwise):
$$\nabla^2\vec{A} = -\mu_0\vec{J}, \qquad \vec B = \nabla\times\vec A$$

In 2D with $\vec J = J_z(x,y)\hat z$, this reduces to a single scalar Poisson equation for $A_z$ — identical in structure to Lesson 05's solver.

Variable-$\mu$ form (for magnetic materials, in terms of $H$ and the magnetic scalar potential where $\vec J = 0$):
$$\nabla\!\cdot\!(\mu\nabla\phi_m) = 0, \qquad \vec H = -\nabla\phi_m$$

### Scripts
- `biot_savart_loop.rlab` — single circular current loop; 3D $\vec B$ via Biot-Savart on a parameterized path; quiver on the $r$-$z$ half-plane; compare on-axis result to the closed form.
- `solenoid_field.rlab` — stack of loops approximating a finite solenoid; show uniform interior $B_z$ and the fall-off at the ends.
- `helmholtz_pair.rlab` — two coaxial coils at separation $d = R$; compute $B_z$ along the axis; verify $d^2B/dz^2 = 0$ at the midpoint that gives a uniform field sweet spot.
- `vector_potential_2d.rlab` — two infinite parallel wires carrying opposite currents. Solve $\nabla^2 A_z = -\mu_0 J_z$ on a 2D grid (reuse Lesson 05's solver), recover $\vec B = (\partial A_z/\partial y, -\partial A_z/\partial x)$, compare to the analytic Biot-Savart result. Introduces the solver style used in FDFD/FDTD for magnetic materials.
- `iron_core_shielding.rlab` — single current-carrying wire inside a cylindrical iron shell ($\mu_r = 1000$). Solve the variable-$\mu$ form; show field concentration in the iron and dramatic reduction outside. Demonstrates why material maps matter for magnetostatics.

---

## Lesson 07 — Faraday's Law & Induction

**Motivation:** Time-varying $\vec B$ creates $\vec E$. This is the first time dynamics enters the course — and the physical basis for every transformer, motor, and generator.

### Learning Objectives
- State Faraday's law in both integral and differential forms
- Compute induced EMF for simple geometries (loop in a changing B-field, moving conductor)
- Derive self- and mutual inductance as geometric constants
- Simulate eddy currents in a 2D conducting plate via a quasi-static approximation

### Key Equations
$$\oint \vec E\cdot d\vec\ell = -\frac{d\Phi_B}{dt}, \qquad \nabla\times\vec E = -\frac{\partial\vec B}{\partial t}$$

$$L = \frac{\Phi_B}{I}, \qquad M_{12} = \frac{\Phi_2}{I_1}$$

### Scripts
- `induced_emf.rlab` — loop in a sinusoidal $\vec B(t) = B_0\sin(\omega t)\hat z$; plot $\Phi(t)$ and $\varepsilon(t) = -d\Phi/dt$.
- `mutual_inductance.rlab` — two concentric coplanar loops; compute $M$ by integrating the flux of loop 1's field through loop 2.
- `eddy_current_plate.rlab` — thin conducting disk in a time-varying uniform $\vec B$; solve the scalar stream-function Laplace equation for the induced current distribution on a 2D grid.

---

## Lesson 08 — Maxwell's Equations — The Complete Set

**Motivation:** Maxwell's addition of the displacement current $\partial\vec D/\partial t$ to Ampère's law is what makes the whole system self-consistent and predicts electromagnetic waves.

### Learning Objectives
- State the four Maxwell equations in differential and integral form, in vacuum and in matter
- Show why the displacement current is required for charge conservation ($\nabla\cdot\vec J + \partial\rho/\partial t = 0$)
- Derive the Poynting vector $\vec S = \vec E\times\vec H$ as the energy flux density
- Verify energy conservation numerically for a simple circuit or radiating field

### Key Equations
$$\nabla\cdot\vec E = \rho/\varepsilon_0 \qquad \nabla\cdot\vec B = 0$$
$$\nabla\times\vec E = -\partial\vec B/\partial t \qquad \nabla\times\vec B = \mu_0\vec J + \mu_0\varepsilon_0\,\partial\vec E/\partial t$$

Poynting's theorem: $\partial u/\partial t + \nabla\cdot\vec S = -\vec J\cdot\vec E$, where $u = \tfrac12(\varepsilon_0 E^2 + B^2/\mu_0)$.

### Scripts
- `maxwell_consistency.rlab` — build a known $\vec E(\vec r, t)$ and $\vec B(\vec r, t)$ plane-wave solution; verify numerically that all four Maxwell equations are satisfied to machine precision (modulo discretization).
- `charge_conservation.rlab` — current through a capacitor: show $\nabla\cdot\vec J = -\partial\rho/\partial t$ at the plates, and that the displacement current bridges the gap.
- `poynting_flow.rlab` — energy flow in a coaxial cable carrying DC power; compute $\vec S$ in the dielectric between the conductors; verify integrated $\int\vec S\cdot d\vec A = IV$.

---

## Lesson 09 — EM Wave Equation & Plane Waves

**Motivation:** Taking the curl of Faraday and substituting Ampère with no sources yields $\nabla^2\vec E = \mu_0\varepsilon_0\,\partial^2\vec E/\partial t^2$. Light emerges from the equations of electricity and magnetism.

### Learning Objectives
- Derive the wave equation from Maxwell's equations in vacuum and show $c = 1/\sqrt{\mu_0\varepsilon_0}$
- Visualize plane-wave solutions: $\vec E$ perpendicular to $\vec B$ perpendicular to $\vec k$
- Characterize polarization states (linear, circular, elliptical) via the Jones vector
- Build a standing wave at a perfect-conductor boundary

### Key Equations
$$\nabla^2\vec E - \mu_0\varepsilon_0\frac{\partial^2\vec E}{\partial t^2} = 0, \qquad c = 1/\sqrt{\mu_0\varepsilon_0} \approx 2.998\times10^8\,\text{m/s}$$

Plane wave: $\vec E(\vec r,t) = \vec E_0 e^{i(\vec k\cdot\vec r - \omega t)}$ with $\omega = c|\vec k|$, $\vec B = \hat k\times\vec E/c$.

### Scripts
- `plane_wave.rlab` — a single plane wave propagating along $+\hat x$; plot $E_y(x,t)$ and $B_z(x,t)$ at several time snapshots; verify the perpendicularity and the $E/B = c$ ratio.
- `polarization.rlab` — Jones-vector sweep: linear, right-circular, left-circular, elliptical. Animated tip of $\vec E$ traced on the $y$-$z$ plane.
- `standing_wave.rlab` — plane wave + perfect-conductor reflection; observe $E(x=0,t) = 0$ at all times and the spatial node/antinode pattern.

---

## Lesson 10 — FDFD — Frequency-Domain Maxwell Solver

**Motivation:** For a single-frequency problem — "drive port 1 at 2.4 GHz, measure the reflection and the field pattern" — running FDTD to steady state is wasteful. A frequency-domain discretization turns Maxwell into one complex-valued sparse linear system, handed straight to `spsolve`. This is the method behind much of commercial electromagnetic solving (and most of Ansys HFSS's internal pipeline).

### Learning Objectives
- Derive the time-harmonic Maxwell curl-curl equation from $\partial/\partial t \to -i\omega$
- Discretize the Yee curl operators on a grid and assemble a sparse complex system
- Apply a stretched-coordinate PML (SC-PML) at the domain boundary
- Inject sources: current density $\vec J$, total-field/scattered-field (TF/SF) plane wave
- Solve for the field and extract transmission/reflection coefficients

### Key Equations

Time-harmonic form ($e^{-i\omega t}$ convention):
$$\nabla\times\vec E = i\omega\mu\vec H, \qquad \nabla\times\vec H = -i\omega\varepsilon\vec E + \vec J$$

Eliminate $\vec H$:
$$\nabla\times\!\left(\mu^{-1}\nabla\times\vec E\right) - \omega^2\varepsilon\vec E = i\omega\vec J$$

On a Yee grid, $\nabla\times$ becomes a sparse matrix $C$; the equation becomes
$$\bigl(C^T M_\mu^{-1} C - \omega^2 M_\varepsilon\bigr)\vec e = i\omega\vec j$$
with diagonal material matrices $M_\varepsilon$, $M_\mu$.

Stretched-coordinate PML: replace $\partial/\partial\alpha$ with $(1/s_\alpha)\partial/\partial\alpha$ where $s_\alpha = \kappa_\alpha + \sigma_\alpha/(i\omega\varepsilon_0)$ inside the PML region. Produces complex-coordinate absorbing layers that work well at all angles.

### Scripts

- `fdfd_1d_layers.rlab` — 1D scalar Helmholtz $(d^2/dx^2 + k^2\varepsilon_r(x))E = -i\omega\mu_0 J$ on a stratified dielectric (air / quarter-wave layer / air); extract transmission $|T|^2$ over a frequency sweep; verify the quarter-wave antireflection minimum vs the analytic thin-film formula.
- `fdfd_2d_tmz.rlab` — 2D TM$_z$ scattering from a dielectric cylinder at one frequency. Complex-valued sparse assembly; `spsolve`; plot $|E_z|$ and the phase. Verify the low-frequency limit against Mie series for a dielectric cylinder.
- `fdfd_pml_demo.rlab` — stretched-coordinate PML vs a hard Dirichlet wall around a point source. Show the standing-wave pattern when reflections dominate and the clean outgoing-wave pattern with PML.
- `fdfd_resonator.rlab` — rectangular 2D cavity with one absorbing port; sweep frequency and find the resonant peaks in the port response. Compare to the analytic cavity modes from Lesson 12.

---

## Lesson 11 — FDTD — Time-Domain, Dispersive Materials, PML

**Motivation:** The Yee algorithm is the default full-wave EM solver used throughout industry and research. In time domain you get broadband results from a single run (via Fourier transform of the response), you naturally handle nonlinearities and pulsed sources, and dispersive materials require only an auxiliary-differential-equation (ADE) update.

### Learning Objectives
- Derive the Yee staggered grid placement of $\vec E$ and $\vec H$
- Implement the leapfrog update equations in 1D, 2D, and 3D
- Treat dispersive materials (Drude metal, Debye water, Lorentz resonator) via ADE
- Inject plane waves cleanly via the total-field/scattered-field (TF/SF) formulation
- Implement a split-field PML and quantify its reflection coefficient
- Recognize the CFL stability limit and the numerical-dispersion error

### Key Equations

1D Yee update (z-directed fields, y-polarized E, in a medium with $\varepsilon(x)$, $\mu(x)$):
$$H_y^{n+\tfrac12}(i+\tfrac12) = H_y^{n-\tfrac12}(i+\tfrac12) + \frac{\Delta t}{\mu(i+\tfrac12)\Delta x}\bigl[E_z^n(i+1) - E_z^n(i)\bigr]$$
$$E_z^{n+1}(i) = E_z^n(i) + \frac{\Delta t}{\varepsilon(i)\Delta x}\bigl[H_y^{n+\tfrac12}(i+\tfrac12) - H_y^{n+\tfrac12}(i-\tfrac12)\bigr]$$

CFL stability: $c\Delta t \le \Delta x / \sqrt d$ in $d$ dimensions.

Drude dispersion: $\varepsilon(\omega) = \varepsilon_\infty - \omega_p^2/(\omega^2 + i\gamma\omega)$. ADE form adds an auxiliary polarization current $\vec{J}_p$ that evolves alongside $\vec E$:
$$\frac{\partial\vec{J}_p}{\partial t} + \gamma\vec{J}_p = \varepsilon_0\omega_p^2\vec E$$

TF/SF injection: define a closed box inside the grid. Inside, fields are the total (incident + scattered). Outside, only the scattered. At the box boundary, add the analytic incident field to the update so the injection is exact.

Split-field PML (Berenger): inside the PML, each field component is split into two, each tied to one spatial direction, with loss applied only to the component whose update derivative is along the PML axis. Reflection coefficient decays as $\propto e^{-\sigma_{\max}\Delta x\,d/(\varepsilon_0 c)}$ where $d$ is the PML depth.

### Scripts

- `fdtd_1d.rlab` — Gaussian pulse launched from the center; propagates in both directions; hit a dielectric slab; measure reflection coefficient and compare to the Fresnel formula.
- `fdtd_2d_scattering.rlab` — TM$_z$ polarization, TF/SF plane-wave source on one side, PEC cylinder in the middle; watch the incident wave, scattered wave, and total field; animated frames.
- `fdtd_dispersive.rlab` — 1D pulse through a thin Drude metal film ($\omega_p$, $\gamma$ for gold); verify the plasma transmission peak above $\omega_p$ and evanescent decay below. ADE update integrated with the normal Yee step.
- `fdtd_tfsf_validation.rlab` — *(shipped)* TF/SF plane-wave injection with an auxiliary 1-D Yee grid that matches the 2-D scheme's numerical dispersion; $|E_z|$ outside the box stays at $\sim 10^{-15}$ (machine zero).
- `fdtd_pml_depth.rlab` — *(shipped)* Bérenger split-field PML on a 2-D vacuum grid; cubic σ profile, depth sweep $d \in \{4, 8, 16\}$ with residual reflection $\sim 0.16 \to 0.07 \to 0.03$ (clear exponential trend, ~ 6 dB per doubling).

---

## Lesson 12 — Waveguides, Cavity Eigenmodes & Radiation

**Motivation:** Two pillars of applied EM: guided propagation in closed structures (microwave engineering) and radiation to infinity (antennas). Numerically, guided modes are a generalized eigenvalue problem on the cross-section; radiation observables are obtained from the near-field via the NF→FF transform so we don't need to fill all of space with grid cells.

### Learning Objectives
- Derive the TE/TM mode equations for a rectangular waveguide and cavity
- Formulate the waveguide cutoff-frequency problem as a 2D generalized eigenvalue problem and solve numerically via `eigs`
- Derive and plot the Hertzian-dipole far-field radiation pattern
- Extend to a half-wave dipole via numerically integrated sinusoidal current
- Implement a near-field-to-far-field (NF→FF) transform that takes tangential fields on a closed surface and produces the 3D radiation pattern

### Key Equations

Rectangular waveguide $a\times b$, TE$_{mn}$:
$$H_z(x, y) = H_0\cos(m\pi x/a)\cos(n\pi y/b), \qquad \omega_c = c\pi\sqrt{(m/a)^2 + (n/b)^2}$$

Numerically, the modes of an arbitrary-cross-section waveguide are the generalized eigenvectors of
$$\bigl(-\nabla_\perp^2\bigr)\phi = k_c^2\phi$$
with Dirichlet (TM) or Neumann (TE) BCs on the metal walls. On a grid this becomes a sparse eigenvalue problem $A\phi = k_c^2\phi$.

Hertzian dipole at origin, current $I_0$, length $d\ell$, at frequency $\omega$, far-field:
$$E_\theta = \frac{i\omega\mu_0 I_0 d\ell}{4\pi r}\sin\theta\,e^{i(kr-\omega t)}, \qquad H_\phi = E_\theta/\eta_0$$

Radiated power: $P = \eta_0|I_0|^2|kd\ell|^2/(12\pi)$.

**NF→FF transform** (Love's equivalence principle): given tangential $\vec E_{\rm tan}$ and $\vec H_{\rm tan}$ on any closed surface $S$ enclosing all sources, the far-field is
$$\vec E_{\rm ff}(\hat r) \propto \int_S\bigl[\hat r\times(\hat n\times\vec E) - \eta_0\hat r\times(\hat r\times(\hat n\times\vec H))\bigr]e^{jk\hat r\cdot\vec r'}\,dS'$$
so a single FDTD or FDFD run in a small box gives the full 3D radiation pattern.

### Scripts

- `waveguide_modes.rlab` — rectangular waveguide eigenvalue problem via 2D Laplacian on an interior grid with Dirichlet BCs, solved as a sparse generalized eigenvalue problem with `eigs`; recover the lowest 4 cutoff frequencies and plot the mode patterns. Extend to an L-shape to show the solver works on non-separable geometries.
- `cavity_resonances.rlab` — 2D rectangular cavity eigenmodes on a grid; compare to the analytic $\omega_{mn} = c\pi\sqrt{(m/a)^2+(n/b)^2}$. Add a small dielectric perturbation and show the frequency shift matches first-order perturbation theory.
- `hertzian_dipole.rlab` — far-field pattern $\sin\theta$; plot as a polar diagram and a 3D torus; compute the total radiated power.
- `half_wave_dipole.rlab` — numerically integrate over a sinusoidal current distribution $I(z) = I_0\cos(kz)$ for $|z| < \lambda/4$; compare the slightly narrower pattern to the Hertzian result.
- `nf2ff_transform.rlab` — *(shipped)* validate Love's equivalence-principle surface integral by populating a cubic Huygens surface with the analytic Hertzian-dipole near field and recovering $\sin\theta$. Lesson 14 reuses the kernel on a real FDTD-generated near field; exercise #5 of L12 asks the student to swap the analytic field for an FDTD run.

---

## Lesson 13 — Transmission Lines, S-Parameters & Antennas

**Motivation:** A 3D field solution frequently reduces to a 1D circuit description with per-unit-length parameters $L'$, $C'$, $R'$, $G'$; the multiport generalization is the $S$-parameter matrix measured by every network analyzer. This lesson closes the loop between Lessons 05–08 (static fields and energy), Lesson 11 (FDTD), and Lesson 12 (radiation) by extracting $Z_0$, $C$, $S$-parameters, and radiation resistance *directly from geometry*.

Four distinct derivations are covered, each checked on its own geometry:

1. **Capacitance from geometry.** $C = Q/V$ is the ratio of two field integrals over the cross-section — reuses Lesson 05's Laplace solver.
2. **Characteristic impedance.** $Z_0 = \sqrt{L'/C'}$ from per-unit-length parameters.
3. **Multiport S-parameters.** Waveport excitation, time-gating, and de-embedding to extract $S_{ij}$ from a single FDTD or FDFD run.
4. **Antenna standing-wave radiation.** A dipole is an open-ended transmission-line stub; integrating the far-field Poynting flux recovers $R_{\rm rad}\approx73.1\,\Omega$ for the half-wave case.

### Learning Objectives

- Extract $C$ and $L$ from 2D Laplace and magnetostatic solutions using both the charge-over-voltage and energy formulations
- Derive $Z_0 = \sqrt{L'/C'}$ and $v = 1/\sqrt{L'C'}$ from per-unit-length parameters
- Derive the telegrapher's equations from a lumped LC cascade and identify wave propagation
- Explain reflection, VSWR, and input impedance on a terminated line
- Extract multiport $S$-parameters from a full-wave simulation via waveport mode matching, time-gating, and de-embedding
- Derive the sinusoidal current distribution on a dipole as a standing wave from end-reflection
- Compute radiation resistance by integrating the Poynting flux and verify $R_{\rm rad}\approx 73.1\,\Omega$

### Key Equations

**Capacitance from geometry:**
$$C = \frac{Q}{V} = \frac{\varepsilon_0\oint_{\partial\Omega_+}\vec E\cdot d\vec A}{\int_-^+ \vec E\cdot d\vec\ell} = \frac{2U_E}{V^2}, \quad U_E = \tfrac12\int \varepsilon_0|\vec E|^2\, dV$$

**Per-unit-length parameters (coax, inner $a$, outer $b$):**
$$C' = \frac{2\pi\varepsilon_0}{\ln(b/a)}, \qquad L' = \frac{\mu_0}{2\pi}\ln(b/a), \qquad Z_0 = \sqrt{\frac{L'}{C'}} = \frac{\eta_0}{2\pi}\ln\!\frac{b}{a}$$

**Parallel-wire line** (radius $a$, center separation $d$):
$$Z_0 = \frac{\eta_0}{\pi}\cosh^{-1}\!\frac{d}{2a} \approx \frac{\eta_0}{\pi}\ln\!\frac{d}{a}\,(\text{for } d\gg a)$$

**Telegrapher's equations:**
$$\frac{\partial V}{\partial z} = -L'\frac{\partial I}{\partial t}, \qquad \frac{\partial I}{\partial z} = -C'\frac{\partial V}{\partial t}$$

**Reflection at a load:**
$$\Gamma = \frac{Z_L - Z_0}{Z_L + Z_0}, \qquad \text{VSWR} = \frac{1+|\Gamma|}{1-|\Gamma|}$$

**S-parameter matrix** (two-port):
$$\begin{pmatrix}b_1\\b_2\end{pmatrix} = \begin{pmatrix}S_{11} & S_{12}\\S_{21} & S_{22}\end{pmatrix}\begin{pmatrix}a_1\\a_2\end{pmatrix}$$
where $a_i$, $b_i$ are the incident and reflected *power-wave* amplitudes at port $i$, normalized to the port's characteristic impedance. Extracted from a time-domain run by mode-filtering the port plane, FFT-ing to the frequency domain, and dividing reflected by incident.

**Dipole current** (open-ended TL stub): $I(z) = I_0\sin[k(L/2 - |z|)]$. For $L = \lambda/2$: $I_0\cos(kz)$.

**Radiation resistance** (half-wave dipole):
$$R_{\rm rad} = \frac{\eta_0}{2\pi}\int_0^\pi\!\frac{\cos^2\!\bigl(\tfrac{\pi}{2}\cos\theta\bigr)}{\sin\theta}\,d\theta \approx 73.13\,\Omega$$

Short dipole: $R_{\rm rad} = 20\pi^2(L/\lambda)^2$.

### Scripts

- `coax_impedance.rlab` — 2D Laplace on the coax cross-section; extract $C'$ via flux method and energy method; sweep $b/a$; verify $Z_0 \approx 60\ln(b/a)\,\Omega$.
- `twin_wire_impedance.rlab` — *(shipped)* pair of conductor disks at $\pm V_0/2$ in vacuum; energy-method $C'$ on a finite-box 2-D Laplace solve; analytic $Z_0 = (\eta_0/\pi)\cosh^{-1}(d/2a)$ sweep over $d/a \in [2, 50]$.
- `telegrapher_propagation.rlab` — 1D staggered leapfrog for $V(i)$, $I(i+\tfrac12)$; pulse propagation at $v = 1/\sqrt{L'C'}$; reflection cases (matched, open, short, $2Z_0$).
- `vswr_standing_wave.rlab` — CW-driven terminated line; measure $|V(z)|$ envelope; extract VSWR; compare to $(1+|\Gamma|)/(1-|\Gamma|)$.
- `s_parameters_tline.rlab` — *(shipped)* 1-D FDTD of a 50→100 Ω step; time-domain peak ratio recovers $|\Gamma| = 1/3$ and $|S_{21}| = 0.943$ to sub-percent; FFT-based extraction reported alongside with a documented few-percent staggered-grid bias.
- `dipole_standing_wave.rlab` — *(shipped)* analytic $I(z) = I_0\sin[k(L/2-|z|)]$ for $L/\lambda \in \{0.1, 0.3, 0.5, 0.7, 1.0\}$; machine-precision $\cos(kz)$ recovery at $L = \lambda/2$; feed-point current $|I(0)|$ vs $L/\lambda$ with null at $L = \lambda$.
- `radiation_resistance.rlab` — *(shipped)* numerical integration of $(\eta_0/2\pi\sin^2(kL/2))\int|F(\theta)|^2\sin\theta\,d\theta$; recovers 73.08 Ω at $L=\lambda/2$ (vs 73.13 Ω analytic) and matches $20\pi^2(L/\lambda)^2$ to sub-percent in the short-dipole limit.

### What Each Derivation Proves

| Derivation | Geometry | Proof |
|---|---|---|
| $Z_0 = (\eta_0/2\pi)\ln(b/a)$ for coax | Annular 2D cross-section | `coax_impedance.rlab` |
| $Z_0 \approx 120\ln(d/a)$ for twin-wire | Pair of disks in 2D | `twin_wire_impedance.rlab` |
| $v = 1/\sqrt{L'C'} = c$ (air) | 1D TL cascade | `telegrapher_propagation.rlab` |
| $\Gamma = (Z_L-Z_0)/(Z_L+Z_0)$, VSWR formula | Terminated 1D line | `vswr_standing_wave.rlab` |
| $S$-parameters from time-gating + FFT | 1D two-section line | `s_parameters_tline.rlab` |
| $I(z) = I_0\sin[k(L/2-\|z\|)]$ | Open-ended 1D stub | `dipole_standing_wave.rlab` |
| $R_{\rm rad}\approx 73.1\,\Omega$ half-wave | 3D far-field sphere | `radiation_resistance.rlab` |

### Prerequisites Satisfied

- Lesson 05 → 2D Laplace solver for cross-section capacitance.
- Lesson 06 → magnetostatics for the inductive side of $Z_0$.
- Lesson 08 → Poynting vector for the radiation-resistance integral.
- Lesson 11 → FDTD machinery, reused for 1D telegrapher propagation and $S$-parameter time-gating.
- Lesson 12 → numerical modes, used here to define waveport excitations.

---

## Lesson 14 — Capstone — End-to-End Device Simulation

**Motivation:** Every prior lesson built one piece of the mini-Ansys pipeline: geometry, materials, solver, post-processing. The capstone runs all of them on a real device from start to finish — a rectangular microstrip-fed patch antenna. This is the same workflow an engineer follows in commercial software, just transparently spelled out.

> **Shipped scope (2026-07):** the published lesson implements this plan's pipeline in **2-D** (geometry → material map → FDTD → probe-trace resonance spectrum). The waveport-$S_{11}$ extraction (step 5) and NF→FF gain pattern (step 6) below remain the documented 3-D production extension — the lesson's *From 2-D to 3-D* section maps each step. The 3-D objectives in this section are the plan's target, not the shipped deliverable.

### Learning Objectives

- Describe a 3D device as a stack of primitives + material assignments (Lesson 04)
- Run full-wave FDTD with a TF/SF source, dispersive material support, and split-field PML (Lesson 11)
- Drive a waveport and extract $S_{11}$ by mode-filtering and time-gating (Lesson 13)
- Apply the NF→FF transform to get the 3D gain pattern (Lesson 12)
- Validate the result against a published design

### Device Under Test

A classical rectangular microstrip patch antenna at 2.45 GHz on FR-4 substrate:

- Ground plane: metal, bottom face
- Substrate: FR-4, $\varepsilon_r = 4.4$, $\tan\delta = 0.02$, thickness $1.6$ mm
- Patch: metal, $\sim 38\times 28$ mm on top surface
- Microstrip feed line: 50 Ω trace (width sized for the substrate) with an inset feed into the patch
- Port: waveport at the far end of the feed line

### Script (single long capstone)

- `patch_antenna.rlab` — the entire pipeline in one script, sectioned clearly:

  1. **Geometry & material map.** Build $\varepsilon_r(x,y,z)$, $\mu_r$, $\sigma$ as `Tensor3` arrays using the Lesson 04 helpers. `imagesc` a horizontal slice through each layer to verify.
  2. **Mesh + CFL time step.** Choose $\Delta = \lambda_{\rm min}/20$ in the substrate; compute $\Delta t$ from CFL.
  3. **Sources & boundary.** TF/SF Gaussian-modulated pulse at the waveport plane, bandwidth covering 1–5 GHz. Split-field PML on all six faces (ground plane handled by extending the metal through the PML).
  4. **Time stepping.** Run until the transient at the waveport decays below a threshold. `imagesc` the field in the substrate at several moments.
  5. **$S_{11}$ extraction.** Record incident and reflected waveforms at the waveport, FFT each, divide. Plot $|S_{11}|$ in dB over 1–5 GHz; identify the resonance and bandwidth.
  6. **NF→FF.** Record tangential $\vec E$, $\vec H$ on a closed surface above the patch during steady state at $f_0 = 2.45$ GHz; integrate to produce the 3D gain pattern. Plot polar cuts and a 3D `surf` of gain.
  7. **Validation.** Compare resonant frequency, $S_{11}$ depth, bandwidth, and gain pattern to the published design and/or a transmission-line-model prediction.

### Optional Extensions

- Swap the patch for a **dual-band design** and verify two resonances appear.
- Load the substrate with a **dispersive model** (Lesson 11) and compare.
- Re-solve the same device with **FDFD** (Lesson 10) at a single frequency and confirm the fields match FDTD's steady-state snapshot.

### What This Demonstrates

Everything the course has built, composed:

| Lesson | Piece used in capstone |
|---|---|
| 04 | Geometry primitives + material-map arrays |
| 05 | (not directly, but the solver architecture is shared) |
| 06 | (not directly, but the vector-potential formulation parallels FDTD $\vec H$ updates) |
| 11 | Core FDTD solver + PML + TF/SF |
| 12 | NF→FF transform for the gain pattern |
| 13 | Waveport excitation, time-gating, $S_{11}$ extraction |

---

## Lesson 15 — Lumped Capacitance Extraction

**Motivation:** Lesson 13 extracted per-unit-length $C'$ from a 2-D transmission-line cross-section. That is the right answer for an *infinite* line, but real circuits have **finite plates with fringing fields**, **multiple conductors that couple capacitively**, and **3-D geometries** (MIM caps, IC bond pads, MEMS structures) where the 2-D approximation breaks down by 10–50 %. This lesson runs the same Laplace solver in two new modes — 2-D capacitance-*matrix* extraction for crosstalk analysis, and 3-D single-conductor extraction for real lumped pF values — and closes the loop between field-solver output and circuit-level $C$.

### Learning Objectives
- Extract a single-conductor lumped capacitance $C$ from a 3-D Laplace solve, via both the energy and the charge (Gauss-integral) methods, and cross-verify
- Quantify the fringing-field correction to the textbook $C = \varepsilon A / d$ for a finite parallel-plate capacitor
- Build the multi-conductor capacitance matrix $C_{ij}$ by solving $N$ Laplace problems with $V_k = 1$ on conductor $k$ and 0 on the rest; reuse a single LU factorisation across all $N$ right-hand sides
- Recognise reciprocity ($C_{ij} = C_{ji}$) and the difference between "Maxwell capacitance" and "mutual capacitance" conventions
- Compute the electrostatic force on a capacitor plate from $F = \tfrac12 V^2\,\partial C/\partial x$ and verify against the parallel-plate analytic result

### Key Equations

**Single-conductor $C$ (charge method).** Surround the high-V conductor with a Gauss surface $S$ in the dielectric:
$$Q = \oint_S \varepsilon\,\vec E\cdot d\vec A, \qquad C = Q / \Delta V.$$

**Single-conductor $C$ (energy method).** With the system at voltage $V$,
$$U_E = \tfrac12 \int_{\Omega}\!\varepsilon |\vec E|^2\, dV, \qquad C = 2U_E / V^2.$$

The two should agree to discretisation precision; energy is usually more accurate at coarse resolution.

**Capacitance matrix.** For $N$ conductors at potentials $V_1, \dots, V_N$ in a single shared dielectric,
$$Q_i = \sum_{j=1}^{N} C_{ij}\,V_j,\qquad C_{ij} = \frac{\partial Q_i}{\partial V_j}\bigg|_{V_k = 0,\,k\neq j}.$$

The "short-circuit" procedure: drive $V_j = 1$ on conductor $j$, hold the rest at 0, solve for $V(\vec r)$, integrate $Q_i = -\oint_{S_i}\!\varepsilon\nabla V\cdot\hat n\,dA$ on each conductor $i$. The full matrix takes $N$ Laplace solves on the **same** $L$ matrix → factor once, back-solve $N$ times.

**Force on a plate.** A virtual-work argument at fixed $V$ gives
$$F = +\tfrac12 V^2 \,\frac{\partial C}{\partial x},$$
attractive between oppositely charged plates. For a parallel-plate of gap $d$ and area $A$, $C = \varepsilon A/d$ so $F = -\tfrac12\varepsilon A V^2 / d^2$ (negative meaning attractive in the $-d$ direction).

**Fringing in a finite parallel-plate.** The ideal capacitance is $C_0 = \varepsilon A/d$; the corrected
$$C \approx C_0 \cdot \left[1 + \frac{d}{\pi L}\bigl(1 + \ln\frac{2\pi L}{d}\bigr)\right]$$
for plates of edge $L\gg d$ (Kirchhoff's classical result). The numerical solve should land within a few percent of this for a moderately wide plate.

### Scripts

- `lumped_C_parallel_plate.rlab` — 3-D Laplace on a box containing two finite square plates separated by air. Extract $C$ via energy and via Gauss-integral on the inner plate surface. Sweep plate side $L/d$ from 5 to 50 to chart the fringing correction; verify the analytic Kirchhoff form for large $L/d$.
- `cap_matrix_microstrip.rlab` — Two coplanar 50 Ω microstrip traces above a ground plane, varying trace-to-trace spacing. Build the 3 × 3 capacitance matrix ($C_{11}$, $C_{22}$, $C_{33}$ for trace1, trace2, ground; off-diagonals for coupling). Use `lu(A)` once and `solve(LU, b_k)` for each $k$; demonstrate the speedup vs three independent `spsolve` calls.
- `cap_matrix_three_trace.rlab` — Three-trace bus over a ground plane; full 4 × 4 capacitance matrix. Verify $C_{ij} = C_{ji}$ to numerical precision and plot the matrix as a heatmap. Convert between the "Maxwell" (short-circuit) and "mutual" (open-circuit) capacitance forms.
- `MIM_capacitor_3d.rlab` — Thin-film metal-insulator-metal capacitor: two parallel rectangular plates separated by a 100 nm dielectric layer ($\varepsilon_r = 25$, high-K). Realistic IC structure; compute $C$ in fF and compare to $\varepsilon_r \varepsilon_0 A/d$.
- `parasitic_bondpad.rlab` — An IC bond pad (square metal patch) over a ground plane through a thick oxide layer. Sweep the oxide thickness and pad size; produce a design-rule curve $C_{\rm pad}(L, t_{\rm ox})$ in fF.
- `tunable_C_force.rlab` — Parallel-plate capacitor with a sweepable gap. For each gap, solve Laplace, extract $C$, compute the electrostatic force on one plate via finite-difference $F = \tfrac12 V^2 \Delta C / \Delta x$. Verify against the analytic $-\tfrac12 \varepsilon A V^2 / d^2$ to sub-percent at large $L/d$, then quantify the fringing-induced deviation at small $L/d$.

### What students learn

By the end, a student can take a multi-conductor geometry — a coupled microstrip bus, a MEMS comb-drive cross-section, an IC bond-pad parasitic — and extract the SPICE-grade capacitance values that circuit simulators consume. The cached-LU pattern (factor once, solve $N$ times) is the workhorse trick of every commercial parasitic-extraction tool.

---

## Lesson 16 — Smith Chart & Impedance Matching

**Motivation:** Every RF and microwave engineer reads impedance matches off a **Smith chart** — the conformal map that turns "translate along a transmission line" into "rotate on a constant-$|\Gamma|$ circle." This lesson treats the chart as a *computation*: build the geometry from scratch, then use it to design real matching networks (lumped L-match, single-stub, double-stub, quarter-wave transformer) and to read $S_{11}$ loci off broadband simulations like the Lesson 14 patch antenna. Connects Lesson 13's $\Gamma$/VSWR algebra to the visual reasoning that drives practical antenna and amplifier design.

### Learning Objectives
- Derive the Smith chart as the bilinear transform $\Gamma = (Z - Z_0) / (Z + Z_0)$ and render the constant-$R$ / constant-$X$ circle families
- Read $Z$, $Y$, $|\Gamma|$, VSWR off a chart position; convert smoothly between impedance and admittance ("flipping" through the chart centre)
- Trace $\Gamma_{\rm in}(d)$ along a lossless TL — the canonical "constant-$|\Gamma|$ rotation"
- Design **L-match** networks (series-then-shunt or shunt-then-series) by traversing constant-resistance and constant-conductance circles
- Design **single-stub** matches: find the shunt-stub length $\ell$ and position $d$ that route an arbitrary load to the chart centre
- Design **double-stub** matches with fixed spacing $d_{12}$; recognise the forbidden region where double-stub matching fails
- Design a **quarter-wave transformer**: $Z_{0,T} = \sqrt{Z_0 Z_L}$ for real loads; visualise the impedance jump on the chart
- Overlay a measured / simulated $S_{11}(f)$ locus (the L14 patch antenna) and read off resonant frequency, bandwidth, and matching-network target

### Key Equations

**Bilinear map.** With normalised impedance $z = Z/Z_0$,
$$\Gamma = \frac{z - 1}{z + 1}, \qquad z = \frac{1 + \Gamma}{1 - \Gamma}.$$

**Constant-resistance circles** (real $r$): centre $(r/(r+1), 0)$, radius $1/(r+1)$.
**Constant-reactance circles** (real $x$): centre $(1, 1/x)$, radius $1/|x|$. Only the portion inside the unit disk $|\Gamma|=1$ is on the chart.

**TL transformation.** A lossless line of length $d$ rotates $\Gamma$ clockwise by $2\beta d$ (towards generator):
$$\Gamma(d) = \Gamma_L\,e^{-2j\beta d}.$$

**VSWR.** $\text{VSWR} = (1 + |\Gamma|)/(1 - |\Gamma|)$ — a single constant-$|\Gamma|$ circle.

**Single-stub match (shunt short-circuited stub).** Given load admittance $y_L$, move along the TL to the point $d$ where $\text{Re}(y(d)) = 1$ (lands on the unit-conductance circle on the admittance chart); the residual susceptance is cancelled by a shunt stub of length $\ell$ chosen from
$$\tan(\beta\ell) = -1/B_d \quad\text{(short-circuited stub)}.$$

**Double-stub match.** Two shunt stubs separated by fixed $d_{12}$ (typically $\lambda/8$ or $3\lambda/8$). Solvable when the load admittance falls outside the *forbidden* circle of radius $\sin^2(\beta d_{12})$ centred at the origin of the rotated admittance chart.

**Quarter-wave transformer.** A line of length $\lambda_0/4$ and characteristic impedance $Z_{0,T} = \sqrt{Z_0 Z_L}$ matches a *real* load $Z_L$ to $Z_0$ at the design frequency. Bandwidth scales with $1/|Z_L - Z_0|$.

### Scripts

- `smith_chart.rlab` — Reusable helper. Draws the chart background (constant-$r$ circles for $r \in \{0.2, 0.5, 1, 2, 5\}$, constant-$x$ circles for $x \in \{\pm 0.2, \pm 0.5, \pm 1, \pm 2, \pm 5\}$, the outer $|\Gamma| = 1$ unit circle, real-axis baseline, and chart annotations) using `axis("equal")` to keep the circles round. Subsequent scripts source this and overlay markers / trajectories.
- `tline_transformation.rlab` — Sweep distance $d/\lambda$ for several load impedances ($Z_L = 25, 50, 100, 100j$); plot the $\Gamma(d)$ trajectories as constant-$|\Gamma|$ circles. Animate one example with `frame()` / `saveanim()`.
- `l_match_synthesis.rlab` — Given a complex load $Z_L = 30 + 50j$, design both possible L-match topologies (series-L + shunt-C and shunt-C + series-L) to match to 50 Ω at 1 GHz. Plot the chart trajectories; print component values.
- `single_stub_match.rlab` — Algorithmic shunt short-circuited stub synthesiser. Input: $Z_L$, $Z_0$. Output: $d$, $\ell$. Plot the load $\Gamma_L$, the rotation arc, the unit-conductance circle, and the final landing at the centre. Verify by computing $\Gamma_{\rm in}$ of the matched network.
- `double_stub_match.rlab` — Same but with two stubs at fixed spacing $d_{12} = \lambda/8$. Demonstrate the forbidden-region check; pick a load inside (fails) and outside (succeeds) the forbidden circle.
- `quarter_wave_transformer.rlab` — Match $Z_L = 100$ Ω to $Z_0 = 50$ Ω with a $\lambda/4$ transformer at $f_0 = 1$ GHz. Sweep frequency 0.5 – 1.5 GHz; plot $|\Gamma|$ vs $f$ and overlay the Smith-chart locus. Show the narrowband behaviour and quantify the −10 dB bandwidth.
- `patch_antenna_smith.rlab` — Load the $S_{11}(f)$ output of Lesson 14's patch antenna; plot the locus on a Smith chart over 1–5 GHz. Annotate the resonant frequency (locus crosses real axis near the chart centre) and the −10 dB matching bandwidth (excursion outside the $|\Gamma| < 0.316$ circle). This is the headline use case for the chart: turning a broadband simulation into a one-glance design summary.

### What students learn

By the end, a student can take any complex load — circuit element, antenna, measurement — and design a matching network with a Smith chart as the working scratchpad. The skill transfers directly to network-analyser readouts and to the impedance-matching task that closes every real antenna design.

---

## Lesson 17 — Lumped Inductance Extraction

**Motivation:** Lesson 15 extracted lumped capacitance — the electric circuit element from a Laplace solve. This lesson is the magnetic dual: extract **lumped inductance $L$** (Henries) and **mutual inductance $M$** (Henries) from a Lesson 06–style vector-potential solve. The math is structurally identical to L15 with the swaps $\varepsilon \to 1/\mu$ and $V \to A_z$; the engineering content is different and complementary. Together, L15 + L17 close the *circuit-element extraction* loop and put the curriculum's "C, L, R" triad on the same numerical footing.

### Learning Objectives
- Extract self-inductance $L$ of an arbitrary 3-D current loop from the magnetic vector potential $\vec A$ via flux ($\Phi/I$) and via stored magnetic energy ($2U_M / I^2$)
- Extract the mutual-inductance matrix $M_{ij}$ for an $N$-loop system using the same cached-LU back-solve trick as Lesson 15's capacitance matrix
- Recognise the duality with capacitance extraction: $\nabla\cdot(\varepsilon\nabla V) = -\rho$ ↔ $\nabla\cdot(\mu^{-1}\nabla A_z) = -J_z$ in 2-D, so `laplacian_eps_2d(1/μ_r, ...)` is the natural solver
- Quantify the **coupling coefficient** $k = M/\sqrt{L_1 L_2}$ for two coils as a function of separation and orientation
- Recover the analytic formulas for parallel-wire self-inductance and for a long solenoid, and quantify the end-effect correction for a finite solenoid

### Key Equations

**Self-inductance (flux method).** For a single closed loop of current $I$,
$$L = \Phi_B / I = \frac{1}{I}\int_S \vec B\cdot d\vec A.$$

**Self-inductance (energy method).** Stored magnetic energy in the system,
$$U_M = \tfrac12 \int_{\Omega}\!\frac{|\vec B|^2}{\mu}\,dV, \qquad L = 2 U_M / I^2.$$

**Mutual inductance.** With current $I_j$ in loop $j$ producing flux $\Phi_{ij}$ through loop $i$,
$$M_{ij} = \Phi_{ij} / I_j.$$

For $N$ coupled loops, the inductance matrix $L_{ij}$ ($i \neq j$ ⇒ $L_{ij} = M_{ij}$, diagonal = self-inductance) is symmetric, and the energy is
$$U_M = \tfrac12 \sum_{i,j} L_{ij} I_i I_j.$$

**Coupling coefficient.** $k = M / \sqrt{L_1 L_2}$, $|k| \le 1$.

**Parallel-wire self-inductance** (per unit length, centres $d$ apart, radii $a$, $d \gg a$):
$$L'_{\rm pair} = \frac{\mu_0}{\pi}\Bigl[\ln\frac{d}{a} + \frac14\Bigr].$$

(The $1/4$ is the internal contribution from the current-distribution inside each wire, often dropped in high-frequency limits where current crowds to the surface.)

**Long solenoid inductance.** $L = \mu_0 n^2 V$ where $n$ = turns per length and $V$ = solenoid volume; for finite length $\ell$ and radius $R$, the textbook end-effect correction is
$$L \approx \mu_0 n^2 \pi R^2 \ell \cdot K(R/\ell)$$
with $K \to 1$ for $\ell/R \gg 1$.

### Scripts

- `lumped_L_loop.rlab` — Single 3-D circular wire loop carrying current $I = 1$ A. Compute $\vec A$ via Biot-Savart on the loop, then $\vec B = \nabla\times\vec A$, then integrate $\Phi_B$ through the loop interior and divide by $I$. Compare to the textbook self-inductance of a thin-wire loop, $L = \mu_0 R [\ln(8R/a) - 2]$.
- `ind_matrix_microstrip.rlab` — Magnetic dual of L15's `cap_matrix_microstrip.rlab`. Two parallel current-carrying traces above a ground plane; solve $\nabla\cdot(\mu^{-1}\nabla A_z) = -\mu_0 J_z$ with current injected into one trace at a time; extract the 2 × 2 per-unit-length inductance matrix $L'_{ij}$ via cached LU. Confirm reciprocity $L'_{12} = L'_{21}$.
- `mutual_inductance_coil_pair.rlab` — Two coaxial circular coils. Sweep the separation $d/R$; compute $M(d)$ from flux integration; verify the analytic Neumann-formula limit at large $d/R$ and the geometric-mean limit at small $d/R$. Plot $M$ and $k = M/\sqrt{L_1 L_2}$ vs $d/R$.
- `inductance_transformer.rlab` — Two concentric coil pairs (primary and secondary) with $n_1$ and $n_2$ turns. Compute $L_1$, $L_2$, $M$, and the coupling coefficient $k$. Verify $V_2/V_1 \to n_2/n_1$ in the tight-coupling limit ($k \to 1$).
- `finite_solenoid.rlab` — A finite-length solenoid; compute $L$ vs $\ell/R$ from $\ell/R = 1$ to $\ell/R = 20$; recover the long-solenoid limit $L \to \mu_0 n^2 \pi R^2 \ell$ and quantify the end-effect correction factor $K(R/\ell)$.
- `tunable_L_force.rlab` — Optional MEMS-style sibling to L15's `tunable_C_force.rlab`. A movable ferromagnetic core inside a solenoid; sweep the core position, extract $L(x)$, compute the magnetic force $F = \tfrac12 I^2 \,\partial L/\partial x$. Verify on a problem with a known analytic answer (e.g. a long-solenoid limit with a partial-fill core).

### What students learn

The magnetic dual of L15: every coil, inductor, and transformer geometry yields an $L$ matrix from a single vector-potential solve, and every mutual-coupling parameter ($M$, $k$, the turns ratio) follows from the same machinery. Combined with L15, this puts circuit-level $C$ and $L$ extraction on identical numerical foundations — the prerequisite skill for any field-to-circuit reduction tool.

---

## Rustlab Dependencies

The full list of feature requests for upstream rustlab lives in `dev/rustlab/requests/`. Short version, now that vector-calculus operators, contour plots, and `surf` have landed:

1. **Vector-field plotting** — `quiver` and `streamplot` (in development). Used by Lessons 01–03, 05, 06, 11.
2. **Laplacian stencil builder** — `laplacian_2d(nx, ny, dx, dy)` returning a sparse matrix, plus a variable-$\varepsilon$ form `laplacian_eps_2d(eps_map, dx, dy)` for Lessons 05, 06, 10.
3. **Helmholtz / curl-curl operator builder** — the Yee-grid complex curl-curl matrix with stretched-coordinate PML, for Lesson 10.
4. **Generalized sparse eigensolver** — `eigs(A, B, n)` for Lesson 12's waveguide/cavity modes.
5. **Shape rasterization primitives** — `rect_mask`, `disk_mask`, `polygon_mask` on a grid (Lesson 04). Can be hand-rolled for now.
6. **Animation export** — multi-frame SVG/GIF/HTML for time-domain visualization (Lessons 09, 11, 14).

Several items (FDTD update helpers, dispersive-material ADE state, S-parameter waveport helpers) are deliberately *not* on the upstream list — they belong as rustlab_em library functions because they are EM-specific workflows rather than general scientific-computing primitives.

**Extensions (L15–L17) require only one optional addition** beyond the existing 0.3.4 builtins:

- **Smith-chart helper** — `smith_chart()` builtin that draws the constant-$R$ / constant-$X$ circle background plus axis labels and locks the visual aspect ratio. Filed as `dev/rustlab/requests/smith-chart.md`. **Strictly optional** — the lesson can hand-roll the background with parametric `(cos t, sin t)` traces and `axis("equal")` (~30 lines of helper code per script vs ~5 lines with the builtin).

Everything else L15–L17 need already ships:
- 3-D Laplace + cached LU (`laplacian_3d`, `lu`, `solve`) — covers L15's lumped 3-D extraction
- 2-D variable-coefficient Laplace (`laplacian_eps_2d`) — already used by L06; covers L17's $\nabla\cdot(\mu^{-1}\nabla A_z)$ form
- `axis("equal")` for circular Smith-chart geometry — confirmed working in 0.3.4
