# Cycle 025 handoff — target-audition instrumentation kit

- Base: `ce61cb4`; scope is bridge-render duration/budget counters, the
  standalone app's stop-time receipt, and the target-Mac audition protocol.
- Verification: normal `make clean && make test`; sanitizer `make clean &&
  make test CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1
  -fsanitize=address,undefined -fno-omit-frame-pointer'`; and `cd app && swift
  test`. The bridge fixture verifies a nonzero measured render duration.
- Runtime attempt: `swift run LatticewakeApp` built the executable on this Mac,
  but this automation environment exposed no Latticewake GUI surface or audio
  observation. It is build evidence only, not a target-device session.
- Limits: no preserved app receipt from a real output route, no Core Audio
  internal timing/lock tracer, no device deadline proof, no MIDI hardware
  session, and no human listening or creative decision exists.
- Requested integration: run `docs/TARGET_MAC_AUDITION.md` on the intended Mac
  and return the exact technical receipt plus any optional listener wording for
  Cycle 026; do not substitute a numerical pass/fail for that wording.
- Rollback: `git revert` this cycle commit; no external state is changed.
