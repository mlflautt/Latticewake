import Foundation
import SwiftUI

private struct BridgeSceneEditorControls {
  var terrainDetail: Double = 0.5
  var terrainZoom: Double = 0.5
  var terrainOffsetX: Double = 0.5
  var terrainOffsetY: Double = 0.5
  var traversalRateRatio: Double = 0.5
  var traversalRadiusX: Double = 0.5
  var traversalRadiusY: Double = 0.5
  var traversalAngle: Double = 0
  var traversalTranslationX: Double = 0.5
  var traversalTranslationY: Double = 0.5
  var attackSeconds: Double = 0.010
  var releaseSeconds: Double = 0.120
  var gain: Double = 1
  var glideSemitones: Double = 12
  var velocityResponse: Double = 1
  var pressureResponse: Double = 1
  var slideResponse: Double = 1
}

@_silgen_name("lw_scene_editor_controls") private func lw_scene_editor_controls(
  _ json: UnsafePointer<CChar>, _ controls: UnsafeMutablePointer<BridgeSceneEditorControls>
) -> Int32
@_silgen_name("lw_scene_apply_editor_controls") private func lw_scene_apply_editor_controls(
  _ json: UnsafePointer<CChar>, _ controls: UnsafePointer<BridgeSceneEditorControls>,
  _ canonicalJSON: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>
) -> Int32
@_silgen_name("lw_string_destroy") private func lw_editor_string_destroy(_ value: UnsafeMutablePointer<CChar>)

struct SceneEditorControls: Equatable {
  var terrainDetail: Double = 0.5
  var terrainZoom: Double = 0.5
  var terrainOffsetX: Double = 0.5
  var terrainOffsetY: Double = 0.5
  var traversalRateRatio: Double = 0.5
  var traversalRadiusX: Double = 0.5
  var traversalRadiusY: Double = 0.5
  var traversalAngle: Double = 0
  var traversalTranslationX: Double = 0.5
  var traversalTranslationY: Double = 0.5
  var attackSeconds: Double = 0.010
  var releaseSeconds: Double = 0.120
  var gain: Double = 1
  var glideSemitones: Double = 12
  var velocityResponse: Double = 1
  var pressureResponse: Double = 1
  var slideResponse: Double = 1
}

enum SceneEditorPreset: String, CaseIterable, Identifiable {
  case luminousBasin = "Luminous Basin"
  case orbitingRidge = "Orbiting Ridge"
  case softArrival = "Soft Arrival"
  case responsiveEdge = "Responsive Edge"

  var id: String { rawValue }

  func applying(to current: SceneEditorControls) -> SceneEditorControls {
    var result = current
    switch self {
    case .luminousBasin:
      result.terrainDetail = 0.68; result.terrainZoom = 0.16
      result.terrainOffsetX = 0.59; result.terrainOffsetY = 0.43
    case .orbitingRidge:
      result.traversalRateRatio = 0.82; result.traversalRadiusX = 0.76
      result.traversalRadiusY = 0.24; result.traversalAngle = 0.18
      result.traversalTranslationX = 0.63; result.traversalTranslationY = 0.46
    case .softArrival:
      result.attackSeconds = 0.18; result.releaseSeconds = 0.72
      result.gain = 0.72; result.velocityResponse = 0.55
    case .responsiveEdge:
      result.attackSeconds = 0.008; result.releaseSeconds = 0.16
      result.glideSemitones = 17; result.pressureResponse = 1.35; result.slideResponse = 0.9
    }
    return result
  }
}

enum SceneEditorBridge {
  static func controls(from bytes: Data) throws -> SceneEditorControls {
    guard let json = String(data: bytes, encoding: .utf8) else { throw editorError(50) }
    var bridge = BridgeSceneEditorControls()
    guard json.withCString({ lw_scene_editor_controls($0, &bridge) }) != 0 else { throw editorError(51) }
    return SceneEditorControls(terrainDetail: bridge.terrainDetail, terrainZoom: bridge.terrainZoom,
                               terrainOffsetX: bridge.terrainOffsetX, terrainOffsetY: bridge.terrainOffsetY,
                               traversalRateRatio: bridge.traversalRateRatio, traversalRadiusX: bridge.traversalRadiusX,
                               traversalRadiusY: bridge.traversalRadiusY, traversalAngle: bridge.traversalAngle,
                               traversalTranslationX: bridge.traversalTranslationX, traversalTranslationY: bridge.traversalTranslationY,
                               attackSeconds: bridge.attackSeconds, releaseSeconds: bridge.releaseSeconds, gain: bridge.gain,
                               glideSemitones: bridge.glideSemitones, velocityResponse: bridge.velocityResponse,
                               pressureResponse: bridge.pressureResponse, slideResponse: bridge.slideResponse)
  }

  static func apply(_ controls: SceneEditorControls, to bytes: Data) throws -> Data {
    // Editing is explicit migration: merely loading a Scene v0 remains lossless.
    let v1 = try SceneDocumentBridge.canonicalV1(from: bytes)
    guard let json = String(data: v1, encoding: .utf8) else { throw editorError(52) }
    var bridge = BridgeSceneEditorControls(terrainDetail: controls.terrainDetail, terrainZoom: controls.terrainZoom,
                                           terrainOffsetX: controls.terrainOffsetX, terrainOffsetY: controls.terrainOffsetY,
                                           traversalRateRatio: controls.traversalRateRatio, traversalRadiusX: controls.traversalRadiusX,
                                           traversalRadiusY: controls.traversalRadiusY, traversalAngle: controls.traversalAngle,
                                           traversalTranslationX: controls.traversalTranslationX, traversalTranslationY: controls.traversalTranslationY,
                                           attackSeconds: controls.attackSeconds, releaseSeconds: controls.releaseSeconds,
                                           gain: controls.gain, glideSemitones: controls.glideSemitones,
                                           velocityResponse: controls.velocityResponse, pressureResponse: controls.pressureResponse,
                                           slideResponse: controls.slideResponse)
    var output: UnsafeMutablePointer<CChar>?
    let success = json.withCString { source in
      withUnsafePointer(to: &bridge) { input in
        lw_scene_apply_editor_controls(source, input, &output)
      }
    }
    guard success != 0, let output else { throw editorError(53) }
    defer { lw_editor_string_destroy(output) }
    return Data(String(cString: output).utf8)
  }

  private static func editorError(_ code: Int) -> NSError {
    NSError(domain: "Latticewake", code: code,
            userInfo: [NSLocalizedDescriptionKey: "Scene editor controls could not be prepared"])
  }
}

struct SceneEditorView: View {
  @Binding var controls: SceneEditorControls
  let apply: () -> Void
  let preview: () -> Void
  let captureA: () -> Void
  let previewA: () -> Void
  let returnToCurrent: () -> Void
  let hasA: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      editorSection("Surface", color: .cyan) {
        slider("Detail", $controls.terrainDetail, 0...1)
        slider("Zoom", $controls.terrainZoom, 0...1)
        slider("Offset X", $controls.terrainOffsetX, 0...1)
        slider("Offset Y", $controls.terrainOffsetY, 0...1)
      }
      editorSection("Traversal", color: .mint) {
        slider("Rate", $controls.traversalRateRatio, 0...1)
        slider("Radius X", $controls.traversalRadiusX, 0...1)
        slider("Radius Y", $controls.traversalRadiusY, 0...1)
        slider("Angle", $controls.traversalAngle, 0...1)
        slider("Position X", $controls.traversalTranslationX, 0...1)
        slider("Position Y", $controls.traversalTranslationY, 0...1)
      }
      editorSection("Articulation", color: .purple) {
        slider("Attack", $controls.attackSeconds, 0.001...1, format: "%.3fs")
        slider("Release", $controls.releaseSeconds, 0.001...2, format: "%.3fs")
        slider("Gain", $controls.gain, 0...1.5)
        slider("Glide", $controls.glideSemitones, 0...24, format: "%.1f st")
        slider("Velocity", $controls.velocityResponse, 0...1)
        slider("Pressure", $controls.pressureResponse, 0...2)
        slider("Slide", $controls.slideResponse, 0...1)
      }
      Menu("Component Presets") {
        ForEach(SceneEditorPreset.allCases) { preset in
          Button(preset.rawValue) { controls = preset.applying(to: controls) }
        }
      }
      HStack {
        Button("Preview Candidate", action: preview)
        Button("Set A", action: captureA)
        Button("Preview A", action: previewA).disabled(!hasA)
        Button("Return", action: returnToCurrent)
      }.buttonStyle(.bordered)
      Text("Changes are prepared outside audio and applied together.")
        .font(.caption2).foregroundStyle(.secondary)
      Button("Apply Scene Changes", action: apply).buttonStyle(.borderedProminent)
    }
  }

  private func editorSection<Content: View>(_ title: String, color: Color,
                                             @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title).font(.caption.bold()).foregroundStyle(color)
      content()
    }
  }

  private func slider(_ title: String, _ value: Binding<Double>, _ range: ClosedRange<Double>, format: String = "%.2f") -> some View {
    HStack(spacing: 6) {
      Text(title).font(.caption).frame(width: 72, alignment: .leading)
      Slider(value: value, in: range)
      Text(String(format: format, value.wrappedValue)).font(.caption2.monospaced()).frame(width: 48, alignment: .trailing)
    }
  }
}
