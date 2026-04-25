# Standalone `.r` scripts (per-lesson)

Each `<NN-topic-slug>/` directory holds shell-runnable `rustlab` scripts
that exercise the same physics as the lesson's notebook source. The
notebook source itself lives at
[`../notebooks/<NN-topic-slug>.md`](../notebooks/) — *not* here.

```
lessons/
└── 01-vector-calculus-and-fields/
    ├── gradient_field.r
    ├── divergence_curl.r
    └── stokes_demo.r
    # *.svg from `rustlab run *.r` land here too (gitignored)
```

Subdirectories are created on demand: a stub lesson with no scripts yet
has no entry under `lessons/` at all. As `.r` scripts are authored for a
new lesson, create `lessons/<slug>/` to hold them.

## Running

```sh
rustlab run lessons/01-vector-calculus-and-fields/gradient_field.r
make lesson-01     # run every .r in lesson 01
```

Scripts call `savefig("foo.svg")` next to themselves; the canonical
rendered plots live in [`../site/`](../site/), so `.r` artefacts
(`*.svg`, `*.html`, `*.png` under each lesson dir) are gitignored.

## Why have both notebooks and scripts?

The notebook is the lesson — prose, math, and code interleaved, executed
by the renderer into the published site. The `.r` scripts are *parallel*
to the notebook's code blocks: each script maps to one or two
` ```rustlab ` blocks in the notebook source. Tinker with a script
without touching the notebook to explore one concept in isolation.

The duplication is intentional and small. When you change one, change
the other.
