# Cycle 017 — bounded real-time bridge handoff

## Objective

Replace the mutable bridge event array with a preallocated single-producer,
single-consumer queue. The SwiftUI input path is the sole producer and the C++
render call is the sole consumer.

## Acceptance checks

1. Input submission never mutates the render event array directly.
2. The queue has a documented fixed capacity, deterministic newest-event drop
   behavior, and observable pending/drop status.
3. The render call consumes at most the kernel event cap, allocates no heap
   memory in bridge-level instrumentation, and returns finite bounded samples.
4. Normal, ASan/UBSan, and Swift package tests pass.

## Non-goals

This does not admit the full AVAudioEngine callback, add Core MIDI/MPE device
I/O, make expressions per-note, create the EngineRack, or establish a human
listening result.
