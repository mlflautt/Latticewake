# Target-Mac audition protocol

This protocol produces evidence for one specific build and output route. It
does not decide whether the music is good, choose a preferred scene, or infer a
human listening result from counters.

## Before starting

Build and launch the standalone `.app` bundle on the intended Apple-Silicon Mac:

```bash
cd "/Users/m1/Music Lab/Latticewake/app"
bash scripts/build_macos_app.sh
open ../build/Latticewake.app
```

Record the app version/tag, Mac model, macOS version, selected audio output,
sample rate, buffer setting if the output device exposes one, and whether any
other audio host is active. This establishes a technical context; it is not a
rating.

## Technical run

1. Start the app and press **Start**.
2. Play QWERTY notes and use the Terrain Stage trackpad gesture for at least
   one minute. Optionally exercise a scene Apply while it is running.
3. Press **Stop** and copy the displayed **Audition receipt** exactly. It
   records callback blocks, frames, maximum bridge-render time, bridge budget
   misses, and rejected blocks.
4. Record any dropout, error, unexpected silence, or crash as observed facts.
   A zero-miss receipt is helpful technical evidence but does not itself prove
   Core Audio has no hidden allocations/locks or that all device deadlines were
   met.

## Listening observation

Only the listener should supply this part. Preserve blank fields rather than
inventing a result:

```text
Build/tag:
Mac and output route:
Sample rate / buffer setting:
Audition receipt:
Observed technical behavior:
Listener observations (optional, in their own words):
Would you continue, revise, or defer? (optional):
```

The listener's response is a creative decision, not a test metric. Attach the
completed record to a later handoff without substituting it with automated
claims.
