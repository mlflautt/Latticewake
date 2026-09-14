import SwiftUI
import LatticewakeBridge

@main struct LatticewakeApp: App {
  var body: some Scene { WindowGroup { ContentView() } }
}

struct ContentView: View {
  @State private var running = false
  var body: some View {
    VStack(spacing: 16) {
      Text("Latticewake").font(.largeTitle)
      Text(String(cString: latticewake_core_version())).foregroundStyle(.secondary)
      Text(running ? "Audio engine not admitted" : "Ready for Cycle 010 kernel")
      Button(running ? "Stop" : "Start") { running.toggle() }.disabled(true)
    }.frame(minWidth: 420, minHeight: 260).padding()
  }
}
