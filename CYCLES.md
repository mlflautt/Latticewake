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

## Next-cycle options

### Cycle 004A — offline terrain-voice scaffold

Add an offline-only mono terrain-voice prototype consuming deterministic terrain
samples, with DC and finite-output checks. This is technical output only;
listening remains a human review gate.

### Cycle 004B — sample-clock transport

Implement a deterministic sample-clock transport that emits no sound, and prove
tempo, phase, and event timing fixtures from sample counts rather than wall
time.

### Cycle 004C — typed proposal boundary

Define `MelodyProposal` and allowlisted `SceneProposal` types, validate them
against Scene v0, and create preview-only traces. No model connection or
automatic commit.
