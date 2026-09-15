# Cycle 033 handoff — Scene v1 and RenderPlanBuilder

Base: `db49c14` (`v0.32.0-alpha.2`).

Implemented:

- Added the component-addressable Scene v1 model: two Surface layers,
  Traversal, Articulation, Harmony, 1–16 named lanes, capped ModulationGraph,
  Routing/Performance Groups, asset descriptors, and Lineage.
- Added strict deterministic Scene v1 serialization and parsing. Migration
  duplicates the Scene v0 terrain into Surface A/B, sets morph to zero, assigns
  stable component IDs, and binds the source SHA-256 supplied by the app.
- Preserved the canonical Scene v0 payload as the Cycle 033 compatibility
  witness. Original v0 and Library v1 files are never rewritten on open.
- Added one portable `RenderPlanBuilder` for terrain tables, bounded role events,
  routing identities, loop timing, and the initial pitched/flat diagnostic.
- Replaced bridge-local terrain/role preparation with the builder. The C bridge
  accepts either scene schema, and v1 role edits remain v1.
- Explicit Save As now migrates the in-memory scene to canonical Scene v1 before
  placing it in the existing library envelope.

Verification:

- Normal warnings-as-errors C++ suite: pass.
- ASan/UBSan warnings-as-errors C++ suite: pass.
- Migration canonicalization, malformed ID/cap checks, terrain table equality,
  role-trace equality, bridge-buffer equality, and v1 role-edit fixtures: pass.
- Command Line Tools Swift build and ad-hoc signed app verification: pass.
- Exact rebuilt app Start/Stop smoke: 429 blocks, 201,802 frames at 48 kHz,
  maximum app-owned bridge render 107 microseconds, zero bridge budget misses,
  and zero rejected blocks. This is technical device evidence, not listening.
- Hosted full-Xcode Swift result and exact-final-SHA status are recorded after
  publication; they are not inferred from the local fallback toolchain.

Limits:

- The compatibility witness is the sound authority in this initial Scene v1
  wire shape. Independent component editing and any necessary explicit v1
  schema evolution belong to Cycle 036.
- Image/audio descriptors do not perform analysis or callback I/O.
- The current diagnostic distinguishes prepared varying tables from flat ones;
  noisy and insufficient-periodicity analysis remains a later terrain-depth
  increment.
- No new listening, hardware MPE, or aesthetic evidence is claimed.

Next target: Cycle 034, the luminous Metal Terrain Stage.

Rollback: revert the Cycle 033 commit. Existing source scene and library files
remain byte-preserved; newly saved v1 documents are additive user files.
