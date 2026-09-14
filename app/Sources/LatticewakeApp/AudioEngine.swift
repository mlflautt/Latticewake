import AVFoundation

@_silgen_name("lw_kernel_create") private func lw_kernel_create() -> OpaquePointer?
@_silgen_name("lw_kernel_destroy") private func lw_kernel_destroy(_ kernel: OpaquePointer)
@_silgen_name("lw_kernel_prepare_demo") private func lw_kernel_prepare_demo(_ kernel: OpaquePointer, _ rate: Double) -> Int32
@_silgen_name("lw_kernel_prepare_scene_json") private func lw_kernel_prepare_scene_json(_ kernel: OpaquePointer, _ json: UnsafePointer<CChar>, _ rate: Double) -> Int32
@_silgen_name("lw_kernel_note_on") private func lw_kernel_note_on(_ kernel: OpaquePointer, _ note: Int32, _ velocity: Float) -> Int32
@_silgen_name("lw_kernel_note_off") private func lw_kernel_note_off(_ kernel: OpaquePointer, _ note: Int32) -> Int32
@_silgen_name("lw_kernel_render") private func lw_kernel_render(_ kernel: OpaquePointer, _ output: UnsafeMutablePointer<Float>, _ frames: UInt32) -> Int32

@MainActor final class LatticewakeAudio: ObservableObject {
  @Published private(set) var running = false
  private let engine = AVAudioEngine()
  private var kernel: OpaquePointer?
  private var sceneJSON = DemoScene.canonicalJSON

  func setScene(bytes: Data) throws {
    guard let text = String(data: bytes, encoding: .utf8) else { throw NSError(domain: "Latticewake", code: 3) }
    sceneJSON = text
  }

  func start() throws {
    guard !running else { return }
    let format = engine.mainMixerNode.outputFormat(forBus: 0)
    guard let created = lw_kernel_create() else { throw NSError(domain: "Latticewake", code: 1) }
    let prepared = sceneJSON.withCString { lw_kernel_prepare_scene_json(created, $0, format.sampleRate) }
    guard prepared != 0 else { lw_kernel_destroy(created); throw NSError(domain: "Latticewake", code: 2) }
    kernel = created
    let node = AVAudioSourceNode { [weak self] _, _, count, audioBufferList -> OSStatus in
      guard let self, let kernel = self.kernel else { return noErr }
      let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
      guard let first = buffers.first?.mData?.assumingMemoryBound(to: Float.self) else { return noErr }
      _ = lw_kernel_render(kernel, first, count)
      for buffer in buffers.dropFirst() {
        guard let pointer = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
        for frame in 0..<Int(count) { pointer[frame] = first[frame] }
      }
      return noErr
    }
    engine.attach(node)
    engine.connect(node, to: engine.mainMixerNode, format: format)
    try engine.start()
    running = true
  }
  func stop() { engine.stop(); if let kernel { lw_kernel_destroy(kernel) }; kernel = nil; running = false }
  func play(note: Int) { if let kernel { _ = lw_kernel_note_on(kernel, Int32(note), 0.7) } }
  func release(note: Int) { if let kernel { _ = lw_kernel_note_off(kernel, Int32(note)) } }
}
