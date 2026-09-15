# Cycle 025 — target-audition instrumentation kit

This cycle adds app-owned render-duration and budget telemetry to the exact C++
entry point used by the AVAudioSourceNode closure. On Stop, Terrain Stage shows
an audition receipt: successful block and frame counts, maximum bridge-render
duration, bridge-budget misses, and rejected blocks.

`docs/TARGET_MAC_AUDITION.md` specifies a reproducible one-minute target-Mac
run and keeps technical facts distinct from listener-provided observations.
The app was compiled and its bridge telemetry was tested locally, but no
completed target-device GUI run or listening response is represented here.
