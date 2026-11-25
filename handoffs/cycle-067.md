# Cycle 067 handoff — per-lane note-gate indicators

Base: `7963639` (`v0.66.0-alpha.1`). The render callback now publishes an atomic
four-bit mask of its tracked role note gates. The Stage shows each lane's own
`NOTE ON` state instead of reporting every enabled lane as sounding when any
lane has a note. Panic and reset clear the mask. The value is a scheduled-note
gate, not an output meter or proof that a voice survived voice stealing. The
existing tracker represents one note per lane, so overlapping chord-note
accounting needs a future richer ownership model.

The bridge fixture enables Motif A alone and verifies only bit 2 becomes active,
then verifies panic clears the mask. The all-lane and stop fixtures verify the
other boundary; existing allocation instrumentation remains in the render path.
`make verify-release` passed normal and ASan/UBSan C++ suites, 46 Swift tests
(one Core MIDI service skip), scripts, signed packaging and bundle verification.
Bundle UUID `975C1EC0-C1EE-308E-97C1-616F362AE8AE`, version `0.67.0-alpha.1`,
build 74. No device, native visual, or human listening session was performed.
Commit, tag, push, and hosted verification are reported in the cycle response.
