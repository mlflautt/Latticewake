# Cycle 022 — four-role performance controls

Four visible role controls edit a mutable draft. Explicit Apply validates and
serializes canonical Scene bytes through C++, atomically saves them, republishes
the prepared scene, and rebuilds the immutable Terrain Stage snapshot.

Acceptance: bounded canonical role read/write, four role controls for enable,
range, density, pattern, and seed; deterministic bridge round-trip fixtures;
normal, sanitizer, and Swift tests. No callback UI reads, role audio sequencer,
human audition, or creative selection is claimed.
