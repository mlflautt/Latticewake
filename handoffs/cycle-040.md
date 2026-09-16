# Cycle 040 handoff — isolated native review harness

Base: `9848441` (`v0.39.0-alpha.1`).

## Implemented

- Added `make launch-review`, which makes an ad-hoc signed, uniquely identified
  review copy of the exact verified standalone app under `build/review/`.
- The review receipt records the copy's bundle path, bundle identifier, PID,
  executable command, hash, and Mach-O UUID. It never kills running instances
  or touches scene files.
- Added the review workflow to the crash-triage protocol and shell syntax
  release checks.

## Native UI evidence

- Native automation bound to the isolated `Latticewake Review` app rather than
  the pre-existing Latticewake instance that invalidated Cycle 039's first UI
  attempt.
- The current Inspector visibly exposed Surface, Traversal, and Articulation
  sections, their bounded sliders, and `Apply Scene Changes`.
- The automation accessibility bridge exposes sliders only with Increment and
  Decrement actions, not direct arbitrary value setting; the specific
  apply-and-render behavior remains covered by the bridge and Swift fixtures.

## Verification

- Pending final exact-head release verification and hosted CI after the release
  commit.

## Remaining gates

- This solves exact-process visual review selection. It is not callback
  admission, a MIDI hardware session, or a human listening decision.
