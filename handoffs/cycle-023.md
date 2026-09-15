# Cycle 023 handoff — role-event preview and replay

- Base: `70498da`; scope is the bounded, offline role-event preview C ABI and
  its read-only Terrain Stage status.
- Verification: `make clean && make test`; sanitizer `make clean && make test
  CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1
  -fsanitize=address,undefined -fno-omit-frame-pointer'`; and `cd app && swift
  test`.
- Evidence: bridge and Swift fixtures repeat the same one-second preview from
  canonical Scene bytes and compare event count, sample range, and FNV-1a
  receipt. The UI requests preview only during scene lifecycle work.
- Limits: preview data is not placed in the real-time queue or rendered as
  role audio. Exact callback-path allocation/lock admission, target-device
  stress, hardware MIDI, human listening, and creative approval remain open.
- Rollback: `git revert` this cycle commit; no external state is changed.
