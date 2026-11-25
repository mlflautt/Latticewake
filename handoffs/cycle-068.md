# Cycle 068 handoff — scene admission before playback

Base: `a27bf06` (`v0.67.0-alpha.1`). Scene changes now validate with the
portable plan builder even while audio is stopped. A failed candidate restores
the previous audio asset set and leaves the accepted scene diagnostic in place.
The stopped role-update path uses the same validation. Scene UI values and
role traces are decoded before publication; loading a document applies its
performance settings and receipts only after its scene installs successfully.

The Swift fixture tests a flat image field, a replacement with missing assets,
subsequent reuse of the accepted field, and malformed JSON rejection. The
complete release suite passed normal and sanitizer C++ checks, Swift, script
checks, signed packaging and bundle verification. Bundle UUID
`9EB71D01-4080-3A91-B4C0-6E2E223A0FC7`, version `0.68.0-alpha.1`, build 75.
No native audio-device, plug-in host, or human listening test was performed.
Commit, tag, push, and hosted verification are reported in the cycle response.
