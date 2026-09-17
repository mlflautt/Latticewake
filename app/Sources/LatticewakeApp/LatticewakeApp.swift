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
  @State private var activeRoles: [RoleControl] = []
  @State private var queuedRoles: [RoleControl]?
  @State private var rolePerformanceMask = RolePerformanceMask()
  @State private var roleTrace = RoleTraceSummary.empty
  @State private var pendingRoleTrace: RoleTraceSummary?
  @State private var performance = PerformanceSettingsV1()
  @State private var editorControls = SceneEditorControls()
  @State private var modulationControls = ModulationControls()
  @State private var previewABytes: Data?
  @State private var previewActive = false
  @State private var growDepth: GrowDepth = .related
  @State private var frozenComponents = FrozenComponents()
  @State private var growProposals: [GrowProposal] = []
  @State private var selectedGrowProposalID: String?
  @State private var acceptedGrowReceipts: [GrowProposalReceiptV1] = []
  @State private var acceptedAgentReceipts: [AgentProposalReceiptV1] = []
  @State private var proposalJSON = ""
  @State private var localProposalIntent: LocalProposalIntent = .orbitPath
  @State private var validatedAgentProposal: ValidatedAgentProposal?
  @State private var proposalStatus = ""
  @State private var undoHistory = SceneUndoHistory()
  @State private var isDirty = false
  @State private var libraryOpen = false
  @State private var inspectorOpen = false
  @State private var diagnosticsOpen = false
  @State private var workspace: StageWorkspace = .perform
  @State private var inspectorPage: StageInspectorPage = .sculpt
  @State private var surfacePresentation = TerrainSurfacePresentation.analyticDefault
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  private var roleEditStatus: String {
    if audio.roleChangesPending {
      return "Queued for next loop • \(Int(audio.roleLoopProgress * 100))% through active loop"
    }
    if roles != activeRoles { return "Edited values are not active yet." }
    return "Role controls match the active loop."
  }
  var body: some View {
    GeometryReader { window in
      let allowsTwoDrawers = window.size.width >= 1_180
      ZStack {
        LatticewakeDesign.background.ignoresSafeArea()
        VStack(spacing: 0) {
          StageTopBar(
            workspace: $workspace,
            sceneName: sceneURL?.deletingPathExtension().lastPathComponent ?? "Starter Terrain",
            isDirty: isDirty,
            audioRunning: audio.running,
            rolesRunning: audio.rolesRunning,
            outputPeak: audio.outputPeak,
            canUndo: undoHistory.canUndo,
            sceneChangesBlocked: audio.roleChangesPending,
            toggleAudio: toggleAudio,
            toggleRoles: toggleRoles,
            selectStarter: selectStarterAtIndex,
            newScene: { selectStarter(DemoScene.gestureJSON, label: "New Gesture Terrain") },
            saveAs: saveAs,
            load: load,
            undo: undo,
            showDiagnostics: { diagnosticsOpen = true },
            panic: { input.panic(reason: "artist") }
          )

          HStack(spacing: 0) {
            StageToolRail(
              libraryOpen: libraryOpen,
              inspectorOpen: inspectorOpen,
              workspace: workspace,
              toggleLibrary: {
                libraryOpen.toggle()
                if libraryOpen && !allowsTwoDrawers { inspectorOpen = false }
              },
              toggleInspector: {
                inspectorOpen.toggle()
                if inspectorOpen && !allowsTwoDrawers { libraryOpen = false }
              },
              showGrow: {
                workspace = .grow
                libraryOpen = true
                if !allowsTwoDrawers { inspectorOpen = false }
              },
              capture: capture
            )

            if libraryOpen && (!inspectorOpen || allowsTwoDrawers) {
              StageContextDrawer(title: workspace == .grow ? "Grow" : "Library",
                                 subtitle: "Scenes, variations, lineage", color: LatticewakeDesign.cyan,
                                 close: { libraryOpen = false }) {
                VStack(alignment: .leading, spacing: 12) {
                  GrowControlsView(depth: $growDepth, frozen: $frozenComponents,
                                   proposals: growProposals, selectedProposalID: $selectedGrowProposalID,
                                   generate: generateGrow, preview: previewGrow, accept: acceptGrow,
                                   reject: rejectGrow)
                  if let last = acceptedGrowReceipts.last {
                    Text("Accepted variations: \(acceptedGrowReceipts.count) • \(last.proposalID)")
                      .font(.caption2.monospaced()).foregroundStyle(.secondary)
                  }
                  Divider().opacity(0.45)
                  ProposalStudioView(json: $proposalJSON, localIntent: $localProposalIntent,
                                     validated: validatedAgentProposal, status: proposalStatus,
                                     validate: validateAgentProposal, preview: previewAgentProposal,
                                     accept: acceptAgentProposal, reject: rejectAgentProposal,
                                     sample: loadProposalFixture, prepareLocal: loadLocalProposal)
                  if let last = acceptedAgentReceipts.last {
                    Text("Accepted agent proposals: \(acceptedAgentReceipts.count) • \(last.proposalID)")
                      .font(.caption2.monospaced()).foregroundStyle(.secondary)
                  }
                  Text("Scene \(receipt.isEmpty ? "unidentified" : receipt)")
                    .font(.caption2.monospaced()).foregroundStyle(.secondary)
                }
              }
            }

            VStack(spacing: 10) {
              HStack {
                VStack(alignment: .leading, spacing: 2) {
                  Text("TERRAIN STAGE").font(.caption2.monospaced()).foregroundStyle(LatticewakeDesign.cyan)
                  StageSourceBadge(presentation: surfacePresentation)
                }
                Spacer()
                Text(audio.running ? "PLAYABLE" : "AUDIO OFF")
                  .font(.caption2.monospaced())
                  .foregroundStyle(audio.running ? LatticewakeDesign.mint : .secondary)
              }

              ZStack(alignment: .topLeading) {
                GeometryReader { stage in
                  TerrainContourSurface(snapshot: terrain.snapshot, pointer: input.pointerPosition,
                                        heldNotes: input.heldNotes.sorted(), activeLanes: audio.activeRoleLanes,
                                        source: surfacePresentation)
                    .frame(width: max(1, stage.size.width), height: max(1, stage.size.height))
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                      input.gestureChanged(location: value.location, size: stage.size,
                                           pointerNote: performance.pointerNote)
                    }.onEnded { _ in input.endGesture() })
                }
                if previewActive {
                  Label("Preview — current saved scene is untouched", systemImage: "eye")
                    .font(.caption).padding(7)
                    .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 7))
                    .padding(12)
                }
                if terrainIsFlat {
                  Label("This path produces no sustained tone", systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(LatticewakeDesign.amber).padding(7)
                    .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 7))
                    .padding(12).offset(y: previewActive ? 38 : 0)
                }
              }
              .frame(minHeight: 260)

              StageMacroRail(controls: $editorControls, commit: applyEditorChanges)
                .disabled(audio.roleChangesPending)

              if !input.voices.isEmpty {
                ScrollView(.horizontal) {
                  HStack(spacing: 6) {
                    ForEach(input.voices) { voice in
                      Text("\(voice.label)  G \(String(format: "%+.2f", voice.glide))  P \(String(format: "%.2f", voice.press))  S \(String(format: "%.2f", voice.slide))")
                        .font(.caption2.monospaced()).padding(.horizontal, 7).padding(.vertical, 4)
                        .background(.white.opacity(0.06), in: Capsule())
                    }
                  }
                }
                .scrollIndicators(.hidden)
              }

              StageLaneStrip(roles: roles, performanceMask: rolePerformanceMask,
                             activeLaneCount: audio.activeRoleLanes, running: audio.rolesRunning,
                             changesPending: audio.roleChangesPending,
                             selectLane: { _ in
                               inspectorPage = .lanes; inspectorOpen = true
                               if !allowsTwoDrawers { libraryOpen = false }
                             },
                             toggleMute: toggleRoleMute, toggleSolo: toggleRoleSolo)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if inspectorOpen {
              StageContextDrawer(title: "Inspector", subtitle: inspectorPage.rawValue,
                                 color: LatticewakeDesign.violet,
                                 close: { inspectorOpen = false }) {
                VStack(alignment: .leading, spacing: 10) {
                  Picker("Inspector", selection: $inspectorPage) {
                    ForEach(StageInspectorPage.allCases) { Text($0.rawValue).tag($0) }
                  }
                  .pickerStyle(.segmented)
                  switch inspectorPage {
                  case .sculpt:
                    Text("Surface · Traversal · Articulation").font(.caption).foregroundStyle(.secondary)
                    SceneEditorView(controls: $editorControls, apply: applyEditorChanges,
                                    preview: previewEditorChanges, captureA: { previewABytes = sceneBytes },
                                    previewA: previewA, returnToCurrent: returnToCurrent,
                                    hasA: previewABytes != nil)
                  case .modulation:
                    ModulationControlsView(controls: $modulationControls, apply: applyModulationChanges)
                  case .lanes:
                    RoleControlsView(controls: $roles, performanceMask: rolePerformanceMask,
                                     editStatus: roleEditStatus, changesPending: audio.roleChangesPending,
                                     rolesRunning: audio.rolesRunning,
                                     toggleMute: toggleRoleMute, toggleSolo: toggleRoleSolo,
                                     apply: applyRoleChanges)
                  }
                  Text(reduceMotion ? "Reduced motion active" : "Live snapshot display")
                    .font(.caption2).foregroundStyle(.secondary)
                }
              }
            }
          }
        }

        if !error.isEmpty {
          VStack {
            Spacer()
            HStack {
              Image(systemName: "exclamationmark.triangle.fill")
              Text(error).lineLimit(2)
              Spacer()
              Button("Dismiss") { error = "" }.buttonStyle(.plain)
            }
            .padding(10).background(Color.red.opacity(0.88), in: RoundedRectangle(cornerRadius: 9))
            .padding(12)
          }
        }
      }
    }
    .frame(minWidth: 760, minHeight: 640)
    .sheet(isPresented: $diagnosticsOpen) {
      VStack(alignment: .leading, spacing: 10) {
        HStack {
          Text("Latticewake Diagnostics").font(.title2.weight(.semibold))
          Spacer()
          Button("Done") { diagnosticsOpen = false }.keyboardShortcut(.cancelAction)
        }
        Divider()
        Text("Scene \(receipt.isEmpty ? "unidentified" : receipt)")
        if roleTrace.eventCount > 0 {
          Text("Role trace: \(roleTrace.eventCount) events • \(roleTrace.receiptText)")
          Text(roleTrace.laneSummaryText)
        }
        Text("\(terrain.snapshot.points.count) immutable trace points • sample \(terrain.snapshot.sampleOffset)")
        Text("Bounded C++ event bridge; device callback admission remains pending.")
        Text(audio.callbackStatus)
        Text(input.status)
        if input.overflowRecoveries > 0 { Text("Recovered input overloads: \(input.overflowRecoveries)").foregroundStyle(.orange) }
        Divider()
        HStack {
          Picker("MIDI mode", selection: Binding(get: { midi.mode }, set: { midi.configure(mode: $0) })) {
            ForEach(LatticewakeMpeMode.allCases) { Text($0.rawValue).tag($0) }
          }.frame(width: 170)
          Text("\(midi.status) • \(midi.sourceCount) source")
        }
        Text("Keyboard: A W S E D F T G Y H U J K")
        Text(String(cString: latticewake_core_version())).font(.caption.monospaced()).foregroundStyle(.secondary)
      }
      .font(.caption)
      .padding(20).frame(minWidth: 580, minHeight: 360, alignment: .topLeading)
    }
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
    }.onChange(of: workspace) { _, next in
      switch next {
      case .perform: break
      case .sculpt:
        inspectorPage = .sculpt
        inspectorOpen = true
        libraryOpen = false
      case .grow:
        libraryOpen = true
        inspectorOpen = false
      }
    }.onChange(of: audio.roleChangesPending) { _, pending in
      guard !pending, let queuedRoles else { return }
      activeRoles = queuedRoles
      self.queuedRoles = nil
      if let pendingRoleTrace { roleTrace = pendingRoleTrace; self.pendingRoleTrace = nil }
    }.onDisappear { input.focusLost(); midi.stop(); audio.stop() }
  }

  private var terrainIsFlat: Bool {
    guard !terrain.snapshot.points.isEmpty else { return false }
    return (terrain.snapshot.points.map(\.value).max() ?? 0) -
      (terrain.snapshot.points.map(\.value).min() ?? 0) < 0.000001
  }

  private func toggleAudio() {
    if audio.running { audio.stop(); return }
    do { try audio.start() } catch { self.error = error.localizedDescription }
  }

  private func toggleRoles() {
    if !audio.running {
      do { try audio.start() } catch { self.error = error.localizedDescription; return }
    }
    if audio.rolesRunning { audio.stopRoles(); performance.roleTransportEnabled = false }
    else { audio.startRoles(); performance.roleTransportEnabled = true }
    isDirty = true
  }

  private func selectStarterAtIndex(_ index: Int) {
    switch index {
    case 0: selectStarter(DemoScene.sustainedJSON, label: "Sustained Terrain")
    case 2: selectStarter(DemoScene.fourRoleJSON, label: "Four Role Loop")
    default: selectStarter(DemoScene.gestureJSON, label: "Gesture Terrain")
    }
  }

  private func applyRoleChanges() {
    do {
      let updated = try RoleSceneBridge.apply(roles, to: sceneBytes)
      if audio.running && audio.rolesRunning {
        let effectiveRoles = rolePerformanceMask.applying(to: roles)
        let runtimeBytes = try RoleSceneBridge.apply(effectiveRoles, to: updated)
        try audio.queueRoleSceneAtLoop(bytes: runtimeBytes)
        if !sceneBytes.isEmpty {
          undoHistory.record(sceneBytes, acceptedGrowReceipts: acceptedGrowReceipts,
                             acceptedAgentReceipts: acceptedAgentReceipts)
        }
        queuedRoles = roles
        pendingRoleTrace = try RoleTraceBridge.preview(sceneBytes: runtimeBytes)
        sceneBytes = updated
        receipt = String(SceneLibrary.receipt(for: updated).sha256.prefix(12))
        isDirty = true
        previewActive = false
        error = ""
      } else {
        try installScene(updated, url: sceneURL, recordUndo: true, dirty: true)
      }
      error = ""
    } catch { self.error = error.localizedDescription }
  }

  private func toggleRoleMute(_ role: Int) {
    rolePerformanceMask.toggleMute(role)
    applyRolePerformanceMask()
  }

  private func toggleRoleSolo(_ role: Int) {
    rolePerformanceMask.toggleSolo(role)
    applyRolePerformanceMask()
  }

  private func applyRolePerformanceMask() {
    do {
      let effectiveRoles = rolePerformanceMask.applying(to: roles)
      let runtimeBytes = try RoleSceneBridge.apply(effectiveRoles, to: sceneBytes)
      let resume = audio.rolesRunning
      if resume { audio.stopRoles() }
      try audio.setScene(bytes: runtimeBytes)
      roleTrace = try RoleTraceBridge.preview(sceneBytes: runtimeBytes)
      if resume { audio.startRoles() }
      error = ""
    } catch { self.error = error.localizedDescription }
  }

  private func applyEditorChanges() {
    do {
      let updated = try SceneEditorBridge.apply(editorControls, to: sceneBytes)
      try installScene(updated, url: sceneURL, recordUndo: true, dirty: true)
    } catch { self.error = error.localizedDescription }
  }
  private func generateGrow() {
    growProposals = GrowEngine.proposeVariants(base: editorControls,
                                               sceneHash: SceneLibrary.receipt(for: sceneBytes).sha256,
                                               depth: growDepth, frozen: frozenComponents)
    selectedGrowProposalID = growProposals.first?.id
    if growProposals.isEmpty { error = "All Grow components are frozen; no variations were created." }
  }
  private func previewGrow(_ proposal: GrowProposal) {
    do { try previewTemporary(SceneEditorBridge.apply(proposal.candidate, to: sceneBytes), label: "Grow preview \(proposal.variationIndex + 1)") }
    catch { self.error = error.localizedDescription }
  }
  private func acceptGrow(_ proposal: GrowProposal) {
    do {
      let candidate = try SceneEditorBridge.apply(proposal.candidate, to: sceneBytes)
      let proposalReceipt = GrowProposalReceiptV1(proposal: proposal, candidateSceneSHA256: SceneLibrary.receipt(for: candidate).sha256)
      try installScene(candidate, url: sceneURL, recordUndo: true, dirty: true)
      acceptedGrowReceipts.append(proposalReceipt)
      self.growProposals = []
      self.selectedGrowProposalID = nil
    } catch { self.error = error.localizedDescription }
  }

  private func rejectGrow() {
    growProposals = []
    selectedGrowProposalID = nil
    returnToCurrent()
  }

  private func validateAgentProposal() {
    do {
      let proposal = try ProposalContractV1.decode(Data(proposalJSON.utf8))
      validatedAgentProposal = try ProposalContractV1.validatedProposal(proposal, base: editorControls,
                                                                         roles: roles,
                                                                         sceneHash: SceneLibrary.receipt(for: sceneBytes).sha256,
                                                                         frozen: frozenComponents)
      proposalStatus = "Validated \(proposal.proposalID); preview or accept explicitly."
    } catch { validatedAgentProposal = nil; proposalStatus = error.localizedDescription }
  }

  private func loadProposalFixture() {
    do {
      guard let json = try ProposalContractV1.fixtureJSON(sceneHash: SceneLibrary.receipt(for: sceneBytes).sha256, frozen: frozenComponents) else {
        proposalStatus = "All editable components are frozen; no proposal can be generated."
        return
      }
      proposalJSON = json
      validatedAgentProposal = nil
      proposalStatus = "Local fixture loaded. Validate it before previewing."
    } catch { proposalStatus = error.localizedDescription }
  }

  private func loadLocalProposal() {
    let sceneHash = SceneLibrary.receipt(for: sceneBytes).sha256
    guard let proposal = LocalProposalProvider.propose(intent: localProposalIntent, sceneHash: sceneHash, frozen: frozenComponents) else {
      proposalStatus = "\(localProposalIntent.component) is frozen; local proposal was not created."
      return
    }
    do {
      let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
      proposalJSON = String(decoding: try encoder.encode(proposal), as: UTF8.self)
      validatedAgentProposal = nil
      proposalStatus = "Local \(localProposalIntent.rawValue) proposal ready. Validate it before previewing."
    } catch { proposalStatus = error.localizedDescription }
  }

  private func previewAgentProposal() {
    guard let validatedAgentProposal else { return }
    do { try previewTemporary(agentCandidateBytes(validatedAgentProposal), label: "Agent proposal preview") }
    catch { self.error = error.localizedDescription }
  }

  private func acceptAgentProposal() {
    guard let validatedAgentProposal else { return }
    do {
      let candidate = try agentCandidateBytes(validatedAgentProposal)
      let receipt = AgentProposalReceiptV1(proposal: validatedAgentProposal.proposal, candidateSceneSHA256: SceneLibrary.receipt(for: candidate).sha256)
      try installScene(candidate, url: sceneURL, recordUndo: true, dirty: true)
      acceptedAgentReceipts.append(receipt)
      proposalStatus = "Accepted \(receipt.proposalID); save the scene to retain its receipt."
      self.validatedAgentProposal = nil
    } catch { self.error = error.localizedDescription }
  }

  private func agentCandidateBytes(_ proposal: ValidatedAgentProposal) throws -> Data {
    let editorApplied = try SceneEditorBridge.apply(proposal.editorCandidate, to: sceneBytes)
    return try RoleSceneBridge.apply(proposal.roleCandidate, to: editorApplied)
  }

  private func rejectAgentProposal() { validatedAgentProposal = nil; proposalStatus = proposalJSON.isEmpty ? "" : "Proposal rejected; scene unchanged." }

  private func previewEditorChanges() {
    do { try previewTemporary(SceneEditorBridge.apply(editorControls, to: sceneBytes), label: "Candidate preview") }
    catch { self.error = error.localizedDescription }
  }

  private func previewA() {
    guard let previewABytes else { return }
    do { try previewTemporary(previewABytes, label: "A preview") }
    catch { self.error = error.localizedDescription }
  }

  private func previewTemporary(_ bytes: Data, label: String) throws {
    try audio.setScene(bytes: bytes)
    try terrain.prepare(sceneBytes: bytes)
    surfacePresentation = try TerrainSurfacePresentation.decode(sceneBytes: bytes)
    previewActive = true
    receipt = "\(label) • Return restores current scene"
  }

  private func returnToCurrent() {
    do {
      try audio.setScene(bytes: sceneBytes)
      try terrain.prepare(sceneBytes: sceneBytes)
      surfacePresentation = try TerrainSurfacePresentation.decode(sceneBytes: sceneBytes)
      previewActive = false
      receipt = String(SceneLibrary.receipt(for: sceneBytes).sha256.prefix(12))
    } catch { self.error = error.localizedDescription }
  }

  private func applyModulationChanges() {
    do {
      let updated = try ModulationBridge.apply(modulationControls, to: sceneBytes)
      try installScene(updated, url: sceneURL, recordUndo: true, dirty: true)
    } catch { self.error = error.localizedDescription }
  }

  private func installScene(_ bytes: Data, url: URL?, recordUndo: Bool, dirty: Bool) throws {
    if recordUndo, !sceneBytes.isEmpty { undoHistory.record(sceneBytes, acceptedGrowReceipts: acceptedGrowReceipts, acceptedAgentReceipts: acceptedAgentReceipts) }
    try audio.setScene(bytes: bytes)
    try terrain.prepare(sceneBytes: bytes)
    let installedRoles = try RoleSceneBridge.controls(from: bytes)
    roles = installedRoles
    rolePerformanceMask = .init()
    editorControls = try SceneEditorBridge.controls(from: bytes)
    modulationControls = try ModulationBridge.controls(from: bytes)
    surfacePresentation = try TerrainSurfacePresentation.decode(sceneBytes: bytes)
    let installedTrace = try RoleTraceBridge.preview(sceneBytes: bytes)
    if audio.roleChangesPending {
      queuedRoles = installedRoles
      pendingRoleTrace = installedTrace
    } else {
      activeRoles = installedRoles
      queuedRoles = nil
      roleTrace = installedTrace
      pendingRoleTrace = nil
    }
    sceneBytes = bytes
    sceneURL = url
    receipt = String(SceneLibrary.receipt(for: bytes).sha256.prefix(12))
    isDirty = dirty
    previewActive = false
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
      let document = SceneLibraryDocumentV1(sceneJSON: String(decoding: migrated, as: UTF8.self), performance: performance, acceptedGrowReceipts: acceptedGrowReceipts, acceptedAgentReceipts: acceptedAgentReceipts)
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
      acceptedGrowReceipts = loaded.acceptedGrowReceipts
      acceptedAgentReceipts = loaded.acceptedAgentReceipts
      try installScene(loaded.sceneBytes, url: url, recordUndo: true, dirty: false)
      receipt = "Loaded \(loaded.originalSceneV0 ? "Scene v0" : "Library v1") \(String(loaded.receipt.sha256.prefix(12)))"
    } catch { self.error = error.localizedDescription }
  }

  private func undo() {
    guard let previous = undoHistory.undo() else { return }
    do { acceptedGrowReceipts = previous.acceptedGrowReceipts; acceptedAgentReceipts = previous.acceptedAgentReceipts; try installScene(previous.sceneBytes, url: sceneURL, recordUndo: false, dirty: true) }
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
