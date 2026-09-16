import Foundation

/// A bounded, preview-only contract for local or external creative providers.
/// Parsing or validating one never changes a scene, a library document, or the
/// audio callback; the caller must still explicitly choose Preview or Accept.
enum ProposalPatchField: String, Codable, CaseIterable {
  case terrainDetail, terrainZoom
  case traversalRadiusX, traversalRadiusY, traversalTranslationX
  case attackSeconds, releaseSeconds, gain

  var component: String {
    switch self {
    case .terrainDetail, .terrainZoom: "Surface"
    case .traversalRadiusX, .traversalRadiusY, .traversalTranslationX: "Traversal"
    case .attackSeconds, .releaseSeconds, .gain: "Articulation"
    }
  }

  var range: ClosedRange<Double> {
    switch self {
    case .terrainDetail, .terrainZoom, .traversalRadiusX, .traversalRadiusY, .traversalTranslationX: 0...1
    case .attackSeconds: 0.001...1
    case .releaseSeconds: 0.001...2
    case .gain: 0...1.5
    }
  }
}

struct ProposalPatchV1: Codable, Equatable {
  let field: ProposalPatchField
  let value: Double
}

struct ScenePatchProposalV1: Codable, Equatable, Identifiable {
  static let schema = "latticewake-proposal-v1"
  let schemaVersion: String
  let proposalID: String
  let provider: String
  let baseSceneSHA256: String
  let frozenComponents: [String]
  let patches: [ProposalPatchV1]
  var id: String { proposalID }
}

enum ProposalContractError: LocalizedError, Equatable {
  case schema, identity(String), baseScene, frozenState, patchCount, duplicateField, invalidValue(String), frozenField(String)
  var errorDescription: String? {
    switch self {
    case .schema: "Unsupported proposal schema"
    case .identity(let field): "Invalid proposal \(field)"
    case .baseScene: "Proposal was generated for a different scene"
    case .frozenState: "Proposal freeze state does not match the active Freeze and Grow boundary"
    case .patchCount: "A proposal must contain 1 to 16 patches"
    case .duplicateField: "A proposal may patch each field only once"
    case .invalidValue(let field): "Invalid value for \(field)"
    case .frozenField(let component): "Proposal tries to change frozen \(component)"
    }
  }
}

enum ProposalContractV1 {
  static func decode(_ bytes: Data) throws -> ScenePatchProposalV1 {
    try JSONDecoder().decode(ScenePatchProposalV1.self, from: bytes)
  }

  static func validatedCandidate(_ proposal: ScenePatchProposalV1, base: SceneEditorControls,
                                 sceneHash: String, frozen: FrozenComponents) throws -> SceneEditorControls {
    guard proposal.schemaVersion == ScenePatchProposalV1.schema else { throw ProposalContractError.schema }
    guard validIdentity(proposal.proposalID) else { throw ProposalContractError.identity("id") }
    guard validIdentity(proposal.provider) else { throw ProposalContractError.identity("provider") }
    guard proposal.baseSceneSHA256 == sceneHash else { throw ProposalContractError.baseScene }
    guard Set(proposal.frozenComponents) == frozen.names else { throw ProposalContractError.frozenState }
    guard (1...16).contains(proposal.patches.count) else { throw ProposalContractError.patchCount }
    var candidate = base; var fields = Set<ProposalPatchField>()
    for patch in proposal.patches {
      guard fields.insert(patch.field).inserted else { throw ProposalContractError.duplicateField }
      guard patch.value.isFinite, patch.field.range.contains(patch.value) else { throw ProposalContractError.invalidValue(patch.field.rawValue) }
      guard !frozen.names.contains(patch.field.component) else { throw ProposalContractError.frozenField(patch.field.component) }
      switch patch.field {
      case .terrainDetail: candidate.terrainDetail = patch.value
      case .terrainZoom: candidate.terrainZoom = patch.value
      case .traversalRadiusX: candidate.traversalRadiusX = patch.value
      case .traversalRadiusY: candidate.traversalRadiusY = patch.value
      case .traversalTranslationX: candidate.traversalTranslationX = patch.value
      case .attackSeconds: candidate.attackSeconds = patch.value
      case .releaseSeconds: candidate.releaseSeconds = patch.value
      case .gain: candidate.gain = patch.value
      }
    }
    return candidate
  }

  private static func validIdentity(_ value: String) -> Bool {
    !value.isEmpty && value.count <= 128 && value.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == "." }
  }
}

extension FrozenComponents {
  var names: Set<String> {
    [surface ? "Surface" : nil, traversal ? "Traversal" : nil, articulation ? "Articulation" : nil].compactMap { $0 }.reduce(into: Set<String>()) { $0.insert($1) }
  }
}
