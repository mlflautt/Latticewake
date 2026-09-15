# Cycle 031 handoff — revisitable scenes and offline captures

Base: `b043e0b` (Cycle 030).

Implemented:

- `SceneLibraryDocumentV1` writes a versioned library document containing the
  original canonical Scene JSON plus explicit performance defaults. Loading a
  raw Scene v0 file returns the exact original bytes and does not migrate or
  overwrite that source file.
- Terrain Stage now offers New, starter-scene selection, Save As, Load, Undo,
  and Capture 8s WAV. Edits are held in memory and marked dirty; applying a
  lane edit never saves over a previously loaded document.
- Three starter choices are supplied: Sustained Terrain, Gesture Terrain, and
  Four Role Loop. All use the established non-flat terrain path; the first two
  disable generated roles, while the loop enables them.
- Offline capture uses the same opaque C++ bridge at 48 kHz for eight seconds,
  with a bounded 256-frame render loop. It writes a mono WAV and a sorted JSON
  receipt whose scene SHA-256, byte count, frame count, sample rate, and role
  transport setting bind the result to its input.
- Swift fixtures cover legacy-v0 preservation, v1 round trip, undo behavior,
  and WAV/receipt integrity.

Verification:

- Normal and ASan/UBSan C++ suites pass, including the established sustained
  pitch and role-transport fixtures.
- `swift build` and the ad-hoc-signed standalone bundle rebuild pass using the
  Command Line Tools route with an isolated module cache. `swift test` on that
  fallback cannot compile the project test target because it lacks the
  `Testing` module. Full Xcode currently requires its one-time licence
  acceptance. No Swift-test, device, or human-listening pass is claimed for
  this revision.

Rollback: revert this cycle commit. Scene v0 bytes and prior library documents
are never altered by the implementation; captures can simply be removed by the
artist from the capture folder if desired.
