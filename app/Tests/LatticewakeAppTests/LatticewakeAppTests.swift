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
@Test func sceneStoreRoundTrips() throws {
  let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: url) }
  let receipt = try SceneStore.saveCanonical(Data("{}".utf8), to: url)
  let (bytes, loaded) = try SceneStore.loadCanonical(from: url)
  #expect(bytes == Data("{}".utf8)); #expect(receipt == loaded)
}
