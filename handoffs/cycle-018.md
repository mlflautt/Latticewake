# Cycle 018 handoff — immutable render-plan publication

## Base and scope

- Base: `4ba07df` (`cycle-017: add bounded bridge event handoff`).
- Owned paths: portable prepared-plan API, bridge plan slots and ABI, Swift
  scene publication adapter, core/bridge tests, architecture/admission docs,
  cycle ledger, version, and this handoff.
- `PreparedTerrainPlan` holds a precomputed terrain table and sample rate.
  `LWKernelRef` owns two persistent plan slots. The UI-side producer prepares
  only the inactive slot, assigns a monotonic generation, then publishes its
  index. The render consumer adopts the index before draining/rendering its next
  block, then releases the former active slot for a later producer write.

## Verification

```text
make clean && make test
make clean && make test CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1 -fsanitize=address,undefined -fno-omit-frame-pointer'
cd app && swift test
```

All checks passed locally on Apple Silicon. Fixtures prove deterministic plan
tables, post-render initial-prepare rejection, one-pending-plan publication,
generation transition at render boundary, and zero observed C++ `operator new`
allocations in the bridge render/adoption call.

## Runtime evidence and limitations

The native adapter can now publish a valid saved Scene while running; parsing
and preparation occur on the main-actor producer side, not in the render call.
This does not prove the complete AVAudioEngine callback path is allocation- or
lock-free, deadline-safe, or ready for admission. `lw_kernel_reset` remains a
stopped-lifecycle operation. There is no target-device stress session, Core
MIDI endpoint, per-note MPE kernel ownership, Metal surface, EngineRack, AI
provider, or human listening evidence.

## Integration and rollback

Cycle 019 can publish immutable terrain-frame snapshots into the Stage UI;
Cycle 020 can add a designated Core MIDI ingress multiplexer. Roll back with
`git revert` of the Cycle 018 commit; no external state is changed.
