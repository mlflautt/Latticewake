import XCTest
import Foundation
import AVFoundation
import LatticewakeBridge
@testable import LatticewakeApp

final class LatticewakeAppTests: XCTestCase {
  func testKeyboardRepeatAndFocusRelease() {
  var keys = KeyboardState()
  let first = keys.down(60)
  let repeated = keys.down(60)
  let second = keys.down(64)
  let released = keys.releaseAll()
  let stale = keys.up(60)
  XCTAssertTrue(first && !repeated && second && !stale)
  XCTAssertEqual(released, [60,64])
  XCTAssertTrue(keys.held.isEmpty)
}

  func testGestureOwnershipAndResize() {
  var pointer = GestureState()
  let note = pointer.begin(held: [])
  XCTAssertEqual(note, 48)
  let duplicate = pointer.begin(held: [60])
  XCTAssertNil(duplicate)
  XCTAssertEqual(pointer.targets, [48])
  let release = pointer.end()
  XCTAssertTrue(release.note == 48 && !pointer.active)
  let shaping = pointer.begin(held: [60,64])
  XCTAssertTrue(shaping == nil && pointer.targets == [60,64])
  XCTAssertEqual(GestureState.normalized(100,length: 200), GestureState.normalized(300,length: 600))
  XCTAssertEqual(GestureState.normalized(-20,length: 200), 0)
}

  func testAudioCallbackRunsOnBackgroundThread() async {
  let success = await withCheckedContinuation { continuation in
    DispatchQueue.global().async {
      let kernel = lw_kernel_create()!
      defer { lw_kernel_destroy(kernel) }
      let prepared = DemoScene.playableJSON.withCString { lw_kernel_prepare_scene_json(kernel, $0, 48000) }
      let block = makeCallbackRenderBlock(CallbackRenderState(kernel: kernel))
      let format = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 2)!
      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 512)!
      buffer.frameLength = 512
      _ = lw_kernel_note_on(kernel, 60, 0.7)
      var silence = ObjCBool(false)
      var timestamp = AudioTimeStamp()
      let result = block(&silence, &timestamp, 512, buffer.mutableAudioBufferList)
      let left = buffer.floatChannelData![0]
      let right = buffer.floatChannelData![1]
      let audible = (0..<512).contains { abs(left[$0]) > 0.00001 }
      let stereo = (0..<512).allSatisfy { left[$0] == right[$0] }
      continuation.resume(returning: prepared == 1 && result == 0 && audible && stereo && !Thread.isMainThread)
    }
  }
  XCTAssertTrue(success)
}

  @MainActor func testOptInDeviceSmoke() async throws {
  guard ProcessInfo.processInfo.environment["LW_DEVICE_SMOKE"] == "1" else { return }
  let audio = LatticewakeAudio()
  try audio.setScene(bytes: Data(DemoScene.playableJSON.utf8))
  try audio.start()
  defer { audio.stop() }
  XCTAssertTrue(audio.enqueueNoteOn(note: 60, velocity: 0.7, source: PerformanceInputSource.keyboard.token))
  try await Task.sleep(for: .seconds(1))
  XCTAssertTrue(audio.enqueueNoteOff(note: 60, source: PerformanceInputSource.keyboard.token))
  try await Task.sleep(for: .milliseconds(200))
  audio.stop()
  XCTAssertGreaterThan(audio.auditionReceipt?.callbackCount ?? 0, 0)
  XCTAssertEqual(audio.auditionReceipt?.rejectedBlocks, 0)
  print(audio.auditionReceipt?.machineLine ?? "missing receipt")
}
  @MainActor func testTerrainStagePreparesImmutableSnapshot() throws {
  let model = TerrainStageModel()
  try model.prepare(sceneBytes: Data(DemoScene.canonicalJSON.utf8), sampleOffset: 480)
  XCTAssertEqual(model.snapshot.sampleOffset, 480)
  XCTAssertEqual(model.snapshot.points.count, 256)
  XCTAssertTrue(model.snapshot.points.allSatisfy { $0.value >= 0 && $0.value <= 1 })
}
  func testMidiDecoderPreservesChannelVoiceMessages() {
  let messages = MIDIMessageDecoder.decode([0x91, 60, 100, 0xE1, 0, 64, 0xD1, 96, 0xB1, 74, 127])
  XCTAssertEqual(messages, [
    MIDIMessage(status: 0x91, data1: 60, data2: 100),
    MIDIMessage(status: 0xE1, data1: 0, data2: 64),
    MIDIMessage(status: 0xD1, data1: 96, data2: 0),
    MIDIMessage(status: 0xB1, data1: 74, data2: 127)
  ])
}

  func testMidiReceiveDispatcherCanHopFromBackgroundToMainActor() async {
    let received = expectation(description: "main actor receives MIDI")
    let dispatcher = MIDIReceiveDispatcher { messages in
      Task { @MainActor in
        XCTAssertTrue(Thread.isMainThread)
        XCTAssertEqual(messages, [MIDIMessage(status: 0x90, data1: 60, data2: 100)])
        received.fulfill()
      }
    }
    DispatchQueue.global().async {
      dispatcher.submit([MIDIMessage(status: 0x90, data1: 60, data2: 100)])
    }
    await fulfillment(of: [received], timeout: 1)
  }

  func testMidiRefreshDispatcherCanHopFromBackgroundToMainActor() async {
    let refreshed = expectation(description: "main actor refreshes MIDI sources")
    let dispatcher = MIDIRefreshDispatcher {
      Task { @MainActor in
        XCTAssertTrue(Thread.isMainThread)
        refreshed.fulfill()
      }
    }
    DispatchQueue.global().async {
      dispatcher.refresh()
    }
    await fulfillment(of: [refreshed], timeout: 1)
  }

  func testCoreMIDIPacketPortDeliversThroughNonisolatedFactory() async throws {
    var client = MIDIClientRef()
    let clientResult = MIDIClientCreateWithBlock("Latticewake MIDI Test" as CFString, &client, { _ in })
    guard clientResult == noErr else { throw XCTSkip("Core MIDI service unavailable: \(clientResult)") }
    defer { MIDIClientDispose(client) }
    let received = expectation(description: "Core MIDI packet reaches main actor")
    let dispatcher = MIDIReceiveDispatcher { messages in
      Task { @MainActor in
        XCTAssertTrue(Thread.isMainThread)
        XCTAssertEqual(messages, [MIDIMessage(status: 0x90, data1: 60, data2: 100)])
        received.fulfill()
      }
    }
    guard let inputPort = createMIDIInputPort(client: client, dispatcher: dispatcher) else {
      throw XCTSkip("Core MIDI input port unavailable")
    }
    defer { MIDIPortDispose(inputPort) }
    var source = MIDIEndpointRef()
    let sourceResult = MIDISourceCreate(client, "Latticewake MIDI Test Source" as CFString, &source)
    guard sourceResult == noErr else { throw XCTSkip("Core MIDI source unavailable: \(sourceResult)") }
    defer { MIDIEndpointDispose(source) }
    XCTAssertEqual(MIDIPortConnectSource(inputPort, source, nil), noErr)

    let storage = UnsafeMutableRawPointer.allocate(byteCount: 1024, alignment: MemoryLayout<MIDIPacketList>.alignment)
    defer { storage.deallocate() }
    let packetList = storage.bindMemory(to: MIDIPacketList.self, capacity: 1)
    let packet = MIDIPacketListInit(packetList)
    let bytes: [UInt8] = [0x90, 60, 100]
    let added = bytes.withUnsafeBufferPointer {
      MIDIPacketListAdd(packetList, 1024, packet, 0, $0.count, $0.baseAddress!)
    }
    XCTAssertNotNil(added)
    XCTAssertEqual(MIDIReceived(source, packetList), noErr)
    await fulfillment(of: [received], timeout: 1)
  }

  func testPerformanceInputSourcesKeepMpeChannelsDistinct() {
    XCTAssertNotEqual(PerformanceInputSource.keyboard.token, PerformanceInputSource.pointer.token)
    XCTAssertNotEqual(PerformanceInputSource.midi(channel: 2).token, PerformanceInputSource.midi(channel: 3).token)
    XCTAssertLessThan(PerformanceInputSource.midi(channel: 16).token, 100)
    let samePitchOnDifferentChannels = [
      PerformanceVoice(source: .midi(channel: 2), note: 60, age: 1, glide: 0, press: 1, slide: 0),
      PerformanceVoice(source: .midi(channel: 3), note: 60, age: 2, glide: 0, press: 1, slide: 0)
    ]
    XCTAssertNotEqual(samePitchOnDifferentChannels[0].id, samePitchOnDifferentChannels[1].id)
  }
  func testSceneStoreRoundTrips() throws {
  let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
  defer { try? FileManager.default.removeItem(at: url) }
  let receipt = try SceneStore.saveCanonical(Data("{}".utf8), to: url)
  let (bytes, loaded) = try SceneStore.loadCanonical(from: url)
  XCTAssertEqual(bytes, Data("{}".utf8)); XCTAssertEqual(receipt, loaded)
}

  func testSceneLibraryPreservesLegacyV0AndRoundTripsV1() throws {
  let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: directory) }
  let legacyURL = directory.appendingPathComponent("legacy.json")
  let legacyBytes = Data(DemoScene.gestureJSON.utf8)
  _ = try SceneStore.saveCanonical(legacyBytes, to: legacyURL)
  let legacy = try SceneLibrary.load(from: legacyURL)
  XCTAssertTrue(legacy.originalSceneV0)
  XCTAssertEqual(legacy.sceneBytes, legacyBytes)

  let libraryURL = directory.appendingPathComponent("scene.latticewake.json")
  let settings = PerformanceSettingsV1(gestureGlideSemitones: 7, pointerNote: 50, roleTransportEnabled: true)
  let document = SceneLibraryDocumentV1(sceneJSON: DemoScene.fourRoleJSON, performance: settings)
  let saved = try SceneLibrary.save(document, to: libraryURL)
  let loaded = try SceneLibrary.load(from: libraryURL)
  XCTAssertFalse(loaded.originalSceneV0)
  XCTAssertEqual(loaded.sceneBytes, try SceneDocumentBridge.canonicalV1(from: Data(DemoScene.fourRoleJSON.utf8)))
  XCTAssertEqual(loaded.performance, settings)
  XCTAssertEqual(saved.sha256, loaded.receipt.sha256)
}

  func testGrowReceiptRoundTripsAndLegacyLibraryStaysReadable() throws {
    let proposal = GrowEngine.propose(base: .init(), sceneHash: "base", depth: .related,
                                      frozen: FrozenComponents(surface: true, traversal: false, articulation: true))
    let receipt = GrowProposalReceiptV1(proposal: proposal, candidateSceneSHA256: "candidate")
    let document = SceneLibraryDocumentV1(sceneJSON: DemoScene.gestureJSON, acceptedGrowReceipts: [receipt])
    let data = try JSONEncoder().encode(document)
    XCTAssertEqual(try JSONDecoder().decode(SceneLibraryDocumentV1.self, from: data).acceptedGrowReceipts, [receipt])
    let legacy = "{\"schemaVersion\":\"latticewake-library-v1\",\"sceneJSON\":\"{}\",\"performance\":{\"gestureGlideSemitones\":12,\"pointerNote\":48,\"roleTransportEnabled\":false}}"
    XCTAssertTrue(try JSONDecoder().decode(SceneLibraryDocumentV1.self, from: Data(legacy.utf8)).acceptedGrowReceipts.isEmpty)
  }

  func testSceneV1MigrationIsDeterministicAndLoadable() throws {
    let source = Data(DemoScene.fourRoleJSON.utf8)
    let first = try SceneDocumentBridge.canonicalV1(from: source)
    let repeated = try SceneDocumentBridge.canonicalV1(from: source)
    XCTAssertEqual(first, repeated)
    XCTAssertTrue(String(decoding: first, as: UTF8.self).contains("\"latticewake-scene-v1\""))

    let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("scene.latticewake.json")
    let document = SceneLibraryDocumentV1(sceneJSON: String(decoding: first, as: UTF8.self))
    _ = try SceneLibrary.save(document, to: url)
    let loaded = try SceneLibrary.load(from: url)
    XCTAssertEqual(loaded.sceneBytes, first)
  }

  func testSceneEditorMigratesExplicitlyAndRoundTripsControls() throws {
    let legacy = Data(DemoScene.gestureJSON.utf8)
    let baseline = try SceneEditorBridge.controls(from: legacy)
    XCTAssertEqual(baseline.attackSeconds, 0.010)
    var edited = baseline
    edited.terrainZoom = 0
    edited.traversalRateRatio = 1
    edited.traversalRadiusY = 0.2
    edited.attackSeconds = 0.04
    edited.releaseSeconds = 0.24
    edited.gain = 0.5
    let applied = try SceneEditorBridge.apply(edited, to: legacy)
    XCTAssertTrue(String(decoding: applied, as: UTF8.self).contains("\"latticewake-scene-v1\""))
    XCTAssertEqual(try SceneEditorBridge.controls(from: applied), edited)
  }

  func testModulationControlsMigrateAndRoundTrip() throws {
    var controls = try ModulationBridge.controls(from: Data(DemoScene.gestureJSON.utf8))
    XCTAssertTrue(controls.pitchEnabled && controls.timbreEnabled && controls.gainEnabled)
    controls.pitchDepth = 0.5
    controls.timbreEnabled = false
    controls.timbreDepth = 0
    controls.gainDepth = -0.25
    let applied = try ModulationBridge.apply(controls, to: Data(DemoScene.gestureJSON.utf8))
    XCTAssertTrue(String(decoding: applied, as: UTF8.self).contains("\"gesture-x\""))
    XCTAssertEqual(try ModulationBridge.controls(from: applied), controls)
  }

  func testComponentPresetsAreDeterministicAndScoped() {
    let base = SceneEditorControls()
    let surface = SceneEditorPreset.luminousBasin.applying(to: base)
    XCTAssertNotEqual(surface.terrainDetail, base.terrainDetail)
    XCTAssertEqual(surface.attackSeconds, base.attackSeconds)
    let traversal = SceneEditorPreset.orbitingRidge.applying(to: base)
    XCTAssertNotEqual(traversal.traversalRadiusX, base.traversalRadiusX)
    XCTAssertEqual(traversal.terrainDetail, base.terrainDetail)
    XCTAssertEqual(SceneEditorPreset.softArrival.applying(to: base), SceneEditorPreset.softArrival.applying(to: base))
  }
  func testGrowProposalIsDeterministicAndHonorsFreeze() {
    let base = SceneEditorControls(); let frozen = FrozenComponents(surface: true, traversal: false, articulation: true)
    let first = GrowEngine.propose(base: base, sceneHash: "abc", depth: .related, frozen: frozen)
    XCTAssertEqual(first, GrowEngine.propose(base: base, sceneHash: "abc", depth: .related, frozen: frozen))
    XCTAssertEqual(first.candidate.terrainDetail, base.terrainDetail); XCTAssertEqual(first.candidate.attackSeconds, base.attackSeconds)
    XCTAssertNotEqual(first.candidate.traversalRadiusX, base.traversalRadiusX)
  }

  func testSceneLibraryRejectsInvalidEmbeddedSceneAndPerformance() throws {
    let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }

    let invalidSceneURL = directory.appendingPathComponent("invalid-scene.latticewake.json")
    XCTAssertThrowsError(try SceneLibrary.save(SceneLibraryDocumentV1(sceneJSON: "{}"), to: invalidSceneURL))

    let invalidPerformanceURL = directory.appendingPathComponent("invalid-performance.latticewake.json")
    let invalidPerformance = PerformanceSettingsV1(gestureGlideSemitones: 25, pointerNote: 48, roleTransportEnabled: false)
    XCTAssertThrowsError(try SceneLibrary.save(SceneLibraryDocumentV1(sceneJSON: DemoScene.fourRoleJSON,
                                                                       performance: invalidPerformance), to: invalidPerformanceURL))
  }

  func testSceneLibraryRejectsInvalidEmbeddedSceneOnLoad() throws {
    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    let invalid = """
    {"schemaVersion":"latticewake-library-v1","sceneJSON":"{}","performance":{"gestureGlideSemitones":12,"pointerNote":48,"roleTransportEnabled":false}}
    """
    _ = try SceneStore.saveCanonical(Data(invalid.utf8), to: url)
    XCTAssertThrowsError(try SceneLibrary.load(from: url))
  }

  func testSceneLibraryDoesNotDowngradeMalformedLibraryEnvelopeToLegacy() throws {
    let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
    defer { try? FileManager.default.removeItem(at: url) }
    let malformed = """
    {"schemaVersion":"latticewake-library-v1","sceneJSON":"{}"}
    """
    _ = try SceneStore.saveCanonical(Data(malformed.utf8), to: url)
    XCTAssertThrowsError(try SceneLibrary.load(from: url))
  }

  func testSceneUndoIsBoundedAndRestoresPrecedingBytes() {
  var history = SceneUndoHistory()
  let first = Data("first".utf8), second = Data("second".utf8)
  history.record(first, acceptedGrowReceipts: []); history.record(first, acceptedGrowReceipts: []); history.record(second, acceptedGrowReceipts: [])
  XCTAssertEqual(history.undo()?.sceneBytes, second)
  XCTAssertEqual(history.undo()?.sceneBytes, first)
  XCTAssertNil(history.undo())
}

  func testOfflineCaptureWritesBoundSceneReceipt() throws {
  let directory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString, isDirectory: true)
  defer { try? FileManager.default.removeItem(at: directory) }
  let bytes = Data(DemoScene.fourRoleJSON.utf8)
  let (url, receipt) = try OfflineCapture.render(sceneBytes: bytes, to: directory)
  let wav = try Data(contentsOf: url)
  let receiptData = try Data(contentsOf: url.appendingPathExtension("receipt.json"))
  let savedReceipt = try JSONDecoder().decode(CaptureReceiptV1.self, from: receiptData)
  XCTAssertEqual(wav.prefix(4), Data("RIFF".utf8))
  XCTAssertEqual(receipt.sceneSHA256, SceneLibrary.receipt(for: bytes).sha256)
  XCTAssertTrue(receipt.frameCount == 384_000 && receipt.roleTransport)
  XCTAssertEqual(savedReceipt, receipt)
}

  func testRoleTracePreviewIsDeterministic() throws {
  let bytes = Data(DemoScene.canonicalJSON.utf8)
  let first = try RoleTraceBridge.preview(sceneBytes: bytes)
  let repeated = try RoleTraceBridge.preview(sceneBytes: bytes)
  XCTAssertEqual(first, repeated)
  XCTAssertGreaterThan(first.eventCount, 0)
}

  func testAuditionReceiptIsStructuredAndStable() {
  let receipt = AuditionReceipt(sampleRate: 48_000, callbackCount: 12,
                                renderedFrames: 6_144, maximumRenderNanoseconds: 123_000,
                                deadlineMisses: 0, rejectedBlocks: 0)
  XCTAssertEqual(receipt.machineLine, "LW_AUDITION_RECEIPT sample_rate=48000.0 callbacks=12 frames=6144 max_render_ns=123000 deadline_misses=0 rejected_blocks=0")
  XCTAssertTrue(receipt.statusText.contains("48000 Hz"))
  XCTAssertTrue(receipt.fileContents.hasSuffix("\n"))
  }
}
