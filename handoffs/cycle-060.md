# Cycle 060 handoff — image-derived terrain Surface

Base: `f827b21` (`v0.60.0-alpha.1`).

## Implemented

- Added a bounded `luminance-srgb-center-crop-v1` ImageIO provider. It creates
  a project-owned 256×256 16-bit scalar field, separate source and field hashes,
  and a cropped source preview.
- Added candidate preview and explicit Replace A/Replace B acceptance in the
  Sculpt inspector. Preview leaves saved Scene bytes unchanged.
- Embedded validated field assets in Library v1 and retained them through
  image-scene save/load and undo.
- Added a fixed-layout `SurfaceFieldView` and C ABI field preparation inputs.
  `RenderPlanBuilder` samples fields along the selected traversal and owns its
  prepared tables before publication; no image object or file path reaches the
  callback.
- Updated the Stage to show the registered source preview, luminance
  interpretation, contours, and traversal for image-backed layers.

## Verification

- `make verify-release`: passed warnings-as-errors C++ tests, ASan/UBSan C++
  suites, Swift tests, shell syntax checks, signed standalone packaging, and
  bundle verification.
- The playable pitch fixtures still measure C4 262.295 Hz, E4 328.767 Hz, and
  G4 393.443 Hz with sustained RMS near 0.022 in the existing renderer tests.
- Image-specific tests cover deterministic import, registered preview,
  scene-library round trip, undo asset retention, field identity rejection,
  prepared-table ownership, and non-flat image-backed rendering.
- Bundle verification passed with code UUID
  `8542408C-0DF3-3004-AF66-1352D578EB95`.
- A native review confirmed the Stage and Sculpt image controls are present.
  The Mac became locked before the chooser/preview interaction could be tested;
  the native import interaction therefore remains open for user verification.

## Remaining gates

- No target-device smoke or human listening result was collected in this cycle.
  Existing technical buffer tests do not establish that the image-derived voice
  sounds useful or satisfying.
- Image import behavior was tested from generated PNG fixtures, not a user
  supplied fractal image in the live app.
- The current provider intentionally has one interpretation and center-crop
  mapping. Audio import, tiled mapping, channel/edge providers, and phase/seam
  treatment remain future work.
- macOS SwiftPM emitted warnings that the user-level cache is not writable;
  test/build completed successfully using repository-local module caches.

## Release

- Bundle version: `0.60.0-alpha.2`, build 67.
- Bundle UUID: `8542408C-0DF3-3004-AF66-1352D578EB95`.
- Annotated tag and exact-SHA hosted CI status are recorded after commit/push.
