import AppKit
import Foundation

enum TerrainSourceKind: String, Equatable {
  case analytic
  case image
  case audio

  var label: String {
    switch self {
    case .analytic: "Analytic"
    case .image: "Image"
    case .audio: "Audio"
    }
  }
}

struct TerrainSurfaceLayerPresentation: Equatable, Identifiable {
  let id: String
  let kind: TerrainSourceKind
  let assetID: String?
  let assetHash: String?
  let mediaType: String?

  var displayName: String {
    guard let assetID, !assetID.isEmpty else {
      return kind == .analytic ? "Procedural fractal" : "Unresolved \(kind.label.lowercased()) asset"
    }
    return assetID
  }
}

struct TerrainSurfacePresentation: Equatable {
  let layers: [TerrainSurfaceLayerPresentation]
  let morph: Double

  static let analyticDefault = TerrainSurfacePresentation(
    layers: [
      TerrainSurfaceLayerPresentation(id: "surface-a", kind: .analytic, assetID: nil,
                                      assetHash: nil, mediaType: nil),
      TerrainSurfaceLayerPresentation(id: "surface-b", kind: .analytic, assetID: nil,
                                      assetHash: nil, mediaType: nil)
    ],
    morph: 0
  )

  var primaryLayer: TerrainSurfaceLayerPresentation { layers.first ?? Self.analyticDefault.layers[0] }
  var visualLayer: TerrainSurfaceLayerPresentation { layers[morph < 0.5 ? 0 : 1] }
  var layerWeights: [Double] { [1 - morph, morph] }

  var sourceSummary: String {
    let a = layers.first?.kind.label ?? "Unknown"
    let b = layers.dropFirst().first?.kind.label ?? "Unknown"
    return "\(a) A ↔ \(b) B • \(Int((morph * 100).rounded()))%"
  }

  static func decode(sceneBytes: Data) throws -> TerrainSurfacePresentation {
    let canonical = try SceneDocumentBridge.canonicalV1(from: sceneBytes)
    guard let root = try JSONSerialization.jsonObject(with: canonical) as? [String: Any],
          let surface = root["surface"] as? [String: Any],
          let rawLayers = surface["layers"] as? [[String: Any]], rawLayers.count == 2,
          let morph = surface["morph"] as? Double else {
      throw NSError(domain: "Latticewake", code: 70,
                    userInfo: [NSLocalizedDescriptionKey: "Surface presentation could not be decoded"])
    }
    let layers = try rawLayers.map { raw -> TerrainSurfaceLayerPresentation in
      guard let id = raw["componentID"] as? String,
            let source = raw["sourceType"] as? String,
            let kind = TerrainSourceKind(rawValue: source) else {
        throw NSError(domain: "Latticewake", code: 71,
                      userInfo: [NSLocalizedDescriptionKey: "Surface layer presentation is invalid"])
      }
      return TerrainSurfaceLayerPresentation(
        id: id,
        kind: kind,
        assetID: raw["assetID"] as? String,
        assetHash: raw["assetHash"] as? String,
        mediaType: raw["mediaType"] as? String
      )
    }
    return TerrainSurfacePresentation(layers: layers, morph: max(0, min(1, morph)))
  }
}

/// UI-only layer media. Both registered Surface layers are retained so the
/// source plane follows the same continuous morph as the prepared audio tables.
struct TerrainSurfaceLayerMedia: Identifiable, Equatable {
  let id: String
  let kind: TerrainSourceKind
  let weight: Double
  let image: NSImage?
  let interpretation: NSImage?
  let contours: [TerrainContourSegment]

  static func == (lhs: TerrainSurfaceLayerMedia, rhs: TerrainSurfaceLayerMedia) -> Bool {
    lhs.id == rhs.id && lhs.kind == rhs.kind && lhs.weight == rhs.weight &&
      lhs.image === rhs.image && lhs.interpretation === rhs.interpretation && lhs.contours == rhs.contours
  }
}

/// Asset visualization and diagnostics are resolved off the audio callback.
struct TerrainSurfaceMedia: Equatable {
  let layers: [TerrainSurfaceLayerMedia]
}
