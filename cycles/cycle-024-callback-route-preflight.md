# Cycle 024 — callback-route preflight instrumentation

This cycle hardens the app-owned callback route without declaring it admitted.
The AVAudioSourceNode closure now delegates only to the bounded C++ renderer
and C memory copies. The C bridge records callback blocks, rendered frames,
and rejected renders through atomics. A 4,096-frame ceiling gives oversized
buffers deterministic silence rather than unbounded work.

The bridge stress fixture preallocates its kernels and output buffer, injects
queue traffic, and renders 400 blocks at 44.1, 48, and 96 kHz across
32–1,024-frame sizes while a test-only allocation probe is active. It also
checks counter totals and oversized-block behavior.

This is deliberately preflight evidence. It does not measure Core Audio's own
internals, hardware deadlines, target-Mac behavior, or human listening.
