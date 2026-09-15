# Cycle 028 — sustained terrain notes

Reproduce the old default's zero table variation, preserve saved scenes, and
offer an explicit unsaved playable starter. Prepare a centered, normalized
terrain waveform with linear interpolation, 10 ms attack, 120 ms release,
eight-voice gain, duplicate note suppression, and deterministic oldest stealing.
Explicit key-up subscription and focus-loss release own keyboard lifetimes.

Acceptance: C4/E4/G4 sustained pitch within 1%, sustained RMS above .005,
release-tail RMS below 1e-5, duplicate and voice-cap fixtures, actual callback
invoked on a background thread, and an opt-in AVAudioEngine device smoke test.
The test suite writes build/playable-baseline.wav. Existing scenes are retained.

Cycles 029–031 remain the accepted next work: gesture ownership/table morph,
audible role transport/source identities, and versioned scene library/captures.
