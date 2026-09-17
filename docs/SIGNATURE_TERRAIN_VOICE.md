# Signature terrain voice

Cycle 058 turns Scene v1's two Surface descriptors into one audible terrain
voice. For analytic scenes, `RenderPlanBuilder` prepares one normalized periodic
table per layer away from the callback. `surface.morph` is the scene's neutral
A/B position; per-note slide extends from that position toward B. The renderer
does not silently replace a flat or unresolved Surface with another oscillator.

## Stable performance controls

| Macro | Durable meaning |
|---|---|
| Morph | Neutral crossfade between prepared Surface A and B |
| Tone | One-pole output bandwidth from dark to open |
| Motion | Traversal rate through the prepared terrain |
| Drive | Normalized soft saturation amount |
| Space | Mix and feedback of the tempo-related cross-delay field |
| Release | Voice release time in seconds |
| Width | Depth of slow opposing left/right motion |

These names and meanings are candidates for the future AU parameter tree.
Their numeric automation addresses are not public or frozen yet.

## Real-time boundary

The output section owns fixed-size delay storage. It allocates and locks
nothing while rendering. Panic and reset invalidate delay history with a
warm-up counter rather than clearing the storage on the callback. The legacy
Scene v0 route retains its dry, open output defaults; new output values enter
only through explicit Scene v1 migration/editing.

## Starter and audition policy

The eight starter candidates are a coverage set, not a ranking: Sustained
Basin, Glass Thread, Warm Drift, Rough Orbit, Wide Bloom, Short Sparks, Deep
Drone, and Motif Current. Each produces unique canonical bytes and exposes its
macro values through the same bridge.

The offline audition harness renders two matched four-second fixtures from the
same scene: pitched MIDI-style notes and a continuous terrain gesture. Each WAV
has a receipt binding fixture name, scene hash, sample rate, and frame count.
Technical distinction does not establish beauty, usefulness, or artist
preference; those remain explicit listening decisions.
