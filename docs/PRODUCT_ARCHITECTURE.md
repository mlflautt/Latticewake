# Latticewake product architecture

Latticewake is a terrain-centered expressive synthesis instrument for artists:
a playable standalone macOS instrument first, and an AUv3 companion only after
the standalone real-time lifecycle is proven. It is not a DAW and will not host
third-party plug-ins.

## Artist-facing workspaces

**Terrain Stage** is the default: an authoritative Metal-backed 2D terrain
surface, direct play, role strip, engine macros, and runtime status. It renders
only immutable C++ terrain-frame snapshots; its Canvas contour overlay is visual
annotation, never audio state. 3D remains an optional secondary view. The Stage
stays playable while Library and Inspector drawers provide contextual depth.

The Cycle 057 product shell makes Perform, Sculpt, and Grow progressive depths
over that persistent Stage. A fixed top bar owns standalone audio, role
transport, scene actions, output, undo, diagnostics, and panic. Six prepared
scene controls form the first macro rail, while lane cards separate direct
performance from detailed lane editing. The current Canvas route remains the
admitted visual baseline; the retained Metal renderer is not described as
production-authoritative until its target-device cost is admitted.

Image and audio Surface descriptors are now visible to the UI without file
access from rendering. A future resolved image Surface uses its source image as
the dimmed coordinate plane, with interpreted contours, traversal, sampling
point, and voices registered above it. Offline analysis produces project-owned
assets and prepared tables; the callback never reads media files.

**Scene**, **Generator**, and **Library** are progressive workspaces over the
same canonical scene model. Scene edits terrain, harmony, roles, paths, and
transitions. Generator creates bounded previews. Library holds scenes, engine
patches, captures, receipts, and exports. Playable moments and evolving loops
precede timeline arrangement; full arrangements and network ensemble work are
not baseline commitments.

## Portable core

The C++ core owns canonical scene interpretation and audio rendering. SwiftUI,
Metal, Core Audio, Core MIDI, and a future AUv3 are adapters.

The current core has one prepared terrain voice. Scene v1 now separates
**Surface**, **Traversal**, and **Articulation**, and one portable
RenderPlanBuilder is the preparation authority for terrain tables and bounded
role timing. The later internal
**EngineRack** provides prepared slots with a stable expressive contract for
note identity, pitch/glide, velocity, pressure, slide, timbre, modulation,
gate, and panic. Terrain remains the signature engine; a terrain-excited
resonator is the first planned additional engine.

Four initial roles—Drone, Pad, Motif A, and Motif B—are the first performance
surface. Scene storage must evolve them as scalable named lanes, each routed to
prepared engine slots and a common harmonic, scale, transport, and terrain
context.

Persistent lane enable state belongs to the Scene. Mute and Solo are transient
performance masks: they prepare an effective runtime role set without changing
scene bytes, dirty state, receipts, or save output. Mute wins over Solo, and a
mask can never enable a lane disabled by the Scene.

Persistent lane edits use a separate double-buffered role-plan handoff. While
transport runs, the artist can distinguish edited, queued, and active values;
one complete prepared role plan becomes active at the exact loop wrap. The
handoff releases notes owned by the preceding role plan, does not replace the
terrain render plan, and performs no callback allocation. A second role edit is
rejected while one is pending rather than overwriting an in-flight plan.

## Real-time boundary

An explicit prepared handoff creates immutable render state before playback.
The render consumer receives only preallocated state and bounded events. It
never parses a Scene, accesses files, UI, Metal, networking, or an AI provider.
The current bridge uses two persistent prepared-plan slots and adopts a
published replacement only at an audio-block boundary.

The standalone bridge currently uses a fixed-capacity SPSC event queue between
the SwiftUI producer and C++ render consumer. Queue overflow drops the newest
event, increments a visible counter, and never blocks the consumer. This is a
single-producer contract; Core MIDI must later enter through an input
multiplexer rather than becoming a second producer. The C++ bridge has
render-call tests with zero observed C++ allocations, but the full AVAudioEngine route still needs
exact-path instrumentation, overload stress, and target-device evidence before
callback admission.

Core MIDI ingress is marshalled onto that same Swift main-actor producer and
uses a portable legacy/lower/upper MPE ownership state. Fixed terrain voices
now retain glide, press, and slide independently by note; hardware MPE and
MPE timing admission remain separate milestones.

## Generative and agent boundary

Generators and AI providers create typed, bounded preview proposals such as
`ScenePatch`, `Melody`, `Pattern`, `EnginePatch`, and `Automation`. They run off
the audio thread and cannot mutate a saved scene directly. Every proposal has
Preview, Accept, Reject, Undo, receipt, source, schema, seed, and lineage.

The first agent role is a proposal partner. A future artist-armed co-performer
may alter only explicitly selected lanes or parameters, with immediate disarm
and undo. Hermes, Codex, and other harnesses use this same proposal boundary;
they do not receive callback access or implicit commit authority. Apple
Intelligence is optional, availability-gated, on-device-first, and deferred
until proposal preview/commit is working.

## Release progression

1. Admit the standalone C++ bridge through measurable real-time evidence.
2. Build the luminous Metal Terrain Stage on the completed Scene v1 and
   RenderPlanBuilder foundations; complete direct-play and MPE admission.
3. Add Surface/Traversal/Articulation editing, modulation, audio-derived
   surfaces, Freeze and Grow, and deeper deterministic lanes.
4. Introduce the EngineRack, a resonator engine, prepared buses/effects, scene
   chains, captures, and export.
5. Add specialist proposal providers and optional Apple Intelligence; ship a
   focused AUv3 companion only after the standalone path is proven.
