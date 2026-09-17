# Latticewake productization roadmap v4

## Purpose

This roadmap turns the technically credible standalone prototype into a
beautiful, immediately playable terrain instrument and then into a dependable
AUv3 companion. It supersedes the cycle numbering in Roadmap v3 without
discarding its architecture: Scene v1, RenderPlanBuilder, source-aware events,
bounded proposal providers, and the portable C++ renderer remain the
foundation.

The next phase is judged by the artist's experience as well as by technical
evidence. A passing renderer is necessary, but it is not a finished
instrument. The product must make the following loop obvious:

**Play → Shape → Move → Grow → Capture.**

## Current truth at Cycle 056

The repository has a strong late-prototype foundation:

- a portable eight-voice terrain renderer with pitch, envelopes, expression,
  source-aware identity, bounded queues, panic, and deterministic overload;
- canonical Scene v1 data, legacy migration, hashes, lineage, undo, capture,
  and a single RenderPlanBuilder preparation authority;
- standalone AVAudioEngine playback, QWERTY and trackpad performance, Core
  MIDI foundations, deterministic four-role generation, loop-boundary role
  publication, Freeze and Grow, and typed agent proposals;
- signed local app builds, sanitizer coverage, crash triage, exact-build launch
  receipts, and guarded single-instance review runs.

It is not yet a release-ready plug-in or a finished visual instrument:

- the repository has no AUv3 extension or Xcode Audio Unit target;
- the main SwiftUI view is still a monolithic, vertically stacked engineering
  console rather than a stable instrument layout;
- the production Stage uses the Canvas fallback while the retained Metal path
  awaits admission;
- the sound palette, output treatment, deep terrain editing, modulation,
  hardware MPE evidence, and human listening evidence remain limited;
- technical diagnostics are more prominent than they should be for an artist.

These are productization gaps, not reasons to replace the core architecture.

## Product principles

### 1. Immediate sound, legible cause

In the standalone app, one clearly labeled audio action may be required. After
that, a key or terrain gesture must create sustained sound immediately. In the
AUv3, there is no Start button: the host owns rendering and MIDI begins sound.

Every meaningful sound change should have a visible cause on the Stage. Motion
that does not communicate traversal, voice, modulation, transport, proposal,
or overload does not belong in the interface.

### 2. The Stage is the instrument

The terrain remains visible and playable while the artist browses scenes,
sculpts components, edits lanes, or grows variations. Inspectors are contextual
drawers, not replacement pages. Diagnostics are hidden behind one disclosure
and never compete with transport, sound, or scene identity.

### 3. Progressive disclosure, not feature concealment

The app has three working depths over one continuous Stage:

- **Perform:** scene, transport, terrain, six to eight musical macros, four
  lane cards, output, save state, undo, and panic.
- **Sculpt:** focused Surface, Traversal, Articulation, Harmony, Modulation, and
  Routing inspectors with live prepared preview, A/B, undo, and reset.
- **Grow:** frozen-component map, bounded candidates, changed-field summary,
  lineage, Preview, Accept, Reject, and Undo.

The artist should not have to understand RenderPlan generations, queue depths,
or hashes in order to make music.

### 4. Luminous cartography with restraint

The visual language uses a graphite/navy field, fine topographic contours,
high-contrast typography, and restrained light. Cyan identifies direct
traversal; amber, violet, mint, and coral identify the four default lanes.
Color is always paired with a label, shape, motion, or state word.

Glow is reserved for energy and focus. Cards use hierarchy and spacing rather
than a border around every value. Reduced motion, scalable type, keyboard
navigation, non-color status, and usable compact plug-in dimensions are part
of the primary design, not later polish.

### 5. Stable concepts across standalone and AUv3

Scene, terrain, traversal, expressive voices, lane identity, macros,
modulation, and proposal semantics stay identical in both products. The
standalone adds library, import, capture, and full Grow workflows. The AUv3 is
a focused performance, automation, and recall companion; it does not embed a
second architecture.

### 6. Technical and aesthetic evidence remain separate

Pitch accuracy, spectral difference, deterministic replay, callback timing,
state restoration, and screenshot geometry can be tested automatically. Tone,
feel, beauty, usefulness, and preference require explicit human review. Scene
candidates remain unranked until that review occurs.

## Target interface architecture

The desktop window is a persistent spatial instrument rather than a scrolling
form:

```text
┌ Scene / save ─ Perform | Sculpt | Grow ─ Transport ─ Tempo ─ Output ─ Panic ┐
│ Library │                                                             │ Inspector
│ scenes  │                 TERRAIN STAGE                               │ context
│ grow    │     contours · traversal · playhead · voices · modulation  │ controls
│ capture │                                                             │ A/B/undo
├─────────┴─────────────────────────────────────────────────────────────┴─────────┤
│ Macro 1       Macro 2       Macro 3       Macro 4       Space       Motion     │
├────────────────────────────────────────────────────────────────────────────────┤
│ DRONE            PAD               MOTIF A            MOTIF B                  │
│ state/activity    state/activity    state/activity     state/activity           │
└────────────────────────────────────────────────────────────────────────────────┘
```

The top bar never moves. The center Stage receives the largest area. Left and
right drawers overlay or compress the Stage according to available width;
they do not push essential transport below the fold. The lane strip is a
performance surface first and an editor only when a lane is selected.

### State vocabulary

The same words and visual treatments are used everywhere:

- **Selected** means receiving edits, never automatically sounding.
- **Armed** means eligible to sound.
- **Sounding** means currently producing or scheduling audio.
- **Muted** and **Soloed** are transient performance masks.
- **Edited** means the scene differs from the active runtime plan.
- **Queued** means a prepared change is waiting for its deterministic boundary.
- **Active** means the callback adopted the prepared state.
- **Preview** is temporary and cannot overwrite saved state.
- **Frozen** cannot be changed by Grow or an agent proposal.
- **Saved/Changed** describes document state, not audio state.

## Shared plug-in architecture

The plug-in work should create explicit products around the existing portable
core:

```text
Scene v1 + assets
        │
RenderPlanBuilder ──> immutable RenderPlan / role plans
        │
portable C++ LatticewakeCore
        │
opaque C/Objective-C++ adapter
   ┌────┴───────────┐
Standalone host     AUv3 AUAudioUnit
AVAudioEngine       host render block
   └────┬───────────┘
shared Swift product model + SwiftUI instrument views
```

The AUv3 must not run AVAudioEngine internally. Its render block consumes the
same immutable plans and bounded events as the standalone adapter. The host
supplies sample rate, render resources, transport, tempo, MIDI/MPE, and render
frames.

Only stable performance controls enter the AU parameter tree. Deep scene
structure remains versioned full state. The initial parameter surface should
be deliberately small: terrain morph, contour/detail, traversal rate and
shape, motion, timbre, attack, release, expression amount, lane levels, space,
and output. Addresses never change after the first public plug-in release.

Full state contains canonical Scene v1 bytes, performance masks, macro values,
asset references or bundled assets, and schema/program versions. Restoring a
Logic project must not depend on the standalone library or arbitrary external
paths.

## Delivery plan

### Meta-cycle IV — Make the instrument desirable

#### Cycle 057 — Experience system and fixed Stage shell

**Reachable target:** a new user can identify scene, play surface, transport,
lanes, sound controls, save state, undo, and panic without scrolling or opening
Diagnostics.

- Split the monolithic `ContentView` into product state, app shell, top
  transport, Terrain Stage, macro rail, lane strip, contextual drawers, status,
  and diagnostics components.
- Add a documented design-token layer for color, type, spacing, corner radius,
  focus, selected, armed, sounding, queued, preview, frozen, dirty, warning,
  and error states.
- Introduce Perform, Sculpt, and Grow modes over the persistent Stage.
- Make Library and Inspector true adaptive drawers. At compact AU widths, show
  one drawer at a time; at large standalone widths, allow both.
- Put Audio/transport, role transport, output, save state, undo, and panic in
  the fixed top bar. Remove duplicated status prose from the performance area.
- Add deterministic view-model fixtures, accessibility identifiers, and
  screenshot baselines at compact, standard, and large sizes.

**Acceptance:** no essential action falls below the fold at supported sizes;
keyboard navigation reaches every action; selected and sounding remain
independent; reduced motion and large text remain usable; native review can
complete the five-second comprehension task.

#### Cycle 058 — Signature terrain voice and first-impression palette

**Reachable target:** opening any starter scene produces a stable, recognizably
different, musically controllable terrain voice rather than a thin technical
demonstration.

- Make both Scene v1 Surface layers and their morph audible through one
  prepared terrain voice path.
- Improve table normalization, interpolation, band-limiting/oversampling where
  measurement shows it is needed, and gain staging across pitch and polyphony.
- Add a bounded musical output section: tone/filter, saturation or contour,
  stereo motion, tempo-aware delay, and a conservative spatial/reverb stage.
  All state is prepared or preallocated; bypass must be deterministic.
- Define six to eight high-value performance macros with stable semantics
  across scenes and the future AU parameter tree.
- Produce eight to twelve technically valid, deliberately varied starter
  scenes spanning sustained, percussive, glassy, rough, warm, spacious, drone,
  and motif-supporting use cases. Do not rank them aesthetically.
- Render matched MIDI and gesture demonstrations with receipts for human
  audition.

**Acceptance:** pitch and release regressions pass; no clicks on note, plan, or
scene boundaries; candidates have measurable spectral/dynamic distinction;
polyphonic peak and limiter behavior remain bounded; the artist supplies the
first explicit palette and macro feel observations.

#### Cycle 059 — Terrain Stage 2 and expressive gesture

**Reachable target:** touching the terrain feels causally connected to the
sound, and the Stage explains the voice without text instructions.

- Admit the retained Metal route or replace it with a measured equivalent;
  Canvas remains a fallback, not a silent claim of Metal authority.
- Render two surface layers, morph, contours, traversal path, current sample,
  direct voices, lane playheads, expression vectors, and modulation energy from
  immutable visualization snapshots.
- Add focus, hover, drag, multi-note shaping, resize, focus-loss, and gesture
  release behavior with visible ownership.
- Add a short dismissible first-play overlay and contextual tooltips rather
  than permanent instruction paragraphs.
- Cap visual refresh independently of audio and drop stale frames.

**Acceptance:** Stage input-to-feedback latency and snapshot cost meet measured
budgets; resize and scale preserve gesture mapping; visual stalls cannot affect
audio; native review verifies that key, pointer, path, and lane activity are
understandable.

#### Cycle 060 — Sculpt workflow and component exchange

**Reachable target:** an artist can change Surface, Traversal, or Articulation
while preserving the other two, compare the result, undo it, and save it.

- Replace the long slider stack with focused Surface, Traversal, Articulation,
  and Harmony inspectors using instrument-appropriate controls and meaningful
  units.
- Coalesce edits into off-callback prepared previews. Remove the routine need
  for a generic “Apply Scene Changes” button while retaining explicit commit
  semantics for A/B and Grow proposals.
- Add component preset browsing, initialize, copy/paste, safe deterministic
  randomize, values-only versus values-plus-modulation loading, A/B, undo, and
  reset.
- Keep flat, noisy, nonperiodic, and invalid traversal diagnostics close to the
  affected control, with a suggested recovery that never substitutes an
  unrelated oscillator.

**Acceptance:** the five-minute task—alter each component, compare A/B, undo,
and save—requires no Diagnostics knowledge; previews never mutate saved state;
every publication is prepared outside the callback and traceable.

#### Cycle 061 — Performance lanes and musical scene flow

**Reachable target:** the four lanes feel like an ensemble the artist can
conduct, not a form of parameters above the Stage.

- Turn each lane into a compact performance card with armed/sounding state,
  activity trace, level, mute, solo, variation, and one role-specific macro.
- Put detailed density, range, pattern, seed, routing, and loop-boundary state
  in the selected lane inspector.
- Add clear Play/Stop, loop position, quantized edit publication, and semantic
  recovery when a queue saturates.
- Expand role musicality with bounded voicing, voice leading, rhythm preview,
  and deterministic variations while retaining source-aware note identity.

**Acceptance:** each lane is independently audible and visually identifiable;
buffer size does not alter event timing; edits clearly progress through Edited,
Queued, and Active; Stop, panic, overload, and scene replacement leave no lane
voices active.

### Meta-cycle V — Make it expressive and dependable

#### Cycle 062 — Modulation and macro language v1

**Reachable target:** assign motion or expression to a selected control in two
actions, then understand its depth and scope while playing.

- Complete the bounded 32-route prepared modulation graph.
- Support gesture X/Y, velocity, pressure, slide, key tracking, lane phase,
  envelopes, LFOs, macros, note-random, and seeded fractal noise.
- Make selected-parameter assignment the primary workflow; keep a matrix as an
  overview and troubleshooting view.
- Show live modulation with restrained rings/trails and explicit per-note,
  per-lane, per-engine, or global scope.
- Reject cycles and cap overflow before publication.

**Acceptance:** deterministic replay, scope isolation, smoothing, cap behavior,
cycle rejection, visible/rendered value agreement, and zero callback allocation
pass.

#### Cycle 063 — Real-time, MIDI/MPE, and device admission

**Reachable target:** standalone performance is technically admitted on the
target Mac and survives realistic expressive use.

- Instrument the exact AVAudioEngine callback for allocation, lock, deadline,
  queue, reset, and plan-publication behavior.
- Complete Core MIDI endpoint lifecycle, sustain, legacy MIDI, lower/upper MPE
  zones, reconnect, endpoint loss, and deterministic voice exhaustion.
- Run supported sample-rate/buffer matrices, rapid scene and role changes,
  focus changes, sleep/wake, device changes, and a long soak.
- Use one exact-build review instance and close it after every automated run.
- Record technical receipts separately from human feel and listening notes.

**Acceptance:** the real-time admission document can truthfully mark the tested
standalone route admitted; hardware MPE and device-change sessions pass; no
stuck voices, duplicate apps, unbounded work, or unexplained crashes remain.

### Meta-cycle VI — Deliver the initial AUv3

#### Cycle 064 — Shared product modules and AUv3 shell

**Reachable target:** Logic discovers an instrument Audio Unit that renders the
same deterministic Scene v1 sound as the standalone app.

- Create a maintained Xcode workspace with shared core, bridge, product model,
  SwiftUI instrument views, standalone target, tests, and AUv3 extension.
- Implement an `AUAudioUnit` render-resource and internal-render-block adapter;
  do not embed AVAudioEngine in the extension.
- Add one MIDI input bus, stereo output, bounded render events, panic, and
  immutable RenderPlan publication.
- Add stable AU parameter addresses for the approved performance macros.
- Establish bundle identifiers, entitlements, versioning, signing, install,
  uninstall, and exact-bundle verification without disturbing unrelated Audio
  Units.

**Acceptance:** `auval` passes; Logic inserts one exact-build instance; C/E/G
MIDI renders; standalone and AUv3 deterministic fixtures match within tolerance;
opening or closing the plug-in creates no extra standalone process.

#### Cycle 065 — Host state, automation, tempo, and compact UI

**Reachable target:** save a Logic project, reopen it, and recover the same
scene, sound, automation, transport relation, and UI state.

- Implement `fullState` restoration with canonical Scene v1, macro values,
  masks, versions, and portable required assets.
- Connect host tempo, beat position, play state, offline rendering, automation,
  MIDI/MPE, and bypass.
- Adapt the shared Stage to compact, standard, and expanded plug-in sizes.
  Library/import/capture remain standalone capabilities; performance and Sculpt
  stay available in the plug-in.
- Add migration fixtures before any public parameter or state schema freezes.

**Acceptance:** Logic project reopen, duplicate instances, preset recall,
automation write/read, tempo changes, offline bounce, MIDI/MPE, and state
migration pass with exact revision receipts.

#### Cycle 066 — Initial plug-in release candidate

**Reachable target:** a new musician can insert Latticewake, choose a scene,
play expressively, shape the terrain, conduct the lanes, automate macros, and
reopen the project without developer guidance.

- Curate—but do not silently rank—the first artist-reviewed scene library and
  macro defaults.
- Add a concise first-run tour, embedded help, keyboard/MPE map, accessible
  names, recovery messaging, and a diagnostics export.
- Complete CPU/memory profiling, multi-instance stress, host validation,
  installation, code signing, notarization where credentials permit, semantic
  versioning, changelog, and rollback package.
- Run task-based UX review in both standalone and Logic: first sound, first
  edit, first lane variation, first save/recall, and first automation.

**Acceptance:** all technical gates pass on the exact release candidate; no
critical UX task requires hidden knowledge; remaining aesthetic choices are
recorded as human decisions rather than inferred from tests.

## Post-initial-release horizon

After Cycle 066, resume the broader North Star in this order:

1. deterministic image- and audio-derived Surfaces;
2. EngineRack plus terrain-excited resonator and prepared buses;
3. scene chains, semantic performance capture, stems, MIDI/MPE, and exports;
4. richer Freeze and Grow providers and documented external-agent adapters;
5. optional availability-gated Apple Intelligence proposals;
6. an explicitly armed, narrow co-performance mode only after proposal safety
   and undo are trusted.

## Experience gates

Every interface milestone is reviewed through the same tasks:

- **Five seconds:** identify where to play, whether audio is active, the scene,
  transport, output, save state, undo, and panic.
- **Thirty seconds:** play three pitches, make a terrain gesture, hear and see a
  response, and stop safely.
- **Five minutes:** sculpt Surface, Traversal, and Articulation; enable a lane;
  compare; undo; and save.
- **Fifteen minutes:** freeze a trusted component, preview variations, accept or
  reject one, capture the result, and return to the saved scene.
- **Plug-in recall:** insert in Logic, play without an internal Start action,
  automate a macro, save, quit, reopen, and recover exactly.

Passing a scripted task establishes usability evidence, not beauty. Each major
visual and audible milestone includes a short exact-build human review with
specific prompts and room for open observations.

## Quality and release policy

Every implementation cycle closes with the standing normal, warnings-as-errors,
ASan/UBSan, Swift, callback, bundle, exact-SHA CI, handoff, commit, annotated
tag, and verified push requirements. Callback-facing cycles additionally test
allocation, locks, queue saturation, plan publication, reset, deadline, and
supported device formats. Visual cycles add size, large-text, reduced-motion,
keyboard, accessibility, and native screenshot review. Audible cycles add
matched rendered examples and explicit human listening without converting
measurements into taste.

The current unpushed Cycle 056 commit and tag must be published and its native
Edited → Queued → Active review closed before Cycle 057 is released. That
closure does not prevent local design implementation from beginning.

## Expected progress

These are planning estimates, not completion claims:

- after Cycle 061: compelling standalone instrument foundation, roughly 80%
  of an initial standalone and 65–75% of its intended first-release UX;
- after Cycle 063: admitted standalone performance path, roughly 90% of the
  initial standalone and 80–85% of its first-release UX;
- after Cycle 065: functionally complete initial AUv3, roughly 75–85% of an
  initial dependable plug-in pending final release review;
- after Cycle 066: credible v0.1 standalone plus AUv3 release candidate, while
  the larger media, EngineRack, composition, and intelligence vision remains a
  multi-release program.

The target is not feature parity with mature commercial synthesizers in ten
cycles. The target is a smaller instrument with a clear identity, excellent
fundamentals, reliable recall, and an interface musicians want to return to.
