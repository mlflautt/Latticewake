# Latticewake

Latticewake is a native Apple-Silicon generative music-creation instrument.
It combines a real-time wave-terrain voice with four harmony-aware generative
roles, direct keyboard/trackpad/MPE performance, and an optional on-device
creative-proposal layer.

This directory is deliberately separate from `hermes-music/`: Latticewake is a
new product foundation, not a modification to the existing SuperDirt palette or
composition lineage.

Start with [the foundation](docs/FOUNDATION.md). The first shared semantic
contract is [Scene v0](contracts/SCENE_V0.md).
The supplied research evidence is preserved intact in
[`research/source-reports/`](research/source-reports/), with hashes recorded in
the foundation document.

Run the current contract-only verification with:

```bash
make test
```

## Status

The offline analytic terrain evaluator now has deterministic fixtures for the
initial Mandelbrot and Julia field families. No audio rendering, UI, MIDI,
model integration, or creative-performance claim has been implemented or
auditioned yet.
Development advances in committed, reviewable increments; see
[`CYCLES.md`](CYCLES.md) for the cycle protocol and next bounded options.
