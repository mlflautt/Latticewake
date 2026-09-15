# Cycle 021 — per-note MPE kernel expression

## Objective

Carry MPE note identity through the bounded bridge event queue and retain
glide, press, and slide in fixed terrain voice slots. Global direct-play
expression remains available as an explicit all-active-voices gesture.

## Acceptance checks

1. A note-specific expression event changes only an active matching voice.
2. A global expression event updates defaults and every current active voice.
3. MPE ingress resolves its active channel note through the portable state
   before submitting a note-specific kernel event.
4. Distinct note-targeted expression fixtures produce distinct finite,
   deterministic output; normal, sanitizer, and Swift checks pass.

## Non-goals

No hardware MPE session, MIDI output, MPE zone voice-steal policy, AUv3, or
full audio callback admission is included.
