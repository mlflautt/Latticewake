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

Image decoding and provider analysis run off the audio thread. The project owns
a normalized derived asset plus source hash, analysis settings, provider
version, generated-asset hash, and portability state. The callback reads only
prebuilt tables in an immutable RenderPlan; it never reads image files.

Cycle 057 adds source-aware presentation structures and Stage labels. It does
not claim image import or analysis. The import pipeline, asset resolver,
provider preview, and first audible image-derived Surface are now an explicit
Cycle 060 target, after the signature voice and registered Stage visualization
are coherent. Audio-derived Surfaces remain later work.
