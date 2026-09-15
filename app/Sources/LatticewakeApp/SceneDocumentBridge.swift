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
