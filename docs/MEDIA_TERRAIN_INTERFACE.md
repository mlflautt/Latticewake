# Media-derived terrain interface

This note defines how Latticewake should represent an imported image—such as a
fractal render—without confusing source media, terrain analysis, traversal, and
sound.

## Visual model

The image is the **source plane**, not a detached thumbnail and not the final
audio waveform. The authoritative 2D Stage shows five registered layers:

1. the imported image, fitted or tiled according to explicit import settings;
2. a restrained height/timbre interpretation derived by the selected provider
   (luminance, channel, edge density, gradient, or later providers);
3. terrain contours calculated from that interpreted field;
4. the traversal curve in terrain coordinates;
5. the current sampling point, direct voices, and lane playheads.

The image remains recognizable but is dimmed and desaturated enough that cyan
direct traversal, colored lane paths, and status remain legible. A temporary
press-and-hold comparison can reveal Source Only, Interpretation, or Contours
without changing the sound.

```text
original pixels ──offline provider──> normalized periodic terrain asset
       │                                      │
       └─ visible source plane                ├─ visible contours/height shading
                                              └─ immutable prepared audio tables
                                                       ▲
traversal path + live sample point ────────────────────┘
```

The live sampling marker may show a small local lens containing the source
pixel, interpreted height, and current value. It must not imply that a single
RGB pixel directly becomes one audio sample unless that is the selected,
documented provider.

## Surface layers

Scene v1 already owns exactly two Surface layers and a morph. Each layer card
shows:

- source type: Analytic, Image, or Audio;
- human-readable asset name;
- miniature source preview when available;
- provider and interpretation;
- portable, missing, or unresolved status;
- Freeze state and A/B identity.

Dropping an image first creates a preview candidate. The artist chooses whether
to replace layer A, replace layer B, or cancel. Traversal and Articulation stay
unchanged, so the effect of replacing only the Surface is understandable.

Morphing two images, or an image and an analytic terrain, crossfades their
prepared normalized fields and visualization in the same coordinate system.
The Stage labels both endpoints; it never presents an unlabeled abstract blend.

## Import boundary

Image decoding and provider analysis run off the audio thread. Preserve the
source file and keep its hash distinct from the generated field hash. Store a
versioned project-owned scalar-field asset and manifest with provider version,
interpretation settings, orientation, coordinate mapping, and portability
state. Do not make a platform-decoded float RGBA image the durable canonical
asset; use a documented field encoding with deterministic normalization and
bounded dimensions.

An Apple media adapter may decode the image and prepare a candidate. An asset
resolver supplies validated in-memory field data to the portable C++
`RenderPlanBuilder`. The builder compiles bounded periodic tables along the
selected traversal. It has no image decoder or filesystem dependency. The
callback reads only immutable prepared tables and never reads media files or
project paths. Missing, flat, malformed, or invalid candidates leave the
current active plan intact and produce a visible diagnostic; there is no
unrelated oscillator fallback.

Begin with one deterministic luminance provider and explicit fit/crop behavior.
Treat channel, edge, gradient, periodic decomposition, interpolation, mip/table
bank shape, and phase alignment as choices to compare against pinned fixtures.
Select resource caps and algorithms from measured quality, preparation latency,
and memory rather than report-proposed fixed dimensions or table-bank sizes.

Cycle 057 added source-aware presentation structures and Stage labels; Cycle
060 now adds the first image import, asset resolver, candidate preview, and
image-derived Surface preparation. Keep the current Stage renderer unless
target-Mac evidence identifies a specific limitation. Audio-derived Surfaces
remain later work. The detailed research critique and proposed tests are in
[`IMAGE_TERRAIN_REPORT_SYNTHESIS.md`](../research/IMAGE_TERRAIN_REPORT_SYNTHESIS.md).

## Cycle 060 implementation boundary

The first bounded image provider is `luminance-srgb-center-crop-v1`. It uses a
256×256 field, creates an orientation-corrected thumbnail capped at 2048 pixels
per edge, center-crops it to a square, composites transparency over neutral
gray, then stores 16-bit big-endian values derived from 8-bit sRGB luminance.
The canonical field bytes are `LWSF`, a 16-bit big-endian version (`1`), 16-bit
big-endian width and height, then row-major 16-bit big-endian samples. SHA-256
of these full bytes is the generated field hash. The source file hash and a
cropped source preview are retained separately.

The first import candidate is reviewed before it can replace Layer A or B.
`Preview` prepares and auditions the image-derived field without changing the
saved scene; `Replace A/B` accepts it; `Cancel` returns to the current scene.
Scene Library v1 embeds the verified field and cropped source preview, so a
saved image Surface reopens without its original file path. The Stage shows the
registered source preview, a luminance interpretation overlay, bounded marching
squares contours, the traversal path, and the selected layer. Audio preparation
copies values into fixed render tables before publication; the callback never
retains the imported field or image object.

This is a deterministic stored-field contract, not a promise that two different
OS image decoders will produce identical import bytes. The field hash binds the
actual imported result, and provider version plus source hash preserve its
provenance. Audio-derived import, multiple image providers, seam correction,
phase alignment choices, and broader portability/export policy remain open.

Cycle 061 aligns the source-plane display with Scene morph: both resolved image
layers remain registered and their source, interpretation, and contour overlays
fade with the same A/B weights used by the prepared audio tables. Image/analytic
morphs show the image contribution fading against the analytic terrain view.
The flat-path warning is suppressed for image-containing scenes until the
diagnostic can be sourced from the prepared audio tables. Raw image brightness
is not sufficient because each table is normalized independently before mixing.
Import now checks the regular-file size before reading, then hashes and decodes
the same bounded byte snapshot to keep provenance tied to the analyzed media.
