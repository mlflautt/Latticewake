# Cycle 003A handoff — Scene v0 serialization boundary

## Base and scope

- Base commit: `d6a5632` (`cycle-002: add analytic terrain evaluator`).
- Owned paths: `contracts/SCENE_V0.md`,
  `cycles/cycle-003a-scene-serialization.md`,
  `src/scene_serialization.{hpp,cpp}`, `tests/core_tests.cpp`, `Makefile`,
  `README.md`, `CYCLES.md`, and this handoff.
- Implementation: strict schema-specific JSON parse/serialize functions that
  operate on bytes in memory only. They construct and validate the existing
  typed `Scene` model.

## Verification

```text
make clean && make test
make clean && make test CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1 -fsanitize=address,undefined -fno-omit-frame-pointer'
```

Both commands passed on the local Apple Clang toolchain. Tests prove canonical
round-trip bytes and rejection of malformed input, duplicate fields, unknown
fields, unsafe 64-bit seed strings, unknown role IDs, and validator-rejected
values.

## Runtime evidence and limitations

This parser has no filesystem, network, audio, MIDI, UI, model, or plugin
behavior. It is not a claim of real-time safety, audio output, human listening,
or creative value. It is intentionally not a general JSON library; unsupported
JSON string escape forms are rejected.

## Integration and rollback

The next owner can use these byte-level functions at an explicit storage/import
boundary, never in an audio callback. Roll back with `git revert` of the cycle
commit; no external state or dependency was changed.
