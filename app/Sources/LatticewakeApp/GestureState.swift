struct GestureState {
  private(set) var targets: [Int] = []
  private(set) var pointerNote: Int?
  private(set) var active = false
  mutating func begin(held: Set<Int>, pointerNote: Int = 48) -> Int? {
    guard !active else { return nil }
    active = true
    // Pointer C3 is outside the displayed keyboard's C4–C5 range.
    let normalizedPointer = min(127, max(0, pointerNote))
    self.pointerNote = held.isEmpty ? normalizedPointer : nil
    targets = held.isEmpty ? [normalizedPointer] : held.sorted()
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
