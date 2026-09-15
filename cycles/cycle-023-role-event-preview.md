# Cycle 023 — role-event preview and replay

This cycle exposes the existing deterministic, four-role generator through a
small C ABI preview boundary. Given validated canonical Scene bytes, a start
sample, and a bounded window, it returns the trace's event count, first/last
sample positions, and a stable FNV-1a receipt over the canonical trace bytes.

Terrain Stage requests that preview on scene restore and explicit role Apply,
then displays the receipt. It never passes the trace to the audio adapter,
event queue, or callback.

Acceptance is repeated C++ and Swift previews with matching summary/receipt,
plus normal, sanitizer, and Swift package checks. It does not admit the audio
callback, provide live role scheduling, establish device behavior, or make a
human listening or creative-quality claim.
