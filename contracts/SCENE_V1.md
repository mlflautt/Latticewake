# Scene v1 contract

Scene v1 is Latticewake's component-addressable creative document. Its canonical
UTF-8 JSON uses the schema identifier `latticewake-scene-v1` and rejects
unknown, missing, duplicate, malformed, or over-cap fields.

## Components

- `surface` owns exactly two identified layers and a morph in `[0, 1]`. A layer
  is `analytic`, `image`, or `audio`; non-analytic layers require a complete
  asset ID, content hash, and media type. Cycle 033 migrates both layers from
  the same v0 terrain and sets morph to zero.
- `traversal` owns its stable ID, seed, sampling distribution, and deformation.
  Uniform sampling is the only admitted Cycle 033 distribution.
- `articulation` owns envelope, gain, glide and expression response defaults,
  plus the deterministic oldest-voice-steal behavior.
- `harmony` owns transport division and the migrated harmonic context.
- `laneCollection` contains 1–16 identified named lanes. The migrated Drone,
  Pad, Motif A, and Motif B names are defaults, not the future collection cap.
- `modulationGraph` owns at most 32 identified routes.
- `routing` owns 1–4 engine slots and named Performance Groups.
- `lineage` binds the migrated source schema and SHA-256 content hash.

Component identifiers and route identifiers are non-empty and unique across a
document. Image and audio analysis is not part of Cycle 033; its descriptors
are reserved without permitting callback file access.

## Compatibility witness

Cycle 033 stores the exact canonical Scene v0 representation as the
`compatibilitySceneV0` string. It is the authoritative sound-equivalence
witness while the component editors are still absent. Scene v1 identity must
match that witness. The portable `RenderPlanBuilder` consumes the validated
compatibility view, so migration does not change accepted sound or lane timing.

Later cycles may make individual component payloads independently editable,
but they must preserve deterministic canonicalization and explicitly migrate
this initial v1 shape if its wire contract changes.

## File behavior

- Opening Scene v0 or Library v1 never rewrites its bytes.
- Explicit Save As migrates the in-memory scene to canonical Scene v1 and puts
  it inside the existing library envelope so current performance preferences
  remain available.
- The bridge accepts raw Scene v0, raw Scene v1, or a Scene v1 payload extracted
  from a library document. Parsing and plan construction occur off the callback.
