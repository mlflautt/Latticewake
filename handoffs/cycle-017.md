# Cycle 017 handoff — bounded real-time bridge handoff

## Base and scope

- Base: `a8945ba` (`cycle-016: add bounded expression input`).
- Owned paths: bridge ABI/implementation, fixed SPSC queue, bridge and core
  tests, Swift audio lifetime capture, product architecture, cycle records,
  README, and version.
- The bridge now owns a 1,023-event usable SPSC queue. SwiftUI input submits
  events as producer; the C++ render call drains a maximum of 256 events per
  block. Overflow drops the newest event and increments a counter exposed via
  `LWKernelStatus`.

## Verification

```text
make clean && make test
make clean && make test CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1 -fsanitize=address,undefined -fno-omit-frame-pointer'
cd app && swift test
```

All three passed locally on Apple Silicon. Bridge fixtures cover saturation,
newest-event rejection, pending/drop status, fixed 256-event drain, reset, and
zero observed C++ `operator new` allocations during `lw_kernel_render`. Core tests continue
to cover finite bounded kernel output and note-specific release behavior.

## Runtime evidence and limitations

The AVAudioSourceNode closure now captures only the prepared opaque C++ handle,
not mutable Swift object state. This reduces the bridge boundary, but it is not
full callback admission: the exact AVAudioEngine route has not received lock
instrumentation, supported-buffer deadline stress, or target-device evidence.
There is no Core MIDI endpoint, per-note MPE ownership, EngineRack, Metal
terrain surface, AI provider, or human listening evidence.

## Integration and rollback

The next cycle should define immutable prepared render-plan handoff and exact
callback-path instrumentation before claiming admission. Core MIDI needs a
designated input multiplexer because this queue deliberately allows one
producer. Roll back with `git revert` of the Cycle 017 commit; no external
state is changed.
