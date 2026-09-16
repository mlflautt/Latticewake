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
`traversalTranslationX`), and Articulation (`attackSeconds`, `releaseSeconds`,
`gain`).

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
