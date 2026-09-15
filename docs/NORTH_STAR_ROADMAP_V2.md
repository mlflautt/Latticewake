# Latticewake North Star Roadmap v2

## Product promise

Latticewake is a terrain-centered expressive instrument for creating living
musical scenes. Its defining creative loop is:

> Play the terrain -> shape its movement -> grow it into a scene -> freeze what
> matters -> generate variations -> capture or sequence the result.

It is a standalone macOS instrument first, an AUv3 companion later, and neither
a DAW nor a third-party plug-in host. The portable C++ engine is authoritative;
SwiftUI, Metal, Core Audio, Core MIDI, AUv3, and intelligence providers are
adapters.

## First principles

1. **Terrain is the instrument.** Other engines may join later, but the terrain
   remains the shared visual, harmonic, and gestural context.
2. **Sound is separable.** Surface describes sonic material, Traversal describes
   motion through it, and Articulation describes how a gesture becomes a voice.
3. **Depth stays contextual.** One continuous Stage opens focused drawers for
   Surface, Traversal, Articulation, Harmony, Lanes, Modulation, Routing, Grow,
   and Library. A patch graph is not the primary interface.
4. **Movement explains itself.** Every animation represents a path, voice,
   modulation value, lane event, transport state, or proposal difference.
5. **Generation preserves agency.** Freeze and Grow produces deterministic,
   bounded previews. Only the artist can accept, save, export, or publish them.
6. **The callback is austere.** It reads immutable prepared plans and bounded
   events; it never parses, allocates, locks, performs I/O, or invokes a model.
7. **Evidence is typed.** Tests can prove determinism, safety, and signal
   behavior; only a person supplies listening or aesthetic conclusions.

## Creative model direction

Scene v1 will organize durable state as Surface, Traversal, Articulation,
Harmony, LaneCollection, ModulationGraph, Routing, and Lineage. Scene v0 and
current library documents remain readable and are migrated only in memory.
Original files are never silently rewritten.

The real-time plan begins with eight simultaneous voices, sixteen named lanes,
four prepared engine slots, and thirty-two modulation routes. Keyboard,
pointer, MIDI/MPE, lane, and future agent events retain source-aware identity
through one input multiplexer.

## Delivery horizons

### Meta-cycle I: instrument truth and coherent foundations

- **032:** consolidate builds, tests, device evidence, architecture, and visual
  language; retain any unproven native interaction gate explicitly.
- **033:** introduce Scene v1 and one portable RenderPlanBuilder with v0
  migration and deterministic canonicalization.
- **034:** build the luminous Terrain Stage shell and authoritative Metal 2D
  contour surface from immutable snapshots.
- **035:** admit keyboard, trackpad, MIDI, and MPE interaction through the exact
  callback and target-device routes.

### Meta-cycle II: a living terrain language

- **036:** create independent Surface, Traversal, and Articulation editors.
- **037:** add bounded modulation assignment, scopes, live values, and matrix.
- **038:** derive non-destructive terrain surfaces from imported audio offline.
- **039:** add Freeze and Grow deterministic proposal previews.
- **040:** deepen Drone, Pad, Motif A, and Motif B into distinct generator
  families with deterministic traces.

### Meta-cycle III: broader instrument and composition ecosystem

- **041:** introduce the ExpressiveEngine rack and a terrain-excited resonator.
- **042:** add scene chains, semantic performance capture, stems, MIDI/MPE, and
  portable export without adding a DAW timeline.
- **043:** connect bounded Hermes, Codex, other harness, and optional
  on-device-first Apple Intelligence proposal providers.
- **044:** ship a focused AUv3 companion using the proven standalone engine and
  Scene v1 state.

## Cycle completion contract

Every cycle requires warnings-as-errors, normal and ASan/UBSan C++ checks, full
Swift tests when the licensed Xcode toolchain is available, a signed standalone
build, relevant callback/queue/overload tests, updated handoff evidence, a clean
worktree, an annotated tag, and a verified push. Visual milestones also require
native review; audible milestones keep technical receipts separate from human
listening observations.

