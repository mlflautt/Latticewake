# Native app boundary

`swift build` builds the standalone macOS SwiftUI app and its narrow C++
bridge. **Start** opens the prepared terrain voice. **Play Roles** starts the
fixed, deterministic Drone, Pad, Motif A, and Motif B loop; **Stop Roles**
releases only generated voices. Keyboard, MIDI, and pointer notes have distinct
source identities, so equal pitches do not cancel one another.

The bridge remains a prototype until exact Core Audio allocation/locking and
target-device stress evidence is complete. Technical render evidence is not a
listening or aesthetic verdict.
