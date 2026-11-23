# Cycle 061 — continuous Surface morph and safe image preflight

## Objective

Make image Surface visualization track the same continuous morph as the
prepared sound, and enforce the image-file resource cap before reading or
decoding source media.

## Scope

- Retain both Surface source planes and crossfade source, interpretation, and
  contours according to Scene morph weights.
- Diagnose flat traversal only when the active image contribution is known.
- Check regular-file size before reading; hash and decode the same bounded data
  snapshot.
- Keep contour generation bounded and avoid per-cell temporary arrays.

## Acceptance

- Endpoint and midpoint field morph diagnostics match linear field interpolation.
- Stage media weights equal `1 - morph` and `morph`; both image layers remain
  visible with their corresponding weights.
- Oversize and invalid-size boundaries reject with explicit errors before
  media decoding.
- Contour count obeys its requested cap and generated segments remain finite.
- Normal, sanitizer, Swift, packaging, and bundle checks pass.

## Non-goals

- New surface providers, spectral/audio import, image tiling, or seam alignment.
- Claiming image-import UI interaction, target-device audio admission, or
  human aesthetic approval without observing those behaviors.
