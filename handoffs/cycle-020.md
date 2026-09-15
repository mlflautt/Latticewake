# Cycle 020 handoff — Core MIDI and MPE ingress

## Base and scope

- Base: `a3cc641` (`cycle-019: add terrain stage snapshots`).
- Owned paths: portable MPE reset, C MPE state ABI/fixtures, Core MIDI ingress,
  audio adapter/UI MIDI controls/tests, contract/status documents, cycle
  records, version, and this handoff.
- The Core MIDI receive callback performs packet copying/decoding only, then
  schedules typed `MIDIMessage` values onto the main actor. That actor is the
  one producer that validates channel ownership in `LWMpeStateRef` and submits
  accepted events to `LWKernelRef`'s existing SPSC queue.

## Verification

```text
make clean && make test
make clean && make test CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1 -fsanitize=address,undefined -fno-omit-frame-pointer'
cd app && swift test
```

All checks passed locally on Apple Silicon. C++ fixtures cover lower-zone
master rejection, member note/expression/release, reset, and invalid mode.
Swift fixtures cover note, pitch bend, channel pressure, and CC74 packet
decoding. No physical MIDI endpoint was connected during this cycle.

## Runtime evidence and limitations

The app now discovers and connects Core MIDI sources, exposes Legacy/MPE
Lower/MPE Upper selection, defers note-off while sustain is held, and panics
when the final source disappears. The audio kernel currently applies the most
recent accepted expression globally, so MPE channel ownership is not yet proof
of independently rendered per-note glide/press/slide. There is no MIDI output,
device hardware session, callback admission, target-device stress, or human
listening evidence.

## Integration and rollback

The next kernel cycle should add note identity to expression events and apply
per-note MPE values inside voices before any independent-expression claim. Roll
back with `git revert` of the Cycle 020 commit; no external state is changed.
