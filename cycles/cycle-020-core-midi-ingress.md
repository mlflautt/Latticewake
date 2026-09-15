# Cycle 020 — Core MIDI and MPE ingress

## Objective

Connect macOS Core MIDI sources to one main-actor ingress producer, validate
legacy/lower/upper MPE channel ownership in the portable C++ bridge, and route
accepted note/expression events to the existing bounded terrain-kernel path.

## Acceptance checks

1. The Core MIDI receive callback never calls the audio kernel directly; it
   decodes packets and transfers typed messages to the main actor.
2. Legacy, lower, and upper MPE modes have explicit master/member boundaries.
3. Pitch bend, channel pressure, CC74, and sustain decode deterministically;
   mode change, endpoint loss, and Panic clear ingress state and stop audio.
4. Bridge, sanitizer, and Swift decoder tests pass.

## Non-goals

No hardware-device session is claimed. The current terrain kernel retains
global expression state, so this cycle validates per-channel MPE ownership at
the ingress boundary but does not yet prove independent per-note rendering.
There is no MIDI output, UMP/MIDI 2.0, AUv3, or callback admission.
