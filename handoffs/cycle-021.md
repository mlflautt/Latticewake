# Cycle 021 handoff — per-note MPE kernel expression

## Base and scope

- Base: `5047e97` (`cycle-020: add core midi mpe ingress`).
- Owned paths: terrain-kernel voice state, note-expression C ABI, MPE active
  note query, Swift audio/MIDI adapters, C++ fixtures, contract/architecture
  documents, cycle records, version, and this handoff.
- Each fixed voice now stores its own glide, press, and slide. MPE channel
  ownership resolves to an active note before `lw_kernel_note_expression`
  submits a bounded event. Trackpad/direct expression intentionally remains
  global and updates defaults plus current active voices.

## Verification

```text
make clean && make test
make clean && make test CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1 -fsanitize=address,undefined -fno-omit-frame-pointer'
cd app && swift test
```

All checks passed locally on Apple Silicon. The core fixture renders two notes,
targets a zero-pressure expression to one note at a time, and proves distinct
finite deterministic buffers. Bridge fixtures additionally resolve the active
note for a lower-zone member channel.

## Runtime evidence and limitations

This proves portable event-to-voice behavior, not MPE controller hardware,
perceptual quality, target-device timing, callback admission, or a listening
result. MPE zone exhaustion still rejects a second note on an active member
channel; voice stealing and MIDI output remain future work.

## Integration and rollback

Cycle 022 can add four-role controls and bounded deterministic role-event
ingress; a later MIDI cycle can add declared zone-exhaustion/steal policy.
Roll back with `git revert` of the Cycle 021 commit; no external state is
changed.
