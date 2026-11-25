# Cycle 066 handoff — reproducible image-scene capture

Base: `3da08a4` (`v0.65.0-alpha.1`). Repeated captures and signature demos now
create unique filenames with exclusive writes. Receipts bind WAV SHA-256 and
image field hashes. If receipt creation fails, the WAV created by that attempt
is removed. The new receipt fields are optional when decoding earlier receipts.
Scene library load now rejects missing referenced image fields explicitly.

Regression checks save and reopen an image-backed scene, compare its offline
render bytes before and after reopening, check missing-field rejection, and
confirm repeated captures keep the earlier file while producing equal audio.
`make verify-release` passed normal and sanitizer C++ suites, Swift, shell
checks, and signed app bundle verification. Bundle UUID
`7CF838B0-5209-332C-9C17-C3FFFC9F3825`, version `0.66.0-alpha.1`, build 73.
No human listening or native scene save/load session was conducted here.
Commit, tag, push, and hosted CI are reported in the cycle response.
