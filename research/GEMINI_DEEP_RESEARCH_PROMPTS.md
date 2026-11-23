# Gemini deep research prompts for Latticewake

These prompts request evidence and implementation options, not decisions to
copy another product. Ask Gemini to cite primary documentation, source code,
papers, and release notes with publication/version dates. Separate established
facts from recommendations and open questions.

## 1. Deterministic image-to-terrain pipeline on macOS

> Research a practical, deterministic image-to-terrain pipeline for a native
> macOS music instrument in 2026. The app is SwiftUI with a portable C++20
> real-time synthesis core. Image decoding and analysis must happen off the
> audio thread. The product should preserve an imported fractal image as a
> recognizable registered source plane, derive normalized terrain tables from
> selected image features, and later render those tables through a prepared
> C++ RenderPlan. Compare Apple-native decoding/processing approaches (ImageIO,
> Core Graphics, Accelerate/vImage, Metal compute where appropriate) with a
> portable CPU provider. Recommend a bounded v1: supported formats, dimension
> and memory limits, orientation/color-space handling, resampling, luminance,
> RGB channel, edge-density and gradient operators, normalization, periodic
> tiling/seam treatment, cancellation, and reproducibility. Explain whether a
> single image yields one field or a bank of periodic tables, and how the artist
> should preview the mapping without implying that RGB pixels are direct audio
> samples. Identify deterministic hash/provenance fields and asset packaging
> requirements. Cite official Apple documentation and primary technical
> sources; distinguish API guarantees from design recommendations. End with an
> implementation sequence, test matrix, failure cases, and unresolved choices.

## 2. Image-backed terrain visualization and interaction

> Research design and implementation patterns for registering an imported
> still image, its interpreted height/timbre field, terrain contours, traversal
> path, sampling marker, and active voices in one resizable macOS instrument
> surface. The source image must remain recognizable beneath a high-contrast
> luminous contour overlay. Compare SwiftUI Canvas, Core Graphics, and
> Metal/MTKView approaches for coordinate transforms, image fit/fill/tile modes,
> accessibility, reduced motion, scale factors, refresh caps, and stale-frame
> dropping. Our audio renderer publishes immutable snapshots; UI work must
> never block it. Propose the smallest useful UI state model for layer A/B,
> morph, source-only/interpretation/contour comparison, preview candidate,
> resolved/missing asset, and explicit replace/cancel actions. Include
> interaction affordances so keyboard play, pointer-owned notes, held-note
> shaping, and traversal are understandable without a permanent instruction
> wall. Cite primary frameworks and relevant HCI/audio-software research.
> Return a component diagram, coordinate conventions, accessibility checklist,
> measurable visual budgets, and testable acceptance criteria. Do not propose
> an unrestricted node graph or clone a commercial synthesizer UI.

## 3. Audio-table construction and real-time admission for image surfaces

> Investigate converting arbitrary bounded image-derived scalar fields into
> pitch-stable periodic wavetable banks for an eight-voice C++20 synthesizer.
> The current voice uses interpolated 2048-sample tables and blends two
> prepared Surface layers; scene preparation is outside the callback. Compare
> table extraction paths, normalization/DC removal, harmonic-band mipmaps,
> interpolation choices, anti-aliasing, cross-layer morphing, and handling of
> flat/noisy/nonperiodic source material. Specify what can be prepared offline
> and what minimal state is needed per voice. Discuss transition clicks,
> phase alignment, parameter smoothing, polyphonic gain, fixed-memory caps,
> overload behavior, and CPU costs at 44.1/48/96 kHz and high notes. Recommend
> deterministic fixtures and objective measurements without treating spectral
> similarity as artistic quality. Use primary DSP papers and official platform
> documentation. Return a staged implementation with risks and pass/fail
> thresholds; explicitly call out where a user audition is still required.

## 4. Current tools and validation workflow for native audio products

> Research the current (2026) Apple and GitHub-supported tools useful for
> developing and validating a standalone macOS instrument that may later add
> AUv3. Focus on Xcode/Swift Package Manager build and test automation,
> GitHub Actions for macOS runners, audio-unit validation and host testing,
> crash diagnostics, code signing/notarization, and UI/accessibility review.
> Distinguish what can be tested in hosted CI from what requires a real target
> Mac, audio device, Logic Pro, MIDI controller, or human listener. Verify
> versions, availability, runner constraints, licensing, and current official
> workflows from Apple and GitHub primary documentation/release notes. Suggest
> a minimal workflow for reproducible builds, C++ sanitizers, Swift tests,
> bundle verification, crash-report triage, and exact-SHA evidence. Avoid
> recommending third-party plugins or services unless they materially address
> a stated gap. Return links, dates, a proposed matrix, and known limitations.

## Suggested hand-back format

For each report, include date checked, a short executive summary, primary
citations, version-specific facts, recommended choices with alternatives,
risks, unknowns, and a minimal first implementation slice. Please preserve
disagreements among sources rather than silently resolving them.
