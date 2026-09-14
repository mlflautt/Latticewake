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

## Next-cycle options

### Cycle 006A — realtime-kernel admission plan

Define the preallocation, lock-free queue, lifetime, and test contracts needed
before any existing component can move toward an audio callback.

### Cycle 006B — four role-lane event generator

Implement deterministic Euclidean/manual patterns for the four existing role
lanes and emit an offline performance trace against the sample clock.

### Cycle 006C — terrain-frame export contract

Define immutable terrain-frame snapshots for a future SwiftUI/Metal surface,
with no UI implementation or real-time cross-thread behavior yet.
