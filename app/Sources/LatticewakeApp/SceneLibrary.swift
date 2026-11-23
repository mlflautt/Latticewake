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
  case missingSurfaceAsset(String)

  var errorDescription: String? {
    switch self {
    case .invalidPerformance(let reason): return "Invalid performance settings: \(reason)"
    case .invalidEmbeddedScene: return "The library document contains an invalid Scene v1 document"
    case .missingSurfaceAsset(let hash): return "Scene references image terrain field \(hash), but its asset is not embedded."
    }
  }
}

struct SceneLibraryDocumentV1: Codable, Equatable {
  static let schema = "latticewake-library-v1"
  let schemaVersion: String
  var sceneJSON: String
  var performance: PerformanceSettingsV1
  var acceptedGrowReceipts: [GrowProposalReceiptV1]
  var acceptedAgentReceipts: [AgentProposalReceiptV1]
  var surfaceAssets: [String: ImageTerrainAsset]

  init(sceneJSON: String, performance: PerformanceSettingsV1 = .init(), acceptedGrowReceipts: [GrowProposalReceiptV1] = [], acceptedAgentReceipts: [AgentProposalReceiptV1] = [], surfaceAssets: [String: ImageTerrainAsset] = [:]) {
    self.schemaVersion = Self.schema
    self.sceneJSON = sceneJSON
    self.performance = performance
    self.acceptedGrowReceipts = acceptedGrowReceipts
    self.acceptedAgentReceipts = acceptedAgentReceipts
    self.surfaceAssets = surfaceAssets
  }

  enum CodingKeys: String, CodingKey { case schemaVersion, sceneJSON, performance, acceptedGrowReceipts, acceptedAgentReceipts, surfaceAssets }
  init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    schemaVersion = try values.decode(String.self, forKey: .schemaVersion)
    sceneJSON = try values.decode(String.self, forKey: .sceneJSON)
    performance = try values.decode(PerformanceSettingsV1.self, forKey: .performance)
    acceptedGrowReceipts = try values.decodeIfPresent([GrowProposalReceiptV1].self, forKey: .acceptedGrowReceipts) ?? []
    acceptedAgentReceipts = try values.decodeIfPresent([AgentProposalReceiptV1].self, forKey: .acceptedAgentReceipts) ?? []
    surfaceAssets = try values.decodeIfPresent([String: ImageTerrainAsset].self, forKey: .surfaceAssets) ?? [:]
  }
}

struct LoadedSceneDocument: Equatable {
  let sceneBytes: Data
  let performance: PerformanceSettingsV1
  let originalSceneV0: Bool
  let receipt: SceneReceipt
  let acceptedGrowReceipts: [GrowProposalReceiptV1]
  let acceptedAgentReceipts: [AgentProposalReceiptV1]
  let surfaceAssets: [String: ImageTerrainAsset]
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
                                 originalSceneV0: false, receipt: receipt, acceptedGrowReceipts: document.acceptedGrowReceipts, acceptedAgentReceipts: document.acceptedAgentReceipts,
                                 surfaceAssets: try validateAssets(document.surfaceAssets))
    }
    return LoadedSceneDocument(sceneBytes: bytes, performance: .init(), originalSceneV0: true, receipt: receipt, acceptedGrowReceipts: [], acceptedAgentReceipts: [], surfaceAssets: [:])
  }

  @discardableResult static func save(_ document: SceneLibraryDocumentV1, to url: URL) throws -> SceneReceipt {
    try document.performance.validate()
    let canonicalScene = try canonicalSceneV1(document.sceneJSON)
    let verifiedAssets = try validateAssets(document.surfaceAssets)
    for hash in try referencedImageHashes(in: canonicalScene) where verifiedAssets[hash] == nil {
      throw SceneLibraryError.missingSurfaceAsset(hash)
    }
    let preparedDocument = SceneLibraryDocumentV1(
      sceneJSON: String(decoding: canonicalScene, as: UTF8.self),
      performance: document.performance,
      acceptedGrowReceipts: document.acceptedGrowReceipts,
      acceptedAgentReceipts: document.acceptedAgentReceipts,
      surfaceAssets: verifiedAssets
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

  private static func validateAssets(_ assets: [String: ImageTerrainAsset]) throws -> [String: ImageTerrainAsset] {
    for (hash, asset) in assets {
      guard hash == asset.id, (try? asset.samples()) != nil else {
        throw SceneLibraryError.invalidEmbeddedScene
      }
    }
    return assets
  }

  private static func referencedImageHashes(in sceneBytes: Data) throws -> [String] {
    guard let root = try JSONSerialization.jsonObject(with: sceneBytes) as? [String: Any],
          let surface = root["surface"] as? [String: Any],
          let layers = surface["layers"] as? [[String: Any]] else { return [] }
    return try layers.compactMap { layer in
      guard layer["sourceType"] as? String == "image" else { return nil }
      guard let hash = layer["assetHash"] as? String, !hash.isEmpty else {
        throw SceneLibraryError.invalidEmbeddedScene
      }
      return hash
    }
  }
}

struct SceneUndoEntry {
  let sceneBytes: Data
  let acceptedGrowReceipts: [GrowProposalReceiptV1]
  let acceptedAgentReceipts: [AgentProposalReceiptV1]
  let surfaceAssets: [String: ImageTerrainAsset]
}

struct SceneUndoHistory {
  private var entries: [SceneUndoEntry] = []
  private let capacity = 32

  var canUndo: Bool { !entries.isEmpty }

  mutating func record(_ bytes: Data, acceptedGrowReceipts: [GrowProposalReceiptV1], acceptedAgentReceipts: [AgentProposalReceiptV1], surfaceAssets: [String: ImageTerrainAsset] = [:]) {
    guard entries.last?.sceneBytes != bytes || entries.last?.acceptedGrowReceipts != acceptedGrowReceipts || entries.last?.acceptedAgentReceipts != acceptedAgentReceipts || entries.last?.surfaceAssets != surfaceAssets else { return }
    entries.append(SceneUndoEntry(sceneBytes: bytes, acceptedGrowReceipts: acceptedGrowReceipts,
                                  acceptedAgentReceipts: acceptedAgentReceipts, surfaceAssets: surfaceAssets))
    if entries.count > capacity { entries.removeFirst(entries.count - capacity) }
  }

  mutating func undo() -> SceneUndoEntry? { entries.popLast() }
}
