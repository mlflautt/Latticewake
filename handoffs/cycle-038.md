# Cycle 038 handoff — validated Scene v1 library boundary

Base: `b50f704` (`v0.37.0-alpha.1`).

## Implemented

- Made `SceneLibrary` canonicalize every embedded scene through the portable
  Scene v1 bridge before a library document is saved or exposed after load.
- Added bounded validation for direct-play performance settings: glide is a
  finite 0–24-semitone value and the pointer note is within MIDI 0–127.
- A document declaring the Library v1 schema now must decode and validate as
  that schema; malformed envelopes can no longer be silently treated as legacy
  Scene v0 files.
- Retained legacy behavior: a genuine non-library Scene v0 file is read as its
  original bytes and is not rewritten automatically.

## Verification

- Focused Swift integration tests: 20 passing, including invalid nested scene,
  invalid performance, malformed-envelope, migration, and legacy-preservation
  fixtures.
- Full exact-head release verification and hosted CI remain pending the release
  commit.

## Remaining gates

- This is a persistence-boundary cycle, not a callback, device, or listening
  admission. It does not change the current Core MIDI or Metal gates.
