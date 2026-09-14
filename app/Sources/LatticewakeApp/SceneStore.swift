import CryptoKit
import Foundation

struct SceneReceipt: Codable, Equatable { let sha256: String; let byteCount: Int }
enum SceneStore {
  static func saveCanonical(_ bytes: Data, to url: URL) throws -> SceneReceipt {
    try bytes.write(to: url, options: .atomic)
    return SceneReceipt(sha256: SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined(), byteCount: bytes.count)
  }
  static func loadCanonical(from url: URL) throws -> (Data, SceneReceipt) {
    let bytes = try Data(contentsOf: url)
    return (bytes, SceneReceipt(sha256: SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined(), byteCount: bytes.count))
  }
}
