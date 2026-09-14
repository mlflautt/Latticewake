import SwiftUI
import LatticewakeBridge

@main struct LatticewakeApp: App {
  var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
  @StateObject private var audio = LatticewakeAudio()
  @State private var error = ""
  var body: some View {
    VStack(spacing: 16) {
      Text("Latticewake").font(.largeTitle)
      Text(String(cString: latticewake_core_version())).foregroundStyle(.secondary)
      Text(audio.running ? "Audition running" : "Ready")
      Text("Host-level audition; C++ callback admission remains pending.").font(.caption).foregroundStyle(.secondary)
      HStack { Button(audio.running ? "Stop" : "Start") { if audio.running { audio.stop() } else { do { try audio.start() } catch { self.error = error.localizedDescription } } }; Button("C4") { audio.play(note: 60) }; Button("E4") { audio.play(note: 64) }; Button("G4") { audio.play(note: 67) } }
      if !error.isEmpty { Text(error).foregroundStyle(.red) }
    }.frame(minWidth: 420, minHeight: 260).padding().onDisappear { audio.stop() }
  }
}
