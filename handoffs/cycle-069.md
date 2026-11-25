# Cycle 069 handoff — native image-scene path, partial

Base: `25b8fcb` (research roadmap after `v0.68.0-alpha.1`). Native walkthrough
used a single app instance at a time and generated `build/review/image-fixture.png`.
Version 0.68 accepted the image, displayed the Image A preview, accepted it,
started the device, and the output meter reached 0.00497 when a keyboard key
was pressed. It created a Library v1 scene file with one embedded image asset;
the source SHA-256 is `f674e6fdf0...` and the field hash is
`49843c3cca49f288fe71aa8dc899157cee72db1fc51295490a23657690dcd249`.
Saved document SHA-256:
`6777620c6dec2ad931d9874f87a4b5ced98f7723f809110cb0fef3b362d5aa47`.

After Save As and again after selecting Load in a freshly reopened app, native
computer-use accessibility calls timed out. Process samples showed the main
thread waiting in the AppKit event loop; this does not establish an app hang
or successful native reload. Both review processes were closed. The native
reload, UI capture and human listening gates remain open; this is a partial
cycle, not completion of the roadmap's round-trip acceptance.

The native-saved file exposed a real issue: the starter scene has all roles
disabled, so role capture created a silent WAV. `OfflineCapture` now rejects
that condition before creating files and tells the artist to enable a role,
while explaining that this is not a live performance recording. A rebuilt
0.69 app showed that message in native review and was closed afterward.

An opt-in Swift fixture loads the exact native-saved document, verifies source
and field hashes, confirms disabled-role capture is rejected, enables Drone in
an in-memory candidate, renders nonzero PCM with the embedded field, verifies
the WAV hash and confirms original scene bytes remain untouched. Run with
`LW_NATIVE_IMAGE_SCENE` and `LW_NATIVE_SOURCE_IMAGE` pointing to the two files.
The full `make verify-release` passed with this fixture enabled: 48 Swift tests,
one Core MIDI service skip, normal and ASan/UBSan C++ checks, scripts and
signed bundle verification. Bundle UUID
`4CABEFDB-95DE-38FF-8509-E37CA29C0AE7`, version `0.69.0-alpha.1`, build 76.
No human listening observation is claimed.
