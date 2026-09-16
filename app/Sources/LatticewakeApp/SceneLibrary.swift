import CryptoKit
import Foundation

struct PerformanceSettingsV1: Codable, Equatable {
  var gestureGlideSemitones: Double = 12
  var pointerNote: Int = 48
  var roleTransportEnabled: Bool = false

  func validate() throws {
    guard gestureGlideSemitones.isFinite, (0...24).contains(gestureGlideSemitones) else {
      throw SceneLibraryError.invalidPerformance("gesture glide must be finite and between 0 and 24 semitones")
    }
    guard (0...127).contains(pointerNote) else {
      throw SceneLibraryError.invalidPerformance("pointer note must be a MIDI note between 0 and 127")
    }
  }
}

enum SceneLibraryError: LocalizedError, Equatable {
  case invalidPerformance(String)
  case invalidEmbeddedScene

  var errorDescription: String? {
    switch self {
    case .invalidPerformance(let reason): return "Invalid performance settings: \(reason)"
    case .invalidEmbeddedScene: return "The library document contains an invalid Scene v1 document"
    }
  }
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
    let declaredSchema = (try? JSONSerialization.jsonObject(with: bytes))
      .flatMap { $0 as? [String: Any] }?["schemaVersion"] as? String
    if declaredSchema == SceneLibraryDocumentV1.schema {
      let document = try JSONDecoder().decode(SceneLibraryDocumentV1.self, from: bytes)
      try document.performance.validate()
      let canonicalScene = try canonicalSceneV1(document.sceneJSON)
      return LoadedSceneDocument(sceneBytes: canonicalScene, performance: document.performance,
                                 originalSceneV0: false, receipt: receipt)
    }
    return LoadedSceneDocument(sceneBytes: bytes, performance: .init(), originalSceneV0: true, receipt: receipt)
  }

  @discardableResult static func save(_ document: SceneLibraryDocumentV1, to url: URL) throws -> SceneReceipt {
    try document.performance.validate()
    let canonicalScene = try canonicalSceneV1(document.sceneJSON)
    let preparedDocument = SceneLibraryDocumentV1(
      sceneJSON: String(decoding: canonicalScene, as: UTF8.self),
      performance: document.performance
    )
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    let bytes = try encoder.encode(preparedDocument)
    return try SceneStore.saveCanonical(bytes, to: url)
  }

  private static func canonicalSceneV1(_ sceneJSON: String) throws -> Data {
    do {
      return try SceneDocumentBridge.canonicalV1(from: Data(sceneJSON.utf8))
    } catch {
      throw SceneLibraryError.invalidEmbeddedScene
    }
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
