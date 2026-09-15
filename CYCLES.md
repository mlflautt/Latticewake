# Latticewake development cycles

Latticewake advances through small, committed development cycles. A cycle is a
bounded technical increment, not a claim that its musical output has been
heard, approved, or preferred.

## Cycle protocol

1. Write the cycle brief: objective, owned paths, explicit non-goals, and acceptance checks.
2. Preserve the prior commit as the rollback point; do not rewrite history.
3. Implement only the stated scope and record deterministic fixtures or technical evidence where applicable.
4. Run the cycle's checks and record their commands and results in a handoff.
5. Commit the completed cycle with a `cycle-###:` conventional subject.
6. Offer the next bounded cycle as options. Human listening and creative preference remain separate review gates.

## Completed

### Cycle 001 — kernel contracts

- Commit: recorded after this document is committed.
- Scope: typed Scene v0 validation and canonical performance-event trace.
- Evidence: warnings-as-errors test build plus AddressSanitizer and UndefinedBehaviorSanitizer runs; see `handoffs/foundation-001.md`.
- Non-goals: audio rendering, DSP, UI, MIDI I/O, model execution, and artistic evaluation.

### Cycle 002A — analytic terrain evaluator

- Commit: recorded after this cycle is committed.
- Scope: deterministic, bounded scalar sampling for `mandelbrot` and `julia`,
  plus `ellipse`, `lissajous`, `spiral`, and `meander` paths.
- Evidence: fixed C++ fixtures cover supported families, path bounds, invalid
  inputs, and repeated evaluation.
- Non-goals: audio rendering/callback, image input, UI, MIDI, serialization,
  third-party dependencies, and artistic evaluation.

### Cycle 003A — scene serialization boundary

- Commit: recorded after this cycle is committed.
- Scope: strict, dependency-free JSON parsing and canonical JSON serialization
  for the typed Scene v0 model.
- Evidence: round-trip canonical-byte fixtures plus malformed, duplicate,
  unknown-field, unsafe-seed, unknown-role, and out-of-range rejection tests.
- Non-goals: files, audio, MIDI, UI, network behavior, and a general JSON API.

### Cycle 004A — offline terrain-voice scaffold

- Commit: recorded after this cycle is committed.
- Scope: deterministic trace-to-mono samples, one-pole DC blocking, and a
  conservative in-memory soft limiter.
- Evidence: deterministic-output, finite/range, DC-tail, and invalid-input
  C++ fixtures.
- Non-goals: device audio, callback integration, render files, playback, MIDI,
  UI, oversampling, and artistic evaluation.

### Cycle 005 — control and render foundation

- Commit: recorded after this cycle is committed.
- Scope: deterministic sample-clock transport, preview-only typed proposals,
  and an in-memory 1x/2x/4x interpolation/decimation harness.
- Evidence: transport timing, proposal-validation/preview ordering, and
  oversampling repeatability/finite-range C++ fixtures.
- Non-goals: audio device/callback, file output, MIDI, model connection,
  autonomous commit, UI, and aesthetic evaluation.

### Cycle 006 — role engine and realtime admission plan

- Commit: recorded after this cycle is committed.
- Scope: deterministic four-role offline trace generation and a written
  admission gate for any future audio-callback work.
- Evidence: repeatability, role-disable, monotonic-trace, and event-cap tests.
- Non-goals: audio callback/device, MIDI, voice allocation, pitch rendering,
  model connection, scene mutation, and artistic evaluation.

### Cycle 007 — direct play and terrain snapshots

- Scope: QWERTY note mapping, smoothed trackpad semantics, and immutable terrain frames.
- Evidence: mapping, smoothing, snapshot repeatability, and invalid-range tests.
- Non-goals: native UI, MIDI device I/O, Metal rendering, callback integration, and artistic evaluation.

### Cycle 008 — MPE state primitives

- Scope: portable legacy/lower/upper MPE state handling and per-note expression state.
- Evidence: deterministic state-machine fixtures.
- Non-goals: Core MIDI endpoints and audio-callback routing.

### Cycle 009 — product boundary and hardening

- Scope: native Swift package boundary, scene-byte storage, version/license, and CI.
- Evidence: core and Swift package verification.
- Non-goals: audible rendering or callback admission.

### Cycle 010 — real-time kernel candidate

- Scope: prepared terrain table, fixed voice/event caps, reset, DC blocking, and limiting.
- Evidence: normal and sanitizer C++ fixtures.
- Non-goals: queue handoff, device audio, or callback admission.

### Cycle 011 — audible standalone shell

- Scope: AVAudioEngine prototype, start/stop controls, and runtime status.
- Evidence: Swift package verification.
- Non-goals: terrain-kernel bridge proof or human listening evidence.

### Cycles 012–016 — bridge, direct play, and scene lifecycle

- Scope: opaque C ABI, C++ terrain render path, QWERTY note lifecycle,
  canonical Scene preparation/storage, and trackpad expression events.
- Evidence: C++ and Swift package checks recorded in their individual handoffs.
- Non-goals: SPSC queue handoff, Core MIDI device I/O, terrain UI, and callback
  admission.

### Cycle 017 — bounded real-time bridge handoff

- Scope: fixed SPSC input queue, status/overflow contract, bridge render
  allocation fixture, and audio closure lifetime narrowing.
- Evidence: normal, ASan/UBSan, and Swift package verification; see
  `handoffs/cycle-017.md`.
- Non-goals: complete AVAudioEngine admission, Core MIDI/MPE device I/O,
  EngineRack, Metal surface, model provider, or human listening evidence.

### Cycle 018 — immutable render-plan publication

- Scope: prepared terrain-plan contract, two persistent bridge plan slots,
  block-boundary adoption, and live scene publication from the Swift adapter.
- Evidence: deterministic plan, pending-plan, generation-transition, normal,
  sanitizer, and Swift package checks; see `handoffs/cycle-018.md`.
- Non-goals: complete callback admission, multi-producer ingestion, Core MIDI,
  Terrain Stage UI, EngineRack, or human listening evidence.

### Cycle 019 — Terrain Stage snapshots

- Scope: bounded C terrain-frame copy boundary and an immutable SwiftUI Canvas
  Stage trace derived from canonical Scene bytes.
- Evidence: deterministic/capacity core bridge fixtures plus a Swift snapshot
  preparation test; see `handoffs/cycle-019.md`.
- Non-goals: Metal or 3D rendering, live transport display, callback admission,
  MIDI, role controls, or human visual/auditory review.

### Cycle 020 — Core MIDI and MPE ingress

- Scope: Core MIDI source lifecycle, one main-actor ingress producer, portable
  legacy/lower/upper MPE state, and inbound note/expression routing.
- Evidence: bridge MPE ownership/reset fixtures, normal/sanitizer checks, and
  Swift MIDI packet decoding; see `handoffs/cycle-020.md`.
- Non-goals: hardware session, MIDI output, independent per-note MPE DSP,
  callback admission, or human listening evidence.

### Cycle 021 — per-note MPE kernel expression

- Scope: note-identified bridge events and fixed-voice glide/press/slide state
  with MPE active-note resolution.
- Evidence: deterministic different-target per-note expression fixture,
  bridge active-note fixture, normal/sanitizer/Swift checks; see
  `handoffs/cycle-021.md`.
- Non-goals: hardware MPE session, zone voice stealing, MIDI output, callback
  admission, or human listening evidence.

### Cycle 022 — four-role performance controls

- Scope: explicit canonical Scene role edits and saved-scene/terrain-plan refresh.
- Evidence: deterministic role-control bridge round trip and normal/sanitizer/Swift checks; see `handoffs/cycle-022.md`.
- Non-goals: live role sequencing, callback UI reads, human audition, or creative selection.

### Cycle 023 — role-event preview and replay

- Scope: an offline C ABI boundary for bounded four-role event generation, with
  a deterministic trace receipt surfaced in Terrain Stage.
- Evidence: repeated C++ and Swift fixtures compare the event count, range, and
  trace receipt for the same canonical Scene bytes.
- Non-goals: routing role notes into the audio callback, live sequencing,
  callback admission, hardware sessions, listening, or creative selection.

### Cycle 024 — callback-route preflight instrumentation

- Scope: bounded callback render counters, an explicit maximum block size,
  safe silence on rejected blocks, and preallocated C++ bridge-route stress.
- Evidence: allocation-probed 44.1/48/96 kHz stress at 32–1,024-frame blocks,
  queue traffic, counter checks, oversized-block behavior, normal, sanitizer,
  and Swift package checks; see `handoffs/cycle-024.md`.
- Non-goals: Core Audio internal lock/allocation proof, device deadline data,
  target-Mac performance, hardware MIDI, human listening, or callback admission.

### Cycle 025 — target-audition instrumentation kit

- Scope: app-owned bridge render-duration/budget telemetry, stop-time audition
  receipt, and a target-Mac protocol that preserves listener observations as
  human-provided evidence.
- Evidence: normal/sanitizer bridge tests check nonzero render-duration
  telemetry; the Swift package compiles the receipt path. See
  `handoffs/cycle-025.md`.
- Non-goals: a completed target-device run, Core Audio internal tracing,
  listener verdict, callback admission, or any automatic quality decision.

### Cycle 026 — standalone app packaging

- Scope: repeatable Apple-Silicon debug `.app` bundle assembly, local ad-hoc
  signing, and a stable bundle identity for the standalone audition target.
- Evidence: `app/scripts/build_macos_app.sh` builds, packages, and signs the
  app; normal, sanitizer, and Swift package checks pass. See
  `handoffs/cycle-026.md`.
- Non-goals: target-device callback receipt, hardware MIDI, listener
  observation, callback admission, or release notarization.

### Cycle 027 — callback isolation correction

- Scope: remove inherited `@MainActor` isolation from the AVAudioSourceNode
  render closure after the first target-Mac Start crash.
- Evidence: the callback captures only an explicitly sendable opaque render
  holder, dispatches to a `nonisolated` renderer, and normal/sanitizer/Swift
  checks pass; see `handoffs/cycle-027.md`.
- Non-goals: a replacement target-Mac callback result, listener observation,
  callback admission, or any creative assessment.

## Next-cycle options

### Cycle 028 — sustained terrain notes

Implemented: centered terrain table, envelope, interpolation, keyboard lifecycle,
explicit playable starter, objective pitch/energy tests and actual device smoke.
See handoffs/cycle-028.md. Full native input review and callback admission remain
open.

### Cycles 029–031 — accepted implementation sequence

Cycle 029 implementation checkpoint: see handoffs/cycle-029-checkpoint.md.
Automated gesture, spectral, glide, callback, and device checks pass. Native
input verification remains open; this is not a completed cycle.

029: both-mode gestures, prepared timbre morph, visible performance feedback.
030: implemented role transport, source-aware identities, and deterministic
sequencing; see handoffs/cycle-030.md. Target-device and listening evidence are
still separate from the technical fixtures.
031: versioned scene library, undo, captures, and three starter scenes;
implemented in `handoffs/cycle-031.md`. Full-Xcode Swift fixture evidence is
pending local Xcode licence acceptance.

Each target stays open until its stated functional tests pass. Device and human
observations remain separate evidence.

### Cycle 032 — baseline consolidation and architecture record

- Scope: consolidate the Cycle 031 app baseline, rebuild and smoke-test the
  exact target app, record the North Star v2 architecture, and define the
  luminous-cartography interface language.
- Evidence: normal and ASan/UBSan C++ suites pass; the signed app starts the
  device route, runs four active lanes, writes a deterministic eight-second
  capture, and stops with zero bridge budget misses or rejected blocks. See
  `handoffs/cycle-032.md` and `docs/REALTIME_ADMISSION.md`.
- Evidence: the hosted full-Xcode Swift suite passes. Local Swift tests remain
  unavailable until the installed Xcode licence is accepted; Command Line
  Tools on this host provide neither `Testing` nor `XCTest`. Native gesture
  feel, hardware MPE, human listening, and exact callback lock/allocation
  admission also remain open.

### Next implementation target — Cycle 033

Introduce Scene v1 and one portable `RenderPlanBuilder`, including deterministic
canonicalization, in-memory Scene v0 migration, stable component identities,
byte-preserved legacy files, and equivalent migrated render fixtures.

### Cycle 033 — Scene v1 and RenderPlanBuilder

- Scope: component-addressable Scene v1, deterministic in-memory Scene v0
  migration, two identified Surface layers, stable component IDs, reserved
  media asset descriptors, and one portable preparation authority.
- Runtime: the C bridge accepts v0 or v1 and builds terrain tables plus bounded
  role timing through `RenderPlanBuilder`. Explicit Save As writes Scene v1
  inside the existing performance-library envelope; legacy source bytes are
  never rewritten.
- Evidence: canonical v1 round trip, duplicate-ID/route-cap validation,
  v0-to-v1 render-buffer equivalence, role-trace equivalence, bridge migration,
  role editing without schema downgrade, normal/sanitizer suites, signed app,
  and hosted Swift fixtures. See `handoffs/cycle-033.md`.
- Retained work: component editors, media analysis, modulation execution, and
  expanded named lanes begin in Cycles 036–040. Cycle 034 is the next target.

### Cycle 034 — luminous Terrain Stage shell

- Scope: replaced the temporary Canvas waveform view with a Metal-backed
  immutable-terrain surface, visible direct/lane activity, a four-role deck,
  scene/output status hierarchy, and contextual Library/Inspector drawers.
- Runtime boundary: Metal consumes only `TerrainStageSnapshot`; its UI-owned
  vertex upload and contour overlay cannot read or stall callback state.
- Evidence: signed app build, native Stage review, responsive scroll behavior,
  and live Four Role Loop review showing four active lanes plus a nonzero output
  meter. See `handoffs/cycle-034.md`.
- Retained work: live terrain playhead animation, richer contour field density,
  full parameter editors, and a reduced-motion automation fixture remain open.
  Cycle 035 input/MPE admission is next.
