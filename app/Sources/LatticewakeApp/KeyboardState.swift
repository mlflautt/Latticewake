struct KeyboardState {
  private(set) var held: Set<Int> = []
  static let notes = ["a":60,"w":61,"s":62,"e":63,"d":64,"f":65,"t":66,"g":67,"y":68,"h":69,"u":70,"j":71,"k":72]
  mutating func down(_ note: Int) -> Bool { held.insert(note).inserted }
  mutating func up(_ note: Int) -> Bool { held.remove(note) != nil }
  mutating func releaseAll() -> [Int] { let notes = held.sorted(); held.removeAll(); return notes }
}
