# Cycle 056 handoff — deterministic role-plan boundaries

Base: `bb042d0` (`v0.55.0-alpha.1`).

## Implemented

- Added a dedicated fixed-capacity, double-buffered role-plan handoff separate
  from the terrain/audio render plan.
- A prepared role edit now remains pending until the exact role-loop boundary;
  the callback releases preceding plan-owned notes and begins the replacement
  sequence at the boundary sample.
- Role status now exposes loop position plus active and pending generations.
- The Stage distinguishes edited, queued, and active role values, shows queued
  loop progress, and prevents an in-flight plan from being overwritten.
- Persistent role edits still update scene bytes, dirty state, undo history,
  and the eventual active trace. Transient Mute/Solo remains separate.
- Direct events are inserted into callback events in frame order without
  allocation, fixing their ordering when generated events occur later in the
  same block.

## Verification

- The bridge boundary fixture prepares an all-disabled replacement, proves the
  old plan remains active before the boundary, adopts generation 2 at sample
  offset zero, leaves the terrain plan at generation 1, and observes zero C++
  allocations throughout the crossing.
- `make verify-release` passed the normal and ASan/UBSan C++ suites, pitch
  fixtures, Swift tests, script checks, signed bundle build, and exact bundle
  verification.
- The opt-in target-device route passed 34 Swift tests without a Core MIDI skip.
  Its new AVAudioEngine role-boundary fixture observed the pending generation
  become active after one four-second loop. The separate device smoke receipt
  recorded 114 callbacks, 53,626 frames, zero deadline misses, and zero rejected
  blocks.
- A pre-final `0.56.0-alpha.1` review candidate launched as one process and its
  receipt matched code UUID `29B88853-5199-329A-926E-41B2F2880E7C`. macOS was
  locked, so visual interaction review could not run; the lifecycle guard then
  closed exactly that one process. After the overload-recovery hardening, final
  bundle verification passed for code UUID `1048032D-2093-36F2-A328-3EC1130FDEA6`;
  that exact final bundle still requires native visual review.
- The exact final bundle then passed a second controlled process smoke: launch
  receipt version `0.56.0-alpha.1`, build 63, code UUID
  `1048032D-2093-36F2-A328-3EC1130FDEA6`, and binary SHA-256
  `38f3233d321176701d71c90e9afa72772a007512a57c66cc2fe1230ee33dbacc`.
  The lifecycle guard again reported zero prior instances and closed exactly
  the one final review process.

## Remaining gates

- Exact target-device transition feel and the musical usefulness of changing a
  loop at its wrap require a human listening decision; the deterministic and
  allocation evidence does not make that aesthetic claim.
- Native visual review of Edited → Queued → Active remains open until the Mac
  desktop is unlocked. The alpha tag records the technically verified revision;
  it does not close this visual or human-listening gate.
