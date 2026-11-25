# Instrument design research: assessment and decisions

## Source and scope

The supplied [Latticewake Instrument Design Research](source-reports/Latticewake%20Instrument%20Design%20Research.md)
is preserved verbatim. SHA-256:
`be715b18c1074be564bf2e9529a0b5a29fff95ffc1b8f62c040176239638aa55`.
Its recommendations are research inputs, not instructions or evidence that
Latticewake already has the proposed capabilities. This assessment updates the
active sequence in [development roadmap v5](../docs/DEVELOPMENT_ROADMAP_V5.md).

## Creative direction: one landscape, two timescales

Retain the report's direction C as a **hypothesis and product direction**:
an audio-rate path shapes the voice; slower, visible motion can eventually
influence a lane's timbre or musical choices on the same surface. A performer
must be able to freeze and independently unlink timbre motion, note generation,
and harmonic constraints. The surface should be useful for direct performance
before it is asked to explain an entire composition.

The current implementation is not that coupled system. Image-derived tables
are prepared along a scene path; direct gestures currently send glide and slide
expression, and the prepared role events are not terrain walkers. Its Stage
draws a registered image, field contours and a path, but it does not show the
actual audio-rate sampling point or four terrain-linked lane playheads. Avoid
labeling the current pointer as a moving audio orbit. The four roles and two
Surface layers are existing useful foundations, not proof of their musical
quality. A native synthetic-image preview and cancel were observed in Cycle
064; accepted image save/reopen and listening remain open in the native app.

## Decisions to carry forward

1. **Play first, compose second.** Validate a responsive sustained terrain
   voice and a clearly explained image-to-sound relationship. Preserve the four
   existing roles and test their contribution independently before binding
   their pitch and rhythm to visual terrain features.
2. **Version interpretations.** `ImageTerrainAsset` already stores provider
   version, source and field hashes, quantized field bytes and a source preview.
   Extend this contract before adding adjustable interpretations: exact mapping,
   transform, settings, algorithm version, field encoding and hash. Reopening
   an existing scene uses its stored field; a new interpreter is an explicit
   preview/accept action, never a silent migration.
3. **Make visual and sonic relationships explicit.** Show source, interpretation
   and path in registered coordinates; label A/B, preview versus accepted, and
   what each gesture really controls. Explore selectable source/field/contour
   views and a meaningful slow walker as prototypes. A 2D view remains the
   editing authority; 3D is optional and requires an actual benefit.
4. **Keep creative authority visible.** Keep typed proposals, frozen-field
   checks, preview, accept, reject, undo and receipts. A lane's musical pattern,
   surface, traversal, and modulation need independently testable freeze scopes.
   LLMs can propose melody or bounded high-level changes; they do not commit,
   process audio, or publish directly. The report's blanket prohibition on
   raw melody arrays is not adopted: bounded typed melodies remain useful.
5. **Build the AUv3 companion around the same core.** Plan stable parameter
   addresses, a documented versioned state envelope and bounded embedded asset
   strategy; measure state size and restoration latency in an actual host.
   The standalone retains its full creation tools. A fixed initial parameter
   tree is our compatibility choice, to be verified in Logic and other hosts,
   not a claim that dynamic trees are universally broken.

## Critique: do not promote hypotheses into facts

- **No mandatory four-channel replacement yet.** The proposed elevation,
  gradient, hue and variance channels are candidates, not demonstrated cures
  for the sound of our renderer. The existing scalar luminance provider is
  versioned and retained. Compare controlled single changes, source images,
  paths and levels before selecting new channels. Sonifyd's additive color
  mapping is useful inspiration but its findings do not establish outcomes for
  this wave-terrain instrument. [Sonifyd paper](https://icad2019.icad.org/wp-content/uploads/2019/06/ICAD_2019_paper_45.pdf).
- **Do not treat 2D image mipmaps as an aliasing guarantee.** Sampling a
  spatially filtered field along a curved path and transforming it into an
  audio waveform is not equivalent to band-limiting that waveform. Compare
  prepared-table spectral limits, oversampling and optional field sampling
  against a high-rate reference at fixed notes, sample rates, paths and levels.
  The [DAFx polygon oscillator paper](https://dafx26.mit.edu/assets/papers/DAFx26_paper_32.pdf)
  studies a different geometry; its measured improvement is not our target or
  evidence that its correction applies unchanged.
- **Do not promise zero DC from local mean subtraction.** A local spatial
  average need not equal the mean along a closed orbit. Existing preparation
  subtracts each table's path mean and the renderer has a DC blocker; measure
  output under morph, expression and transitions as well as static tables.
- **Do not mandate image recognizability by ear.** A threshold such as seven
  out of ten correctly identified images is arbitrary for this instrument.
  Compare matched, level-controlled, unranked examples and ask musicians about
  meaningful distinction, control, and usefulness. Identification may be an
  optional study, not a release gate or an aesthetic score.
- **Do not replace working queue/plan code merely because a library exists.**
  The prototype already has bounded queues, two prepared plan slots and
  source-aware events. Audit producer ownership, lifetime, overflow and
  reclamation on the exact standalone and future AU paths first. The
  [readerwriterqueue project](https://github.com/cameron314/readerwriterqueue)
  distinguishes non-allocating `try_enqueue` from potentially allocating
  `enqueue`; [farbot](https://github.com/hogliux/farbot) is a separate
  candidate for specific handoff problems. Neither is adopted without tests,
  dependency/license review and a demonstrated gap.
- **Do not silently invent replacement terrain for a missing asset.** Reject
  preparation, retain the previously active scene, and offer a clear relink or
  restore path. An analytic fallback derived from the hash is not the artist's
  original sound and would conflict with truthful recall.
- **Do not conflate spatial filtering, voice management and provenance.**
  Source and note identity already exist, but current role gate tracking is one
  note per lane, and scene epoch, chord ownership, sustain, device loss, voice
  stealing and transition policies require explicit work. A note gate is not an
  output meter. No assertion of full MPE or real-time admission follows.
- **Treat numerical budgets as proposed experiments.** CPU percentages,
  alias-reduction dB, fixed image sizes, -120 dB buffer invariance, plug-in
  validation settings and Foundation Models token budget are not measurements
  of this build. Define reference signals, denominators, machine, buffer sizes
  and tolerances before adopting release gates. No library or license claim in
  the report authorizes copying code or settles distribution obligations.

## Selected primary-source checks

- [Apple AUAudioUnit](https://developer.apple.com/documentation/audiotoolbox/auaudiounit)
  documents the v3 extension/factory approach, render block, parameters, host
  transport and document state. It does not establish Logic project relocation
  behavior, asset size limits or that embedding is always required.
- [Apple TN3193](https://developer.apple.com/documentation/technotes/tn3193-managing-the-on-device-foundation-model-s-context-window)
  describes the documented model session's 4,096-token context and counts
  prompts, instructions, schemas and responses. Recheck actual platform and
  model availability when implementing; no model is integrated by this report.
- The NDLR's [official product description](https://conductivelabs.com/pages/the-ndlr-explore-more)
  is a reference for a shared harmonic context and coordinated roles; it does
  not validate a particular Latticewake walker design.

Only the sources above were checked for the claims stated here. Other report
links, licenses, version-specific tool behavior and performance assertions are
leads to verify before a dependency or distribution decision.
