# Cycle 024 handoff — callback-route preflight instrumentation

- Base: `c96d07a`; scope is the app-owned AVAudioSourceNode-to-C++ render route,
  bounded counters, rejected-block silence, and bridge stress fixture.
- Verification: normal `make clean && make test`; sanitizer `make clean &&
  make test CXXFLAGS='-std=c++20 -Wall -Wextra -Werror -pedantic -O1
  -fsanitize=address,undefined -fno-omit-frame-pointer'`; and `cd app && swift
  test`.
- Evidence: after all setup allocations, the fixture exercises 400 renders for
  each 44.1/48/96 kHz kernel at 32–1,024 frames while injecting bounded queue
  traffic. It observes no C++ `new`, validates counter totals, and confirms a
  4,097-frame block is rejected. The Swift package compiles the exact source
  node closure that delegates to that C ABI.
- Limits: no Core Audio internal allocation/lock tracer, device deadline
  measurement, target-Mac stress session, hardware MIDI session, or human
  listening result exists. This cycle does not admit the callback.
- Rollback: `git revert` this cycle commit; no external state is changed.
