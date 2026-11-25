# Cycle 068 — scene admission before playback

Reject malformed or unpreparable scenes, including missing image fields, when
they are selected rather than deferring failure until the audio device starts.
Keep accepted assets and scene diagnostics on failure. Prepare UI data before
publishing a new scene and apply loaded performance/receipt data only after a
successful install. Verify the stopped-audio failure and asset rollback path.
