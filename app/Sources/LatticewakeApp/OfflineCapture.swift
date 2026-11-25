import Foundation
import LatticewakeBridge

@_silgen_name("lw_kernel_create") private func capture_kernel_create() -> OpaquePointer?
@_silgen_name("lw_kernel_destroy") private func capture_kernel_destroy(_ kernel: OpaquePointer)
@_silgen_name("lw_kernel_prepare_scene_json") private func capture_kernel_prepare_scene_json(_ kernel: OpaquePointer, _ json: UnsafePointer<CChar>, _ rate: Double) -> Int32
@_silgen_name("lw_kernel_set_roles_running") private func capture_kernel_set_roles_running(_ kernel: OpaquePointer, _ running: UInt32)
@_silgen_name("lw_kernel_render") private func capture_kernel_render(_ kernel: OpaquePointer, _ output: UnsafeMutablePointer<Float>, _ frames: UInt32) -> Int32
@_silgen_name("lw_kernel_note_on_source") private func capture_kernel_note_on(_ kernel: OpaquePointer, _ note: Int32, _ velocity: Float, _ source: UInt32) -> Int32
@_silgen_name("lw_kernel_note_off_source") private func capture_kernel_note_off(_ kernel: OpaquePointer, _ note: Int32, _ source: UInt32) -> Int32
@_silgen_name("lw_kernel_note_expression_source") private func capture_kernel_expression(_ kernel: OpaquePointer, _ note: Int32, _ glide: Float, _ press: Float, _ slide: Float, _ source: UInt32) -> Int32

struct CaptureReceiptV1: Codable, Equatable {
  let schemaVersion: String
  let sceneSHA256: String
  let sceneByteCount: Int
  let sampleRate: Int
  let frameCount: Int
  let roleTransport: Bool
  let wavFilename: String
  let surfaceFieldHashes: [String]?
}

struct SignatureDemonstrationReceiptV1: Codable, Equatable {
  let schemaVersion: String
  let sceneSHA256: String
  let fixture: String
  let sampleRate: Int
  let frameCount: Int
  let wavFilename: String
}

enum OfflineCapture {
  static let sampleRate = 48_000
  static let frameCount = sampleRate * 8
  private static let blockFrames = 256

  static func render(sceneBytes: Data, assets: [String: ImageTerrainAsset] = [:], to directory: URL) throws -> (URL, CaptureReceiptV1) {
    guard let text = String(data: sceneBytes, encoding: .utf8), let kernel = capture_kernel_create() else {
      throw NSError(domain: "Latticewake", code: 40, userInfo: [NSLocalizedDescriptionKey: "Could not create offline renderer"])
    }
    defer { capture_kernel_destroy(kernel) }
    let prepared = try prepare(text, assets: assets, kernel: kernel)
    guard prepared != 0 else { throw NSError(domain: "Latticewake", code: 41, userInfo: [NSLocalizedDescriptionKey: "Scene could not be prepared for capture"] ) }
    capture_kernel_set_roles_running(kernel, 1)
    var samples = [Float](repeating: 0, count: frameCount)
    var offset = 0
    while offset < samples.count {
      let count = min(blockFrames, samples.count - offset)
      let rendered = samples.withUnsafeMutableBufferPointer { buffer in
        capture_kernel_render(kernel, buffer.baseAddress!.advanced(by: offset), UInt32(count))
      }
      guard rendered != 0 else { throw NSError(domain: "Latticewake", code: 42, userInfo: [NSLocalizedDescriptionKey: "Offline render rejected a block"] ) }
      offset += count
    }
    let sceneHash = SceneLibrary.receipt(for: sceneBytes).sha256
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let wavURL = directory.appendingPathComponent("latticewake-\(sceneHash.prefix(12))-48000-8s.wav")
    try wavData(samples).write(to: wavURL, options: .atomic)
    let receipt = CaptureReceiptV1(schemaVersion: "latticewake-capture-v1", sceneSHA256: sceneHash,
                                   sceneByteCount: sceneBytes.count, sampleRate: sampleRate,
                                   frameCount: samples.count, roleTransport: true, wavFilename: wavURL.lastPathComponent,
                                   surfaceFieldHashes: try referencedHashes(text))
    let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    try encoder.encode(receipt).write(to: wavURL.appendingPathExtension("receipt.json"), options: .atomic)
    return (wavURL, receipt)
  }

  static func renderSignatureDemonstrations(sceneBytes: Data, assets: [String: ImageTerrainAsset] = [:], to directory: URL) throws
    -> [(URL, SignatureDemonstrationReceiptV1)] {
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return try ["midi-notes", "terrain-gesture"].map { fixture in
      guard let text = String(data: sceneBytes, encoding: .utf8), let kernel = capture_kernel_create() else {
        throw NSError(domain: "Latticewake", code: 43, userInfo: [NSLocalizedDescriptionKey: "Could not create demonstration renderer"])
      }
      defer { capture_kernel_destroy(kernel) }
      guard try prepare(text, assets: assets, kernel: kernel) != 0 else {
        throw NSError(domain: "Latticewake", code: 44, userInfo: [NSLocalizedDescriptionKey: "Demonstration scene could not be prepared"])
      }
      let frames = sampleRate * 4
      var samples = [Float](repeating: 0, count: frames)
      let source: UInt32 = fixture == "midi-notes" ? 30 : 2
      let note: Int32 = fixture == "midi-notes" ? 60 : 48
      guard capture_kernel_note_on(kernel, note, 0.72, source) != 0 else {
        throw NSError(domain: "Latticewake", code: 45, userInfo: [NSLocalizedDescriptionKey: "Demonstration note was rejected"])
      }
      var offset = 0
      var midiStage = 0
      var gestureReleased = false
      while offset < frames {
        if fixture == "midi-notes" && midiStage == 0 && offset >= sampleRate {
          _ = capture_kernel_note_off(kernel, note, source)
          _ = capture_kernel_note_on(kernel, 64, 0.68, source)
          midiStage = 1
        } else if fixture == "midi-notes" && midiStage == 1 && offset >= sampleRate * 2 {
          _ = capture_kernel_note_off(kernel, 64, source)
          _ = capture_kernel_note_on(kernel, 67, 0.66, source)
          midiStage = 2
        } else if fixture == "midi-notes" && midiStage == 2 && offset >= sampleRate * 3 {
          _ = capture_kernel_note_off(kernel, 67, source)
          midiStage = 3
        } else if fixture == "terrain-gesture" {
          let progress = Float(offset) / Float(frames)
          _ = capture_kernel_expression(kernel, note, sin(progress * .pi * 2) * 0.72,
                                        0.55 + 0.35 * sin(progress * .pi), progress, source)
          if offset >= sampleRate * 3 && !gestureReleased {
            _ = capture_kernel_note_off(kernel, note, source); gestureReleased = true
          }
        }
        let count = min(blockFrames, frames - offset)
        let rendered = samples.withUnsafeMutableBufferPointer { buffer in
          capture_kernel_render(kernel, buffer.baseAddress!.advanced(by: offset), UInt32(count))
        }
        guard rendered != 0 else {
          throw NSError(domain: "Latticewake", code: 46, userInfo: [NSLocalizedDescriptionKey: "Demonstration render rejected a block"])
        }
        offset += count
      }
      let sceneHash = SceneLibrary.receipt(for: sceneBytes).sha256
      let url = directory.appendingPathComponent("latticewake-\(sceneHash.prefix(12))-\(fixture).wav")
      try wavData(samples).write(to: url, options: .atomic)
      let receipt = SignatureDemonstrationReceiptV1(schemaVersion: "latticewake-signature-demo-v1",
                                                     sceneSHA256: sceneHash, fixture: fixture,
                                                     sampleRate: sampleRate, frameCount: frames,
                                                     wavFilename: url.lastPathComponent)
      let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
      try encoder.encode(receipt).write(to: url.appendingPathExtension("receipt.json"), options: .atomic)
      return (url, receipt)
    }
  }

  private static func referencedHashes(_ json: String) throws -> [String] {
    guard let root = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any] else {
      throw NSError(domain: "Latticewake", code: 47, userInfo: [NSLocalizedDescriptionKey: "Invalid scene document"])
    }
    guard let surface = root["surface"] as? [String: Any],
          let layers = surface["layers"] as? [[String: Any]], layers.count == 2 else { return [] }
    return try layers.compactMap { layer in
      guard layer["sourceType"] as? String == "image" else { return nil }
      guard let hash = layer["assetHash"] as? String, !hash.isEmpty else {
        throw NSError(domain: "Latticewake", code: 48, userInfo: [NSLocalizedDescriptionKey: "Image Surface has no field hash"])
      }
      return hash
    }
  }

  private static func prepare(_ json: String, assets: [String: ImageTerrainAsset], kernel: OpaquePointer) throws -> Int32 {
    let root = try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any]
    let surface = root?["surface"] as? [String: Any]
    guard let layers = surface?["layers"] as? [[String: Any]], layers.count == 2 else {
      return json.withCString { capture_kernel_prepare_scene_json(kernel, $0, Double(sampleRate)) }
    }
    let hashes: [String?] = try layers.map { layer in
      guard layer["sourceType"] as? String == "image" else { return nil }
      guard let hash = layer["assetHash"] as? String, let asset = assets[hash], asset.id == hash else {
        throw NSError(domain: "Latticewake", code: 49, userInfo: [NSLocalizedDescriptionKey: "Capture requires the scene's embedded image field"])
      }
      return hash
    }
    let samples = try hashes.map { hash -> [UInt16] in
      guard let hash, let asset = assets[hash] else { return [] }
      return try asset.samples()
    }
    return samples[0].withUnsafeBufferPointer { a in
      samples[1].withUnsafeBufferPointer { b in
        (hashes[0] ?? "").withCString { ah in
          (hashes[1] ?? "").withCString { bh in
            let fields = [
              LWSurfaceField(samples: a.baseAddress, width: UInt32(hashes[0].flatMap { assets[$0]?.width } ?? 0),
                             height: UInt32(hashes[0].flatMap { assets[$0]?.height } ?? 0), content_hash: ah),
              LWSurfaceField(samples: b.baseAddress, width: UInt32(hashes[1].flatMap { assets[$0]?.width } ?? 0),
                             height: UInt32(hashes[1].flatMap { assets[$0]?.height } ?? 0), content_hash: bh)
            ]
            return fields.withUnsafeBufferPointer { pointer in
              json.withCString { lw_kernel_prepare_scene_json_with_fields(kernel, $0, Double(sampleRate), pointer.baseAddress!) }
            }
          }
        }
      }
    }
  }

  private static func wavData(_ samples: [Float]) -> Data {
    var data = Data()
    func append16(_ value: UInt16) { data.append(UInt8(value & 0xff)); data.append(UInt8(value >> 8)) }
    func append32(_ value: UInt32) { append16(UInt16(value & 0xffff)); append16(UInt16(value >> 16)) }
    data.append(contentsOf: "RIFF".utf8); append32(UInt32(36 + samples.count * 2)); data.append(contentsOf: "WAVEfmt ".utf8)
    append32(16); append16(1); append16(1); append32(UInt32(sampleRate)); append32(UInt32(sampleRate * 2)); append16(2); append16(16)
    data.append(contentsOf: "data".utf8); append32(UInt32(samples.count * 2))
    for sample in samples { append16(UInt16(bitPattern: Int16((min(1, max(-1, sample)) * 32767).rounded()))) }
    return data
  }
}
