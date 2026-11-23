# Cycle 061 handoff — continuous Surface morph and safe image preflight

Base: `bc8cd05` (`v0.60.0-alpha.2`).

## Implemented

- The Stage now retains both Surface image sources and crossfades source pixels,
  luminance interpretation, and per-layer contours with the canonical
  `1 - morph` / `morph` weights.
- Image-path variation diagnostics interpolate both image fields using the
  same morph value. Mixed image/analytic morphs do not claim flatness based on
  only the image layer.
- The importer checks the selected URL is a regular file and enforces the
  64 MiB cap before reading. It then hashes and decodes the same byte snapshot,
  avoiding a path-change gap between provenance and interpretation.
- Marching-squares contours no longer allocate temporary arrays per cell and
  continue to obey the explicit segment cap.

## Verification

- `make verify-release`: passed warnings-as-errors C++ tests, ASan/UBSan C++
  suites, 43 Swift tests (one environment-dependent Core MIDI skip), shell
  syntax checks, signed app packaging, and bundle verification.
- Pitch fixture remained stable: C4 262.295 Hz, E4 328.767 Hz, G4 393.443 Hz;
  sustained RMS was approximately 0.022.
- New Swift regressions cover size-limit boundaries, opposing fields whose
  midpoint morph is flat, morph weights, and contour cap.
- Bundle verification passed with UUID
  `D8C767E7-2236-3BE1-844D-4A921142AE33` (version `0.61.0-alpha.1`, build 68).
- Native review opened one build and confirmed the updated Stage/Inspector.
  The synthetic PNG appeared in the native chooser, but computer input timed
  out before it could be accepted or previewed. That import UI behavior remains
  unverified. The single app process was closed after review.

## Remaining gates

- No physical image chosen in the live app or user listening decision was
  observed in this cycle.
- The visualization crossfades source fields and their contours; it is not a
  novel recomputed contour topology for every mixed scalar field.
- Mixed image/analytic flatness awaits a shared prepared diagnostic from the
  render plan; this cycle suppresses an unsupported flat warning in that case.

## Release

- Bundle version: `0.61.0-alpha.1`, build 68.
- Bundle UUID: `D8C767E7-2236-3BE1-844D-4A921142AE33`.
- Commit, annotated tag, exact-SHA hosted CI, and repository cleanliness are
  recorded after commit and push.
