import Foundation

private struct BridgeRoleTraceSummary {
  var eventCount: UInt64 = 0
  var firstSample: UInt64 = 0
  var lastSample: UInt64 = 0
  var receipt: UInt64 = 0
}

@_silgen_name("lw_role_preview_scene_json") private func lw_role_preview_scene_json(
  _ json: UnsafePointer<CChar>, _ startSample: UInt64, _ frames: UInt64,
  _ sampleRate: Double, _ summary: UnsafeMutablePointer<BridgeRoleTraceSummary>
) -> Int32

struct RoleTraceSummary: Equatable {
  let eventCount: UInt64
  let firstSample: UInt64
  let lastSample: UInt64
  let receipt: UInt64

  static let empty = RoleTraceSummary(eventCount: 0, firstSample: 0, lastSample: 0, receipt: 0)

  var receiptText: String { String(receipt, radix: 16, uppercase: false).leftPadding(toLength: 16, withPad: "0") }
}

private extension String {
  func leftPadding(toLength length: Int, withPad pad: Character) -> String {
    String(repeating: String(pad), count: max(0, length - count)) + self
  }
}

enum RoleTraceBridge {
  static func preview(sceneBytes: Data, startSample: UInt64 = 0,
                      frames: UInt64 = 48_000, sampleRate: Double = 48_000) throws -> RoleTraceSummary {
    guard let json = String(data: sceneBytes, encoding: .utf8) else {
      throw NSError(domain: "Latticewake", code: 20, userInfo: [NSLocalizedDescriptionKey: "Scene bytes are not UTF-8."])
    }
    var bridge = BridgeRoleTraceSummary()
    guard json.withCString({ lw_role_preview_scene_json($0, startSample, frames, sampleRate, &bridge) }) != 0 else {
      throw NSError(domain: "Latticewake", code: 21, userInfo: [NSLocalizedDescriptionKey: "Role preview could not be generated."])
    }
    return RoleTraceSummary(eventCount: bridge.eventCount, firstSample: bridge.firstSample,
                            lastSample: bridge.lastSample, receipt: bridge.receipt)
  }
}
