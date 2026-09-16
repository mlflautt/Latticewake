# Cycle 036 handoff — standalone build identity and idle baseline

Base: `3e72eec` (`v0.35.0-alpha.10`).

## Implemented

- Replaced the app packaging script's stale hard-coded SwiftPM product path
  with `swift build --show-bin-path`.
- Added `make bundle-verify`, which validates that the signed app's Mach-O code
  UUID matches SwiftPM's current product and verifies the app signature.
- Replaced the root Stage `ScrollView` with a bounded `VStack` layout.

## Target-Mac evidence

Before the packaging repair, the launch sample came from stale app code and
spent about 20–30% CPU in repeated SwiftUI layout. After the repair, the exact
freshly packaged app process was sampled for five seconds at 0% CPU, and the
crash triage report found no new crash report.

## Verification

- `swift test`: pass; 17 cases.
- `make test`: pass.
- `make bundle-verify`: required against the final signed app.
- Target-Mac bounded launch plus `sample`: pass for the exact packaged binary.

## Remaining gates

Core MIDI automatic connection remains disarmed pending a target-device
endpoint session. Metal remains unavailable as the active Stage renderer until
its separate idle-cost gate passes. This does not grant audio callback admission
or constitute a human listening decision.
