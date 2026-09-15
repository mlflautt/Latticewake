# Cycle 035 handoff — input multiplexer and panic recovery

Base: `417987b` (`v0.34.0-alpha.3`).

## Implemented

- Added `PerformanceInputMultiplexer`, the one main-actor producer for direct
  keyboard, pointer, MIDI, and MPE input. It owns visible held-note, pointer,
  source-aware voice, expression, and overload-recovery state.
- Assigned stable source tokens: keyboard, pointer, and one token per MIDI/MPE
  channel. A release or expression event therefore cannot affect the same pitch
  owned by another source.
- Routed the Stage’s direct-play and focus-loss behavior through the
  multiplexer. The Stage now shows each direct voice's source, note, glide,
  pressure, and slide values without reading callback state.
- Routed Core MIDI ingress through the same multiplexer. MIDI panic now requests
  a kernel panic rather than stopping the audio engine.
- Added `lw_kernel_panic`: a producer requests it atomically; the callback
  resets voices and discards already-pending events at the next render boundary.
  This makes event-queue overload recovery deterministic without a UI-thread
  mutation of live kernel state.

## Verification

- `make test`: pass; normal warnings-as-errors C++ core, bridge, and playable
  fixtures passed.
- ASan/UBSan build and fixtures in `/tmp/latticewake-cycle035-sanitized`: pass.
- `swift test`: pass; 14 XCTest cases, including background callback rendering
  and distinct MPE-channel source-token coverage.
- `LW_DEVICE_SMOKE=1 swift test --filter LatticewakeAppTests/testOptInDeviceSmoke`:
  pass. App-owned receipt: 48 kHz, 117 callbacks, 55,037 frames, maximum bridge
  render 219,209 ns, zero bridge budget misses, zero rejected blocks.
- `bash app/scripts/build_macos_app.sh`: pass; rebuilt standalone app is
  ad-hoc signed.
- Native UI lifecycle smoke: pass; the rebuilt app launched, entered Audition
  on Start, and returned to Ready on Stop without a crash.

## Runtime evidence and limitations

The local smoke confirms this revision starts and renders through the app-owned
device route. It does not prove Core Audio's internal allocation/lock behavior,
complete callback admission, native gesture feel, hardware MPE endpoint
behavior, or listening quality. No human listening or aesthetic verdict is
recorded.

## Next target

Complete the remaining callback-admission evidence: exact-route allocation and
lock instrumentation where available, buffer/sample-rate stress on the rebuilt
app, then a bounded hardware-MPE and gesture review protocol.

## Rollback

Revert the Cycle 035 commit. The change adds no scene-format migration and does
not rewrite saved scenes or source-media assets.
