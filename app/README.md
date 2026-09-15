# Native app boundary

`swift build` builds the standalone macOS SwiftUI app and its narrow C++
bridge. **Start** opens the prepared terrain voice. **Play Roles** starts the
fixed, deterministic Drone, Pad, Motif A, and Motif B loop; **Stop Roles**
releases only generated voices. Keyboard, MIDI, and pointer notes have distinct
source identities, so equal pitches do not cancel one another.

The bridge remains a prototype until exact Core Audio allocation/locking and
target-device stress evidence is complete. Technical render evidence is not a
listening or aesthetic verdict.

## Scene library and capture

Choose one of the three starter scenes, then use **Save As** to create a
versioned `latticewake-library-v1` document. **Load** also accepts raw Scene v0
JSON without rewriting it. Changes are deliberate: lane edits do not overwrite
files until Save As, and Undo affects only the current in-memory scene.

**Capture 8s WAV** writes an offline 48 kHz mono WAV and a JSON sidecar receipt
under the app's Application Support `Latticewake/Captures` directory. The
receipt binds capture settings and scene content hash; it does not represent a
listening or musical-quality judgment.
