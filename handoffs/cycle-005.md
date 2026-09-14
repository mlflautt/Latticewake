# Cycle 005 handoff — control and render foundation

## Base and scope

- Base commit: `61af378` (`cycle-004: add offline terrain voice scaffold`).
- Owned paths: `cycles/cycle-005-control-render-foundation.md`,
  `contracts/PROPOSALS_V0.md`, `src/sample_transport.*`, `src/proposals.*`,
  `src/offline_oversampling.*`, `tests/core_tests.cpp`, `Makefile`,
  `README.md`, `docs/FOUNDATION.md`, `CYCLES.md`, and this handoff.
- Implementation: in-memory sample-clock conversion, bounded proposal
  validation/preview traces, plus a deterministic interpolation and average
  decimation test harness at 1x, 2x, and 4x.

## Verification

```text
make clean && make test
make clean && make test CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1 -fsanitize=address,undefined -fno-omit-frame-pointer'
```

Both commands passed on the local Apple Clang toolchain. Tests cover exact
sample-to-beat timing, proposal trace ordering and invalid proposals,
factor-1 equivalence with the ordinary offline renderer, and finite bounded
2x/4x outputs.

## Runtime evidence and limitations

No component opens an audio device, runs an audio callback, writes a file,
sends MIDI, calls a model, connects Apple Intelligence, or mutates a Scene
from a proposal. The oversampling transition-energy value is a sample-delta
metric, not a complete aliasing or perceptual-quality measurement.

## Integration and rollback

Cycle 006 may add four-lane deterministic event generation or document the
real-time admission plan. Use proposal functions only at a preview boundary.
Roll back with `git revert` of this cycle commit; no external state or
dependency was changed.
