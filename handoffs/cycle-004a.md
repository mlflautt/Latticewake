# Cycle 004A handoff — offline terrain-voice scaffold

## Base and scope

- Base commit: `34d830f` (`cycle-003: add strict scene serialization`).
- Owned paths: `cycles/cycle-004a-offline-terrain-voice.md`,
  `src/offline_terrain_voice.{hpp,cpp}`, `tests/core_tests.cpp`, `Makefile`,
  `README.md`, `docs/FOUNDATION.md`, `CYCLES.md`, and this handoff.
- Implementation: an in-memory trace renderer that maps normalized terrain
  values to bipolar mono samples, applies a one-pole DC blocker, and then a
  bounded soft limiter.

## Verification

```text
make clean && make test
make clean && make test CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1 -fsanitize=address,undefined -fno-omit-frame-pointer'
```

Both commands passed on the local Apple Clang toolchain. Fixtures establish
repeatability, finite/range-bounded output, decay of a constant-input DC tail,
and explicit rejection of invalid configuration and non-finite trace values.

## Runtime evidence and limitations

This is not an audio device, callback, file renderer, plug-in, or playback
implementation. It has no oversampling or measured aliasing evidence and does
not establish perceptual quality, human listening, or creative value.

## Integration and rollback

The next owner may add sample-clock transport or offline oversampling around
this API without using it on an audio callback until a separate real-time
contract is proven. Roll back with `git revert` of the cycle commit; no
external state or dependency was changed.
