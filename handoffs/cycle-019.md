# Cycle 019 handoff — Terrain Stage snapshots

## Base and scope

- Base: `37b7235` (`cycle-018: publish immutable terrain plans`).
- Owned paths: C terrain-frame ABI, bridge snapshot fixture, Terrain Stage
  SwiftUI model/view/test, architecture/readme/cycle records, version, and this
  handoff.
- `lw_terrain_frame_scene_json` parses and builds a frame off the audio path,
  then copies at most the caller-provided number of `LWTerrainFramePoint`
  values. The Swift main actor owns a 256-point buffer and publishes a value
  snapshot to `TerrainStageView`.

## Verification

```text
make clean && make test
make clean && make test CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1 -fsanitize=address,undefined -fno-omit-frame-pointer'
cd app && swift test
```

All checks passed locally on Apple Silicon. Bridge fixtures cover finite,
normalized, deterministic frame points and capacity rejection. Swift fixtures
verify that canonical demo Scene bytes prepare exactly 256 points at the
requested sample offset.

## Runtime evidence and limitations

The app package compiles and tests the Canvas-based Stage surface. This is not
visual approval from a live artist session, a Metal renderer, a full terrain
field visualization, transport-synchronized animation, device callback
admission, Core MIDI/MPE integration, or evidence about audible output.

## Integration and rollback

Cycle 020 can add Core MIDI/MPE through a designated ingress multiplexer;
another UI cycle can add role controls and an optional Metal-backed field while
preserving the snapshot boundary. Roll back with `git revert` of the Cycle 019
commit; no external state is changed.
