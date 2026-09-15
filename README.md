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

Run the portable core and bridge verification with:

```bash
make test
```

## Status

The portable core provides deterministic analytic terrain, canonical Scene v0
bytes, offline four-role traces, typed proposal previews, direct-play semantics,
MPE state primitives, and a fixed-capacity terrain render candidate. The native
SwiftUI app uses an AVAudioEngine host with a C++ terrain bridge, saved Scene
bytes, QWERTY direct notes, and trackpad expression.

The C++ bridge now has a fixed SPSC input queue, two persistent prepared plan
slots, and bridge-level render allocation tests. It is still not admitted to a device callback: see the
[real-time admission gate](docs/REALTIME_ADMISSION.md). No target-device
performance or human listening result is claimed.

The native Terrain Stage now renders a 256-point immutable C++ terrain trace in
a SwiftUI 2D Canvas. It is an initial scene visualization, not a Metal field,
3D view, live transport display, or creative evaluation.

The intended product architecture and bounded agent boundary are in
[the product architecture](docs/PRODUCT_ARCHITECTURE.md).
Development advances in committed, reviewable increments; see
[`CYCLES.md`](CYCLES.md) for the cycle protocol and next bounded options.
