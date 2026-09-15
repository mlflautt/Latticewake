import AVFoundation

@_silgen_name("lw_kernel_create") private func lw_kernel_create() -> OpaquePointer?
@_silgen_name("lw_kernel_destroy") private func lw_kernel_destroy(_ kernel: OpaquePointer)
@_silgen_name("lw_kernel_prepare_demo") private func lw_kernel_prepare_demo(_ kernel: OpaquePointer, _ rate: Double) -> Int32
@_silgen_name("lw_kernel_prepare_scene_json") private func lw_kernel_prepare_scene_json(_ kernel: OpaquePointer, _ json: UnsafePointer<CChar>, _ rate: Double) -> Int32
@_silgen_name("lw_kernel_publish_scene_json") private func lw_kernel_publish_scene_json(_ kernel: OpaquePointer, _ json: UnsafePointer<CChar>, _ rate: Double) -> Int32
@_silgen_name("lw_kernel_note_on") private func lw_kernel_note_on(_ kernel: OpaquePointer, _ note: Int32, _ velocity: Float) -> Int32
@_silgen_name("lw_kernel_expression") private func lw_kernel_expression(_ kernel: OpaquePointer, _ glide: Float, _ press: Float, _ slide: Float) -> Int32
@_silgen_name("lw_kernel_note_off") private func lw_kernel_note_off(_ kernel: OpaquePointer, _ note: Int32) -> Int32
@_silgen_name("lw_kernel_render") private func lw_kernel_render(_ kernel: OpaquePointer, _ output: UnsafeMutablePointer<Float>, _ frames: UInt32) -> Int32

@MainActor final class LatticewakeAudio: ObservableObject {
  @Published private(set) var running = false
  private let engine = AVAudioEngine()
  private var kernel: OpaquePointer?
  private var sourceNode: AVAudioSourceNode?
  private var sceneJSON = DemoScene.canonicalJSON

  func setScene(bytes: Data) throws {
    guard let text = String(data: bytes, encoding: .utf8) else { throw NSError(domain: "Latticewake", code: 3) }
    if running, let kernel {
      let sampleRate = engine.mainMixerNode.outputFormat(forBus: 0).sampleRate
      guard text.withCString({ lw_kernel_publish_scene_json(kernel, $0, sampleRate) }) != 0 else {
        throw NSError(domain: "Latticewake", code: 4, userInfo: [NSLocalizedDescriptionKey: "Scene change is pending or could not be prepared"])
      }
    }
    sceneJSON = text
  }

  func start() throws {
    guard !running else { return }
    let format = engine.mainMixerNode.outputFormat(forBus: 0)
    guard let created = lw_kernel_create() else { throw NSError(domain: "Latticewake", code: 1) }
    let prepared = sceneJSON.withCString { lw_kernel_prepare_scene_json(created, $0, format.sampleRate) }
    guard prepared != 0 else { lw_kernel_destroy(created); throw NSError(domain: "Latticewake", code: 2) }
    let node = AVAudioSourceNode { _, _, count, audioBufferList -> OSStatus in
      let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
      guard let first = buffers.first?.mData?.assumingMemoryBound(to: Float.self) else { return noErr }
      _ = lw_kernel_render(created, first, count)
      for buffer in buffers.dropFirst() {
        guard let pointer = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
        for frame in 0..<Int(count) { pointer[frame] = first[frame] }
      }
      return noErr
    }
    kernel = created
    sourceNode = node
    engine.attach(node)
    engine.connect(node, to: engine.mainMixerNode, format: format)
    do {
      try engine.start()
    } catch {
      engine.disconnectNodeOutput(node)
      engine.detach(node)
      sourceNode = nil
      kernel = nil
      lw_kernel_destroy(created)
      throw error
    }
    running = true
  }
  func stop() {
    engine.stop()
    if let sourceNode {
      engine.disconnectNodeOutput(sourceNode)
      engine.detach(sourceNode)
    }
    sourceNode = nil
    if let kernel { lw_kernel_destroy(kernel) }
    kernel = nil
    running = false
  }
  func play(note: Int) { if let kernel { _ = lw_kernel_note_on(kernel, Int32(note), 0.7) } }
  func release(note: Int) { if let kernel { _ = lw_kernel_note_off(kernel, Int32(note)) } }
  func expression(glide: Double, press: Double, slide: Double) { if let kernel { _ = lw_kernel_expression(kernel, Float(glide), Float(press), Float(slide)) } }
  func midiPlay(note: Int, velocity: Double) -> Bool { guard let kernel else { return false }; return lw_kernel_note_on(kernel, Int32(note), Float(velocity)) != 0 }
  func midiRelease(note: Int) -> Bool { guard let kernel else { return false }; return lw_kernel_note_off(kernel, Int32(note)) != 0 }
  func midiExpression(glide: Double, press: Double, slide: Double) { expression(glide: glide, press: press, slide: slide) }
  func midiPanic() { stop() }
}
