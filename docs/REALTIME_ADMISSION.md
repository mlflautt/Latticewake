# Real-time kernel admission gate

No current Latticewake component is admitted to an audio callback. Admission is
per component and requires evidence for the exact target build, not a claim
based on offline tests. Cycles 017–018 provide bounded C++ event handoff and
two-slot prepared-plan publication only; they are not evidence for the entire
AVAudioEngine path.

## Required contract

- Allocate every buffer, trace-free state object, and voice slot before start.
- Do not allocate, lock, wait, log, perform filesystem/network work, invoke a
  model, parse JSON, or touch UI/Metal APIs in the callback.
- Move non-audio work through bounded single-producer/single-consumer queues
  with specified overflow behavior. The current bridge drops newest events on
  overflow and exposes a drop counter. The audio side never waits for a
  producer.
- Publish immutable scenes and visual snapshots with explicit lifetime/epoch
  ownership; callback-visible data cannot be freed concurrently. The current
  two-slot plan bridge does not free either slot during playback and accepts at
  most one pending replacement.
- Set an explicit per-block event cap and a deterministic overload policy.
- Keep denormal, non-finite, and reset handling local and bounded.

## Evidence needed before admission

1. Allocation and lock instrumentation around the exact callback path.
2. Fixed-capacity and queue-overflow tests.
3. Stress tests at target sample rates, buffer sizes, and maximum voice/event
   counts, recording deadline misses and reset behavior.
4. A target-device listening and performance session, clearly recorded as human
   review rather than inferred from technical metrics.

Offline components—including the terrain renderer, parser, proposal preview,
oversampling harness, and role generator—remain outside this gate until they
are redesigned and evidenced for callback use.
