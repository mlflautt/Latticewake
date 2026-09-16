import Foundation
import SwiftUI

private struct BridgeModulationControls {
  var pitchEnabled: UInt32 = 1
  var pitchDepth: Float = 1
  var timbreEnabled: UInt32 = 1
  var timbreDepth: Float = 1
  var gainEnabled: UInt32 = 1
  var gainDepth: Float = 1
}

@_silgen_name("lw_scene_modulation_controls") private func lw_scene_modulation_controls(
  _ json: UnsafePointer<CChar>, _ controls: UnsafeMutablePointer<BridgeModulationControls>
) -> Int32
@_silgen_name("lw_scene_apply_modulation_controls") private func lw_scene_apply_modulation_controls(
  _ json: UnsafePointer<CChar>, _ controls: UnsafePointer<BridgeModulationControls>,
  _ canonicalJSON: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>
) -> Int32
@_silgen_name("lw_string_destroy") private func lw_modulation_string_destroy(_ value: UnsafeMutablePointer<CChar>)

struct ModulationControls: Equatable {
  var pitchEnabled = true; var pitchDepth = 1.0
  var timbreEnabled = true; var timbreDepth = 1.0
  var gainEnabled = true; var gainDepth = 1.0
}

enum ModulationBridge {
  static func controls(from bytes: Data) throws -> ModulationControls {
    guard let json = String(data: bytes, encoding: .utf8) else { throw error(60) }
    var bridge = BridgeModulationControls()
    guard json.withCString({ lw_scene_modulation_controls($0, &bridge) }) != 0 else { throw error(61) }
    return ModulationControls(pitchEnabled: bridge.pitchEnabled != 0, pitchDepth: Double(bridge.pitchDepth),
                              timbreEnabled: bridge.timbreEnabled != 0, timbreDepth: Double(bridge.timbreDepth),
                              gainEnabled: bridge.gainEnabled != 0, gainDepth: Double(bridge.gainDepth))
  }

  static func apply(_ controls: ModulationControls, to bytes: Data) throws -> Data {
    let v1 = try SceneDocumentBridge.canonicalV1(from: bytes)
    guard let json = String(data: v1, encoding: .utf8) else { throw error(62) }
    // Disabled routes are omitted from canonical Scene v1 and therefore own a
    // neutral zero depth rather than retaining hidden inactive state.
    var bridge = BridgeModulationControls(pitchEnabled: controls.pitchEnabled ? 1 : 0,
                                          pitchDepth: Float(controls.pitchEnabled ? controls.pitchDepth : 0),
                                          timbreEnabled: controls.timbreEnabled ? 1 : 0,
                                          timbreDepth: Float(controls.timbreEnabled ? controls.timbreDepth : 0),
                                          gainEnabled: controls.gainEnabled ? 1 : 0,
                                          gainDepth: Float(controls.gainEnabled ? controls.gainDepth : 0))
    var output: UnsafeMutablePointer<CChar>?
    let result = json.withCString { source in withUnsafePointer(to: &bridge) { lw_scene_apply_modulation_controls(source, $0, &output) } }
    guard result != 0, let output else { throw error(63) }
    defer { lw_modulation_string_destroy(output) }
    return Data(String(cString: output).utf8)
  }

  private static func error(_ code: Int) -> NSError {
    NSError(domain: "Latticewake", code: code,
            userInfo: [NSLocalizedDescriptionKey: "Modulation controls could not be prepared"])
  }
}

struct ModulationControlsView: View {
  @Binding var controls: ModulationControls
  let apply: () -> Void
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Modulation").font(.caption.bold()).foregroundStyle(.orange)
      route("Gesture X", "Pitch", $controls.pitchEnabled, $controls.pitchDepth)
      route("Gesture Y", "Timbre", $controls.timbreEnabled, $controls.timbreDepth)
      route("Pressure", "Gain", $controls.gainEnabled, $controls.gainDepth)
      Text("Three bounded per-note routes; zero disables a route's effect.").font(.caption2).foregroundStyle(.secondary)
      Button("Apply Modulation", action: apply).buttonStyle(.bordered)
    }
  }
  private func route(_ source: String, _ target: String, _ enabled: Binding<Bool>, _ depth: Binding<Double>) -> some View {
    HStack(spacing: 6) {
      Toggle("\(source) → \(target)", isOn: enabled).font(.caption).frame(width: 138, alignment: .leading)
      Slider(value: depth, in: -1...1).disabled(!enabled.wrappedValue)
      Text(String(format: "%+.2f", depth.wrappedValue)).font(.caption2.monospaced()).frame(width: 38, alignment: .trailing)
    }
  }
}
