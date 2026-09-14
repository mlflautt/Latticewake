# Cycle 003A — Scene v0 serialization boundary

## Objective

Define a strict JSON representation for Scene v0 and add an independent,
dependency-free parser and canonical serializer. The parser must construct the
existing typed model and call the existing Scene validator.

## Acceptance checks

1. A valid typed Scene serializes and parses into an equivalent typed Scene.
2. Serialization is canonical: identical valid scene values yield identical
   UTF-8 bytes.
3. The parser rejects malformed JSON, duplicate or unknown fields, incorrect
   types, invalid enum strings, unsafe integer values, and values rejected by
   the typed validator.
4. No audio, MIDI, UI, filesystem, network, or dependency behavior is added.

## Non-goals

This cycle is not a general-purpose JSON library. The parser supports only the
strict JSON subset and fixed schema required for a Latticewake Scene v0 file.
