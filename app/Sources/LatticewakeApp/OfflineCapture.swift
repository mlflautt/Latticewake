import Foundation
import LatticewakeBridge

@_silgen_name("lw_kernel_create") private func capture_kernel_create() -> OpaquePointer?
@_silgen_name("lw_kernel_destroy") private func capture_kernel_destroy(_ kernel: OpaquePointer)
@_silgen_name("lw_kernel_prepare_scene_json") private func capture_kernel_prepare_scene_json(_ kernel: OpaquePointer, _ json: UnsafePointer<CChar>, _ rate: Double) -> Int32
@_silgen_name("lw_kernel_set_roles_running") private func capture_kernel_set_roles_running(_ kernel: OpaquePointer, _ running: UInt32)
@_silgen_name("lw_kernel_render") private func capture_kernel_render(_ kernel: OpaquePointer, _ output: UnsafeMutablePointer<Float>, _ frames: UInt32) -> Int32

struct CaptureReceiptV1: Codable, Equatable {
  let schemaVersion: String
  let sceneSHA256: String
  let sceneByteCount: Int
  let sampleRate: Int
  let frameCount: Int
  let roleTransport: Bool
  let wavFilename: String
}

enum OfflineCapture {
  static let sampleRate = 48_000
  static let frameCount = sampleRate * 8
  private static let blockFrames = 256

  static func render(sceneBytes: Data, to directory: URL) throws -> (URL, CaptureReceiptV1) {
    guard let text = String(data: sceneBytes, encoding: .utf8), let kernel = capture_kernel_create() else {
      throw NSError(domain: "Latticewake", code: 40, userInfo: [NSLocalizedDescriptionKey: "Could not create offline renderer"])
    }
    defer { capture_kernel_destroy(kernel) }
    let prepared = text.withCString { capture_kernel_prepare_scene_json(kernel, $0, Double(sampleRate)) }
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
                                   frameCount: samples.count, roleTransport: true, wavFilename: wavURL.lastPathComponent)
    let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    try encoder.encode(receipt).write(to: wavURL.appendingPathExtension("receipt.json"), options: .atomic)
    return (wavURL, receipt)
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
