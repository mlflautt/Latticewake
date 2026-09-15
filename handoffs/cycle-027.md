# Cycle 027 handoff — callback isolation correction

- Base: `53a6625`; scope is the Core Audio I/O-thread crash reported from
  `v0.26.0-alpha.1`.
- Diagnosis: the crash report's Thread 11 shows `swift_task_checkIsolatedSwift`
  followed by `closure #2 in LatticewakeAudio.start()`. The source-node closure
  inherited `@MainActor` isolation and was invoked by Core Audio off-main.
- Change: a nonisolated factory creates the source node. Its render closure
  captures only `CallbackRenderState`, an explicit opaque sendable holder, and
  calls the nonisolated render route.
- Verification: normal `make clean && make test`; ASan/UBSan `make clean &&
  make test CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1
  -fsanitize=address,undefined -fno-omit-frame-pointer'`; and `cd app && swift
  test` all passed.
- Limits: compile/offline checks do not prove the exact target device no longer
  traps. No callback receipt, target-device run, listener observation, or
  admission decision exists for this revision.
- Rollback: `git revert` this cycle commit; no external service is changed.
