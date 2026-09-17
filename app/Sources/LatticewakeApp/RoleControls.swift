import Foundation
import SwiftUI

private struct BridgeRoleControl {
  var enabled: UInt32 = 1
  var range: Float = 0.5
  var density: Float = 0.5
  var variation: Float = 0
  var seedOffset: UInt64 = 0
  var pattern: UInt32 = 0
}

@_silgen_name("lw_scene_role_control") private func lw_scene_role_control(
  _ json: UnsafePointer<CChar>, _ roleIndex: UInt32, _ control: UnsafeMutablePointer<BridgeRoleControl>
) -> Int32
@_silgen_name("lw_scene_apply_role_control") private func lw_scene_apply_role_control(
  _ json: UnsafePointer<CChar>, _ roleIndex: UInt32, _ control: UnsafePointer<BridgeRoleControl>,
  _ canonicalJSON: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>
) -> Int32
@_silgen_name("lw_string_destroy") private func lw_string_destroy(_ value: UnsafeMutablePointer<CChar>)

struct RoleControl: Identifiable, Equatable {
  let id: Int
  var enabled: Bool
  var range: Double
  var density: Double
  var variation: Double
  var seedOffset: UInt64
  var pattern: Int
  static let names = ["Drone", "Pad", "Motif A", "Motif B"]
  static let basePatterns = ["Held", "Rise", "Fall", "Pulse"]
  static func patterns(for role: Int) -> [String] {
    switch role {
    case 2: basePatterns + ["Euclid 3/8", "Euclid 5/8", "Euclid 7/8", "Offbeat"]
    case 3: basePatterns + ["Cellular", "Rotate 5", "Recursive", "Coprime"]
    default: basePatterns
    }
  }
}

struct RolePerformanceMask: Equatable {
  var muted: Set<Int> = []
  var soloed: Set<Int> = []

  var isActive: Bool { !muted.isEmpty || !soloed.isEmpty }

  mutating func toggleMute(_ role: Int) {
    if !muted.insert(role).inserted { muted.remove(role) }
  }

  mutating func toggleSolo(_ role: Int) {
    if !soloed.insert(role).inserted { soloed.remove(role) }
  }

  func applying(to controls: [RoleControl]) -> [RoleControl] {
    controls.map { control in
      var effective = control
      let passesSolo = soloed.isEmpty || soloed.contains(control.id)
      effective.enabled = control.enabled && passesSolo && !muted.contains(control.id)
      return effective
    }
  }
}

enum RoleSceneBridge {
  static func controls(from bytes: Data) throws -> [RoleControl] {
    guard let json = String(data: bytes, encoding: .utf8) else { throw NSError(domain: "Latticewake", code: 20) }
    return try (0..<4).map { index in
      var control = BridgeRoleControl()
      guard json.withCString({ lw_scene_role_control($0, UInt32(index), &control) }) != 0 else {
        throw NSError(domain: "Latticewake", code: 21)
      }
      return RoleControl(id: index, enabled: control.enabled != 0, range: Double(control.range),
                         density: Double(control.density), variation: Double(control.variation), seedOffset: control.seedOffset,
                         pattern: Int(control.pattern))
    }
  }

  static func apply(_ controls: [RoleControl], to bytes: Data) throws -> Data {
    var result = bytes
    for control in controls {
      guard let json = String(data: result, encoding: .utf8) else { throw NSError(domain: "Latticewake", code: 22) }
      var bridge = BridgeRoleControl(enabled: control.enabled ? 1 : 0, range: Float(control.range),
                                     density: Float(control.density), variation: Float(control.variation), seedOffset: control.seedOffset,
                                     pattern: UInt32(control.pattern))
      var output: UnsafeMutablePointer<CChar>?
      let success = json.withCString { source in
        withUnsafePointer(to: &bridge) { input in
          lw_scene_apply_role_control(source, UInt32(control.id), input, &output)
        }
      }
      guard success != 0, let output else { throw NSError(domain: "Latticewake", code: 23) }
      defer { lw_string_destroy(output) }
      result = Data(String(cString: output).utf8)
    }
    return result
  }
}

struct RoleControlsView: View {
  @Binding var controls: [RoleControl]
  let performanceMask: RolePerformanceMask
  let editStatus: String
  let changesPending: Bool
  let rolesRunning: Bool
  let toggleMute: (Int) -> Void
  let toggleSolo: (Int) -> Void
  let apply: () -> Void

  var body: some View {
    DisclosureGroup("Four Roles") {
      ForEach($controls) { $control in
        VStack(alignment: .leading, spacing: 5) {
          HStack {
            Toggle(RoleControl.names[control.id], isOn: $control.enabled)
            Button("M") { toggleMute(control.id) }
              .buttonStyle(.borderedProminent).tint(performanceMask.muted.contains(control.id) ? .orange : .gray)
              .help("Temporarily mute \(RoleControl.names[control.id]) without changing the scene")
              .disabled(changesPending)
            Button("S") { toggleSolo(control.id) }
              .buttonStyle(.borderedProminent).tint(performanceMask.soloed.contains(control.id) ? .mint : .gray)
              .help("Temporarily solo \(RoleControl.names[control.id]) without changing the scene")
              .disabled(changesPending)
            Spacer()
            Picker("Pattern", selection: $control.pattern) {
              let patterns = RoleControl.patterns(for: control.id)
              ForEach(patterns.indices, id: \.self) { Text(patterns[$0]).tag($0) }
            }.labelsHidden().frame(width: 140)
          }
          HStack {
            Text("Density").font(.caption)
            Slider(value: $control.density, in: 0...1)
            Text("Range").font(.caption)
            Slider(value: $control.range, in: 0...1)
            Text("Variation").font(.caption)
            Slider(value: $control.variation, in: 0...1)
            Stepper("Seed \(control.seedOffset)", value: $control.seedOffset, in: 0...9999)
              .font(.caption).frame(width: 112)
          }
        }.padding(.vertical, 3)
      }
      if performanceMask.isActive {
        Text("Performance mask active — scene enable states are unchanged.")
          .font(.caption2).foregroundStyle(.orange)
      }
      Text(editStatus).font(.caption2).foregroundStyle(changesPending ? .orange : .secondary)
      Button(rolesRunning ? "Queue at Loop Boundary" : "Apply Role Changes", action: apply)
        .buttonStyle(.borderedProminent).disabled(changesPending)
    }.frame(maxWidth: .infinity, alignment: .leading)
  }
}
