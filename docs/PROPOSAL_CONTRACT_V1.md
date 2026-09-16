# Proposal Contract v1

`latticewake-proposal-v1` is the boundary for a provider that wants to suggest
a bounded Scene patch. A provider may be a local generator, Hermes, Codex, or
another harness. It has no file, callback, transport, or commit authority.

```json
{
  "schemaVersion": "latticewake-proposal-v1",
  "proposalID": "provider-variation-001",
  "provider": "example-local-provider",
  "baseSceneSHA256": "<64 lowercase hex characters>",
  "frozenComponents": ["Surface"],
  "patches": [{"field": "traversalRadiusX", "value": 0.62}]
}
```

The receiver validates the exact base-scene hash, exact active freeze set, a
maximum of 16 unique allowlisted fields, and field ranges before deriving a
temporary candidate. The initial fields are Surface (`terrainDetail`,
`terrainZoom`), Traversal (`traversalRadiusX`, `traversalRadiusY`,
`traversalTranslationX`), Articulation (`attackSeconds`, `releaseSeconds`,
`gain`), and the four initial role/lane controls. Role fields use an explicit
role prefix (`drone`, `pad`, `motifA`, or `motifB`) followed by `Enabled`,
`Density`, `Range`, `Pattern`, or `SeedOffset`. `Enabled`, `Pattern`, and
`SeedOffset` must be whole numeric values in their documented bounds.
Drone and Pad pattern indexes are deliberately capped at `0...3`; Motif A and
Motif B add four bounded role-specific families at `4...7`. These indexes are
stable, serialized scene choices—not a general-purpose algorithm language.

Validation and candidate derivation are pure operations. They do not alter the
audio callback, current scene, library document, undo history, or user taste.
Preview, Accept, Reject, Undo, and an accepted-proposal receipt remain explicit
artist-facing actions; external-provider UI and any Apple Intelligence adapter
are deferred until those actions use this same boundary.

## Local Freeze and Grow sets

The built-in Freeze and Grow provider is deliberately separate from this JSON
interchange contract. It derives a maximum of three deterministic variations
from the current scene hash, selected depth, and active freeze boundary. The
candidate position is a stable revisit handle, not a quality rank: Latticewake
does not select, save, or recommend one. If every editable component is frozen,
it creates no candidate at all. Each candidate still uses explicit Preview,
Accept, Reject-all, Undo, and a receipt on acceptance.

## Role proposals

Role patches are validated against the active four-role controls before a
candidate is prepared. They are never sent directly to transport or the audio
callback. The `Lanes` freeze boundary prevents every role patch; a valid role
candidate is prepared through the same explicit Preview, Accept, Undo, and
receipt path as a surface patch. The built-in `Drone Foundation` and `Motif
Pulse` palette entries are deliberately small examples, not musical rankings
or autonomous composition.

Motif A adds Euclidean 3/8, 5/8, and 7/8 distributions plus an Offbeat form.
Motif B adds Cellular, Rotate 5, Recursive, and Coprime forms. Each resolves
to a finite degree and rhythm sequence during preparation, then contributes to
the ordinary deterministic role trace. No generator runs in the audio
callback, and no form is asserted to be aesthetically preferable.
