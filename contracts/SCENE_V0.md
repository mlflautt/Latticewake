# Latticewake Scene v0 contract

This is the semantic contract and wire format for Scene v0. It is serialized as
strict UTF-8 JSON and parsed into the typed model before the same Scene
validator runs. The parser is intentionally schema-specific, not a general
JSON configuration surface.

## Wire-format rules

- Objects reject duplicate and unknown fields. Every required field must be
  present; `createdFrom` and `tuningID` are optional and may be `null`.
- JSON numbers must be finite. `seed` and each role `seedOffset` are decimal
  strings so all unsigned 64-bit values survive JavaScript-number boundaries.
- `maxIterations`, scale degrees, chord fields, and pattern values are JSON
  integer numbers within their target C++ integer range.
- The canonical serializer emits compact JSON with a fixed field order and
  direct UTF-8 strings. Equal valid typed scenes produce equal serialized bytes.
- The current parser accepts simple JSON string escapes and direct UTF-8, but
  rejects `\\u` escapes. A future revision may broaden input support only
  without changing canonical output or semantics.

## Required scene identity

| Field | Meaning |
| --- | --- |
| `schemaVersion` | Literal `latticewake-scene-v0`. |
| `sceneID` | Stable user-facing identifier. |
| `seed` | Unsigned 64-bit deterministic seed, serialized as a decimal string. |
| `title` | User-editable scene label. |
| `createdFrom` | Optional parent scene ID; never rewrites a parent. |

## Harmonic context

`harmonicContext` contains `tonic`, `mode`, `scaleDegrees`, `chordDegree`,
`chordQuality`, `inversion`, `octaveReference`, and `tempoBPM`.

V0 accepts tonal/modal named scales only. The contract reserves `tuningID` for
later microtonal support; its presence is optional and has no V0 effect.

## Terrain and path

`terrain` contains `kind`, `detail`, `zoom`, `offsetX`, `offsetY`, `rotation`,
`motion`, `maxIterations`, and `normalization`.

`path` contains `kind`, `rateRatio`, `radiusX`, `radiusY`, `angle`,
`translationX`, `translationY`, `meander`, `feedback`, and `spatialLimit`.

All normalized creative controls are in `[0, 1]`. Implementation maps them to
the documented safe domain for a specific field/path and rejects non-finite
values. `maxIterations` is an explicit finite integer cap; it is never inferred
from UI resolution, CPU capacity, or an image size.

For V0 validation, `maxIterations` is in `[1, 4096]`, `tempoBPM` is finite and
greater than zero, and all named identity, harmonic, terrain, and path kinds
are non-empty. Richer parameter mappings and named enum registries remain a
later contract revision.

## Role lanes

`roles` is exactly four records with IDs `drone`, `pad`, `motifA`, and `motifB`.
Each contains `enabled`, `range`, `density`, `pattern`, `rhythm`, `variation`,
`seedOffset`, `voiceRoute`, and `midiRoute`.

`pattern` and `rhythm` are independent. A rhythm step explicitly represents
`note`, `rest`, or `tie`; an implementation must not turn a tie into a newly
triggered note. V0 allows manual and Euclidean rhythms only. Cellular automata
and grammar pattern providers are later typed extensions.

## Trace and proposal boundaries

A `PerformanceEvent` records a monotonic sample-time offset, event type,
origin (`player`, `generator`, or `proposal`), and payload. A proposal can
reference a scene and propose only allowlisted changes to `harmonicContext`,
`terrain`, `path`, or one role record. It cannot introduce executable code,
URLs, file paths, MIDI endpoint IDs, or unbounded values.

## V0 validation rules

- Same scene bytes plus seed and performance trace must produce the same event
  trace in the deterministic engine.
- Scene loading rejects unknown role IDs, duplicate role IDs, missing required
  roles, non-finite numbers, invalid enum values, and values outside declared
  ranges.
- Proposal validation is separate from scene validation and can only yield a
  preview candidate; commit remains an explicit user action.
- A published scene records an exact content hash and refuses overwrite.
