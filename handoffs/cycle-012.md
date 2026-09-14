# Cycle 012 handoff

- Base: `9768d8a`; opaque C handle, prepare/render/reset/note functions, and Swift AVAudioEngine adapter.
- Verification: C++ normal + ASan/UBSan tests and `app/swift test` pass.
- Limits: demo Scene is bridge-owned; no canonical Scene preparation, direct keyboard/trackpad host wiring, allocation instrumentation, or human audition evidence.
