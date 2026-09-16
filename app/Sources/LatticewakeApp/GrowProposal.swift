import Foundation
import SwiftUI

enum GrowDepth: String, CaseIterable, Identifiable { case subtle = "Subtle", related = "Related", exploratory = "Exploratory"; var id: String { rawValue }
  var amplitude: Double { switch self { case .subtle: 0.08; case .related: 0.20; case .exploratory: 0.36 } }
}
struct FrozenComponents: Equatable { var surface = false; var traversal = false; var articulation = false }
struct GrowProposal: Identifiable, Equatable {
  let id: String
  let baseSceneHash: String
  let seed: UInt64
  /// A deterministic position in a small candidate set. It is not a score or
  /// ranking: artists choose whether any candidate is worth accepting.
  let variationIndex: Int
  let depth: GrowDepth
  let frozen: FrozenComponents
  let candidate: SceneEditorControls
  let changed: [String]
}

struct GrowProposalReceiptV1: Codable, Equatable, Identifiable {
  static let schema = "latticewake-grow-receipt-v1"
  let schemaVersion: String
  let proposalID: String
  let provider: String
  let baseSceneSHA256: String
  let candidateSceneSHA256: String
  let seed: UInt64
  let depth: String
  let frozenComponents: [String]
  let changedComponents: [String]
  var id: String { proposalID }

  init(proposal: GrowProposal, candidateSceneSHA256: String) {
    schemaVersion = Self.schema
    proposalID = proposal.id
    provider = "local-freeze-grow-v1"
    baseSceneSHA256 = proposal.baseSceneHash
    self.candidateSceneSHA256 = candidateSceneSHA256
    seed = proposal.seed
    depth = proposal.depth.rawValue
    frozenComponents = [proposal.frozen.surface ? "Surface" : nil, proposal.frozen.traversal ? "Traversal" : nil, proposal.frozen.articulation ? "Articulation" : nil].compactMap { $0 }
    changedComponents = proposal.changed
  }
}

enum GrowEngine {
  static func propose(base: SceneEditorControls, sceneHash: String, depth: GrowDepth, frozen: FrozenComponents) -> GrowProposal {
    proposeVariants(base: base, sceneHash: sceneHash, depth: depth, frozen: frozen, count: 1)[0]
  }

  /// Produces a deliberately small, repeatable local exploration set. This is
  /// not a recommender: order is stable only so the artist can revisit a
  /// candidate, and no candidate receives an aesthetic score.
  static func proposeVariants(base: SceneEditorControls, sceneHash: String, depth: GrowDepth,
                              frozen: FrozenComponents, count: Int = 3) -> [GrowProposal] {
    guard (1...4).contains(count) else { return [] }
    guard !frozen.surface || !frozen.traversal || !frozen.articulation else { return [] }
    return (0..<count).map { variationIndex in
      propose(base: base, sceneHash: sceneHash, depth: depth, frozen: frozen, variationIndex: variationIndex)
    }
  }

  private static func propose(base: SceneEditorControls, sceneHash: String, depth: GrowDepth,
                              frozen: FrozenComponents, variationIndex: Int) -> GrowProposal {
    var seed: UInt64 = 14695981039346656037
    for byte in sceneHash.utf8 { seed = (seed ^ UInt64(byte)) &* 1099511628211 }
    seed ^= UInt64(depth.rawValue.utf8.reduce(0, { $0 &+ UInt64($1) }))
    // Mix the bounded candidate position before deriving values, so each
    // proposal has its own stable seed while preserving all freeze boundaries.
    seed ^= UInt64(variationIndex + 1) &* 0x9e3779b97f4a7c15
    var state = seed
    func delta(_ amount: Double) -> Double { state = state &* 6364136223846793005 &+ 1442695040888963407; return (Double(state >> 11) / Double(UInt64.max >> 11) * 2 - 1) * amount }
    func bounded(_ value: Double, _ range: ClosedRange<Double>) -> Double { min(range.upperBound, max(range.lowerBound, value)) }
    var candidate = base; var changed: [String] = []
    if !frozen.surface { candidate.terrainDetail = bounded(base.terrainDetail + delta(depth.amplitude), 0...1); candidate.terrainZoom = bounded(base.terrainZoom + delta(depth.amplitude), 0...1); changed.append("Surface") }
    if !frozen.traversal { candidate.traversalRadiusX = bounded(base.traversalRadiusX + delta(depth.amplitude), 0...1); candidate.traversalRadiusY = bounded(base.traversalRadiusY + delta(depth.amplitude), 0...1); candidate.traversalTranslationX = bounded(base.traversalTranslationX + delta(depth.amplitude), 0...1); changed.append("Traversal") }
    if !frozen.articulation { candidate.attackSeconds = bounded(base.attackSeconds + delta(depth.amplitude * 0.3), 0.001...1); candidate.releaseSeconds = bounded(base.releaseSeconds + delta(depth.amplitude), 0.001...2); candidate.gain = bounded(base.gain + delta(depth.amplitude), 0...1.5); changed.append("Articulation") }
    return GrowProposal(id: "local-\(seed)", baseSceneHash: sceneHash, seed: seed,
                        variationIndex: variationIndex, depth: depth, frozen: frozen,
                        candidate: candidate, changed: changed)
  }
}

struct GrowControlsView: View {
  @Binding var depth: GrowDepth; @Binding var frozen: FrozenComponents
  let proposals: [GrowProposal]
  @Binding var selectedProposalID: String?
  let generate: () -> Void
  let preview: (GrowProposal) -> Void
  let accept: (GrowProposal) -> Void
  let reject: () -> Void
  var body: some View { VStack(alignment: .leading, spacing: 6) {
    Text("Freeze & Grow").font(.caption.bold()).foregroundStyle(.mint)
    Picker("Depth", selection: $depth) { ForEach(GrowDepth.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
    Toggle("Freeze Surface", isOn: $frozen.surface); Toggle("Freeze Traversal", isOn: $frozen.traversal); Toggle("Freeze Articulation", isOn: $frozen.articulation)
    Button("Generate 3 Local Variations", action: generate).buttonStyle(.borderedProminent)
    if proposals.isEmpty == false {
      Text("A small deterministic set — none is ranked or saved.").font(.caption2).foregroundStyle(.secondary)
      ForEach(proposals) { proposal in
        let selected = selectedProposalID == proposal.id
        VStack(alignment: .leading, spacing: 3) {
          HStack {
            Button { selectedProposalID = proposal.id } label: {
              Label("Variation \(proposal.variationIndex + 1)", systemImage: selected ? "checkmark.circle.fill" : "circle")
            }.buttonStyle(.plain)
            Spacer()
            Text(proposal.changed.joined(separator: ", ")).font(.caption2).foregroundStyle(.secondary)
          }
          if selected {
            HStack { Button("Preview") { preview(proposal) }; Button("Accept") { accept(proposal) }; Button("Reject all", action: reject) }.buttonStyle(.bordered)
          }
        }.padding(5).background(selected ? Color.mint.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 5))
      }
    }
  } }
}
