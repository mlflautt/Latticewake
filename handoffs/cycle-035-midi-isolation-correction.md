# Cycle 035 correction handoff — Core MIDI executor isolation

Base: `61d4cacc8adb7a6c08e33706b8bd0587f0f7301f` (`v0.35.0-alpha.3`).

## Trigger and diagnosis

The initial target-Mac crash report for `v0.35.0-alpha.2` records an
`EXC_BREAKPOINT` in `swift_task_checkIsolatedSwift` on a Core MIDI delivery
thread. The relevant stack passed through the MIDI input packet closure. This
was a Swift actor-isolation assertion in MIDI ingress, not an audio-renderer or
terrain-kernel failure.

## Implemented

- Added explicitly sendable packet and endpoint-refresh dispatchers retained by
  `MIDIIngress` for the lifetime of its input port and MIDI client.
- Made both Core MIDI callbacks capture only their dispatcher and construct in
  explicitly nonisolated client/port factory functions. Packet decoding happens
  without application state, then the existing receive and refresh paths are
  explicitly scheduled on the main actor.
- Added Swift regression fixtures that submit a MIDI note and endpoint refresh
  from background queues and verify delivery on the main actor.
- Added an exact Core MIDI fixture: a virtual source sends a real packet to the
  factory-created input port and verifies delivery through its worker callback
  reaches the main actor without an executor assertion.

## Verification

- `swift test`: pass; 17 XCTest cases, including the exact virtual-Core-MIDI
  packet-delivery fixture and both background-to-main dispatcher fixtures.
- `make test`: pass; normal warnings-as-errors core, bridge, and playable
  fixtures passed.
- ASan/UBSan core, bridge, and playable fixtures: pass in
  `/tmp/latticewake-cycle035-midi-sanitized`.
- `LW_DEVICE_SMOKE=1 swift test --filter LatticewakeAppTests/testOptInDeviceSmoke`:
  pass. Its app-owned 48 kHz receipt reports 117 callbacks, 55,037 frames,
  maximum bridge render 153,083 ns, zero bridge budget misses, and zero
  rejected blocks.
- `make test`: pass; normal warnings-as-errors core, bridge, and playable
  fixtures passed for the follow-up.
- ASan/UBSan core, bridge, and playable fixtures: pass in
  `/tmp/latticewake-cycle035-midi-v4-sanitized`.
- `LW_DEVICE_SMOKE=1 swift test --filter LatticewakeAppTests/testOptInDeviceSmoke`:
  pass. Its app-owned 48 kHz receipt reports 117 callbacks, 55,037 frames,
  maximum bridge render 228,875 ns, zero bridge budget misses, and zero
  rejected blocks.
- The rebuilt `0.35.0-alpha.4` standalone app is ad-hoc signed. A shell
  fresh-launch probe was ambiguous because earlier app instances had already
  been launched from the same bundle; it is not recorded as a clean new-process
  launch assertion.

## Runtime evidence and limitations

The regression fixtures exercise dispatcher boundaries but are not a hardware
MIDI or MPE session. The first correction release remained incomplete: its
factories were still created in a main-actor method, which a target-Mac report
proved can retain actor isolation on the Core MIDI packet block. The follow-up
release moves factory construction out of that context. It does not alter
callback-admission status, establish device deadline behavior, or record a
human listening claim.

The target-Mac `v0.35.0-alpha.4` report additionally found a separate startup
failure in SwiftUI layout negotiation, not MIDI: an unbounded Stage content
width combined with the terrain `GeometryReader` could recurse while the root
window was sizing. The follow-up constrains the Stage to a finite width and the
terrain to a finite 320-point drawing height. Native launch evidence must be
recorded for the final revision.

The repaired layout remained alive but consumed excessive idle CPU with the
`MTKView` visual adapter on the target OS. The final baseline therefore uses
the existing immutable-snapshot Canvas renderer inside the same Stage surface.
The Metal adapter is retained in source but is not an admitted visual runtime
path until it passes a target-Mac idle-cost check.

The final `0.35.0-alpha.9` baseline additionally keeps Core MIDI connection
disarmed at launch while the free-function callback boundary awaits a dedicated
hardware endpoint session. QWERTY and terrain gestures remain available. The
target-Mac launch smoke survived without a new crash record; the debug build's
idle CPU remains elevated and is an open visual-runtime performance issue, not
a resolved metric.

## Rollback

Revert the correction commit. Scene documents, captures, and user media are not
migrated or rewritten by this change.
