# Cycle 035 handoff — target-Mac crash triage

Base: `535f99c` (`v0.35.0-alpha.9`).

## Implemented

- Added `scripts/triage_macos_crash.sh` with safe `baseline`, bounded `smoke`,
  and `report` modes.
- The evidence bundle records version, build, binary SHA-256, Mach-O UUID,
  timestamp, known/new diagnostic reports, report classification, and relevant
  Latticewake frames.
- Added `docs/CRASH_TRIAGE_PROTOCOL.md`, Make targets, and README discovery.

## Verification

- `zsh -n scripts/triage_macos_crash.sh`: pass.
- `make crash-baseline`: pass; current app build metadata bundle created.
- `make crash-report` is the no-new-report and report-copy verification route.

## Limits

The procedure detects and preserves target-Mac failures; it does not make a
bounded smoke equivalent to sustained playback, callback admission, hardware
MPE proof, or a human listening decision.

## Rollback

Revert this commit. It does not alter scene documents, captures, or audio
kernel state.
