import Testing
import Foundation
@testable import LatticewakeApp
@Test func boundaryIsPresent() { #expect(true) }
@Test func sceneStoreRoundTrips() throws {
  let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: url) }
  let receipt = try SceneStore.saveCanonical(Data("{}".utf8), to: url)
  let (bytes, loaded) = try SceneStore.loadCanonical(from: url)
  #expect(bytes == Data("{}".utf8)); #expect(receipt == loaded)
}
