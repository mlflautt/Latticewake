# Cycle 044 handoff — accepted Grow receipts and reversible lineage

Base: `d94cc19` (`v0.43.0-alpha.1`).

## Implemented

- Added `GrowProposalReceiptV1`, a typed, deterministic record of the local
  provider, base and candidate scene hashes, seed, depth, frozen components,
  and changed components.
- Accepted Grow proposals now create a receipt only after the candidate has
  been prepared and installed through the canonical Scene v1 bridge.
- Scene-library documents persist accepted Grow receipts while remaining
  readable when an older Library v1 document has no receipt field.
- Undo snapshots now include both scene bytes and Grow receipts, so undoing an
  accepted variation restores the preceding lineage state as well as sound.
- The standard Swift test route redirects its cache to `/tmp` and disables the
  nested SwiftPM sandbox, which is incompatible with this workspace sandbox.

## Verification

- 25 Swift integration tests pass with the standard cache/sandbox route,
  including receipt round-trip and old-library decoding fixtures.
- Normal C++ and sanitizer checks remain required before release commit.

## Remaining gates

- Complete native visual review of the Grow drawer and receipt status.
- The proposal boundary remains local only: no external providers, Apple
  Intelligence, cloud fallback, automatic commit, or callback access.
