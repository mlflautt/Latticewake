# Latticewake proposal boundary v0

Proposals are optional creative inputs. They remain distinct from a Scene and
can only produce a temporary preview trace; no proposal function commits,
persists, or mutates a Scene.

`MelodyProposal` has a proposal ID, target scene ID, provenance `source`, and
1–1024 notes. Each note has non-negative `startBeat`, duration in `(0, 64]`, a
scale degree in `[-64, 64]`, and normalized velocity. Preview timing converts
beats to sample offsets through an explicit sample rate and tempo.

`SceneProposal` is validation-only in v0. It may contain 1–16 normalized
patches for exactly these targets: terrain detail, terrain motion, path rate
ratio, path radius X, and path radius Y. URLs, executable code, file paths,
MIDI endpoint IDs, arbitrary keys, and direct scene mutation are not part of
this format.

Future Apple Intelligence or another provider must emit one of these bounded
types, be validated, and be visibly previewed before a person decides whether
to make a separate committed Scene edit.
