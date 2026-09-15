import CoreGraphics
import Foundation

enum PerformanceInputSource: Hashable, Sendable {
  case keyboard
  case pointer
  case midi(channel: Int)

  var token: UInt32 {
    switch self {
    case .keyboard: return 1
    case .pointer: return 3
    case let .midi(channel): return UInt32(16 + min(16, max(1, channel)))
    }
  }

  var label: String {
    switch self {
    case .keyboard: return "Key"
    case .pointer: return "Pointer"
    case let .midi(channel): return "MIDI ch \(channel)"
    }
  }
}

struct PerformanceVoice: Identifiable, Equatable {
  let source: PerformanceInputSource
  let note: Int
  let age: UInt64
  var glide: Double
  var press: Double
  var slide: Double

  var id: String { "\(source.token):\(note)" }
  var label: String { "\(source.label) \(note)" }
}

private struct PerformanceVoiceKey: Hashable {
  let source: PerformanceInputSource
  let note: Int
}

// The sole Swift-side producer of direct-performance events. All calls occur
// on the main actor; the bridge remains the one SPSC queue producer observed by
// the audio callback. Roles are prepared inside the portable callback path.
@MainActor final class PerformanceInputMultiplexer: ObservableObject {
  @Published private(set) var heldNotes: Set<Int> = []
  @Published private(set) var pointerPosition: CGPoint?
  @Published private(set) var pointerNote: Int?
  @Published private(set) var voices: [PerformanceVoice] = []
  @Published private(set) var status = "Input ready"
  @Published private(set) var overflowRecoveries = 0

  private weak var audio: LatticewakeAudio?
  private var keyboard = KeyboardState()
  private var gesture = GestureState()
  private var voiceMap: [PerformanceVoiceKey: PerformanceVoice] = [:]
  private var nextAge: UInt64 = 0

  func attach(audio: LatticewakeAudio) { self.audio = audio }

  func keyboardDown(note: Int) {
    guard keyboard.down(note) else { return }
    heldNotes = keyboard.held
    noteOn(note: note, velocity: 0.7, source: .keyboard)
  }

  func keyboardUp(note: Int) {
    guard keyboard.up(note) else { return }
    heldNotes = keyboard.held
    noteOff(note: note, source: .keyboard)
  }

  func gestureChanged(location: CGPoint, size: CGSize, pointerNote defaultPointerNote: Int) {
    guard size.width > 0, size.height > 0 else { return }
    if let note = gesture.begin(held: keyboard.held, pointerNote: defaultPointerNote) {
      noteOn(note: note, velocity: 0.7, source: .pointer)
    }
    let x = GestureState.normalized(location.x, length: size.width)
    let y = GestureState.normalized(location.y, length: size.height)
    pointerPosition = CGPoint(x: x * size.width, y: y * size.height)
    pointerNote = gesture.pointerNote
    for note in gesture.targets {
      let source: PerformanceInputSource = note == gesture.pointerNote ? .pointer : .keyboard
      expression(note: note, source: source, glide: 2 * x - 1, press: 1, slide: 1 - y)
    }
  }

  func endGesture() {
    let ended = gesture.end()
    if let note = ended.note { noteOff(note: note, source: .pointer) }
    for note in ended.targets where note != ended.note {
      expression(note: note, source: .keyboard, glide: 0, press: 1, slide: 0)
    }
    pointerPosition = nil
    pointerNote = nil
  }

  func focusLost() {
    endGesture()
    for note in keyboard.releaseAll() { noteOff(note: note, source: .keyboard) }
    heldNotes = keyboard.held
  }

  func midiNoteOn(note: Int, velocity: Double, channel: Int) {
    noteOn(note: note, velocity: velocity, source: .midi(channel: channel))
  }

  func midiNoteOff(note: Int, channel: Int) {
    noteOff(note: note, source: .midi(channel: channel))
  }

  func midiExpression(note: Int, channel: Int, glide: Double, press: Double, slide: Double) {
    expression(note: note, source: .midi(channel: channel), glide: glide, press: press, slide: slide)
  }

  func panic(reason: String) {
    _ = audio?.panic()
    clearDisplayState()
    status = "Panic: \(reason)"
  }

  func audioStopped() {
    clearDisplayState()
    status = "Input ready"
  }

  private func noteOn(note: Int, velocity: Double, source: PerformanceInputSource) {
    guard (0...127).contains(note), let audio, audio.running else { return }
    guard audio.enqueueNoteOn(note: note, velocity: velocity, source: source.token) else {
      recoverOverflow(); return
    }
    let key = PerformanceVoiceKey(source: source, note: note)
    guard voiceMap[key] == nil else { return }
    voiceMap[key] = PerformanceVoice(source: source, note: note, age: nextAge,
                                     glide: 0, press: 1, slide: 0)
    nextAge &+= 1
    publishVoices()
    status = "\(source.label) note \(note)"
  }

  private func noteOff(note: Int, source: PerformanceInputSource) {
    let key = PerformanceVoiceKey(source: source, note: note)
    guard let audio, audio.running else { voiceMap.removeValue(forKey: key); publishVoices(); return }
    guard audio.enqueueNoteOff(note: note, source: source.token) else {
      recoverOverflow(); return
    }
    voiceMap.removeValue(forKey: key)
    publishVoices()
  }

  private func expression(note: Int, source: PerformanceInputSource, glide: Double, press: Double, slide: Double) {
    let key = PerformanceVoiceKey(source: source, note: note)
    guard voiceMap[key] != nil, let audio, audio.running else { return }
    guard audio.enqueueExpression(note: note, source: source.token, glide: glide, press: press, slide: slide) else {
      recoverOverflow(); return
    }
    voiceMap[key]?.glide = glide
    voiceMap[key]?.press = press
    voiceMap[key]?.slide = slide
    publishVoices()
  }

  private func recoverOverflow() {
    overflowRecoveries &+= 1
    _ = audio?.panic()
    clearDisplayState()
    status = "Input queue overload recovered"
  }

  private func clearDisplayState() {
    keyboard = KeyboardState()
    _ = gesture.end()
    heldNotes = []
    pointerPosition = nil
    pointerNote = nil
    voiceMap.removeAll()
    voices = []
  }

  private func publishVoices() {
    voices = voiceMap.values.sorted { $0.age < $1.age }
  }
}
