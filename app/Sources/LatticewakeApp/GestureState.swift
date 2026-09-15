struct GestureState {
  private(set) var targets: [Int] = []
  private(set) var pointerNote: Int?
  private(set) var active = false
  mutating func begin(held: Set<Int>) -> Int? {
    guard !active else { return nil }
    active = true
    // Pointer C3 is outside the displayed keyboard's C4–C5 range.
    pointerNote = held.isEmpty ? 48 : nil
    targets = held.isEmpty ? [48] : held.sorted()
    return pointerNote
  }
  mutating func end() -> (note: Int?, targets: [Int]) {
    let result = (pointerNote, targets)
    active = false; pointerNote = nil; targets = []
    return result
  }
  static func normalized(_ coordinate: Double, length: Double) -> Double {
    guard coordinate.isFinite, length.isFinite, length > 0 else { return 0.5 }
    return min(1, max(0, coordinate / length))
  }
}
