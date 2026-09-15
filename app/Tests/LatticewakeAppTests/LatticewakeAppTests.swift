import Testing
import Foundation
import AVFoundation
import LatticewakeBridge
@testable import LatticewakeApp

@Test func keyboardRepeatAndFocusRelease() {
  var keys = KeyboardState()
  let first = keys.down(60)
  let repeated = keys.down(60)
  let second = keys.down(64)
  let released = keys.releaseAll()
  let stale = keys.up(60)
  #expect(first && !repeated && second && !stale)
  #expect(released == [60,64])
  #expect(keys.held.isEmpty)
}

@Test func gestureOwnershipAndResize() {
  var pointer = GestureState()
  let note = pointer.begin(held: [])
  #expect(note == 48)
  let duplicate = pointer.begin(held: [60])
  #expect(duplicate == nil)
  #expect(pointer.targets == [48])
  let release = pointer.end()
  #expect(release.note == 48 && !pointer.active)
  let shaping = pointer.begin(held: [60,64])
  #expect(shaping == nil && pointer.targets == [60,64])
  #expect(GestureState.normalized(100,length: 200) == GestureState.normalized(300,length: 600))
  #expect(GestureState.normalized(-20,length: 200) == 0)
}

@Test func audioCallbackRunsOnBackgroundThread() async {
  let success = await withCheckedContinuation { continuation in
    DispatchQueue.global().async {
      let kernel = lw_kernel_create()!
      defer { lw_kernel_destroy(kernel) }
      let prepared = DemoScene.playableJSON.withCString { lw_kernel_prepare_scene_json(kernel, $0, 48000) }
      let block = makeCallbackRenderBlock(CallbackRenderState(kernel: kernel))
      let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)!
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 512)!
      buffer.frameLength = 512
      _ = lw_kernel_note_on(kernel, 60, 0.7)
      var silence = ObjCBool(false)
      var timestamp = AudioTimeStamp()
      let result = block(&silence, &timestamp, 512, buffer.mutableAudioBufferList)
      let left = buffer.floatChannelData![0]
      let right = buffer.floatChannelData![1]
      let audible = (0..<512).contains { abs(left[$0]) > 0.00001 }
      let stereo = (0..<512).allSatisfy { left[$0] == right[$0] }
      continuation.resume(returning: prepared == 1 && result == 0 && audible && stereo && !Thread.isMainThread)
    }
  }
  #expect(success)
}

@Test @MainActor func optInDeviceSmoke() async throws {
  guard ProcessInfo.processInfo.environment["LW_DEVICE_SMOKE"] == "1" else { return }
  let audio = LatticewakeAudio()
  try audio.setScene(bytes: Data(DemoScene.playableJSON.utf8))
  try audio.start()
  defer { audio.stop() }
  audio.play(note: 60)
  try await Task.sleep(for: .seconds(1))
  audio.release(note: 60)
  try await Task.sleep(for: .milliseconds(200))
  audio.stop()
  #expect((audio.auditionReceipt?.callbackCount ?? 0) > 0)
  #expect(audio.auditionReceipt?.rejectedBlocks == 0)
  print(audio.auditionReceipt?.machineLine ?? "missing receipt")
}
@Test @MainActor func terrainStagePreparesImmutableSnapshot() throws {
  let model = TerrainStageModel()
  try model.prepare(sceneBytes: Data(DemoScene.canonicalJSON.utf8), sampleOffset: 480)
  #expect(model.snapshot.sampleOffset == 480)
  #expect(model.snapshot.points.count == 256)
  #expect(model.snapshot.points.allSatisfy { $0.value >= 0 && $0.value <= 1 })
}
@Test func midiDecoderPreservesChannelVoiceMessages() {
  let messages = MIDIMessageDecoder.decode([0x91, 60, 100, 0xE1, 0, 64, 0xD1, 96, 0xB1, 74, 127])
  #expect(messages == [
    MIDIMessage(status: 0x91, data1: 60, data2: 100),
    MIDIMessage(status: 0xE1, data1: 0, data2: 64),
    MIDIMessage(status: 0xD1, data1: 96, data2: 0),
    MIDIMessage(status: 0xB1, data1: 74, data2: 127)
  ])
}
@Test func sceneStoreRoundTrips() throws {
  let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: url) }
  let receipt = try SceneStore.saveCanonical(Data("{}".utf8), to: url)
  let (bytes, loaded) = try SceneStore.loadCanonical(from: url)
  #expect(bytes == Data("{}".utf8)); #expect(receipt == loaded)
}

@Test func roleTracePreviewIsDeterministic() throws {
  let bytes = Data(DemoScene.canonicalJSON.utf8)
  let first = try RoleTraceBridge.preview(sceneBytes: bytes)
  let repeated = try RoleTraceBridge.preview(sceneBytes: bytes)
  #expect(first == repeated)
  #expect(first.eventCount > 0)
}

@Test func auditionReceiptIsStructuredAndStable() {
  let receipt = AuditionReceipt(sampleRate: 48_000, callbackCount: 12,
                                renderedFrames: 6_144, maximumRenderNanoseconds: 123_000,
                                deadlineMisses: 0, rejectedBlocks: 0)
  #expect(receipt.machineLine == "LW_AUDITION_RECEIPT sample_rate=48000.0 callbacks=12 frames=6144 max_render_ns=123000 deadline_misses=0 rejected_blocks=0")
  #expect(receipt.statusText.contains("48000 Hz"))
  #expect(receipt.fileContents.hasSuffix("\n"))
}
