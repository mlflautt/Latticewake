# Cycle 064 handoff — image scene preview and capture

Base: `30fc088` (`v0.63.0-alpha.1`). Candidate image preview now uses a
separate temporary asset collection and leaves the accepted asset collection
alone. Return restores accepted assets, while a failed return keeps the preview
and candidate visible. A zero-weight candidate preview explains how Morph
affects its audibility.

Offline role capture and signature demonstrations now resolve and validate
embedded image fields using the C++ preparation route. Capture receipts include
the referenced field hashes; legacy receipts without the optional field remain
decodable. Missing fields fail before a capture is written.

`make verify-release` passed normal warnings-as-errors and ASan/UBSan C++
checks, Swift tests (46 executed, one Core MIDI service skip), script checks,
and signed bundle verification. Bundle UUID
`E6682648-65E6-3619-A65D-5B14B31619B5`, version `0.64.0-alpha.1`, build 71.
The capture fixture rejects missing fields, emits nonzero PCM for a valid image
field, and round-trips its receipt.

Native review used one app instance and a generated fractal image. The chooser
imported it, Preview displayed the registered image and sampling path, and
Cancel restored the analytic source; the app was closed afterward. The preview
was not auditioned and acceptance/save/load was not exercised through the UI.
At the reviewed window size the top bar and inspector extended beyond the
right edge, and some macro labels wrapped awkwardly. Responsive layout needs a
dedicated correction and another visual review.

Capture produces the existing eight-second mono role passage; it is not a
recording of the artist's live performance. Commit, tag, push, and hosted CI
status are reported in the cycle response.
