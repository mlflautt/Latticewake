import AVFoundation

@MainActor final class LatticewakeAudio: ObservableObject {
  @Published private(set) var running = false
  private let engine = AVAudioEngine()
  private var phase = 0.0
  private var frequency = 220.0

  func start() throws {
    guard !running else { return }
    let format = engine.mainMixerNode.outputFormat(forBus: 0)
    let node = AVAudioSourceNode { [weak self] _, _, count, audioBufferList -> OSStatus in
      guard let self else { return noErr }
      let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
      let increment = 2.0 * Double.pi * self.frequency / format.sampleRate
      for frame in 0..<Int(count) {
        let sample = Float(sin(self.phase) * 0.12)
        self.phase += increment
        if self.phase >= 2.0 * Double.pi { self.phase -= 2.0 * Double.pi }
        for buffer in buffers { buffer.mData?.assumingMemoryBound(to: Float.self)[frame] = sample }
      }
      return noErr
    }
    engine.attach(node)
    engine.connect(node, to: engine.mainMixerNode, format: format)
    try engine.start()
    running = true
  }
  func stop() { engine.stop(); running = false }
  func play(note: Int) { frequency = 440.0 * pow(2.0, Double(note - 69) / 12.0) }
}
