# Cycle 019 — Terrain Stage snapshots

## Objective

Build the first artist-facing Terrain Stage around immutable C++ terrain-frame
snapshots. The Stage displays an authoritative 2D trace of the scene path and
terrain values without allowing the audio callback to read UI state.

## Acceptance checks

1. A C ABI copies a bounded terrain frame into caller-owned memory from valid
   canonical Scene bytes; malformed inputs and zero capacity fail explicitly.
2. Repeated frame requests produce identical finite, normalized values.
3. SwiftUI prepares the frame on the main actor and renders its points in a
   dedicated 2D Stage view.
4. Core/bridge normal and sanitizer suites and the Swift terrain-snapshot test
   pass.

## Non-goals

No frame is generated in the audio callback. This is a 2D trace surface, not a
Metal renderer, full 2D field raster, 3D fractal view, live transport visual,
scene editor, Core MIDI, or a listening claim.
