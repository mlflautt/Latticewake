import CryptoKit
import Foundation

struct PerformanceSettingsV1: Codable, Equatable {
  var gestureGlideSemitones: Double = 12
  var pointerNote: Int = 48
  var roleTransportEnabled: Bool = false
}

struct SceneLibraryDocumentV1: Codable, Equatable {
  static let schema = "latticewake-library-v1"
  let schemaVersion: String
  var sceneJSON: String
  var performance: PerformanceSettingsV1

  init(sceneJSON: String, performance: PerformanceSettingsV1 = .init()) {
    self.schemaVersion = Self.schema
    self.sceneJSON = sceneJSON
    self.performance = performance
  }
}

struct LoadedSceneDocument: Equatable {
  let sceneBytes: Data
  let performance: PerformanceSettingsV1
  let originalSceneV0: Bool
  let receipt: SceneReceipt
}

enum SceneLibrary {
  static func load(from url: URL) throws -> LoadedSceneDocument {
    let (bytes, receipt) = try SceneStore.loadCanonical(from: url)
    guard String(data: bytes, encoding: .utf8) != nil else {
      throw NSError(domain: "Latticewake", code: 30, userInfo: [NSLocalizedDescriptionKey: "Scene file is not UTF-8 text"])
    }
    if let document = try? JSONDecoder().decode(SceneLibraryDocumentV1.self, from: bytes),
       document.schemaVersion == SceneLibraryDocumentV1.schema {
      return LoadedSceneDocument(sceneBytes: Data(document.sceneJSON.utf8), performance: document.performance,
                                 originalSceneV0: false, receipt: receipt)
    }
    return LoadedSceneDocument(sceneBytes: bytes, performance: .init(), originalSceneV0: true, receipt: receipt)
  }

  @discardableResult static func save(_ document: SceneLibraryDocumentV1, to url: URL) throws -> SceneReceipt {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let bytes = try encoder.encode(document)
    try bytes.write(to: url, options: .atomic)
    return receipt(for: bytes)
  }

  static func receipt(for bytes: Data) -> SceneReceipt {
    SceneReceipt(sha256: SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined(), byteCount: bytes.count)
  }
}

struct SceneUndoHistory {
  private var entries: [Data] = []
  private let capacity = 32

  var canUndo: Bool { !entries.isEmpty }

  mutating func record(_ bytes: Data) {
    guard entries.last != bytes else { return }
    entries.append(bytes)
    if entries.count > capacity { entries.removeFirst(entries.count - capacity) }
  }

  mutating func undo() -> Data? { entries.popLast() }
}
