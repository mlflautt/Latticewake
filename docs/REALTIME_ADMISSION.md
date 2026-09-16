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

## Cycle 024 preflight evidence

The Swift `AVAudioSourceNode` closure now delegates directly to the bounded
`lw_kernel_render` entry point. Its route copies the already-rendered mono
buffer into any additional output buffers with C memory operations; it does not
parse scenes, request UI state, create role events, take an application lock,
or touch storage. The bridge counts successful blocks, frames, and rejected
oversized buffers through atomics. Blocks above its explicit 4,096-frame cap
are zeroed by the adapter rather than rendered with an unbounded span.

The bridge fixture preallocates its kernel and buffers, then exercises 400
callback renders at each of 44.1, 48, and 96 kHz over 32–1,024-frame blocks,
with note-queue traffic; it observes zero C++ `new` calls during those renders.
The same fixture verifies the oversized-block rejection and counters.

This is a source-level and bridge-level preflight, not admission. It does not
instrument Core Audio's internals, prove the Swift runtime performs no hidden
work, measure actual device deadlines, or replace the required target-device
performance and human listening session.

## Cycle 025 target-audition kit

The app now presents a stop-time audition receipt containing callback blocks,
rendered frames, maximum bridge-render duration, bridge-budget misses, and
rejected blocks. Duration is measured around the app-owned C++ renderer and
compared to the block's sample-time budget; it does not measure the entire
Core Audio scheduling path. The reproducible target-Mac procedure and a
listener-owned record template are in [TARGET_MAC_AUDITION.md](TARGET_MAC_AUDITION.md).

No completed target-Mac session or listening observation is recorded in this
repository. Therefore Cycle 025 provides instrumentation and protocol only;
it does not change the admission status above.

## Callback isolation correction

The first target-Mac Start attempt on `v0.26.0-alpha.1` crashed because its
source-node closure inherited `@MainActor` isolation and Core Audio invoked it
on an I/O thread. The callback now captures only an explicitly sendable opaque
render-state holder and calls a `nonisolated` render helper. It must be
recompiled and retested on the target route before any admission claim.

## Cycle 032 target-device smoke evidence

The exact rebuilt Cycle 032 app started its device route without reproducing
the isolation crash. The Four Role Loop starter reported four active lanes,
produced a nonzero output meter, completed an eight-second 48 kHz capture, and
stopped with this app-owned bridge receipt: 7,248 blocks, 3,409,460 frames,
maximum render duration 832 microseconds, zero bridge budget misses, and zero
rejected blocks. The capture receipt binds 384,000 frames to canonical scene
hash `eab26874b4d26c1333277074519511661d74d29b8f75fe815446deafa5fa842e`.

This closes the replacement-start smoke check only. Native trackpad gesture
feel, hardware MPE, human listening, and exact callback allocation/lock evidence
remain open. Consequently the admission status at the top of this document is
unchanged.

## Cycle 035 input boundary evidence

Cycle 035 makes the main-actor `PerformanceInputMultiplexer` the sole direct
performance producer for the bridge queue. It assigns distinct source tokens to
keyboard, pointer, and every MIDI/MPE channel, and its Swift fixture confirms
same-pitch MPE voices retain distinct identities. The bridge panic path is now
requested atomically by the producer and consumed by the callback, which resets
its active kernel and discards pending events at that block boundary.

Normal, sanitizer, Swift, and an opt-in local 48 kHz device smoke fixture pass
for the release revision. The smoke measured 117 callbacks and 55,037 frames
with zero app-owned bridge budget misses or rejected blocks. It does not measure
Core Audio internal allocations or locks, certify hardware MIDI/MPE behavior, or
constitute callback admission. The status at the top of this document remains
unchanged.

## Cycle 035 Core MIDI isolation correction

The `v0.35.0-alpha.2` target-Mac crash report identified a separate ingress
problem: Core MIDI invoked its packet block on a MIDI worker thread while the
block inherited main-actor isolation. `v0.35.0-alpha.3` stores a sendable packet
dispatcher that decodes packets off-actor and explicitly schedules delivery to
the main-actor input multiplexer. A Swift regression test calls that dispatcher
from a background queue and verifies receipt on the main actor.

`v0.35.0-alpha.3` showed the dispatcher alone was insufficient: because the
Core MIDI closure literal was still created in a main-actor method, its stored
callback retained the executor assertion. `v0.35.0-alpha.4` creates both client
and input-port blocks in nonisolated factory functions. Its Swift fixture sends
a packet through a virtual Core MIDI source and verifies delivery reaches the
main actor through the dispatcher.

This corrects MIDI ingress isolation only. It neither changes the audio callback
route nor supplies the allocation, lock, deadline, hardware-MPE, or listening
evidence required for callback admission.
