# Target-Mac crash triage protocol

Use this procedure before asking a collaborator to supply a crash report. It
creates a time-bounded, exact-build evidence bundle and does not delete reports,
kill existing app instances, or modify saved scenes.

## Standard loop

1. Rebuild and code-sign the exact app revision, then run `make bundle-verify`.
   It proves the app-bundle executable byte-matches SwiftPM's current product.
2. Run `make crash-baseline`. This writes app version, build number, binary
   SHA-256, Mach-O UUID, timestamp, and the known report set under
   `build/crash-triage/`.
3. Run `make crash-smoke` for the eight-second bounded launch check, or launch
   the app manually and then run `make crash-report`.
4. Read `build/crash-triage/summary.txt`. A newly produced `.ips` file is copied
   into the bundle for a reproducible handoff.
5. Classify before changing code: Swift executor isolation, Core MIDI lifecycle,
   SwiftUI layout/view lifecycle, audio host/callback, or unclassified.
6. Add the smallest deterministic regression that exercises the exact boundary;
   rebuild and repeat this loop from a new baseline.

## Evidence rules

- “No new report during an eight-second smoke” means only that the bounded
  launch did not crash. It is not audio, MIDI hardware, UI-feel, or real-time
  admission evidence.
- A report’s version, binary SHA-256, and UUID must match the build under test.
  A report from a prior process or an app bundle replaced in place is stale
  evidence and must be labelled as such.
- Never diagnose runtime behavior from `swift test` alone: package verification
  is required before a standalone launch claim.
- Do not use an automated result to infer listening quality or artistic merit.
- Keep failing reports. A fix must cite the report’s faulting thread and
  relevant frames, then add a regression at that boundary.

## Current gate matrix

| Boundary | Automated evidence | Still required |
| --- | --- | --- |
| Standalone startup | crash baseline + bounded smoke | sustained target-Mac session |
| Core MIDI/MPE | virtual-source packet fixture | explicit endpoint/hardware reconnect session |
| SwiftUI Stage | bounded startup smoke | visual and accessibility review at target sizes |
| Audio callback | bridge fixture + device smoke | allocation/lock/deadline instrumentation and human audition |
| Metal surface | source retained | target-Mac idle-cost admission before re-enabling it |

## Handoff contents

Each crash correction handoff records: report path and build identity, minimal
classification, reproducer, regression fixture, normal/sanitizer/Swift results,
bounded launch outcome, remaining gates, rollback commit, and whether a human
action is still required.
