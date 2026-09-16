import SwiftUI
import AppKit
import LatticewakeBridge
import UniformTypeIdentifiers

@main struct LatticewakeApp: App {
  var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
  @StateObject private var audio = LatticewakeAudio()
  @StateObject private var input = PerformanceInputMultiplexer()
  @StateObject private var terrain = TerrainStageModel()
  @StateObject private var midi = MIDIIngress()
  @State private var error = ""
  @State private var receipt = ""
  @State private var sceneBytes = Data()
  @State private var sceneURL: URL?
  @State private var roles: [RoleControl] = []
  @State private var roleTrace = RoleTraceSummary.empty
  @State private var performance = PerformanceSettingsV1()
  @State private var editorControls = SceneEditorControls()
  @State private var undoHistory = SceneUndoHistory()
  @State private var isDirty = false
  @State private var libraryOpen = false
  @State private var inspectorOpen = false
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  var body: some View {
    VStack {
      VStack(spacing: 14) {
      HStack(alignment: .firstTextBaseline) {
        VStack(alignment: .leading, spacing: 2) {
          Text("Latticewake").font(.title.bold())
          Text("TERRAIN STAGE").font(.caption2.monospaced()).foregroundStyle(.cyan)
        }
        Spacer()
        VStack(alignment: .trailing, spacing: 2) {
          Text(audio.running ? "AUDITION" : "READY").font(.caption.monospaced()).foregroundStyle(audio.running ? .mint : .secondary)
          Text("OUT \(Int(audio.outputPeak * 100))%").font(.caption2.monospaced()).foregroundStyle(.secondary)
        }
        Button("Panic") { input.panic(reason: "artist") }.buttonStyle(.bordered)
      }
      HStack {
        Button("Library") { libraryOpen.toggle() }.buttonStyle(.bordered)
        Button("Inspect") { inspectorOpen.toggle() }.buttonStyle(.bordered)
        Menu("Starter Scenes") {
          Button("Sustained Terrain") { selectStarter(DemoScene.sustainedJSON, label: "Sustained Terrain") }
          Button("Gesture Terrain") { selectStarter(DemoScene.gestureJSON, label: "Gesture Terrain") }
          Button("Four Role Loop") { selectStarter(DemoScene.fourRoleJSON, label: "Four Role Loop") }
        }
        Button("New") { selectStarter(DemoScene.gestureJSON, label: "New Gesture Terrain") }
        Button("Save As…") { saveAs() }
        Button("Load…") { load() }
        Button("Undo") { undo() }.disabled(!undoHistory.canUndo)
        Button("Capture 8s WAV") { capture() }
      }
      Text(sceneURL == nil ? "Unsaved scene\(isDirty ? " • changed" : "")" : "\(sceneURL!.lastPathComponent)\(isDirty ? " • unsaved changes" : "")")
        .font(.caption).foregroundStyle(.secondary)
      if !terrain.snapshot.points.isEmpty,
         (terrain.snapshot.points.map(\.value).max() ?? 0) - (terrain.snapshot.points.map(\.value).min() ?? 0) < 0.000001 {
        Text("This path produces no sustained tone.").foregroundStyle(.orange)
      }
      HStack {
        Text("Play the terrain").font(.headline)
        Spacer()
        Text(audio.running ? "Audition running" : "Start to play").foregroundStyle(.secondary)
      }
      if !roles.isEmpty {
        RoleControlsView(controls: $roles, apply: applyRoleChanges)
      }
      Text(audio.rolesRunning ? "Roles playing • \(audio.activeRoleLanes) active lane\(audio.activeRoleLanes == 1 ? "" : "s")" : "Roles stopped")
        .font(.caption).foregroundStyle(.secondary)
      Text("Hold keys for notes. Drag to play C3, or shape held keys. Left/right: pitch • up/down: timbre.").font(.caption)
      Text("Sampling path").font(.caption)
      ProgressView("Output", value: audio.outputPeak, total: 1).frame(maxWidth: 300)
      GeometryReader { geometry in
        TerrainContourSurface(snapshot: terrain.snapshot, pointer: input.pointerPosition,
                              heldNotes: input.heldNotes.sorted(), activeLanes: audio.activeRoleLanes)
          .frame(width: max(1, geometry.size.width), height: 320)
          .contentShape(Rectangle())
          .gesture(DragGesture(minimumDistance: 0).onChanged { value in
            input.gestureChanged(location: value.location, size: geometry.size, pointerNote: performance.pointerNote)
          }.onEnded { _ in input.endGesture() })
      }
      .frame(minHeight: 320, maxHeight: 320)
      Text("Held notes: \(input.heldNotes.sorted().map(String.init).joined(separator: ", "))\(input.pointerNote.map { " • pointer \($0)" } ?? "")").font(.caption)
      if !input.voices.isEmpty {
        HStack(spacing: 6) {
          ForEach(input.voices) { voice in
            Text("\(voice.label) • G \(String(format: "%.2f", voice.glide)) • P \(String(format: "%.2f", voice.press)) • S \(String(format: "%.2f", voice.slide))")
              .font(.caption2.monospaced()).padding(5).background(.white.opacity(0.06), in: Capsule())
          }
        }
      }
      StageRoleDeck(roles: roles, activeLanes: audio.activeRoleLanes, running: audio.rolesRunning)
      if libraryOpen || inspectorOpen {
        HStack(alignment: .top, spacing: 12) {
          if libraryOpen {
            StageDrawer(title: "Library", color: .cyan) {
              Text("Scenes, captures, and lineage stay explicit.").font(.caption).foregroundStyle(.secondary)
              Button("Close Library") { libraryOpen = false }.font(.caption)
              Text("Current: \(receipt.isEmpty ? "unidentified" : receipt)").font(.caption2.monospaced()).foregroundStyle(.secondary)
            }
          }
          if inspectorOpen {
            StageDrawer(title: "Inspector", color: .purple) {
              Text("Surface · Traversal · Articulation").font(.caption)
              SceneEditorView(controls: $editorControls, apply: applyEditorChanges)
              Text(reduceMotion ? "Reduced motion active" : "Live snapshot display").font(.caption2).foregroundStyle(.secondary)
              Button("Close Inspector") { inspectorOpen = false }.font(.caption)
            }
          }
        }
      }
      DisclosureGroup("Diagnostics") {
      if !receipt.isEmpty { Text("Scene \(receipt)").font(.caption).foregroundStyle(.secondary) }
      if roleTrace.eventCount > 0 {
        Text("Role preview: \(roleTrace.eventCount) events • trace \(roleTrace.receiptText)").font(.caption).foregroundStyle(.secondary)
      }
      Text("256 immutable trace points • sample \(terrain.snapshot.sampleOffset)").font(.caption).foregroundStyle(.secondary)
      Text("Bounded C++ event bridge; device callback admission remains pending.").font(.caption).foregroundStyle(.secondary)
      Text(audio.callbackStatus).font(.caption).foregroundStyle(.secondary)
      Text(input.status).font(.caption).foregroundStyle(.secondary)
      if input.overflowRecoveries > 0 { Text("Recovered input overloads: \(input.overflowRecoveries)").font(.caption).foregroundStyle(.orange) }
      }
      HStack {
        Button(audio.running ? "Stop" : "Start") { if audio.running { audio.stop() } else { do { try audio.start() } catch { self.error = error.localizedDescription } } }
        Button(audio.rolesRunning ? "Stop Roles" : "Play Roles") {
          if !audio.running { do { try audio.start() } catch { self.error = error.localizedDescription; return } }
          if audio.rolesRunning { audio.stopRoles(); performance.roleTransportEnabled = false }
          else { audio.startRoles(); performance.roleTransportEnabled = true }
          isDirty = true
        }
      }
      HStack {
        Picker("MIDI", selection: Binding(get: { midi.mode }, set: { midi.configure(mode: $0) })) {
          ForEach(LatticewakeMpeMode.allCases) { Text($0.rawValue).tag($0) }
        }.labelsHidden().frame(width: 140)
        Text("\(midi.status) • \(midi.sourceCount) source").font(.caption).foregroundStyle(.secondary)
      }
      Text("Play: A W S E D F T G Y H U J K").font(.caption)
      Text(String(cString: latticewake_core_version())).font(.caption2).foregroundStyle(.secondary)
      if !error.isEmpty { Text(error).foregroundStyle(.red) }
      }
      .frame(maxWidth: 1_040, alignment: .leading)
      .padding(.horizontal, 16)
      .padding(.vertical)
    }
    .frame(minWidth: 620, minHeight: 620)
    .focusable().task {
      do {
      input.attach(audio: audio)
      try installScene(Data(DemoScene.gestureJSON.utf8), url: nil, recordUndo: false, dirty: false)
      } catch { self.error = error.localizedDescription }
      // MIDI connection remains deliberately opt-in while the standalone
      // Core MIDI worker-thread boundary is being revalidated on this target.
    }.onKeyPress(phases: [.down, .up, .repeat]) { press in
      guard let note = KeyboardState.notes[press.characters.lowercased()] else { return .ignored }
      if press.phase == .down { input.keyboardDown(note: note) }
      if press.phase == .up { input.keyboardUp(note: note) }
      return .handled
    }.onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
      input.focusLost()
    }.task(id: audio.running) {
      guard audio.running else { return }
      while !Task.isCancelled && audio.running {
        audio.refreshMeter()
        try? await Task.sleep(for: .milliseconds(50))
      }
    }.onChange(of: audio.running) { _, running in
      if !running { input.audioStopped() }
    }.onDisappear { input.focusLost(); midi.stop(); audio.stop() }
  }

  private func applyRoleChanges() {
    do {
      let updated = try RoleSceneBridge.apply(roles, to: sceneBytes)
      try installScene(updated, url: sceneURL, recordUndo: true, dirty: true)
      error = ""
    } catch { self.error = error.localizedDescription }
  }

  private func applyEditorChanges() {
    do {
      let updated = try SceneEditorBridge.apply(editorControls, to: sceneBytes)
      try installScene(updated, url: sceneURL, recordUndo: true, dirty: true)
    } catch { self.error = error.localizedDescription }
  }

  private func installScene(_ bytes: Data, url: URL?, recordUndo: Bool, dirty: Bool) throws {
    if recordUndo, !sceneBytes.isEmpty { undoHistory.record(sceneBytes) }
    try audio.setScene(bytes: bytes)
    try terrain.prepare(sceneBytes: bytes)
    roles = try RoleSceneBridge.controls(from: bytes)
    editorControls = try SceneEditorBridge.controls(from: bytes)
    roleTrace = try RoleTraceBridge.preview(sceneBytes: bytes)
    sceneBytes = bytes
    sceneURL = url
    receipt = String(SceneLibrary.receipt(for: bytes).sha256.prefix(12))
    isDirty = dirty
    error = ""
  }

  private func selectStarter(_ json: String, label: String) {
    do {
      performance = .init()
      try installScene(Data(json.utf8), url: nil, recordUndo: true, dirty: false)
      receipt = "\(label) — unsaved"
    } catch { self.error = error.localizedDescription }
  }

  private func saveAs() {
    let panel = NSSavePanel()
    panel.allowedContentTypes = [.json]
    panel.nameFieldStringValue = "Latticewake Scene.latticewake.json"
    guard panel.runModal() == .OK, let url = panel.url else { return }
    do {
      let migrated = try SceneDocumentBridge.canonicalV1(from: sceneBytes)
      let document = SceneLibraryDocumentV1(sceneJSON: String(decoding: migrated, as: UTF8.self), performance: performance)
      let saved = try SceneLibrary.save(document, to: url)
      sceneBytes = migrated; sceneURL = url; isDirty = false
      receipt = "Saved Scene v1 \(String(saved.sha256.prefix(12)))"
    } catch { self.error = error.localizedDescription }
  }

  private func load() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.json]
    panel.allowsMultipleSelection = false
    guard panel.runModal() == .OK, let url = panel.url else { return }
    do {
      let loaded = try SceneLibrary.load(from: url)
      performance = loaded.performance
      try installScene(loaded.sceneBytes, url: url, recordUndo: true, dirty: false)
      receipt = "Loaded \(loaded.originalSceneV0 ? "Scene v0" : "Library v1") \(String(loaded.receipt.sha256.prefix(12)))"
    } catch { self.error = error.localizedDescription }
  }

  private func undo() {
    guard let previous = undoHistory.undo() else { return }
    do { try installScene(previous, url: sceneURL, recordUndo: false, dirty: true) }
    catch { self.error = error.localizedDescription }
  }

  private func capture() {
    do {
      let root = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                             appropriateFor: nil, create: true)
        .appendingPathComponent("Latticewake/Captures", isDirectory: true)
      let (url, captureReceipt) = try OfflineCapture.render(sceneBytes: sceneBytes, to: root)
      receipt = "Capture \(url.lastPathComponent) • \(captureReceipt.frameCount) frames"
    } catch { self.error = error.localizedDescription }
  }
}
