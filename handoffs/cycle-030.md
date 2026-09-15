# Cycle 030 handoff — role transport

Base: `734e230` (Cycle 029 checkpoint).

Scope completed: the four existing deterministic role traces are now prepared
outside the callback as fixed, eight-beat role plans. The callback only scans
that immutable bounded plan and its fixed direct-event queue. Drone, Pad,
Motif A, and Motif B receive separate source identities (100–103), use the
scene scale for degree-to-pitch mapping, and can be started or stopped from
Terrain Stage. A stop inserts source-specific releases, so a generated
note-off cannot silence an equal-pitch keyboard, pointer, or MIDI note.

Direct sources are also explicit: keyboard 1, MIDI 2, pointer 3. Gesture
expression targets only its owning direct source. Scene publication swaps the
new role sequence at a loop boundary; the terrain plan may still become active
at the normal prepared-render-plan handoff.

Verification: normal and ASan/UBSan C++ suites pass through the installed
Command Line Tools toolchain. The bridge fixture verifies role start/stop,
source ownership, fixed loop length, audible renderer output, and zero
allocations during its role-callback render. `swift build` and the ad-hoc-signed
app-bundle rebuild pass under that same toolchain. `swift test` cannot run
there because that fallback SDK lacks Swift's `Testing` module; the licensed
full-Xcode toolchain must run the Swift fixture suite later. This handoff makes
no device or human listening claim.

User-facing behavior: start audio, then press **Play Roles**. Each enabled lane
starts at the loop boundary and the status line reports active lanes. **Stop
Roles**, Panic, or stopping audio releases generated notes. Applying lane
controls prepares the next deterministic loop; saved-scene lifecycle remains
Cycle 031 scope.

Rollback: revert the Cycle 030 commit and rebuild. This adds no scene-format
migration and never overwrites a saved scene.
