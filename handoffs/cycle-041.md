# Cycle 041 handoff — bounded expressive modulation matrix

Base: `54cf995` (`v0.40.0-alpha.1`).

## Implemented

- Added three explicit, per-note Scene v1 modulation routes: Gesture X →
  pitch, Gesture Y → terrain timbre, and pressure → gain.
- Routes are constrained to the existing 32-route graph cap, the three listed
  source/target pairs, `per-note` scope, and bipolar depth `[-1, 1]`.
- Empty legacy graphs preserve prior direct-play expression behavior. Once an
  explicit route exists, the prepared graph owns all three route depths.
- Prepared render plans carry only scalar route depths. The callback reads no
  UI or scene data and performs no routing allocation.
- Added C ABI and Inspector controls to enable a route and set its depth;
  applying controls explicitly migrates legacy Scene v0 in memory.

## Verification

- Portable fixtures cover route validation, prepared-depth transfer, and C ABI
  control round trips.
- Swift integration fixture covers migration and modulation control round trip.
- Full local release verification passed: normal C++ fixtures, fresh
  ASan/UBSan fixtures, 22 Swift tests, script checks, packaging, and
  signed-bundle identity verification.
- Isolated native review confirmed the Inspector exposes all three named route
  toggles, their bipolar sliders, and the explicit bounded-route explanation.
- Hosted CI remains pending the release commit.

## Remaining gates

- This is the first intentionally small modulation vocabulary, not the full
  source/target matrix, LFO/envelope system, or modulation-of-modulation plan.
- It is not a human listening decision or callback real-time admission.
