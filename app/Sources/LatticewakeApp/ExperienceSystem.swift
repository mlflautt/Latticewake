import SwiftUI

enum StageWorkspace: String, CaseIterable, Identifiable {
  case perform = "Perform"
  case sculpt = "Sculpt"
  case grow = "Grow"
  var id: String { rawValue }
}

enum StageInspectorPage: String, CaseIterable, Identifiable {
  case sculpt = "Scene"
  case modulation = "Motion"
  case lanes = "Lanes"
  var id: String { rawValue }
}

enum LatticewakeDesign {
  static let background = Color(red: 0.025, green: 0.038, blue: 0.061)
  static let panel = Color(red: 0.045, green: 0.067, blue: 0.098)
  static let raised = Color(red: 0.063, green: 0.092, blue: 0.130)
  static let line = Color.white.opacity(0.10)
  static let cyan = Color(red: 0.27, green: 0.91, blue: 0.94)
  static let amber = Color(red: 0.95, green: 0.68, blue: 0.33)
  static let violet = Color(red: 0.67, green: 0.57, blue: 0.98)
  static let mint = Color(red: 0.45, green: 0.89, blue: 0.72)
  static let coral = Color(red: 1.0, green: 0.49, blue: 0.51)
  static let laneColors = [amber, violet, mint, coral]
}

struct StageTopBar: View {
  @Binding var workspace: StageWorkspace
  let sceneName: String
  let isDirty: Bool
  let audioRunning: Bool
  let rolesRunning: Bool
  let outputPeak: Double
  let canUndo: Bool
  let sceneChangesBlocked: Bool
  let toggleAudio: () -> Void
  let toggleRoles: () -> Void
  let selectStarter: (Int) -> Void
  let newScene: () -> Void
  let saveAs: () -> Void
  let load: () -> Void
  let undo: () -> Void
  let showDiagnostics: () -> Void
  let panic: () -> Void

  var body: some View {
    HStack(spacing: 14) {
      HStack(spacing: 9) {
        RoundedRectangle(cornerRadius: 7)
          .fill(LatticewakeDesign.cyan.gradient)
          .frame(width: 27, height: 27)
          .rotationEffect(.degrees(10))
          .shadow(color: LatticewakeDesign.cyan.opacity(0.25), radius: 8)
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 1) {
          Text("Latticewake").font(.headline.weight(.semibold))
          HStack(spacing: 4) {
            Text(sceneName).lineLimit(1)
            if isDirty { Text("• Changed").foregroundStyle(LatticewakeDesign.amber) }
          }
          .font(.caption2).foregroundStyle(.secondary)
        }
      }
      .frame(minWidth: 190, alignment: .leading)

      Picker("Workspace", selection: $workspace) {
        ForEach(StageWorkspace.allCases) { Text($0.rawValue).tag($0) }
      }
      .pickerStyle(.segmented)
      .frame(maxWidth: 270)

      Spacer(minLength: 8)

      Button(action: toggleAudio) {
        Label(audioRunning ? "Stop Audio" : "Start Audio",
              systemImage: audioRunning ? "waveform" : "waveform.slash")
      }
      .buttonStyle(.borderedProminent)
      .tint(audioRunning ? LatticewakeDesign.cyan : .gray)
      .help(audioRunning ? "Stop the standalone audio device" : "Start the standalone audio device")

      Button(action: toggleRoles) {
        Label(rolesRunning ? "Stop" : "Play", systemImage: rolesRunning ? "stop.fill" : "play.fill")
      }
      .buttonStyle(.bordered)

      VStack(alignment: .trailing, spacing: 2) {
        Text("OUT").font(.caption2.monospaced()).foregroundStyle(.secondary)
        ProgressView(value: outputPeak, total: 1).frame(width: 64)
      }

      Menu {
        Menu("Starter Scenes") {
          Button("Sustained Terrain") { selectStarter(0) }
          Button("Gesture Terrain") { selectStarter(1) }
          Button("Four Role Loop") { selectStarter(2) }
        }
        .disabled(sceneChangesBlocked)
        Button("New Gesture Scene", action: newScene).disabled(sceneChangesBlocked)
        Divider()
        Button("Save As…", action: saveAs)
        Button("Load…", action: load).disabled(sceneChangesBlocked)
      } label: {
        Label("Scene", systemImage: "doc")
      }
      .menuStyle(.borderlessButton)
      .fixedSize()

      Button(action: undo) { Image(systemName: "arrow.uturn.backward") }
        .help("Undo the last accepted scene edit")
        .disabled(!canUndo || sceneChangesBlocked)
      Button(action: showDiagnostics) { Image(systemName: "waveform.path.ecg") }
        .help("Show technical diagnostics")
      Button("Panic", action: panic)
        .buttonStyle(.bordered).tint(LatticewakeDesign.coral)
    }
    .padding(.horizontal, 14)
    .frame(minHeight: 58)
    .background(LatticewakeDesign.background.opacity(0.96))
    .overlay(alignment: .bottom) { Divider().opacity(0.45) }
  }
}

struct StageToolRail: View {
  let libraryOpen: Bool
  let inspectorOpen: Bool
  let workspace: StageWorkspace
  let toggleLibrary: () -> Void
  let toggleInspector: () -> Void
  let showGrow: () -> Void
  let capture: () -> Void

  var body: some View {
    VStack(spacing: 9) {
      railButton("books.vertical", "Scene Library", libraryOpen, toggleLibrary)
      railButton("slider.horizontal.3", "Scene Inspector", inspectorOpen, toggleInspector)
      railButton("sparkles", "Grow", workspace == .grow, showGrow)
      railButton("record.circle", "Capture eight-second WAV", false, capture)
      Spacer()
      Image(systemName: "command").foregroundStyle(.secondary)
        .help("Play with A W S E D F T G Y H U J K")
    }
    .padding(.vertical, 11)
    .frame(width: 50)
    .background(LatticewakeDesign.background.opacity(0.82))
    .overlay(alignment: .trailing) { Divider().opacity(0.4) }
  }

  private func railButton(_ systemImage: String, _ label: String, _ active: Bool,
                          _ action: @escaping () -> Void) -> some View {
    Button(action: action) { Image(systemName: systemImage).frame(width: 30, height: 30) }
      .buttonStyle(.plain)
      .foregroundStyle(active ? LatticewakeDesign.cyan : .secondary)
      .background(active ? LatticewakeDesign.cyan.opacity(0.10) : .clear,
                  in: RoundedRectangle(cornerRadius: 8))
      .help(label)
      .accessibilityLabel(label)
  }
}

struct StageContextDrawer<Content: View>: View {
  let title: String
  let subtitle: String
  let color: Color
  let close: () -> Void
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        VStack(alignment: .leading, spacing: 1) {
          Text(title.uppercased()).font(.caption2.monospaced()).foregroundStyle(color)
          Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
        Spacer()
        Button(action: close) { Image(systemName: "xmark") }.buttonStyle(.plain)
          .accessibilityLabel("Close \(title)")
      }
      Divider().opacity(0.45)
      ScrollView { content.frame(maxWidth: .infinity, alignment: .leading) }
    }
    .padding(12)
    .frame(width: 292)
    .background(LatticewakeDesign.panel)
    .overlay(alignment: .trailing) { Divider().opacity(0.4) }
  }
}

struct StageMacroRail: View {
  @Binding var controls: SceneEditorControls
  let commit: () -> Void

  var body: some View {
    HStack(spacing: 8) {
      macro("Contour", value: $controls.terrainDetail, range: 0...1, format: "%.0f%%", scale: 100)
      macro("Scale", value: $controls.terrainZoom, range: 0...1, format: "%.0f%%", scale: 100)
      macro("Motion", value: $controls.traversalRateRatio, range: 0...1, format: "%.0f%%", scale: 100)
      macro("Orbit", value: $controls.traversalRadiusX, range: 0...1, format: "%.0f%%", scale: 100)
      macro("Release", value: $controls.releaseSeconds, range: 0.001...2, format: "%.2fs")
      macro("Expression", value: $controls.pressureResponse, range: 0...2, format: "%.0f%%", scale: 50)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Terrain performance macros")
  }

  private func macro(_ label: String, value: Binding<Double>, range: ClosedRange<Double>,
                     format: String, scale: Double = 1) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 4) {
        Text(label).font(.caption2).foregroundStyle(.secondary)
        Spacer(minLength: 2)
        Text(String(format: format, value.wrappedValue * scale)).font(.caption2.monospaced())
      }
      Slider(value: value, in: range) { editing in if !editing { commit() } }
        .controlSize(.mini).tint(LatticewakeDesign.cyan)
    }
    .padding(.horizontal, 8).padding(.vertical, 7)
    .frame(maxWidth: .infinity)
    .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 9))
  }
}

struct StageLaneStrip: View {
  let roles: [RoleControl]
  let performanceMask: RolePerformanceMask
  let activeLaneCount: Int
  let running: Bool
  let changesPending: Bool
  let selectLane: (Int) -> Void
  let toggleMute: (Int) -> Void
  let toggleSolo: (Int) -> Void

  var body: some View {
    HStack(spacing: 8) {
      ForEach(roles) { role in
        let color = LatticewakeDesign.laneColors[role.id % LatticewakeDesign.laneColors.count]
        let sounding = running && role.enabled && !performanceMask.muted.contains(role.id) && activeLaneCount > 0
        VStack(alignment: .leading, spacing: 6) {
          Button { selectLane(role.id) } label: {
            VStack(alignment: .leading, spacing: 6) {
              HStack(spacing: 6) {
                Circle().fill(sounding ? color : .secondary.opacity(0.45)).frame(width: 7, height: 7)
                Text(RoleControl.names[role.id]).font(.caption.weight(.semibold))
                Spacer()
                Text(changesPending ? "QUEUED" : (sounding ? "SOUNDING" : (role.enabled ? "ARMED" : "OFF")))
                  .font(.caption2.monospaced()).foregroundStyle(changesPending ? LatticewakeDesign.amber : color)
              }
              HStack(spacing: 3) {
                ForEach(0..<8, id: \.self) { step in
                  Capsule().fill(step % max(1, 5 - role.pattern % 4) == 0 ? color : Color.white.opacity(0.08))
                    .frame(height: 3)
                }
              }
            }
          }
          .buttonStyle(.plain)
          .accessibilityLabel("Open \(RoleControl.names[role.id]) lane, \(sounding ? "sounding" : (role.enabled ? "armed" : "off"))")
          HStack {
            Text(RoleControl.patterns(for: role.id)[min(role.pattern, RoleControl.patterns(for: role.id).count - 1)])
              .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
            Spacer()
            performanceButton("M", accessibilityLabel: "Mute \(RoleControl.names[role.id])",
                              active: performanceMask.muted.contains(role.id), color: LatticewakeDesign.amber) {
              toggleMute(role.id)
            }
            performanceButton("S", accessibilityLabel: "Solo \(RoleControl.names[role.id])",
                              active: performanceMask.soloed.contains(role.id), color: LatticewakeDesign.mint) {
              toggleSolo(role.id)
            }
          }
        }
        .padding(9)
        .background(color.opacity(sounding ? 0.12 : 0.035), in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .leading) { Rectangle().fill(color).frame(width: 3).clipShape(Capsule()) }
      }
    }
  }

  private func performanceButton(_ label: String, accessibilityLabel: String,
                                 active: Bool, color: Color,
                                 action: @escaping () -> Void) -> some View {
    Button(label, action: action)
      .buttonStyle(.plain).font(.caption2.weight(.semibold))
      .foregroundStyle(active ? color : .secondary)
      .padding(.horizontal, 5).padding(.vertical, 2)
      .background(active ? color.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: 4))
      .disabled(changesPending)
      .accessibilityLabel(accessibilityLabel)
  }
}

struct StageSourceBadge: View {
  let presentation: TerrainSurfacePresentation

  var body: some View {
    HStack(spacing: 6) {
      Image(systemName: presentation.primaryLayer.kind == .image ? "photo" :
              (presentation.primaryLayer.kind == .audio ? "waveform" : "point.3.connected.trianglepath.dotted"))
      Text(presentation.sourceSummary)
    }
    .font(.caption2.monospaced()).foregroundStyle(.secondary)
    .accessibilityLabel("Terrain source \(presentation.sourceSummary)")
  }
}
