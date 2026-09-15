# Cycle 027 — callback isolation correction

The first target-Mac Start report for `v0.26.0-alpha.1` identified a Swift
concurrency trap on Core Audio's I/O thread. The AVAudioSourceNode closure had
been created lexically inside `@MainActor LatticewakeAudio`, so Swift asserted
the main executor when Core Audio called it.

The source node is now created by a `nonisolated` factory. Its callback
captures only an `@unchecked Sendable` opaque C++ kernel holder and invokes a
`nonisolated` C-memory/C++ render helper. It does not capture the actor-owned
audio adapter or UI state.

Normal, sanitizer, and Swift package checks pass. A new human-triggered Start
on the rebuilt bundle is required to prove the reported crash is gone.
