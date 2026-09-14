# Cycle 002A — analytic terrain evaluator

## Objective

Implement a pure C++20 analytic terrain sampler for validated Scene v0 inputs.
It must produce a deterministic normalized scalar and bounded path coordinates
for the initial `mandelbrot` and `julia` terrain families.

## Owned paths

- `src/terrain_evaluator.hpp`
- `src/terrain_evaluator.cpp`
- `tests/core_tests.cpp`
- `Makefile`
- `handoffs/cycle-002a.md`
- `CYCLES.md`

## Acceptance checks

1. Invalid scenes, invalid sample input, unsupported field kinds, and
   non-finite intermediate results return the documented neutral result.
2. Supported path kinds (`ellipse`, `lissajous`, `spiral`, `meander`) yield
   finite coordinates bounded by `path.spatialLimit`.
3. Supported analytic fields yield a deterministic scalar in `[0, 1]`, with a
   smooth escape value for escaped points and neutral zero for interior points.
4. Fixed test fixtures cover both field families, all path kinds, invalid
   inputs, and determinism.

## Non-goals

No audio render/callback, image sampling, UI, MIDI, serialization, third-party
dependency, or creative selection is part of this cycle.
