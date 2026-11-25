# Latticewake development roadmap v5

This is the active planning sequence after Cycle 068. It refines
[roadmap v4](PRODUCTIZATION_ROADMAP_V4.md) without renumbering completed
cycles. The [research assessment](../research/INSTRUMENT_DESIGN_RESEARCH_SYNTHESIS.md)
records the evidence, accepted direction and rejected assumptions. The
instrument is a standalone prototype today; an AUv3 extension and its host
validation are future work.

## North star

Play a recognizable terrain voice, see the relationship between a surface and
its prepared traversal, shape it with direct gesture, grow reproducible musical
roles, preserve trusted parts, and capture or recall the scene. Explore a
shared landscape at audio and musical timescales without forcing every surface
edit to change both timbre and notes. Human listening and aesthetic preference
remain explicit decisions.

## Next milestones

### Cycle 069 — honest first-use path and native scene round trip

Status: **partial**. Native image import, preview, accept, device meter response
and scene-file creation were observed. Native reload and UI capture remain open
after computer-use accessibility timeouts; see `handoffs/cycle-069.md`.

- Exercise one controlled image through Choose, Preview, Accept, play, Save As,
  close/reopen, Load and capture with one managed app instance and generated
  fixture media. Verify the saved image field and source hash survive and the
  original media and previously saved scene remain intact.
- Record concrete state and device evidence, fix failures found in that path,
  and separately record any human listening observations if volunteered.
- **Gate:** a successful technical native round trip on the exact build; failure
  remains open. Do not treat a screenshot or offline test as a listening result.

### Cycle 070 — image and sound measurement harness

- Build a small, licensed or generated fixture corpus: flat, gradient, hard
  edge, fractal, alpha and contrasting images. Preserve source hashes, provider
  settings, scene, path, note, seed, sample rate and output hashes.
- Measure pitch, RMS/peak, DC, seam discontinuity, high-frequency alias energy
  against a documented high-rate reference, preparation latency and memory.
  Render matched examples for artist review without aesthetic ranking.
- Compare existing luminance with one independently controlled alternative
  interpretation and, separately, a band-limiting candidate. Do not combine
  multiple DSP changes in one comparison or replace existing scene behavior.
- **Gate:** reproducible measurement protocol, repeatable files, declared limits
  and at least one understandable A/B comparison; musical approval remains human.

### Cycle 071 — real-time and voice ownership audit

- Audit actual plan publication and retirement, source-aware events and role
  generation, MIDI thread handoff, panic, overload and stopped-audio behavior.
- Define note instance and scene-transition ownership before changing behavior;
  cover overlapping chord notes per lane, voice steal, sustain and reconnect.
- Measure exact device callback allocations, locks and deadline behavior at
  supported rates and buffer sizes. Compare event timing across buffers and
  document numerical tolerances separately from bitwise reproducibility.
- **Gate:** no stuck notes in fixtures and target-device stress evidence for the
  exact route; unmeasured lock or device behavior remains unadmitted.

### Cycle 072 — visual and gestural truth

- Fix known compact Stage issues, verify horizontal scrolling and accessibility,
  and make direct gesture's pitch and timbre effects explicit. Keep image,
  interpretation, contours and path registered under resize and display scale.
- Prototype an independently controlled slow terrain walker and visible anchor
  for one lane; keep note generation and timbre movement separately enabled.
  Compare its trace across seeds and buffers. Do not present it as a live
  audio-rate cursor if the audio still reads prepared tables.
- **Gate:** native resize and gesture review plus reproducible walker trace;
  require artist feedback before generalizing to four coupled lanes.

### Cycle 073 — focused AUv3 foundation

- Create a minimal extension and host adapter around the portable C ABI, with
  no internal AVAudioEngine. Define initial stable parameter IDs and a bounded,
  versioned state envelope for canonical scenes and required assets.
- Host MIDI, resource lifecycle, sample rates, transport and state restoration
  are separate acceptance points. Measure embedded state size and recall cost;
  do not assume bookmarking or a particular sandbox behavior is necessary.
- **Gate:** automated validation and a real Logic insertion, note rendering,
  project save/reopen and restored scene test. Standalone remains the full lab.

### Cycle 074 — Freeze and Grow in musical context

- Validate independent locks for Surface, Traversal, Harmony and individual
  lanes; preview deterministic variations with exact changed fields, A/B,
  explicit acceptance, rejection, undo and receipts.
- Add a single bounded generator or walker-informed variation only after its
  behavior is inspectable. Typed Melody and ScenePatch proposals may come from
  local deterministic code or an external harness, with no direct commit.
- **Gate:** frozen data is unchanged, seed replay matches, rejection changes
  nothing, acceptance is undoable, and a musician can assess usefulness.

## Later, subject to evidence

Image channels beyond the first comparison, audio-derived surfaces, resonators,
scene chains, audio/MIDI exports beyond the existing capture, optional Apple
Foundation Models, and explicitly armed co-performance remain candidates.
Avoid making a new framework, a specific channel count, a 3D renderer, or an
untested numerical threshold a prerequisite for the first usable instrument.
The release gates remain normal and sanitizer checks, relevant callback and
device checks, signed builds, native review when applicable, committed code,
annotated tag, push, and exact-commit hosted checks.
