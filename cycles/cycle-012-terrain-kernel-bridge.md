# Cycle 012 — terrain-kernel C ABI bridge

Builds the Swift package with the portable Scene, terrain evaluator, and fixed
capacity kernel sources through an opaque C ABI. AVAudioEngine now renders the
C++ kernel rather than the temporary Swift oscillator. It remains outside the
callback-admission gate until allocation/queue/device evidence exists.
