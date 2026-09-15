# Research reference organization handoff

Base: `d01bc3a` (`v0.34.0-alpha.2`).
Release: `v0.34.0-alpha.3`.

## Scope

Moved seven user-supplied synthesizer reference documents from the shared Music
Lab root into `research/reference-synths/`, preserving their original filenames.
Added an indexed, hash-recorded reference library and exposed it from the
project README. PDFs use Git LFS so the public repository retains pointer-based
history rather than embedding large binary revisions in ordinary Git objects.
The report remains verbatim Markdown, including its source trailing whitespace.

## Research synthesis

The source set reinforces Latticewake's existing direction: a playable,
authoritative terrain surface; independently exchangeable Surface, Traversal,
and Articulation; bounded routing and modulation; semantic expression mappings
across keyboard, pointer, MIDI, and MPE; and offline preparation for expensive
media or spectral work. It does not authorize copying another product's UI,
DSP implementation, presets, or brand language.

The comparative first-principles report is retained as secondary research. Its
technical claims must be verified against primary documentation and Latticewake
fixtures before they guide a runtime design decision.

## Verification

- SHA-256 values were recorded before the move and indexed after it.
- The seven original root paths were checked absent after the move.
- Git records the sources as additions, rather than renames, because they
  originated outside the Latticewake Git worktree; original filenames and hashes
  provide the continuity record.
- `git diff --check`, nonempty-file checks, and reference-index link checks:
  pass for authored files and PDF pointers. The verbatim report intentionally
  retains pre-existing trailing whitespace, so full-tree `git diff --check`
  reports those source lines.
- Normal C++, ASan/UBSan, Swift, and signed-app checks: pending. The local
  toolchain stops before compilation because the Xcode licence has not been
  accepted; no attempt was made to accept it on the artist's behalf.

## Runtime evidence and limitations

No C++, Swift, app bundle, callback, MIDI, or device behavior changed. This
update carries no audio, UI, listening, or callback-admission claim.

## Rollback

Revert the documentation commit to return the tracked files to their original
repository state. The original external files are now represented by their
tracked paths and hashes.
