# Image-to-terrain research synthesis

## Purpose and source record

This note evaluates the two supplied research reports as design input for
Latticewake. They are useful literature and hypothesis documents, not approved
implementation specifications. The supplied report copies are preserved in
[`research/source-reports/`](source-reports/).

| Report | SHA-256 | Scope |
| --- | --- | --- |
| [`Image-to-Terrain Audio Synthesis Pipeline.md`](source-reports/Image-to-Terrain%20Audio%20Synthesis%20Pipeline.md) | `934e8d2a3b3d652a95029da97418cca4bd95bf1b7e17f4a4e7bbefafe15c6ea1` | Image ingest, field analysis, periodic table preparation, real-time handoff, assets, and validation. |
| [`macOS Image Terrain Instrument Plan.md`](source-reports/macOS%20Image%20Terrain%20Instrument%20Plan.md) | `531acb13404fa69f206b95556ed19765f6f1b583b8f0362c4af7c2a57c48338e` | Stage rendering and gestures, macOS tooling, CI, accessibility, and future AUv3 validation. |

## Architectural conclusion

Treat an imported image as a **source plane from which the artist makes a
Surface**, not as a screenshot that is automatically converted into an
oscillator. Preserve the distinction between source pixels, a normalized
height/timbre field, the chosen traversal, and the prepared audio tables. The
Stage should register these layers in one coordinate system and keep the
original recognizable while showing the selected interpretation, contours,
traversal, and live sampling position.

The portable C++ `RenderPlanBuilder` remains authoritative for sound. Apple
frameworks may decode and present media, but decoding and analysis are offline
and versioned. The builder receives validated in-memory field data through an
asset-resolution boundary; it does not open image paths or parse image files.
Only immutable prepared tables and bounded state reach the callback. This
retains the existing opaque C ABI and avoids coupling the core to Apple image
frameworks or Swift/C++ interop.

## Ideas to adopt

1. **Make image provenance visible and durable.** Record original-file hash,
   canonical field hash, provider/version, interpretation parameters,
   fit/crop/tile transform, and portability state. Keep project-owned derived
   assets; never rewrite the source image.
2. **Make import a reversible preview.** Display Source, Interpretation, and
   Contours as registered views or a restrained overlay. Let the artist choose
   Replace A, Replace B, or Cancel. Preserve Traversal, Articulation, and the
   active scene until explicit acceptance and plan publication.
3. **Keep gesture geometry shared.** Define normalized field coordinates and
   one explicit fit/crop/tile transform for both drawing and pointer mapping.
   A sampling marker should expose the interpreted value and selected source
   location; it must not suggest that RGB pixels are direct samples unless a
   provider explicitly defines that mapping.
4. **Keep budgets and failure states visible.** Bound decode dimensions, pixel
   count, derived-field size, analysis time, and prepared-plan memory. Cancel
   stale previews. A flat, missing, malformed, or nonperiodic surface should
   report its condition and preserve the currently active plan.
5. **Measure before specializing the renderer.** Compare table interpolation,
   anti-aliasing, morph behavior, and memory against named fixtures. Keep audio
   measurements separate from human judgments of tone and playability.

## Critique and decisions not to import literally

- **Do not make a 512×512 float RGBA buffer the durable canonical format.** It
  is a reasonable working representation, but color-management, decoder, and
  resampling differences can change its bytes across platforms or versions.
  Define a versioned, documented scalar-field asset encoding with explicit
  orientation, dimensions, quantization, coordinate convention, and hash. Keep
  source hash and generated-field hash distinct. Select dimensions and
  quantization through import-quality and memory tests rather than adopting a
  report's fixed dimensions.
- **Do not adopt a 67-megapixel or 1-GiB decode allowance.** That is not an
  appropriate interactive safety budget. Decode/downsample to a conservative
  bounded working size and test peak memory on the target Mac before setting
  product limits. The report's 8K and 512-square suggestions are hypotheses,
  not selected limits.
- **Do not make Moisan periodic-plus-smooth decomposition, a 64-frame bank,
  eleven mip levels, or a specific interpolation kernel mandatory in v1.**
  They are candidate techniques. First compare explicit edge handling (crop,
  mirror, tile), simple periodic extraction, and spectral methods with fixtures
  for seam energy, aliasing, timbre continuity, preparation time, and memory.
  Use the smallest table-bank design that passes the intended sound tests.
- **Do not treat table-phase alignment as the sole morph/timbre design.**
  Compare phase-locked and alternative alignment on the same surfaces. Make
  the chosen policy audible and explainable; do not hide phase discontinuities
  behind a technical label.
- **Do not add a sine fallback for missing or invalid terrain.** That conflicts
  with Latticewake's terrain-truth principle. Failed import or preparation
  leaves the current plan active and reports why the candidate cannot sound.
- **Do not exchange RenderPlans through an unproven raw-pointer retirement
  queue.** The callback may not free, lock, allocate, or decrement a final
  shared reference. Ownership, publication, voice lifetime, and reclamation
  need a separate bounded proof and stress test before any handoff mechanism
  changes.
- **Do not replace SwiftUI Canvas or the retained Metal view based on anecdotal
  resize reports.** The report correctly identifies tradeoffs but does not
  prove a defect in Latticewake's current renderer. Keep the current Stage
  renderer until target-Mac resize, registration, frame-time, accessibility,
  and power measurements identify a specific failure. A direct `CAMetalLayer`
  renderer is an experiment, not an architecture prerequisite.
- **Do not adopt the report's future-version claims, exact runner hardware,
  deprecation statements, precise performance numbers, or third-party
  postmortems as verified facts.** Check current official documentation when a
  concrete implementation decision depends on them. Hosted CI can validate
  supported build and offline behavior; physical graphics, audio, MIDI, and
  Logic sessions require the target Mac and human review.
- **Do not switch to Swift/C++ interoperability.** The project already chose
  an opaque C ABI. The additional interop surface is not justified by the
  image workflow.

## Revised image-surface implementation sequence

1. Define a versioned scalar `SurfaceField` asset and manifest. Specify
   dimensions, numeric encoding, orientation, coordinate origin, normalization,
   source and generated hashes, provider/version, and safe limits. Keep media
   import outside Scene JSON; the scene references the immutable asset.
2. Add an offline image adapter that produces a preview candidate. Start with
   one predictable interpretation (linear-light luminance) and explicit
   fit/crop behavior. Add channel, gradient, edge-density, and tiled providers
   only as separately tested options.
3. Add an asset resolver that supplies validated field bytes to
   `RenderPlanBuilder`. The portable builder compiles the field along a named
   traversal into bounded periodic tables and returns diagnostics. It has no
   filesystem or decoder dependency.
4. Show the imported image, interpreted field, contours, path, and sample
   marker with shared transforms. A/B and Cancel operate on a candidate; only
   explicit acceptance updates the scene, and only a successfully prepared
   plan can become active.
5. Extend morphing and the table bank after measuring memory, preparation
   latency, aliasing, phase behavior, and click-free publication. Preserve the
   active plan on all failures.

### Proposed acceptance evidence for Cycle 060

- Deterministic field bytes and hashes for a pinned corpus of images, including
  flat, alpha, wide/tall, grayscale, high-detail fractal, and malformed cases.
- Import cancellation and replacement leave the saved scene and current
  traversal/articulation unchanged until explicit acceptance.
- The visual source, interpretation, contours, and hit-testing remain
  registered after resize and display-scale changes.
- A field-backed RenderPlan produces measured pitch, energy, peak, DC, alias,
  and seam results; flat or invalid input never becomes an unrelated tone.
- Repeated preparation agrees within declared deterministic tolerances; peak
  memory and latency fit documented caps on the target Mac.
- Human listening separately records whether the image-to-sound mapping is
  understandable and creatively useful. Technical metrics do not choose an
  aesthetic winner.

## Source verification

Official Apple documentation confirms that `CAMetalDisplayLink` is a Metal
display-timing API and that SwiftUI can expose synthetic accessibility children
for otherwise opaque graphics. This supports those as available tools, not as
evidence that Latticewake needs a custom renderer. GitHub's official changelog
confirms macOS 14 hosted-runner retirement on November 2, 2026 and lists
replacement labels. Other exact runner virtualization, GPU, toolchain, API
deprecation, and performance assertions in the reports remain unverified here.

The choices above preserve Latticewake's established architecture: Scene v1
asset references, immutable prepared RenderPlans, the portable C++ kernel,
opaque C ABI, explicit Preview/Accept/Cancel, no callback file access, and no
silent replacement oscillator.
