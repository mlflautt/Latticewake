# Cycle 005 — control and render foundation

## Objective

Advance three compatible offline foundations together: sample-clock transport,
preview-only typed proposals, and deterministic 1x/2x/4x terrain-trace
oversampling. Each component remains in-memory and explicitly non-autonomous.

## Acceptance checks

1. Transport time derives only from a sample offset, sample rate, and tempo.
2. A validated melody proposal produces an ordered preview trace but cannot
   mutate a scene; scene patches are allowlisted and validation-only.
3. Oversampling produces finite, bounded, deterministic mono output at each
   declared factor; factor 1 matches the existing renderer exactly.

## Non-goals

No audio callback/device, file render, MIDI, model call, Apple Intelligence
integration, autonomous commit, UI, or perceptual/aesthetic evaluation.
