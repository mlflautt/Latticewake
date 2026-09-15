import Testing
import Foundation
@testable import LatticewakeApp
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
