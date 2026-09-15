# Latticewake

Latticewake is a native Apple-Silicon generative music-creation instrument.
It combines a real-time wave-terrain voice with four harmony-aware generative
roles, direct keyboard/trackpad/MPE performance, and an optional on-device
creative-proposal layer.

This directory is deliberately separate from `hermes-music/`: Latticewake is a
new product foundation, not a modification to the existing SuperDirt palette or
composition lineage.

Start with [the foundation](docs/FOUNDATION.md). The first shared semantic
contract is [Scene v0](contracts/SCENE_V0.md); the component-addressable
[Scene v1](contracts/SCENE_V1.md) is now the explicit-save format.
The supplied research evidence is preserved intact in
[`research/source-reports/`](research/source-reports/), with hashes recorded in
the foundation document.
External synth manuals and the comparative first-principles report are kept in
[`research/reference-synths/`](research/reference-synths/). Its index records
scope, retained lessons, explicit non-goals, and source hashes so product
influences remain reviewable rather than implicit.

Run the portable core and bridge verification with:

```bash
make test
```

## Status

The portable core provides deterministic analytic terrain, canonical Scene v0
bytes, offline four-role traces, typed proposal previews, direct-play semantics,
MPE state primitives, deterministic Scene v1 migration, and a portable
RenderPlanBuilder. The native
SwiftUI app uses an AVAudioEngine host with a C++ terrain bridge, saved Scene
bytes, QWERTY direct notes, and trackpad expression.

The C++ bridge now has a fixed SPSC input queue, two persistent prepared plan
slots, bridge-level render allocation tests, and deterministic role scheduling.
It is still not admitted to a device callback: see the
[real-time admission gate](docs/REALTIME_ADMISSION.md). No target-device
human listening result is claimed. A Cycle 032 target-device smoke run is
recorded as technical evidence only.

The native Terrain Stage now renders the immutable C++ terrain trace through a
Metal-backed 2D surface, with a separate contour overlay and explicit direct
voice/lane activity. It is an authoritative 2D performance surface, not a 3D
view or creative evaluation.

Core MIDI sources are now discovered by the standalone app with Legacy, MPE
Lower, and MPE Upper ingress modes. This is tested packet/ownership routing;
it has not received a hardware session, MIDI output support, or per-note MPE
voice-rendering hardware proof. The portable kernel does retain expression per
fixed voice and has deterministic fixtures for note-specific routing.

The Stage exposes four role controls and a live role transport. Role events are
prepared deterministically outside the callback and consumed through the same
bounded source-aware event path as direct play. The deterministic preview trace
remains visible for review and replay; neither it nor device metrics are an
aesthetic judgment.

The audio adapter now exposes callback-route preflight counters and rejects
blocks above 4,096 frames as silence. Its bridge stress evidence is documented
in the real-time admission gate; it is not target-device callback admission or
a listening result.

For a real standalone audition, follow the
[target-Mac protocol](docs/TARGET_MAC_AUDITION.md). Its technical receipt and
listener observation are intentionally separate evidence.

Build a local debug `.app` bundle with:

```bash
cd app && bash scripts/build_macos_app.sh
```

The intended product architecture and bounded agent boundary are in
[the product architecture](docs/PRODUCT_ARCHITECTURE.md).
Development advances in committed, reviewable increments; see
[`CYCLES.md`](CYCLES.md) for the cycle protocol and next bounded options.
The consolidated delivery sequence is [Roadmap v3](docs/DEVELOPMENT_ROADMAP_V3.md).
