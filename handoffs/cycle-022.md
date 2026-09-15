# Cycle 022 handoff — four-role performance controls

- Base: `99672e2`; scope is canonical C++ role-control read/write plus SwiftUI
  draft controls and explicit Apply persistence/publication.
- Verification: normal `make test`, ASan/UBSan `make test`, and `cd app && swift test`.
- Evidence: bridge fixture writes Motif A enable/density/seed/pattern, rereads
  canonical bytes, and verifies values. UI has no callback-visible state.
- Limits: role events remain offline previews; no live sequencer, Metal field,
  callback admission, hardware, listening, or creative approval evidence.
- Rollback: `git revert` this cycle commit; no external state is changed.
