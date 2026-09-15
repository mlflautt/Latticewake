import SwiftUI
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
  var body: some View {
    VStack(spacing: 14) {
      Text("Latticewake").font(.largeTitle)
      HStack {
        Text("Terrain Stage").font(.headline)
        Spacer()
        Text(audio.running ? "Audition running" : "Ready").foregroundStyle(.secondary)
      }
      TerrainStageView(snapshot: terrain.snapshot)
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .gesture(DragGesture(minimumDistance: 0).onChanged { value in
          audio.expression(glide: value.location.x / 210 - 1, press: 0.7,
                           slide: min(1, max(0, value.location.y / 280)))
        })
      if !receipt.isEmpty { Text("Scene \(receipt)").font(.caption).foregroundStyle(.secondary) }
      Text("256 immutable trace points • sample \(terrain.snapshot.sampleOffset)").font(.caption).foregroundStyle(.secondary)
      Text("Bounded C++ event bridge; device callback admission remains pending.").font(.caption).foregroundStyle(.secondary)
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
        if !FileManager.default.fileExists(atPath: url.path) { _ = try SceneStore.saveCanonical(Data(DemoScene.canonicalJSON.utf8), to: url) }
        let (bytes, loaded) = try SceneStore.loadCanonical(from: url)
        try audio.setScene(bytes: bytes)
        try terrain.prepare(sceneBytes: bytes)
        receipt = String(loaded.sha256.prefix(12))
      } catch { self.error = error.localizedDescription }
      midi.start(audio: audio)
    }.onKeyPress { press in
      let map = ["a":60,"w":61,"s":62,"e":63,"d":64,"f":65,"t":66,"g":67,"y":68,"h":69,"u":70,"j":71,"k":72]
      guard let note = map[press.characters] else { return .ignored }
      if press.phase == .down { audio.play(note: note) } else { audio.release(note: note) }
      return .handled
    }.onDisappear { midi.stop(); audio.stop() }
  }
}
