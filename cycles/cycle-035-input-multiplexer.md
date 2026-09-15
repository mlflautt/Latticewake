# Cycle 035 — input multiplexer and panic recovery

## Objective

Make keyboard, pointer, MIDI, and MPE routes enter the portable kernel through
one main-actor performance-input producer, preserve per-source note ownership,
and recover a saturated event queue at a callback-owned panic boundary.

## Owned paths

- `app/Sources/LatticewakeApp/InputMultiplexer.swift`
- Swift input, MIDI ingress, and audio-adapter integration
- C bridge panic boundary, SPSC queue support, and bridge/Swift fixtures

## Non-goals

- Hardware MPE certification, MIDI output, or a human performance review.
- Full Core Audio lock/allocation admission proof.
- Scene v1 editors, EngineRack, effects, or visual redesign.

## Acceptance checks

- Same-pitch notes from distinct input sources, including distinct MPE channels,
  retain separate identities.
- Keyboard repeat, focus loss, pointer ownership, and panic leave no direct
  voices represented by the input layer.
- Queue overload requests callback-owned reset; the UI never resets a live
  kernel directly.
- Normal, ASan/UBSan, Swift, signed-app, and opt-in local-device checks are
  recorded separately from hardware and listening evidence.
