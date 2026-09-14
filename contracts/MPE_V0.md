# Latticewake MPE v0 contract

MPE is an expressive input/output route. It does not replace the four musical
role lanes or turn the application into a sixteen-part multitimbral engine.

## Inputs

Each inbound endpoint is configured as exactly one of:

| Mode | Required behavior |
| --- | --- |
| `legacy` | Read note, velocity, sustain, pitch bend, channel pressure, and CC74 from one selected channel. |
| `mpeLower` | Treat channel 1 as the master and ascending configured member channels as per-note channels. |
| `mpeUpper` | Treat channel 16 as the master and descending configured member channels as per-note channels. |

The voice allocator combines master-channel state with member-channel state at
note render time. A member channel cannot represent two independently
expressive active notes. If a configured zone is exhausted, the selected voice
steal policy is applied and recorded in the trace; the engine does not silently
merge notes onto one member channel.

## Semantic expression

| Semantic value | MIDI source | DSP destination |
| --- | --- | --- |
| `glide` | per-note pitch bend | pitch ratio and optional path translation |
| `press` | channel pressure | amplitude/terrain-detail mapping selected by scene |
| `slide` | CC74 | path radius, terrain zoom, or spectral mapping selected by scene |

All incoming continuous controls are normalized, range-mapped by an explicit
scene mapping, and smoothed in the C++ core. UI-event rate and trackpad polling
rate must never define audio-rate behavior directly.

## Outputs

Each role lane has an optional `midiRoute` containing endpoint ID, mode, master
channel, member-channel count, and note range. Outbound MPE allocates a free
member channel for each generated note, emits expression only on that note's
member channel, and resets/reclaims it on note end, transport stop, panic, or
scene replacement.

## Required tests

- Lower/upper zone decoding and legacy fallback.
- Glide, press, and slide affect only the owning active note.
- Exhaustion applies the declared voice-steal policy and leaves no stuck note.
- Stop, panic, and scene replacement reclaim every outbound member channel.
- Sample-time trace reproduces note and expression event order.
