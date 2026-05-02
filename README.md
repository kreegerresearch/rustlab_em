# rustlab_em

A self-contained course for learning classical electromagnetics and Maxwell's equations from the ground up — paired with runnable simulations that turn the math into field lines, potential maps, propagating waves, and scattering patterns. Each lesson combines a theory document with rustlab scripts that solve the governing PDEs on real geometries.

> Rendered lessons live in [`book/`](book/) — start there.

## Goals

- Build genuine physical intuition for electric and magnetic fields by seeing them computed and plotted
- Progress from Coulomb's law to full-wave FDTD simulation, one concept at a time
- Learn the numerical methods (finite differences, relaxation, Yee grid) that make real-world EM simulation possible
- Connect abstract vector calculus to concrete geometries: capacitors, coaxial cables, solenoids, waveguides, antennas

## Toolchain

Simulations run in [rustlab](../rustlab), a scientific computing CLI with a matrix-oriented scripting language. Run any script from the repo root:

```bash
rustlab run lessons/05-poisson-laplace-bvp/parallel_plate.r
```

Generated plots (SVG/HTML) appear next to the script and are gitignored — the canonical rendered output lives under `book/`. Open the per-lesson SVGs in any browser, or run `make html` to build the interactive Plotly view at `book/index.html`.

## Lessons

The curriculum targets a "mini Ansys" endpoint: given arbitrary geometry and material assignments, compute electric and magnetic fields, $S$-parameters, and radiation patterns. Lesson 14 is the end-to-end capstone; everything before it builds a piece of the pipeline.

The links below point at the **rendered** notebooks under [`book/`](book/) — what GitHub displays inline with executed code, captured `print()` output, and inline SVG plots. Sources live at [`notebooks/<slug>.md`](notebooks/) and are regenerated to the book by `make notebooks`.

### 01 — Vector Calculus & Fields
**Status: Drafted** | [`book/01-vector-calculus-and-fields.md`](book/01-vector-calculus-and-fields.md)

The mathematical foundation. Gradient, divergence, and curl on 2D/3D grids; line, surface, and volume integrals; the divergence theorem and Stokes' theorem as they actually apply to EM. Build intuition for scalar vs. vector fields, flux, and circulation by computing them numerically on meshes.

### 02 — Electrostatics & Coulomb's Law
**Status: Drafted** | [`book/02-electrostatics-coulomb.md`](book/02-electrostatics-coulomb.md)

Electric fields from discrete charges via superposition. Point charges, dipoles, line and ring distributions. Field lines and equipotential contours. Sets up the physical objects that the rest of the course manipulates.

### 03 — Gauss's Law & Electric Potential
**Status: Drafted** | [`book/03-gauss-law-and-potential.md`](book/03-gauss-law-and-potential.md)

Flux through closed surfaces; $\nabla\cdot\vec{E} = \rho/\varepsilon_0$. Symmetric analytic solutions (sphere, cylinder, infinite plane) and their numerical verification. Electric potential $V$, the relation $\vec{E} = -\nabla V$, and equipotential surfaces as contour plots.

### 04 — Geometry & Material Maps
**Status: Planned** | [`book/04-geometry-and-material-maps.md`](book/04-geometry-and-material-maps.md)

The toolkit that bridges "a user drew a shape" and "the solver has numbers to work with." Rasterize primitives (rectangle, disk, polygon) and boolean-combine them into region masks. Assign spatial $\varepsilon_r(x,y)$, $\mu_r(x,y)$, $\sigma(x,y)$ arrays per region. Demonstrate a simple conformal-boundary correction. Every downstream solver consumes these arrays.

### 05 — Poisson & Laplace BVP — Dielectrics & Conductors
**Status: Planned** | [`book/05-poisson-laplace-bvp.md`](book/05-poisson-laplace-bvp.md)

The first numerical PDE solver. $\nabla\!\cdot\!(\varepsilon\nabla V) = -\rho$ discretized on a 2D grid via finite differences; iterative relaxation (Jacobi, Gauss-Seidel, SOR) vs. direct sparse solve. Geometries: parallel-plate capacitor with a dielectric slab between, coaxial cable with mixed dielectric fill, L-shaped conductor corner singularity.

### 06 — Magnetostatics & Vector Potential
**Status: Planned** | [`book/06-magnetostatics.md`](book/06-magnetostatics.md)

Magnetic fields from steady currents. Numerical Biot-Savart integration over arbitrary current paths; Ampère's law with symmetric analytic solutions. Then the BVP counterpart: solve $\nabla^2\vec{A} = -\mu_0\vec{J}$ on a grid with material $\mu_r$ regions, and recover $\vec B = \nabla\times\vec A$ for complex geometries where Biot-Savart is impractical.

### 07 — Faraday's Law & Induction
**Status: Planned** | [`book/07-faraday-induction.md`](book/07-faraday-induction.md)

$\oint \vec{E}\cdot d\vec{\ell} = -d\Phi_B/dt$. Induced EMF, Lenz's law, self- and mutual inductance. Eddy currents in a thin conducting plate as a 2D simulation.

### 08 — Maxwell's Equations — The Complete Set
**Status: Planned** | [`book/08-maxwell-equations.md`](book/08-maxwell-equations.md)

The displacement current $\partial\vec{D}/\partial t$ and why Ampère's law needed it. The four equations in differential and integral form; charge conservation as a built-in consistency condition; the Poynting vector and energy flow.

### 09 — EM Wave Equation & Plane Waves
**Status: Planned** | [`book/09-em-waves.md`](book/09-em-waves.md)

Deriving the wave equation from Maxwell in vacuum; $c = 1/\sqrt{\mu_0\varepsilon_0}$. Plane waves, polarization states (linear, circular, elliptical), standing waves at a perfect conductor. Animated field visualization.

### 10 — FDFD — Frequency-Domain Maxwell Solver
**Status: Planned** | [`book/10-fdfd-frequency-domain.md`](book/10-fdfd-frequency-domain.md)

The steady-state counterpart to FDTD. Discretize the vector Helmholtz / Maxwell curl-curl equation on a Yee grid as a complex-valued sparse linear system, then hand it to `spsolve`. Single-frequency transmission through a stratified dielectric, scattering off a 2D dielectric cylinder, resonance in a driven cavity. Cheap, direct, and the natural way to get an $S$-parameter at one frequency.

### 11 — FDTD — Time-Domain, Dispersive Materials, PML
**Status: Planned** | [`book/11-fdtd-simulation.md`](book/11-fdtd-simulation.md)

The Yee grid and leapfrog update equations — the workhorse numerical method of real-world EM simulation. 1D propagation through a dielectric slab; 2D total-field/scattered-field plane-wave injection around a PEC/dielectric cylinder; dispersive media (Drude metal, Debye water, Lorentz resonator) via auxiliary-differential-equation updates; split-field perfectly matched layer absorbing boundaries.

### 12 — Waveguides, Cavity Eigenmodes & Radiation
**Status: Planned** | [`book/12-waveguides-and-radiation.md`](book/12-waveguides-and-radiation.md)

Rectangular waveguide TE/TM modes computed as a numerical generalized eigenvalue problem on a 2D cross-section grid; cavity resonances the same way. Hertzian and half-wave dipole radiation patterns, plus a near-field-to-far-field transform so FDTD simulations can be turned into 3D gain patterns without filling the whole far-field region with grid cells.

### 13 — Transmission Lines, S-Parameters & Antennas
**Status: Planned** | [`book/13-transmission-lines-and-antennas.md`](book/13-transmission-lines-and-antennas.md)

Connecting the 3D field picture back to 1D circuit parameters. Capacitance extraction from 2D Laplace solutions; characteristic impedance $Z_0 = \sqrt{L'/C'}$ of coax and twin-wire lines; telegrapher's equations and reflection at a terminated load (VSWR). Multiport $S$-parameters via waveport excitation, time-gating, and de-embedding. Dipole antennas as open-ended transmission-line stubs — derivation of $I(z) = I_0\sin[k(L/2-|z|)]$ and the 73 Ω half-wave radiation resistance by far-field Poynting integration.

### 14 — Capstone: End-to-End Device Simulation
**Status: Planned** | [`book/14-capstone-device-simulation.md`](book/14-capstone-device-simulation.md)

Put everything together. Build a microstrip-fed rectangular patch antenna from scratch — substrate, ground plane, trace, patch — as a material map (Lesson 04). Run it through FDTD (Lesson 11) with waveport excitation (Lesson 13) and a TF/SF source, extract $S_{11}$ via time-gating, and compute the 3D gain pattern via the NF→FF transform (Lesson 12). Compare the result to a published design. A working "mini Ansys" session, top to bottom.

## Repository Structure

```
notebooks/                # editable source notebooks (committed)
  <slug>.md               # one per lesson; ```rustlab``` blocks + prose
  README.md               # editor-facing notes (skipped by the renderer)
lessons/                  # standalone .r scripts (per-lesson subdirs)
  <slug>/
    *.r                   # parallel to notebook code blocks
    *.svg|html|png        # .r script artefacts (gitignored)
book/                     # rendered notebooks for GitHub display (committed)
  README.md               # hand-written index (GitHub landing)
  <slug>.md               # rendered notebook with inline plots
  plots/<slug>/           # captured SVG figures
  index.html, <slug>.html # interactive HTML build (`make html`, gitignored)
docs/
  lesson-site-pattern.md  # reusable design pattern for other rustlab courses
dev/
  rustlab/requests/       # feature requests to file upstream against ../rustlab
AGENTS.md                 # conventions and rustlab reference for this repo
```

Each lesson notebook follows a consistent structure: Learning Objectives → Background → Theory → Simulations → Exercises → Connections to Upcoming Lessons. Edit the source at `notebooks/<slug>.md`, then run `make notebooks` to regenerate `book/`.

## License

Licensed under either of

- Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or <http://www.apache.org/licenses/LICENSE-2.0>)
- MIT license ([LICENSE-MIT](LICENSE-MIT) or <http://opensource.org/licenses/MIT>)

at your option.

### Contribution

Unless you explicitly state otherwise, any contribution intentionally submitted for inclusion in the work by you, as defined in the Apache-2.0 license, shall be dual licensed as above, without any additional terms or conditions.
