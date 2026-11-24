# Cycle 062 handoff — terrain diagnostic correction

Base: `13c0606` (`v0.61.0-alpha.1`).

The renderer previously initialized the range of the mixed tables from the
unmixed A table, so a silent B table at 100% morph was incorrectly reported as
pitched. The range now starts empty and includes only actual mixed samples.
A regression covers a non-flat image A, flat image B, and morph at 100%.

The Stage no longer labels image-containing scenes flat using raw image
brightness: image audio tables are centered and normalized before mixing, so
the raw estimate can differ from the renderer. Exposing the prepared audio
diagnostic safely to the UI remains future work. Layer views now use component
identity instead of image asset identity, so the same image in A and B does
not produce duplicate SwiftUI view identifiers.

Both hosted verification runs for base commit `13c0606` passed. The native
image chooser, audible image-derived sound and mixed-field visual quality still
need an end-to-end session; no human listening result is claimed.

`make verify-release` passed normal warnings-as-errors and ASan/UBSan C++
checks, Swift tests (43 executed, one Core MIDI service unavailable skip),
script checks, signed package build and bundle verification. The bundle UUID
is `AFECC9C2-C9FF-38CA-954D-D9E29A427D20`, version `0.62.0-alpha.1`, build 69.
No device or native visual review was performed for this correction.

Commit, tag, push, and hosted CI status are reported alongside this cycle.
