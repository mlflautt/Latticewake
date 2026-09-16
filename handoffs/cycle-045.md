# Cycle 045 handoff — proposal contract boundary

Base: `5e4b03b` (`v0.44.0-alpha.1`).

## Implemented

- Added `latticewake-proposal-v1`, a bounded JSON contract for preview-only
  ScenePatch proposals from local or external providers.
- The pure validator requires an exact base scene hash and exact Freeze and
  Grow boundary, accepts only 1–16 unique allowlisted patches, and rejects
  invalid identities, duplicate fields, out-of-range values, or a patch to a
  frozen component.
- Candidate derivation is isolated from audio, files, library state, undo, and
  taste. No provider may commit or save through this contract.
- Documented the stable contract for Hermes, Codex, and other harnesses.

## Verification

- Focused Swift fixture proves allowed patches apply while frozen and stale
  proposals fail before candidate derivation.
- Full release verification remains required before commit.

## Remaining gates

- Build the artist-facing Proposal Studio atop this same contract: explicit
  validate, preview, accept, reject, undo, and receipt actions.
- Complete native review of the Grow drawer. No Apple Intelligence, cloud
  fallback, callback access, or autonomous co-performance is present.
