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

Core MIDI sources are now discovered by the standalone app with Legacy, MPE
Lower, and MPE Upper ingress modes. This is tested packet/ownership routing;
it has not received a hardware session, MIDI output support, or per-note MPE
voice-rendering hardware proof. The portable kernel does retain expression per
fixed voice and has deterministic fixtures for note-specific routing.

The Stage also exposes four draft role controls. Applying them is explicit: it
writes validated canonical Scene bytes, then refreshes the prepared scene and
terrain snapshot; it does not yet schedule role notes in the audio callback.

Applying or restoring a scene also generates one bounded, offline role-event
preview window and displays its deterministic trace receipt. This is traceable
material for review and replay—not a live sequencer or a statement about the
audible result.

The audio adapter now exposes callback-route preflight counters and rejects
blocks above 4,096 frames as silence. Its bridge stress evidence is documented
in the real-time admission gate; it is not target-device callback admission or
a listening result.

The intended product architecture and bounded agent boundary are in
[the product architecture](docs/PRODUCT_ARCHITECTURE.md).
Development advances in committed, reviewable increments; see
[`CYCLES.md`](CYCLES.md) for the cycle protocol and next bounded options.
