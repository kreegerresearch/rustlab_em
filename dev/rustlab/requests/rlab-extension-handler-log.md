# Request: rustlab CLI announces itself as the `.rlab` handler

**Status**: **Landed**
**Date opened**: 2026-05-02
**Date landed**: 2026-05-02 (same-day turnaround)
**Upstream commit**: `ef460bc` ("Rename .r → .rlab; bump to 0.2.0; add Environment & Tooling docs")
**Origin**: `rustlab_em` repo-wide migration of script extension `.r` → `.rlab` (commit `c00237c`).

## What shipped

`commands/run::execute` now emits a single always-on stderr banner at the top of every `rustlab run` invocation. Observed format (rustlab 0.2.0):

```
rustlab 0.2.0 — interpreting <abs-path-to-script> (.rlab)
```

Locked in by an integration test in the upstream repo. Same-day turnaround on the request: filed in commit `a340c6e` here, shipped in upstream `ef460bc`.

Compared to the proposal below: stderr-not-stdout was honoured, single-line was honoured, version-in-banner was honoured. The `--quiet` / `RUSTLAB_QUIET=1` suppression switch and the optional non-`.rlab` extension lint were not added; not blocking, can be follow-on requests if a use-case for silence emerges (e.g. golden-output diff testing of stderr).

## Original proposal (kept for context)

## Motivation

`rustlab_em` recently migrated its 26 lesson scripts from the `.r` extension (which collides with R, the statistics language) to `.rlab`. The migration was clean on the curriculum side — `git mv`, `git log --follow` history preserved, GitHub Linguist now classifies the repo as MATLAB via `.gitattributes`.

But on the runtime side, `rustlab run path/to/script.rlab` is silent about the language identity. The CLI accepts any path and produces output, with no log line that says "rustlab is handling this `.rlab` file." Two consequences follow:

1. **Identity erosion.** rustlab is a distinct domain-specific language for DSP modelling, with its own grammar and semantics. Today, an observer watching CI logs or a developer running `rustlab run foo.rlab` sees no acknowledgement of *what language is parsing the file*. That makes it easier to mentally reduce rustlab to "matlab-flavoured shim" — exactly the framing the `.rlab` rename was meant to push back on. A startup banner of one line ("rustlab 0.X.Y handling foo.rlab") is the cheapest possible reinforcement.
2. **Debugging friction.** When a script fails — bad syntax, missing builtin, runtime panic — the error message currently identifies the file but not the interpreter version or the recognised file type. A handler-identity log line up front means every error report self-contains the rustlab version that produced it.

## Proposed change

Have `rustlab run <path>` emit a single stderr line at startup naming the interpreter, version, and file:

```
rustlab 0.X.Y — handling .rlab file: lessons/05-poisson-laplace-bvp/laplace_2d.rlab
```

Constraints to keep the change minimal:

- **Stderr, not stdout.** Curriculum scripts use `print()` to stdout; preserving stdout for script output keeps the existing `make notebooks` / `make lesson-NN` golden output intact, and keeps redirected pipes (`rustlab run foo.rlab > out.txt`) clean.
- **Single line.** A multi-line banner is too noisy when running `make lesson-05` (five scripts in a row).
- **Suppressible.** A `--quiet` flag (or `RUSTLAB_QUIET=1` env var) silences the banner for users who want absolute silence — same pattern `cargo`, `npm`, `go` ship.
- **REPL-friendly.** `rustlab` (no args, interactive) already prints a banner; this change is only about file-mode invocations.

The exact wording isn't load-bearing; "rustlab" appearing as the noun is. Variants like `rustlab v0.X.Y — running .rlab script: …` are equivalent.

## Optional follow-ons (not blocking)

- **Extension lint.** If `rustlab run foo.txt` is invoked, the banner could note "non-standard extension `.txt`; treating as rustlab source" — a soft hint that `.rlab` is the canonical extension without enforcing it.
- **`rustlab --version`** dedicated subcommand (if not already present) for scripted version detection.
- **Log target.** A future `RUSTLAB_LOG=info` env var (tracing-style) could fold this banner in alongside parse-phase / eval-phase tracing for debug builds.

## Why this matters for `rustlab_em`

Every `make lesson-NN` invocation in CI eventually flows into a docs-generated artefact that students see. A future "How rustlab works" lesson can quote the startup line directly from a `make lesson-01` log. Without the banner, the lesson has to *manually* tell readers that the file is being parsed by rustlab — instead of letting the tool announce itself.

## References

- `rustlab_em` commit `c00237c` ("Migrate rustlab script extension from .r to .rlab")
- Curriculum-side `.gitattributes` and README updates that frame MATLAB highlighting as a *temporary proxy* for the rustlab language
- [`../../../docs/rustlab-language.md`](../../../docs/rustlab-language.md) — full curriculum-side write-up of rustlab as its own language (overlaps with MATLAB, where the proxy breaks down, long-term roadmap)
