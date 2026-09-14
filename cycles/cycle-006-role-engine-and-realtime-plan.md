# Cycle 006 — role engine and realtime admission plan

## Objective

Implement deterministic offline event generation for the four Scene roles and
define the separate admission contract required before moving any core component
onto an audio callback.

## Acceptance checks

1. A valid enabled four-role Scene produces a monotonic, reproducible trace for
   a fixed sample window and transport configuration.
2. Disabled roles produce no events; `tie` rhythm steps never create a new
   note-on event.
3. Invalid scenes, transport values, and event-cap overflow fail explicitly.
4. The real-time plan declares preallocation, queue, lifetime, and measurable
   admission requirements without claiming they are implemented.

## Non-goals

No audio callback/device, MIDI, voice allocator, actual pitch conversion,
model call, automatic scene mutation, or human/aesthetic selection.
