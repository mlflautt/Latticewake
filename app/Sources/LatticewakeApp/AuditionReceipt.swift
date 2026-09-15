import Foundation

struct AuditionReceipt: Equatable {
  let sampleRate: Double
  let callbackCount: UInt64
  let renderedFrames: UInt64
  let maximumRenderNanoseconds: UInt64
  let deadlineMisses: UInt64
  let rejectedBlocks: UInt64

  var statusText: String {
    "Audition receipt: \(callbackCount) blocks, \(renderedFrames) frames at \(Int(sampleRate)) Hz, max \(maximumRenderNanoseconds / 1_000) µs, \(deadlineMisses) bridge budget misses, \(rejectedBlocks) rejected."
  }

  var machineLine: String {
    "LW_AUDITION_RECEIPT sample_rate=\(sampleRate) callbacks=\(callbackCount) frames=\(renderedFrames) max_render_ns=\(maximumRenderNanoseconds) deadline_misses=\(deadlineMisses) rejected_blocks=\(rejectedBlocks)"
  }

  var fileContents: String { machineLine + "\n" }
}
