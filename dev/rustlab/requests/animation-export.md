# Request: Multi-Frame Animation Export

**Status**: Proposed (nice-to-have)
**Date**: 2026-04-22
**Origin**: `rustlab_em` Lessons 08, 09

## Motivation

Time-domain EM simulations (Lesson 08 plane waves, Lesson 09 FDTD) have time as a first-class variable. A single SVG can't capture a wave *propagating* through a dielectric or scattering off a cylinder — and a snapshot doesn't tell the story. Rustlab currently has no multi-frame output path.

## Proposed API

Two options, not mutually exclusive:

### Option A: Animated Plotly HTML (simplest)

```
figure()
for t in 0:dt:T
  imagesc(Ez(:, :, t), "viridis")
  title("t = ${t:%.2f} ns")
  frame()                      # stash the current figure state as frame N; clear for next
end
saveanim("wave.html", fps=30)  # emits a Plotly animation with a play bar
```

Plotly natively supports animation via `frames` in the figure JSON. This would be a thin wrapper around the existing HTML backend.

### Option B: GIF export (via savefig extension)

```
savefig("wave.gif", frames=Ez_sequence, fps=30)
```

Takes a rank-3 array (ny × nx × nt) and emits an animated GIF. Requires a GIF encoder dependency (`gif` crate is small and pure Rust).

## Semantics

- **`frame()`** captures the current figure's state into an internal frame buffer and clears the active figure for the next iteration (like `hold off`).
- **`saveanim(path)`** flushes the frame buffer to disk.
- **Clear on new figure**: calling `figure()` resets the frame buffer, so accidentally mixing static and animated plots doesn't leak state.

## Scope

Option A (Plotly HTML) is the smaller lift and ships within the existing notebook pipeline. Option B (GIF) is nice for standalone demos but not essential for the notebook site.

Fallback: as long as scripts can emit a sequence of numbered SVG files (`frame_0000.svg` … `frame_0120.svg`), users can stitch with `ffmpeg` externally. This works today via a manual `savefig("outputs/frame_%04d.svg" % t)` loop — document this as the current workaround in `rustlab_em` Lessons 08–09.

## References

- Plotly [Intro to Animations](https://plotly.com/python/animations/) — the data model we'd emit.
- Matplotlib [`FuncAnimation`](https://matplotlib.org/stable/api/_as_gen/matplotlib.animation.FuncAnimation.html).
