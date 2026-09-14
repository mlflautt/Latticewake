# Latticewake foundation 001 handoff

## Scope

Base repository commit: `44f58f475b549587492b9fc29309cf6e3b65ca34`.

This handoff owns only `Latticewake/`. It added a dependency-free C++20 typed
Scene v0 validator, canonical event trace, Make test target, MPE semantic
contract, and report-informed foundation documents. The three user-supplied
research reports were unmodified; they were later relocated intact to
`research/source-reports/` and committed with their original hashes.

## Evidence

- `make test` passed with warnings treated as errors.
- `make clean && make test CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1 -fsanitize=address,undefined -fno-omit-frame-pointer'` passed.
- The current host has Apple Clang 21/Xcode 26.6 and no `cmake` executable;
  the Make target intentionally avoids new dependencies.

## Runtime boundaries

No terrain DSP, Core Audio callback, MIDI/MPE device I/O, Metal rendering,
Apple Intelligence call, audio file render, hardware probe, or listening test
was implemented. Passing tests establish typed-contract and event-order
behavior only.

## Next integration request

Implement an offline analytic terrain evaluator and fixed-size render fixture
against `Scene` only after defining its output normalization and test vectors.
Keep JSON parsing, Core Audio, and SwiftUI outside that focused change. The
future evaluator must preserve the hard iteration cap and non-finite reset
requirements in `docs/FOUNDATION.md`.

## Rollback

All work is contained in the untracked `Latticewake/` directory. Removing that
directory removes this foundation without touching the existing Hermes Music
runtime or user research reports.
