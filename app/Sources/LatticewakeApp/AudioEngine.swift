import AVFoundation
import Darwin
import LatticewakeBridge

@_silgen_name("lw_kernel_create") private func lw_kernel_create() -> OpaquePointer?
@_silgen_name("lw_kernel_destroy") private func lw_kernel_destroy(_ kernel: OpaquePointer)
@_silgen_name("lw_kernel_prepare_demo") private func lw_kernel_prepare_demo(_ kernel: OpaquePointer, _ rate: Double) -> Int32
@_silgen_name("lw_kernel_prepare_scene_json") private func lw_kernel_prepare_scene_json(_ kernel: OpaquePointer, _ json: UnsafePointer<CChar>, _ rate: Double) -> Int32
@_silgen_name("lw_kernel_publish_scene_json") private func lw_kernel_publish_scene_json(_ kernel: OpaquePointer, _ json: UnsafePointer<CChar>, _ rate: Double) -> Int32
@_silgen_name("lw_kernel_note_on") private func lw_kernel_note_on(_ kernel: OpaquePointer, _ note: Int32, _ velocity: Float) -> Int32
@_silgen_name("lw_kernel_note_on_source") private func lw_kernel_note_on_source(_ kernel: OpaquePointer, _ note: Int32, _ velocity: Float, _ source: UInt32) -> Int32
@_silgen_name("lw_kernel_expression") private func lw_kernel_expression(_ kernel: OpaquePointer, _ glide: Float, _ press: Float, _ slide: Float) -> Int32
@_silgen_name("lw_kernel_note_expression") private func lw_kernel_note_expression(_ kernel: OpaquePointer, _ note: Int32, _ glide: Float, _ press: Float, _ slide: Float) -> Int32
@_silgen_name("lw_kernel_note_expression_source") private func lw_kernel_note_expression_source(_ kernel: OpaquePointer, _ note: Int32, _ glide: Float, _ press: Float, _ slide: Float, _ source: UInt32) -> Int32
@_silgen_name("lw_kernel_note_off") private func lw_kernel_note_off(_ kernel: OpaquePointer, _ note: Int32) -> Int32
@_silgen_name("lw_kernel_note_off_source") private func lw_kernel_note_off_source(_ kernel: OpaquePointer, _ note: Int32, _ source: UInt32) -> Int32
@_silgen_name("lw_kernel_set_roles_running") private func lw_kernel_set_roles_running(_ kernel: OpaquePointer, _ running: UInt32)
@_silgen_name("lw_kernel_render") private func lw_kernel_render(_ kernel: OpaquePointer, _ output: UnsafeMutablePointer<Float>, _ frames: UInt32) -> Int32

private struct BridgeCallbackStatus {
  var callbackCount: UInt64 = 0
  var renderedFrames: UInt64 = 0
  var renderFailures: UInt64 = 0
  var maximumRenderNanoseconds: UInt64 = 0
  var deadlineMisses: UInt64 = 0
  var maximumCallbackFrames: UInt32 = 0
}

private struct BridgeRoleStatus {
  var running: UInt32 = 0
  var activeLanes: UInt32 = 0
  var loopFrames: UInt64 = 0
}

@_silgen_name("lw_kernel_role_status") private func lw_kernel_role_status(
  _ kernel: OpaquePointer, _ status: UnsafeMutablePointer<BridgeRoleStatus>
) -> Int32

@_silgen_name("lw_kernel_callback_status") private func lw_kernel_callback_status(
  _ kernel: OpaquePointer, _ status: UnsafeMutablePointer<BridgeCallbackStatus>
) -> Int32

final class CallbackRenderState: @unchecked Sendable {
  let kernel: OpaquePointer
  init(kernel: OpaquePointer) { self.kernel = kernel }
}

private enum CallbackRenderRoute {
  nonisolated static func render(kernel: OpaquePointer, frameCount: AVAudioFrameCount,
                                 audioBufferList: UnsafeMutablePointer<AudioBufferList>) -> OSStatus {
    let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
    guard let firstBuffer = buffers.first, let firstData = firstBuffer.mData else { return noErr }
    let first = firstData.assumingMemoryBound(to: Float.self)
    let rendered = lw_kernel_render(kernel, first, frameCount)
    var index = 1
    while index < buffers.count {
      let buffer = buffers[index]
      if let destination = buffer.mData {
        let bytes = min(Int(buffer.mDataByteSize), Int(frameCount) * MemoryLayout<Float>.stride)
        memcpy(destination, firstData, bytes)
      }
      index += 1
    }
    if rendered == 0 {
      var zeroIndex = 0
      while zeroIndex < buffers.count {
        if let destination = buffers[zeroIndex].mData { memset(destination, 0, Int(buffers[zeroIndex].mDataByteSize)) }
        zeroIndex += 1
      }
    }
    return noErr
  }
}

nonisolated func makeCallbackRenderBlock(_ state: CallbackRenderState) -> AVAudioSourceNodeRenderBlock {
  { @Sendable _, _, count, audioBufferList -> OSStatus in
    CallbackRenderRoute.render(kernel: state.kernel, frameCount: count, audioBufferList: audioBufferList)
  }
}

private nonisolated func makeCallbackSourceNode(_ state: CallbackRenderState) -> AVAudioSourceNode {
  AVAudioSourceNode(renderBlock: makeCallbackRenderBlock(state))
}

@MainActor final class LatticewakeAudio: ObservableObject {
  @Published private(set) var running = false
  @Published private(set) var outputPeak: Double = 0
  @Published private(set) var rolesRunning = false
  @Published private(set) var activeRoleLanes = 0
  func refreshMeter() {
    outputPeak = kernel.map { Double(lw_kernel_output_peak($0)) } ?? 0
    if let kernel {
      var status = BridgeRoleStatus()
      if lw_kernel_role_status(kernel, &status) != 0 {
        rolesRunning = status.running != 0
        activeRoleLanes = Int(status.activeLanes)
      }
    }
  }
  @Published private(set) var callbackStatus = "No callback blocks rendered."
  @Published private(set) var auditionReceipt: AuditionReceipt?
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
    let node = makeCallbackSourceNode(CallbackRenderState(kernel: created))
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
    auditionReceipt = nil
    callbackStatus = "Callback preflight active (maximum 4096 frames)."
  }
  func stop() {
    engine.stop()
    if let sourceNode {
      engine.disconnectNodeOutput(sourceNode)
      engine.detach(sourceNode)
    }
    sourceNode = nil
    if let kernel {
      var status = BridgeCallbackStatus()
      if lw_kernel_callback_status(kernel, &status) != 0 {
        let receipt = AuditionReceipt(sampleRate: engine.mainMixerNode.outputFormat(forBus: 0).sampleRate,
                                      callbackCount: status.callbackCount,
                                      renderedFrames: status.renderedFrames,
                                      maximumRenderNanoseconds: status.maximumRenderNanoseconds,
                                      deadlineMisses: status.deadlineMisses,
                                      rejectedBlocks: status.renderFailures)
        auditionReceipt = receipt
        callbackStatus = receipt.statusText
      }
      lw_kernel_destroy(kernel)
    }
    kernel = nil
    running = false
    rolesRunning = false
    activeRoleLanes = 0
  }
  func play(note: Int) { if let kernel { _ = lw_kernel_note_on(kernel, Int32(note), 0.7) } }
  func release(note: Int) { if let kernel { _ = lw_kernel_note_off(kernel, Int32(note)) } }
  func pointerPlay(note: Int) { if let kernel { _ = lw_kernel_note_on_source(kernel, Int32(note), 0.7, 3) } }
  func pointerRelease(note: Int) { if let kernel { _ = lw_kernel_note_off_source(kernel, Int32(note), 3) } }
  func pointerExpression(note: Int, glide: Double, press: Double, slide: Double) { if let kernel { _ = lw_kernel_note_expression_source(kernel, Int32(note), Float(glide), Float(press), Float(slide), 3) } }
  func keyboardExpression(note: Int, glide: Double, press: Double, slide: Double) { if let kernel { _ = lw_kernel_note_expression_source(kernel, Int32(note), Float(glide), Float(press), Float(slide), 1) } }
  func startRoles() { if let kernel { lw_kernel_set_roles_running(kernel, 1); rolesRunning = true } }
  func stopRoles() { if let kernel { lw_kernel_set_roles_running(kernel, 0); rolesRunning = false } }
  func expression(glide: Double, press: Double, slide: Double) { if let kernel { _ = lw_kernel_expression(kernel, Float(glide), Float(press), Float(slide)) } }
  func midiPlay(note: Int, velocity: Double) -> Bool { guard let kernel else { return false }; return lw_kernel_note_on_source(kernel, Int32(note), Float(velocity), 2) != 0 }
  func midiRelease(note: Int) -> Bool { guard let kernel else { return false }; return lw_kernel_note_off_source(kernel, Int32(note), 2) != 0 }
  func midiNoteExpression(note: Int, glide: Double, press: Double, slide: Double) { if let kernel { _ = lw_kernel_note_expression_source(kernel, Int32(note), Float(glide), Float(press), Float(slide), 2) } }
  func midiPanic() { stop() }
}
