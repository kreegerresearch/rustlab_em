# Request: Vector-Calculus Operators on Uniform Grids

**Status**: Landed (`gradient`, `divergence`, `curl`, plus 3-D variants — verified in `rustlab/docs/quickref.md`, used by Lessons 01-03)
**Date**: 2026-04-22
**Origin**: `rustlab_em` Lessons 01, 02, 03, 07, 08

## Motivation

Every electromagnetics simulation computes $\nabla f$, $\nabla\cdot\vec F$, or $\nabla\times\vec F$ on a discrete grid. Students writing these by hand from central-difference stencils obscures the physics. These are the EM analogues of `diff`, `conv`, and `fft` — low-level numerical primitives that deserve to be builtins.

## Proposed API

```
# 2D gradient of a scalar field on a uniform grid
[Fx, Fy] = gradient(F, dx, dy)    # F is an ny×nx matrix
[Fx, Fy] = gradient(F)            # dx = dy = 1 default

# 3D gradient (returns 3 matrices or a rank-3 tensor — pick a consistent convention)
[Fx, Fy, Fz] = gradient3(F, dx, dy, dz)

# Divergence of a 2D vector field
D = divergence(Fx, Fy, dx, dy)    # D is ny×nx scalar field

# Divergence, 3D
D = divergence3(Fx, Fy, Fz, dx, dy, dz)

# Curl — in 2D returns the z-component (a scalar field)
Cz = curl(Fx, Fy, dx, dy)

# Curl, 3D — returns the three components
[Cx, Cy, Cz] = curl3(Fx, Fy, Fz, dx, dy, dz)
```

## Semantics

- **Interior points**: 2nd-order central differences.
- **Boundary points**: 2nd-order one-sided (forward/backward) differences so the output is the same shape as the input. This matches MATLAB/Octave and NumPy conventions.
- **Grid convention**: `F(i, j)` corresponds to position `(x = (j-1)*dx, y = (i-1)*dy)` — i.e. rows index $y$, columns index $x$. Document this clearly; it is the common source of bugs.
- **Complex inputs**: supported — EM fields are routinely complex in the frequency domain.

## Alternatives Considered

- **Leave as user-space**: every EM lesson reimplements the 5-line central-difference stencil. Error-prone and a distraction from physics.
- **Build via `conv2`**: possible but requires knowing the convolution kernel. Less discoverable.

## Scope

Minimal useful surface is `gradient`, `divergence`, `curl` in 2D. 3D versions are nice-to-have but used in fewer lessons (mostly Lesson 09 FDTD, which manages its own Yee-grid stencils).

## References

- MATLAB: [`gradient`](https://www.mathworks.com/help/matlab/ref/gradient.html), [`divergence`](https://www.mathworks.com/help/matlab/ref/divergence.html), [`curl`](https://www.mathworks.com/help/matlab/ref/curl.html).
- NumPy: [`numpy.gradient`](https://numpy.org/doc/stable/reference/generated/numpy.gradient.html) — we would follow its boundary-handling.
