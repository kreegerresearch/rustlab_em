# `lessons/_shared/`

Helpers shared across multiple lessons. Imported with `run "../_shared/<file>.rlab"` from the lesson script. Functions defined in the included file land in the caller's scope.

| File | Defines | Used by |
|---|---|---|
| `em.rlab` | `pml_sigma_profile(N, npml, sigma_max)`, `pml_stretching_factor(sigma, omega, eps0)`, `fdfd_tmz_pml_2d(eps_map, omega, dx, dy, npml, sigma_max)` | Lessons 10, 11, 13 |

`em.rlab` is Phase 1 of the Yee-grid + SC-PML upstream feature request — see [`../../dev/rustlab/requests/yee-and-pml-builders.md`](../../dev/rustlab/requests/yee-and-pml-builders.md). When any of the documented graduation triggers fires, these functions are reimplemented in pure Rust as `crates/rustlab-em` and this directory goes away.
