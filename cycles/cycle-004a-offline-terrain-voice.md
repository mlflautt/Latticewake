# Cycle 004A — offline terrain-voice scaffold

## Objective

Render a deterministic, in-memory `TerrainEvaluation` trace to bounded mono
samples. Apply a one-pole DC blocker before a conservative soft limiter, and
reject invalid inputs instead of manufacturing output.

## Acceptance checks

1. Equal trace and configuration values render byte-identical sample vectors.
2. Output samples are finite and lie in `[-1, 1]`.
3. A constant terrain trace decays toward zero after DC blocking.
4. Invalid configuration and invalid terrain values fail explicitly.

## Non-goals

No audio device, callback, file export, playback, MIDI, UI, oversampling, or
creative judgement is part of this cycle.
