import Foundation
import CryptoKit
import LatticewakeBridge

enum SceneDocumentBridge {
  static func canonicalV1(from bytes: Data) throws -> Data {
    guard let source = String(data: bytes, encoding: .utf8) else {
      throw NSError(domain: "Latticewake", code: 40,
                    userInfo: [NSLocalizedDescriptionKey: "Scene is not UTF-8 text"])
    }
    let sourceHash = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
    var output: UnsafeMutablePointer<CChar>?
    let migrated = source.withCString { sourcePointer in
      sourceHash.withCString { hashPointer in
        lw_scene_migrate_v1_json(sourcePointer, hashPointer, &output)
      }
    }
    guard migrated == 1, let output else {
      throw NSError(domain: "Latticewake", code: 41,
                    userInfo: [NSLocalizedDescriptionKey: "Scene could not migrate to Scene v1"])
    }
    defer { lw_string_destroy(output) }
    return Data(String(cString: output).utf8)
  }
}

enum SurfaceSceneBridge {
  static func replacingLayer(_ index: Int, with asset: ImageTerrainAsset, in sceneBytes: Data) throws -> Data {
    guard (0..<2).contains(index) else { throw ImageTerrainAssetError.invalidField }
    let canonical = try SceneDocumentBridge.canonicalV1(from: sceneBytes)
    guard var root = try JSONSerialization.jsonObject(with: canonical) as? [String: Any],
          var surface = root["surface"] as? [String: Any],
          var layers = surface["layers"] as? [[String: Any]], layers.count == 2 else {
      throw NSError(domain: "Latticewake", code: 72,
                    userInfo: [NSLocalizedDescriptionKey: "Scene Surface could not be updated"])
    }
    var layer = layers[index]
    layer["sourceType"] = "image"
    layer["assetID"] = asset.sourceName
    layer["assetHash"] = asset.contentHash
    layer["mediaType"] = "application/vnd.latticewake.surface-field-v1"
    layer.removeValue(forKey: "analytic")
    layers[index] = layer
    surface["layers"] = layers
    root["surface"] = surface
    let updated = try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys, .withoutEscapingSlashes])
    return try SceneDocumentBridge.canonicalV1(from: updated)
  }
}
