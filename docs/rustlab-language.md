# rustlab is its own language

This curriculum runs on [rustlab](https://github.com/kreegerresearch/rustlab) — a domain-specific scripting language for matrix and DSP work, implemented in pure Rust. rustlab files use the `.rlab` extension, and the `rustlab` CLI is the only thing that runs them.

The curriculum's editor settings, GitHub Linguist hint, and `.gitattributes` rule all map `.rlab` to **MATLAB/Octave** for *syntax highlighting only*. That mapping is a deliberate temporary proxy; this doc exists to make sure the proxy doesn't get mistaken for the real story.

> **TL;DR.** rustlab looks like MATLAB at first glance because they share a lot of surface syntax (matrix literals, 1-based indexing, `%` comments, `.*` element-wise ops). Underneath, rustlab is a separate language with its own runtime, its own builtins, its own notebook integration, and its own roadmap. We use MATLAB highlighting today because there's no native rustlab grammar in the open-source highlighter ecosystem yet — *not* because rustlab is "matlab in Rust."

## What rustlab actually is

A standalone CLI + interpreter written end-to-end in Rust. The project ships:

- **The `rustlab` binary** — runs scripts (`rustlab run foo.rlab`) and an interactive REPL (`rustlab` with no args).
- **A scripting language** with matrix-first semantics, broadcasting, sparse-matrix support, and a small core grammar (loops, conditionals, user-defined functions, anonymous functions, function handles).
- **A standard library of builtins** spanning math, statistics, FFT, FIR/IIR filter design, fixed-point quantisation, sparse linear algebra, sparse eigensolvers, geometry rasterisation, plotting, and notebook capture.
- **A notebook pipeline** that renders ` ```rustlab ` fenced code blocks in Markdown to executed output (text + SVG plots + HTML animations) — driving every page under [`book/`](../book/) here.

There is no MATLAB runtime, no Octave runtime, no SciPy bridge, no FFI to LAPACK/BLAS, no GPL/LGPL/AGPL/copyleft dependency. The default policy is pure-Rust hand-rolls under MIT or Apache-2.0; `AGENTS.md` Rule 9 in the upstream rustlab repo codifies this.

## What's distinct about it

A non-exhaustive sample of features that are rustlab-specific — none of these run in MATLAB or Octave without writing the code yourself:

- **Sparse PDE stencil builders.** `laplacian_2d(nx, ny, dx, dy, bc)` returns a sparse 5-point Laplacian with a `bc` selector; `laplacian_1d`, `laplacian_3d`, and `laplacian_eps_2d(eps_map, dx, dy, bc)` are all builtins. Lessons 05–07 use them as their primary solver primitive.
- **Hand-rolled sparse infrastructure.** `spsolve` runs sparse Cholesky / sparse LU with AMD ordering — pure Rust, no `faer`, no LAPACK. The 200×200 SPD case factors in ~0.4 s, the 100×100 complex case in ~0.6 s. `eigs(A, n)` and `eigs(A, B, n)` provide partial sparse eigenvalue decomposition via hand-rolled Lanczos / Arnoldi.
- **Geometry rasterisation primitives.** `rect_mask`, `disk_mask`, `polygon_mask` — see Lesson 04. These are first-class builtins, not user-space helpers.
- **Notebook integration baked into the runtime.** Variables persist across ` ```rustlab ` blocks; the active figure is captured automatically (no `savefig()` calls in notebook code blocks); `frame()` and `saveanim()` produce per-block Plotly HTML animations. The `rustlab notebook render` subcommand drives the pipeline.
- **Rendering backends.** Terminal heatmaps, SVG, PNG, interactive HTML (Plotly), and an interactive 3-D viewer for `surf` — all implemented in rustlab itself.
- **`Tensor3` rank-3 array type** with `gradient3`/`divergence3`/`curl3` builtins, distinct from rustlab's matrix type and not interchangeable with it.

## Where it overlaps with MATLAB/Octave on purpose

rustlab inherits matrix-first conventions because they're well-suited to the problem domain — and because every numerics practitioner already knows them. Specifically:

- **Matrix literals.** `[1, 2; 3, 4]` is a 2×2 matrix in both. Comma separates columns; semicolon separates rows.
- **1-based indexing.** `v(1)` is the first element; `M(end)` is the last; `v(2:4)` is a slice.
- **Element-wise vs matrix operators.** `*` is matrix multiply; `.*`, `./`, `.^` are element-wise.
- **Comments.** `%` and `#` both work (rustlab notebooks idiomatically use `%`; standalone `.rlab` files use `#`).
- **Function definition.** `function [out] = name(args) … end`.

These overlaps are why MATLAB syntax highlighting *looks right* on a rustlab file. They're also what makes rustlab approachable for anyone with prior MATLAB/Octave/Julia exposure.

## Where the proxy breaks down

A user who edits `.rlab` files in MATLAB-syntax mode and reaches for MATLAB instincts will hit walls:

- **No object system.** rustlab has no classes, no `classdef`, no method dispatch on user types. Function handles and anonymous functions cover the small slice of dispatch that scripts need.
- **No toolboxes, no `pkg`.** rustlab's standard library is built in; there's no per-installation extension surface.
- **`max(M1, M2)` is not element-wise on matrices.** The MATLAB form takes two matrices and returns the element-wise maximum; rustlab's `max` takes a vector or two scalars. Lesson 04 documents the inclusion-exclusion idiom for boolean-mask unions because of this.
- **No `polyfit`, `regress`, or other stat-toolbox staples.** Hand-roll the normal-equations slope fit when needed (Lesson 05's corner-singularity script does exactly this).
- **Single-arg indexing on `zeros(1, N)` matrices.** Indexing a `[1×N]` *matrix* with one index treats it as a row index; indexing the same shape produced by `zeros(N)` (a *vector*) treats the index as element position. This bit Lesson 06's first Biot-Savart prototype.
- **Sparse semantics are explicit.** Mixed sparse/dense pairs auto-promote to dense in some operations; the `sparse(...)`, `sparsevec(...)`, `speye(...)`, `spdiags(...)` constructors are first-class.
- **The plotting model is rustlab's, not MATLAB's.** `quiver`/`streamplot`/`contour`/`imagesc`/`surf` exist with similar names but their backends and per-format behaviour are rustlab-specific (terminal, SVG, HTML, viewer all from the same call).

If a habit transferred from MATLAB doesn't work, the answer is almost always in [`../rustlab/docs/quickref.md`](../../rustlab/docs/quickref.md) (overview) or [`../rustlab/docs/functions.md`](../../rustlab/docs/functions.md) (full signatures) — not in MATLAB documentation.

## Why we use MATLAB highlighting today (and not later)

GitHub Linguist's grammar pack ships definitions for MATLAB / Octave but not for rustlab — Linguist requires an upstreamed `linguist-language` entry plus a TextMate grammar, and that submission hasn't happened yet. Editor extensions face the same chicken-and-egg problem: VS Code, Neovim, Vim all rely on either bundled grammars or third-party plugins, none of which currently target `.rlab`.

The temporary mapping has three observable consequences:

1. GitHub displays `.rlab` files with MATLAB syntax colours and counts them as MATLAB in the language stats bar.
2. Editors honour the user's `files.associations` / `vim.filetype.add` setting and apply MATLAB highlighting locally.
3. Search engines indexing GitHub will see this curriculum's code as MATLAB.

None of those map to a runtime claim: every `.rlab` script in this repo is parsed by `rustlab`, not by MATLAB or Octave. The proxy stops at the highlighter.

## What "rustlab as its own language" buys us long-term

Three concrete payoffs once the language identity is taken seriously. The third already shipped:

- **A native Linguist definition.** Submitting a TextMate grammar + Linguist entry will let GitHub display the curriculum as rustlab — accurate language stats, accurate syntax classes (so a future `frame()` builtin gets coloured as a builtin call rather than a generic MATLAB function name).
- **A language server.** A rustlab LSP server backed by the existing parser would unlock go-to-definition, hover-docs over builtins, and inline diagnostic surfacing — none of which MATLAB's tooling provides for `.rlab` files.
- **A clear self-identification on every run.** ✅ **Shipped in rustlab 0.2.0** (upstream commit `ef460bc`). Every `rustlab run <script>.rlab` invocation now prints `rustlab 0.2.0 — interpreting <path> (.rlab)` to stderr at startup. The line is always-on, single-line, and locked in by an upstream integration test. Filed at [`../dev/rustlab/requests/rlab-extension-handler-log.md`](../dev/rustlab/requests/rlab-extension-handler-log.md), shipped same-day.

## See also

- [`../README.md`](../README.md) — top-level project overview (Environment & Tooling section)
- [`../AGENTS.md`](../AGENTS.md) — Tool: Rustlab section
- [`../../rustlab/docs/quickref.md`](../../rustlab/docs/quickref.md) — language + builtins cheatsheet
- [`../../rustlab/docs/functions.md`](../../rustlab/docs/functions.md) — full builtin signatures
- [`../../rustlab/docs/notebooks.md`](../../rustlab/docs/notebooks.md) — notebook directives, frontmatter, formats
- [`../dev/rustlab/requests/rlab-extension-handler-log.md`](../dev/rustlab/requests/rlab-extension-handler-log.md) — proposed CLI banner for handler identification
