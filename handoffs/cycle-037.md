# Cycle 037 handoff — reproducible release gate and exact-process receipts

Base: `8ca8794` (`v0.36.0-alpha.1`).

## Implemented

- Added `make verify-release` and made macOS hosted verification run that same
  complete command: normal C++ fixtures, fresh ASan/UBSan fixtures, Swift
  tests, standalone packaging, and signed-bundle identity verification.
- Added `scripts/launch_exact_macos_app.sh` and `make launch-exact`. The helper
  verifies the default package identity, launches through Launch Services, and
  records the newly created exact-binary PID, observed command, version,
  binary hash, and Mach-O UUID.
- Extended the crash triage protocol with the evidence boundary for exact
  process receipts. It intentionally does not claim to automate a UI action.

## Verification

- `make verify-release`: passed locally: normal C++ fixtures, fresh
  ASan/UBSan fixtures, 17 Swift tests, shell syntax checks, packaging, and
  signed-bundle identity verification.
- A fresh target-Mac crash baseline plus `make launch-exact` identified PID
  `94335` for the packaged `0.37.0-alpha.1` executable. Its receipt records
  SHA-256 `59d9932754ff0aa02cad9f45a5736d2e6a6f6164e18e40b718ec41562d0f7e70`
  and Mach-O UUID `2897351A-3668-3CD9-BD26-6D465DA8B5AA`.
- The exact process survived a five-second `sample`; crash reporting found no
  new Latticewake report from that baseline.
- Hosted CI is pending the final release commit and tag.

## Remaining gates

- The receipt identifies a launched process but does not prove control-level UI
  behavior, human listening, MIDI hardware lifecycle, or callback admission.
- Core MIDI automatic connection remains disarmed pending an explicit endpoint
  session; Metal remains deferred until its own idle-cost gate passes.
