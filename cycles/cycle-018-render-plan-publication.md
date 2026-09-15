# Cycle 018 — immutable render-plan publication

## Objective

Prepare terrain state outside rendering and publish it through two persistent
render-plan slots. The C++ renderer may adopt a published plan only at a block
boundary; the producer never rewrites the active or pending slot.

## Acceptance checks

1. A prepared terrain plan has deterministic table bytes and a validated sample
   rate before it can be activated.
2. Initial preparation is rejected after rendering begins; live replacement
   uses a separate publish operation.
3. Only one replacement may be pending. Publishing while pending fails without
   altering the pending plan.
4. Adoption changes the active generation at a block boundary without observed
   C++ `operator new` allocation in bridge render instrumentation.

## Non-goals

This is not full AVAudioEngine callback admission, concurrent multi-producer
ingestion, Core MIDI/MPE device support, a scene editor, EngineRack, or a human
audition result.
