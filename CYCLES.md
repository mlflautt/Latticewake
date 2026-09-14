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

## Next-cycle options

### Cycle 002A — analytic terrain evaluator

Implement a pure, bounded smooth-potential terrain evaluator with fixed fixtures. It accepts validated scene terrain/path inputs and emits normalized field values. No audio callback, image import, or UI.

### Cycle 002B — scene serialization boundary

Specify a versioned serialized Scene v0 representation, parse it into the existing typed model, and prove rejection of unknown or malformed values. No runtime audio behavior.

### Cycle 002C — offline voice scaffold

Add an offline-only mono terrain-voice prototype consuming a deterministic control trace, with DC and finite-output checks. This is technical output only; listening remains a human review gate.
