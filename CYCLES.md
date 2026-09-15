# Latticewake development cycles

Latticewake advances through small, committed development cycles. A cycle is a
bounded technical increment, not a claim that its musical output has been
heard, approved, or preferred.

## Cycle protocol

1. Write the cycle brief: objective, owned paths, explicit non-goals, and acceptance checks.
2. Preserve the prior commit as the rollback point; do not rewrite history.
3. Implement only the stated scope and record deterministic fixtures or technical evidence where applicable.
4. Run the cycle's checks and record their commands and results in a handoff.
5. Commit the completed cycle with a `cycle-###:` conventional subject.
6. Offer the next bounded cycle as options. Human listening and creative preference remain separate review gates.

## Completed

### Cycle 001 — kernel contracts

- Commit: recorded after this document is committed.
- Scope: typed Scene v0 validation and canonical performance-event trace.
- Evidence: warnings-as-errors test build plus AddressSanitizer and UndefinedBehaviorSanitizer runs; see `handoffs/foundation-001.md`.
- Non-goals: audio rendering, DSP, UI, MIDI I/O, model execution, and artistic evaluation.

### Cycle 002A — analytic terrain evaluator

- Commit: recorded after this cycle is committed.
- Scope: deterministic, bounded scalar sampling for `mandelbrot` and `julia`,
  plus `ellipse`, `lissajous`, `spiral`, and `meander` paths.
- Evidence: fixed C++ fixtures cover supported families, path bounds, invalid
  inputs, and repeated evaluation.
- Non-goals: audio rendering/callback, image input, UI, MIDI, serialization,
  third-party dependencies, and artistic evaluation.

### Cycle 003A — scene serialization boundary

- Commit: recorded after this cycle is committed.
- Scope: strict, dependency-free JSON parsing and canonical JSON serialization
  for the typed Scene v0 model.
- Evidence: round-trip canonical-byte fixtures plus malformed, duplicate,
  unknown-field, unsafe-seed, unknown-role, and out-of-range rejection tests.
- Non-goals: files, audio, MIDI, UI, network behavior, and a general JSON API.

### Cycle 004A — offline terrain-voice scaffold

- Commit: recorded after this cycle is committed.
- Scope: deterministic trace-to-mono samples, one-pole DC blocking, and a
  conservative in-memory soft limiter.
- Evidence: deterministic-output, finite/range, DC-tail, and invalid-input
  C++ fixtures.
- Non-goals: device audio, callback integration, render files, playback, MIDI,
  UI, oversampling, and artistic evaluation.

### Cycle 005 — control and render foundation

- Commit: recorded after this cycle is committed.
- Scope: deterministic sample-clock transport, preview-only typed proposals,
  and an in-memory 1x/2x/4x interpolation/decimation harness.
- Evidence: transport timing, proposal-validation/preview ordering, and
  oversampling repeatability/finite-range C++ fixtures.
- Non-goals: audio device/callback, file output, MIDI, model connection,
  autonomous commit, UI, and aesthetic evaluation.

### Cycle 006 — role engine and realtime admission plan

- Commit: recorded after this cycle is committed.
- Scope: deterministic four-role offline trace generation and a written
  admission gate for any future audio-callback work.
- Evidence: repeatability, role-disable, monotonic-trace, and event-cap tests.
- Non-goals: audio callback/device, MIDI, voice allocation, pitch rendering,
  model connection, scene mutation, and artistic evaluation.

### Cycle 007 — direct play and terrain snapshots

- Scope: QWERTY note mapping, smoothed trackpad semantics, and immutable terrain frames.
- Evidence: mapping, smoothing, snapshot repeatability, and invalid-range tests.
- Non-goals: native UI, MIDI device I/O, Metal rendering, callback integration, and artistic evaluation.

### Cycle 008 — MPE state primitives

- Scope: portable legacy/lower/upper MPE state handling and per-note expression state.
- Evidence: deterministic state-machine fixtures.
- Non-goals: Core MIDI endpoints and audio-callback routing.

### Cycle 009 — product boundary and hardening

- Scope: native Swift package boundary, scene-byte storage, version/license, and CI.
- Evidence: core and Swift package verification.
- Non-goals: audible rendering or callback admission.

### Cycle 010 — real-time kernel candidate

- Scope: prepared terrain table, fixed voice/event caps, reset, DC blocking, and limiting.
- Evidence: normal and sanitizer C++ fixtures.
- Non-goals: queue handoff, device audio, or callback admission.

### Cycle 011 — audible standalone shell

- Scope: AVAudioEngine prototype, start/stop controls, and runtime status.
- Evidence: Swift package verification.
- Non-goals: terrain-kernel bridge proof or human listening evidence.

### Cycles 012–016 — bridge, direct play, and scene lifecycle

- Scope: opaque C ABI, C++ terrain render path, QWERTY note lifecycle,
  canonical Scene preparation/storage, and trackpad expression events.
- Evidence: C++ and Swift package checks recorded in their individual handoffs.
- Non-goals: SPSC queue handoff, Core MIDI device I/O, terrain UI, and callback
  admission.

### Cycle 017 — bounded real-time bridge handoff

- Scope: fixed SPSC input queue, status/overflow contract, bridge render
  allocation fixture, and audio closure lifetime narrowing.
- Evidence: normal, ASan/UBSan, and Swift package verification; see
  `handoffs/cycle-017.md`.
- Non-goals: complete AVAudioEngine admission, Core MIDI/MPE device I/O,
  EngineRack, Metal surface, model provider, or human listening evidence.

### Cycle 018 — immutable render-plan publication

- Scope: prepared terrain-plan contract, two persistent bridge plan slots,
  block-boundary adoption, and live scene publication from the Swift adapter.
- Evidence: deterministic plan, pending-plan, generation-transition, normal,
  sanitizer, and Swift package checks; see `handoffs/cycle-018.md`.
- Non-goals: complete callback admission, multi-producer ingestion, Core MIDI,
  Terrain Stage UI, EngineRack, or human listening evidence.

### Cycle 019 — Terrain Stage snapshots

- Scope: bounded C terrain-frame copy boundary and an immutable SwiftUI Canvas
  Stage trace derived from canonical Scene bytes.
- Evidence: deterministic/capacity core bridge fixtures plus a Swift snapshot
  preparation test; see `handoffs/cycle-019.md`.
- Non-goals: Metal or 3D rendering, live transport display, callback admission,
  MIDI, role controls, or human visual/auditory review.

### Cycle 020 — Core MIDI and MPE ingress

- Scope: Core MIDI source lifecycle, one main-actor ingress producer, portable
  legacy/lower/upper MPE state, and inbound note/expression routing.
- Evidence: bridge MPE ownership/reset fixtures, normal/sanitizer checks, and
  Swift MIDI packet decoding; see `handoffs/cycle-020.md`.
- Non-goals: hardware session, MIDI output, independent per-note MPE DSP,
  callback admission, or human listening evidence.

### Cycle 021 — per-note MPE kernel expression

- Scope: note-identified bridge events and fixed-voice glide/press/slide state
  with MPE active-note resolution.
- Evidence: deterministic different-target per-note expression fixture,
  bridge active-note fixture, normal/sanitizer/Swift checks; see
  `handoffs/cycle-021.md`.
- Non-goals: hardware MPE session, zone voice stealing, MIDI output, callback
  admission, or human listening evidence.

## Next-cycle options

### Cycle 022 — four-role performance controls

Expose initial role enable/density/range/pattern/seed controls, deterministic
offline replay, and visible trace status without callback UI reads.
