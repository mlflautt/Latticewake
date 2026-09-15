# Cycle 026 handoff — standalone app packaging

- Base: `ba7d8db`; scope is repeatable debug `.app` packaging and local ad-hoc
  signing for the standalone audition target.
- Verification: normal `make clean && make test`; sanitizer `make clean &&
  make test CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1
  -fsanitize=address,undefined -fno-omit-frame-pointer'`; `cd app && swift
  test`; and `bash scripts/build_macos_app.sh`.
- Runtime attempt: the bundled app launched through `open -W`, but this
  automation host exposed no app accessibility surface or stop-time receipt.
  It is not used as callback, device, or listening evidence.
- Limits: no release signing/notarization, target-device receipt, device
  deadline result, hardware MIDI session, or listener observation.
- Requested integration: run the manual protocol on the intended output route
  and return the displayed receipt plus optional listener wording for Cycle 027.
- Rollback: `git revert` this cycle commit; the app bundle is an ignored build
  artifact and no external service is changed.
