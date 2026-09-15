import CoreMIDI
import Foundation

enum LatticewakeMpeMode: String, CaseIterable, Identifiable {
  case legacy = "Legacy"
  case lower = "MPE Lower"
  case upper = "MPE Upper"
  var id: String { rawValue }
  var bridgeMode: UInt32 {
    switch self { case .legacy: return 0; case .lower: return 1; case .upper: return 2 }
  }
  var masterChannel: Int32 { self == .upper ? 16 : 1 }
  var memberCount: Int32 { self == .legacy ? 1 : 15 }
}

struct MIDIMessage: Sendable, Equatable {
  let status: UInt8
  let data1: UInt8
  let data2: UInt8
}

enum MIDIMessageDecoder {
  static func decode(_ bytes: [UInt8]) -> [MIDIMessage] {
    var messages: [MIDIMessage] = []
    var index = 0
    while index < bytes.count {
      let status = bytes[index]
      guard status >= 0x80 else { index += 1; continue }
      let type = status & 0xF0
      let length = (type == 0xC0 || type == 0xD0) ? 2 : 3
      guard type >= 0x80, type <= 0xE0, index + length <= bytes.count else {
        index += 1
        continue
      }
      messages.append(MIDIMessage(status: status, data1: bytes[index + 1],
                                  data2: length == 3 ? bytes[index + 2] : 0))
      index += length
    }
    return messages
  }
}

@_silgen_name("lw_mpe_state_create") private func lw_mpe_state_create(
  _ mode: UInt32, _ masterChannel: Int32, _ memberCount: Int32
) -> OpaquePointer?
@_silgen_name("lw_mpe_state_destroy") private func lw_mpe_state_destroy(_ state: OpaquePointer)
@_silgen_name("lw_mpe_note_on") private func lw_mpe_note_on(_ state: OpaquePointer, _ channel: Int32, _ note: Int32) -> Int32
@_silgen_name("lw_mpe_note_off") private func lw_mpe_note_off(_ state: OpaquePointer, _ channel: Int32, _ note: Int32) -> Int32
@_silgen_name("lw_mpe_expression") private func lw_mpe_expression(_ state: OpaquePointer, _ channel: Int32, _ glide: Float, _ press: Float, _ slide: Float) -> Int32
@_silgen_name("lw_mpe_active_note") private func lw_mpe_active_note(_ state: OpaquePointer, _ channel: Int32, _ note: UnsafeMutablePointer<Int32>) -> Int32
@_silgen_name("lw_mpe_reset") private func lw_mpe_reset(_ state: OpaquePointer)

@MainActor final class MIDIIngress: ObservableObject {
  @Published private(set) var sourceCount = 0
  @Published private(set) var status = "MIDI inactive"
  @Published private(set) var mode: LatticewakeMpeMode = .legacy

  private weak var audio: LatticewakeAudio?
  private var client = MIDIClientRef()
  private var port = MIDIPortRef()
  private var mpe: OpaquePointer?
  private var connectedSources = Set<MIDIEndpointRef>()
  private var sustain = Set<Int>()
  private var deferredReleases: [(channel: Int, note: Int)] = []

  func stop() {
    if let mpe { lw_mpe_state_destroy(mpe) }
    mpe = nil
    if port != 0 { MIDIPortDispose(port) }
    port = 0
    if client != 0 { MIDIClientDispose(client) }
    client = 0
    connectedSources.removeAll()
    sourceCount = 0
  }

  func start(audio: LatticewakeAudio) {
    guard client == 0 else { return }
    self.audio = audio
    configure(mode: .legacy)
    guard MIDIClientCreateWithBlock("Latticewake MIDI" as CFString, &client, { [weak self] _ in
      Task { @MainActor [weak self] in self?.refreshSources() }
    }) == noErr else { status = "MIDI client unavailable"; return }
    guard MIDIInputPortCreateWithBlock(client, "Latticewake Input" as CFString, &port, { [weak self] packetList, _ in
      let messages = Self.messages(from: packetList)
      Task { @MainActor [weak self] in self?.receive(messages) }
    }) == noErr else { status = "MIDI input unavailable"; return }
    refreshSources()
  }

  func configure(mode: LatticewakeMpeMode) {
    if mpe != nil { panic() }
    if let mpe { lw_mpe_state_destroy(mpe) }
    mpe = lw_mpe_state_create(mode.bridgeMode, mode.masterChannel, mode.memberCount)
    self.mode = mode
    sustain.removeAll()
    deferredReleases.removeAll()
    status = mpe == nil ? "MIDI configuration unavailable" : "MIDI \(mode.rawValue)"
  }

  func panic() {
    if let mpe { lw_mpe_reset(mpe) }
    sustain.removeAll()
    deferredReleases.removeAll()
    audio?.midiPanic()
    status = "MIDI panic"
  }

  private func refreshSources() {
    guard port != 0 else { return }
    let previousCount = connectedSources.count
    for source in connectedSources { MIDIPortDisconnectSource(port, source) }
    connectedSources.removeAll()
    for index in 0..<MIDIGetNumberOfSources() {
      let source = MIDIGetSource(index)
      if MIDIPortConnectSource(port, source, nil) == noErr { connectedSources.insert(source) }
    }
    sourceCount = connectedSources.count
    if previousCount > 0 && sourceCount == 0 { panic() }
    else if mpe != nil { status = sourceCount == 0 ? "MIDI waiting for source" : "MIDI \(mode.rawValue): \(sourceCount) source" }
  }

  private func receive(_ messages: [MIDIMessage]) {
    for message in messages { receive(message) }
  }

  func receive(_ message: MIDIMessage) {
    guard let mpe else { return }
    let channel = Int(message.status & 0x0F) + 1
    switch message.status & 0xF0 {
    case 0x90 where message.data2 > 0:
      if lw_mpe_note_on(mpe, Int32(channel), Int32(message.data1)) != 0 {
        _ = audio?.midiPlay(note: Int(message.data1), velocity: Double(message.data2) / 127.0)
      }
    case 0x80, 0x90:
      if sustain.contains(channel) { deferredReleases.append((channel, Int(message.data1))) }
      else { release(channel: channel, note: Int(message.data1)) }
    case 0xE0:
      let bend = (Int(message.data2) << 7) | Int(message.data1)
      applyExpression(channel: channel, glide: Double(bend - 8192) / 8192.0, press: 1, slide: 0)
    case 0xD0:
      applyExpression(channel: channel, glide: 0, press: Double(message.data1) / 127.0, slide: 0)
    case 0xB0 where message.data1 == 74:
      applyExpression(channel: channel, glide: 0, press: 1, slide: Double(message.data2) / 127.0)
    case 0xB0 where message.data1 == 64:
      if message.data2 >= 64 { sustain.insert(channel) }
      else {
        sustain.remove(channel)
        let releases = deferredReleases.filter { $0.channel == channel }
        deferredReleases.removeAll { $0.channel == channel }
        for release in releases { self.release(channel: release.channel, note: release.note) }
      }
    default: break
    }
  }

  private func release(channel: Int, note: Int) {
    guard let mpe, lw_mpe_note_off(mpe, Int32(channel), Int32(note)) != 0 else { return }
    _ = audio?.midiRelease(note: note)
  }

  private func applyExpression(channel: Int, glide: Double, press: Double, slide: Double) {
    guard let mpe, lw_mpe_expression(mpe, Int32(channel), Float(glide), Float(press), Float(slide)) != 0 else { return }
    var note: Int32 = 0
    guard lw_mpe_active_note(mpe, Int32(channel), &note) != 0 else { return }
    audio?.midiNoteExpression(note: Int(note), glide: glide, press: press, slide: slide)
  }

  nonisolated private static func messages(from list: UnsafePointer<MIDIPacketList>) -> [MIDIMessage] {
    var result: [MIDIMessage] = []
    var packet = withUnsafePointer(to: list.pointee.packet) { $0 }
    for _ in 0..<Int(list.pointee.numPackets) {
      let bytes = withUnsafeBytes(of: packet.pointee.data) { Array($0.prefix(Int(packet.pointee.length))) }
      result.append(contentsOf: MIDIMessageDecoder.decode(bytes))
      packet = UnsafePointer(MIDIPacketNext(packet))
    }
    return result
  }
}
