# Cycle 035 correction handoff — Core MIDI executor isolation

Base: `faa4374b9ac9f5bc0863b1bb7ab7ecf74ebe76ae` (`v0.35.0-alpha.2`).

## Trigger and diagnosis

The target-Mac crash report for `v0.35.0-alpha.2` records an
`EXC_BREAKPOINT` in `swift_task_checkIsolatedSwift` on a Core MIDI delivery
thread. The relevant stack passed through the MIDI input packet closure. This
was a Swift actor-isolation assertion in MIDI ingress, not an audio-renderer or
terrain-kernel failure.

## Implemented

- Added explicitly sendable packet and endpoint-refresh dispatchers retained by
  `MIDIIngress` for the lifetime of its input port and MIDI client.
- Made both Core MIDI callbacks capture only their dispatcher. Packet decoding
  happens without application state, then the existing receive and refresh
  paths are explicitly scheduled on the main actor.
- Added Swift regression fixtures that submit a MIDI note and endpoint refresh
  from background queues and verify delivery on the main actor.

## Verification

- `swift test`: pass; 15 XCTest cases, including the background-to-main MIDI
  dispatcher regression fixture.
- `make test`: pass; normal warnings-as-errors core, bridge, and playable
  fixtures passed.
- ASan/UBSan core, bridge, and playable fixtures: pass in
  `/tmp/latticewake-cycle035-midi-sanitized`.
- `LW_DEVICE_SMOKE=1 swift test --filter LatticewakeAppTests/testOptInDeviceSmoke`:
  pass. Its app-owned 48 kHz receipt reports 117 callbacks, 55,037 frames,
  maximum bridge render 153,083 ns, zero bridge budget misses, and zero
  rejected blocks.
- The final `swift test` run contains 16 XCTest cases: both receive and
  endpoint-refresh dispatchers are exercised from background queues.
- The rebuilt `0.35.0-alpha.3` standalone app is ad-hoc signed; a fresh launch
  stayed running through the startup smoke window.

## Runtime evidence and limitations

The regression fixture exercises the executor boundary but is not a hardware
MIDI or MPE session. The correction does not alter callback-admission status,
does not establish device deadline behavior, and records no human listening
claim.

## Rollback

Revert the correction commit. Scene documents, captures, and user media are not
migrated or rewritten by this change.
