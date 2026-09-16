import Foundation
import SwiftUI

enum GrowDepth: String, CaseIterable, Identifiable { case subtle = "Subtle", related = "Related", exploratory = "Exploratory"; var id: String { rawValue }
  var amplitude: Double { switch self { case .subtle: 0.08; case .related: 0.20; case .exploratory: 0.36 } }
}
struct FrozenComponents: Equatable { var surface = false; var traversal = false; var articulation = false }
struct GrowProposal: Identifiable, Equatable { let id: String; let baseSceneHash: String; let seed: UInt64; let depth: GrowDepth; let frozen: FrozenComponents; let candidate: SceneEditorControls; let changed: [String] }

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
    var seed: UInt64 = 14695981039346656037
    for byte in sceneHash.utf8 { seed = (seed ^ UInt64(byte)) &* 1099511628211 }
    seed ^= UInt64(depth.rawValue.utf8.reduce(0, { $0 &+ UInt64($1) }))
    var state = seed
    func delta(_ amount: Double) -> Double { state = state &* 6364136223846793005 &+ 1442695040888963407; return (Double(state >> 11) / Double(UInt64.max >> 11) * 2 - 1) * amount }
    func bounded(_ value: Double, _ range: ClosedRange<Double>) -> Double { min(range.upperBound, max(range.lowerBound, value)) }
    var candidate = base; var changed: [String] = []
    if !frozen.surface { candidate.terrainDetail = bounded(base.terrainDetail + delta(depth.amplitude), 0...1); candidate.terrainZoom = bounded(base.terrainZoom + delta(depth.amplitude), 0...1); changed.append("Surface") }
    if !frozen.traversal { candidate.traversalRadiusX = bounded(base.traversalRadiusX + delta(depth.amplitude), 0...1); candidate.traversalRadiusY = bounded(base.traversalRadiusY + delta(depth.amplitude), 0...1); candidate.traversalTranslationX = bounded(base.traversalTranslationX + delta(depth.amplitude), 0...1); changed.append("Traversal") }
    if !frozen.articulation { candidate.attackSeconds = bounded(base.attackSeconds + delta(depth.amplitude * 0.3), 0.001...1); candidate.releaseSeconds = bounded(base.releaseSeconds + delta(depth.amplitude), 0.001...2); candidate.gain = bounded(base.gain + delta(depth.amplitude), 0...1.5); changed.append("Articulation") }
    return GrowProposal(id: "local-\(seed)", baseSceneHash: sceneHash, seed: seed, depth: depth, frozen: frozen, candidate: candidate, changed: changed)
  }
}

struct GrowControlsView: View {
  @Binding var depth: GrowDepth; @Binding var frozen: FrozenComponents
  let proposal: GrowProposal?; let generate: () -> Void; let preview: () -> Void; let accept: () -> Void; let reject: () -> Void
  var body: some View { VStack(alignment: .leading, spacing: 6) {
    Text("Freeze & Grow").font(.caption.bold()).foregroundStyle(.mint)
    Picker("Depth", selection: $depth) { ForEach(GrowDepth.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
    Toggle("Freeze Surface", isOn: $frozen.surface); Toggle("Freeze Traversal", isOn: $frozen.traversal); Toggle("Freeze Articulation", isOn: $frozen.articulation)
    Button("Generate Local Variation", action: generate).buttonStyle(.borderedProminent)
    if let proposal { Text("\(proposal.id) • \(proposal.changed.isEmpty ? "no mutable components" : proposal.changed.joined(separator: ", "))").font(.caption2).foregroundStyle(.secondary); HStack { Button("Preview", action: preview); Button("Accept", action: accept); Button("Reject", action: reject) }.buttonStyle(.bordered) }
  } }
}
