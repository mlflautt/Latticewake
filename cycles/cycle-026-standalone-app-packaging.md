# Cycle 026 — standalone app packaging

The SwiftPM executable is now assembled into `build/Latticewake.app` by
`app/scripts/build_macos_app.sh`. The script builds the Apple-Silicon debug
binary, copies the application metadata, and applies local ad-hoc signing.
This gives the standalone audition protocol a stable application bundle and
bundle identifier (`com.mlflautt.latticewake`).

Automation launched the bundle, but no accessibility surface or stop-time
audition receipt was available. That launch is not target-device performance or
listening evidence. The supported evidence procedure remains the manual
protocol in `docs/TARGET_MAC_AUDITION.md`.
