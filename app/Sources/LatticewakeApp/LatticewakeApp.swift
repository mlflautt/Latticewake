import SwiftUI
import AppKit
import LatticewakeBridge

@main struct LatticewakeApp: App {
  var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
  @StateObject private var audio = LatticewakeAudio()
  @StateObject private var terrain = TerrainStageModel()
  @StateObject private var midi = MIDIIngress()
  @State private var error = ""
  @State private var receipt = ""
  @State private var sceneBytes = Data()
  @State private var sceneURL: URL?
  @State private var roles: [RoleControl] = []
  @State private var roleTrace = RoleTraceSummary.empty
  @State private var keyboard = KeyboardState()
  @State private var gesture = GestureState()
  @State private var pointer: CGPoint?
  var body: some View {
    VStack(spacing: 14) {
      Text("Latticewake").font(.largeTitle)
      Button("Try Playable Starter (unsaved)") {
        do {
          let bytes = Data(DemoScene.playableJSON.utf8)
          try audio.setScene(bytes: bytes)
          try terrain.prepare(sceneBytes: bytes)
          roles = try RoleSceneBridge.controls(from: bytes)
          roleTrace = try RoleTraceBridge.preview(sceneBytes: bytes)
          sceneBytes = bytes
          sceneURL = nil
          receipt = "Playable starter — unsaved"
        } catch { self.error = error.localizedDescription }
      }
      if !terrain.snapshot.points.isEmpty,
         (terrain.snapshot.points.map(\.value).max() ?? 0) - (terrain.snapshot.points.map(\.value).min() ?? 0) < 0.000001 {
        Text("This path produces no sustained tone.").foregroundStyle(.orange)
      }
      HStack {
        Text("Terrain Stage").font(.headline)
        Spacer()
        Text(audio.running ? "Audition running" : "Ready").foregroundStyle(.secondary)
      }
      if !roles.isEmpty {
        RoleControlsView(controls: $roles, apply: applyRoleChanges)
      }
      Text("Hold keys for notes. Drag to play C3, or shape held keys. Left/right: pitch • up/down: timbre.").font(.caption)
      Text("Sampling path").font(.caption)
      ProgressView("Output", value: audio.outputPeak, total: 1).frame(maxWidth: 300)
      GeometryReader { geometry in
        TerrainStageView(snapshot: terrain.snapshot)
          .overlay(alignment: .topLeading) {
            if let pointer { Circle().stroke(.orange, lineWidth: 3).frame(width: 18,height: 18).position(pointer) }
          }
          .clipShape(RoundedRectangle(cornerRadius: 12))
          .contentShape(Rectangle())
          .gesture(DragGesture(minimumDistance: 0).onChanged { value in
            guard audio.running else { return }
            if let note = gesture.begin(held: keyboard.held) { audio.play(note: note) }
            let x = GestureState.normalized(value.location.x, length: geometry.size.width)
            let y = GestureState.normalized(value.location.y, length: geometry.size.height)
            pointer = CGPoint(x: x*geometry.size.width,y: y*geometry.size.height)
            for note in gesture.targets { audio.midiNoteExpression(note: note, glide: 2*x-1, press: 1, slide: 1-y) }
          }.onEnded { _ in endGesture() })
      }.frame(height: 280)
      Text("Held notes: \(keyboard.held.sorted().map(String.init).joined(separator: ", "))\(gesture.pointerNote.map { " • pointer \($0)" } ?? "")").font(.caption)
      DisclosureGroup("Diagnostics") {
      if !receipt.isEmpty { Text("Scene \(receipt)").font(.caption).foregroundStyle(.secondary) }
      if roleTrace.eventCount > 0 {
        Text("Role preview: \(roleTrace.eventCount) events • trace \(roleTrace.receiptText)").font(.caption).foregroundStyle(.secondary)
      }
      Text("256 immutable trace points • sample \(terrain.snapshot.sampleOffset)").font(.caption).foregroundStyle(.secondary)
      Text("Bounded C++ event bridge; device callback admission remains pending.").font(.caption).foregroundStyle(.secondary)
      Text(audio.callbackStatus).font(.caption).foregroundStyle(.secondary)
      }
      HStack { Button(audio.running ? "Stop" : "Start") { if audio.running { audio.stop() } else { do { try audio.start() } catch { self.error = error.localizedDescription } } }; Button("Panic") { midi.panic() } }
      HStack {
        Picker("MIDI", selection: Binding(get: { midi.mode }, set: { midi.configure(mode: $0) })) {
          ForEach(LatticewakeMpeMode.allCases) { Text($0.rawValue).tag($0) }
        }.labelsHidden().frame(width: 140)
        Text("\(midi.status) • \(midi.sourceCount) source").font(.caption).foregroundStyle(.secondary)
      }
      Text("Play: A W S E D F T G Y H U J K").font(.caption)
      Text(String(cString: latticewake_core_version())).font(.caption2).foregroundStyle(.secondary)
      if !error.isEmpty { Text(error).foregroundStyle(.red) }
    }.frame(minWidth: 520, minHeight: 520).padding().focusable().task {
      do {
        let directory = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Latticewake", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("scene-v0.json")
        if !FileManager.default.fileExists(atPath: url.path) { _ = try SceneStore.saveCanonical(Data(DemoScene.playableJSON.utf8), to: url) }
        let (bytes, loaded) = try SceneStore.loadCanonical(from: url)
        try audio.setScene(bytes: bytes)
        try terrain.prepare(sceneBytes: bytes)
        roles = try RoleSceneBridge.controls(from: bytes)
        roleTrace = try RoleTraceBridge.preview(sceneBytes: bytes)
        sceneBytes = bytes
        sceneURL = url
        receipt = String(loaded.sha256.prefix(12))
      } catch { self.error = error.localizedDescription }
      midi.start(audio: audio)
    }.onKeyPress(phases: [.down, .up, .repeat]) { press in
      guard let note = KeyboardState.notes[press.characters.lowercased()] else { return .ignored }
      if press.phase == .down, audio.running, keyboard.down(note) { audio.play(note: note) }
      if press.phase == .up, keyboard.up(note) { audio.release(note: note) }
      return .handled
    }.onReceive(NotificationCenter.default.publisher(for: NSWindow.didResignKeyNotification)) { _ in
      endGesture()
      for note in keyboard.releaseAll() { audio.release(note: note) }
    }.onReceive(Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()) { _ in
      audio.refreshMeter()
    }.onChange(of: audio.running) { _, running in
      if !running { endGesture(); _ = keyboard.releaseAll() }
    }.onDisappear { for note in keyboard.releaseAll() { audio.release(note: note) }; midi.stop(); audio.stop() }
  }

  private func endGesture() {
    let ended = gesture.end()
    if let note = ended.note { audio.release(note: note) }
    for note in ended.targets { audio.midiNoteExpression(note: note, glide: 0, press: 1, slide: 0) }
    pointer = nil
  }

  private func applyRoleChanges() {
    do {
      let updated = try RoleSceneBridge.apply(roles, to: sceneBytes)
      try audio.setScene(bytes: updated)
      try terrain.prepare(sceneBytes: updated)
      roleTrace = try RoleTraceBridge.preview(sceneBytes: updated)
      if let sceneURL { receipt = String(try SceneStore.saveCanonical(updated, to: sceneURL).sha256.prefix(12)) }
      sceneBytes = updated
      error = ""
    } catch { self.error = error.localizedDescription }
  }
}
