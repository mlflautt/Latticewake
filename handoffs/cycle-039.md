# Cycle 039 handoff — prepared Surface, Traversal, and Articulation editing

Base: `f2e9136` (`v0.38.0-alpha.1`).

## Implemented

- Made the portable `RenderPlanBuilder` accept Scene v1 directly and transfer
  its Articulation component into prepared terrain-plan parameters.
- The realtime terrain voice now uses prepared attack, release, gain, glide,
  velocity, pressure, and slide response values. No scene parsing or UI access
  occurs in the callback.
- Added a bounded C ABI for reading and applying Surface, Traversal, and
  Articulation controls to a canonical Scene v1 document.
- Added the Stage Inspector editor. Surface and traversal sliders modify the
  authoritative compatibility terrain/path; articulation sliders modify the
  prepared voice. Controls apply together through the existing explicit scene
  handoff and are undoable.
- Editing a Scene v0 is an explicit in-memory migration on Apply. Loading a
  legacy scene remains byte-preserving until an artist deliberately edits or
  saves it.

## Verification

- C++ and bridge fixtures verify Scene v1 articulation preparation, editor
  control canonical round trips, and a changed terrain render.
- Swift integration tests verify explicit migration and editor round trip.
- Full local release verification passed: normal C++ fixtures, fresh
  ASan/UBSan fixtures, 21 Swift tests, script checks, packaging, and
  signed-bundle identity verification.
- A native UI automation attempt was intentionally not accepted as review
  evidence: automation selected a pre-existing app instance showing retired
  Inspector text rather than the exact packaged process receipt. No visual
  acceptance is claimed for this cycle.
- Hosted CI remains pending the release commit.

## Remaining gates

- The editor is a functional 2D Stage control surface, not Metal admission or
  a human-audition result. Callback allocation/lock/deadline admission and
  Core MIDI hardware lifecycle remain open gates.
- Exact-process native UI automation needs a PID-aware target boundary (or a
  cleanly isolated target instance) before it can validate a packaged UI.
