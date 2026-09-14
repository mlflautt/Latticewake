# Cycle 006 handoff — role engine and realtime admission plan

## Base and scope

- Base commit: `597a7eb` (`cycle-005: add control and render foundations`).
- Owned paths: `cycles/cycle-006-role-engine-and-realtime-plan.md`,
  `src/role_event_generator.*`, `docs/REALTIME_ADMISSION.md`,
  `tests/core_tests.cpp`, `Makefile`, `README.md`, `docs/FOUNDATION.md`,
  `CYCLES.md`, and this handoff.
- Implementation: seeded, bounded, offline four-lane event traces driven by
  Scene rhythm/pattern/density fields, plus a separate callback admission plan.

## Verification

```text
make clean && make test
make clean && make test CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1 -fsanitize=address,undefined -fno-omit-frame-pointer'
```

Both commands passed on the local Apple Clang toolchain. Fixtures cover
reproducible traces, disabled lanes, monotonic ordering, and the hard event
cap.

## Runtime evidence and limitations

The generator does not render sound, allocate voices, convert to pitches, send
MIDI, run a callback, or choose music. The real-time document is a gate and not
evidence that the gate has been satisfied.

## Integration and rollback

The next cycle may define direct-play inputs, terrain snapshots, or an offline
MPE state machine. Roll back with `git revert` of this cycle commit; no
external state or dependency was changed.
