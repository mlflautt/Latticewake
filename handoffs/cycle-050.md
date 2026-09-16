# Cycle 050 handoff — bounded Freeze and Grow candidate set

Base: `4698d31` (`v0.49.0-alpha.1`).

## Implemented

- Replaced the single opaque Freeze and Grow variation with a set of exactly
  three deterministic local candidates.
- Each candidate has a stable seed and position for revisiting the same scene,
  depth, and freeze boundary. Position is explicitly not a ranking or quality
  judgement.
- Artists select one candidate for Preview or Accept; Reject all restores the
  current scene. No candidate is auto-previewed, saved, accepted, or preferred.
- A fully frozen boundary produces no variations, and the provider cap is four
  candidates at the API boundary (the product UI requests three).

## Verification

- Full release verification passed: normal portable tests, ASan/UBSan,
  30 Swift tests (one existing Core MIDI-service skip), shell checks, packaging,
  and bundle verification.
- Focused Swift coverage proves stable set generation, unique IDs/seeds, freeze
  refusal, and invalid cap refusal.
- Native one-app review passed. The Stage displayed all three unranked
  variations; Preview visibly stated it was temporary; accepting deliberately
  selected Variation 2 created one receipt; Undo restored the prior state; a
  fully frozen boundary created no candidate.
- Lifecycle evidence: `closed_latticewake_instances=0` before review and
  `closed_latticewake_instances=1` after review.

## Remaining gates

- Future providers remain proposal-only and must use an explicit contract,
  preview, acceptance, undo, and receipt boundary.
