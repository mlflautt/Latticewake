import Foundation
import SwiftUI

/// A bounded, preview-only contract for local or external creative providers.
/// Parsing or validating one never changes a scene, a library document, or the
/// audio callback; the caller must still explicitly choose Preview or Accept.
enum ProposalPatchField: String, Codable, CaseIterable {
  case terrainDetail, terrainZoom
  case traversalRadiusX, traversalRadiusY, traversalTranslationX
  case attackSeconds, releaseSeconds, gain
  case droneEnabled, droneDensity, droneRange, dronePattern, droneSeedOffset
  case padEnabled, padDensity, padRange, padPattern, padSeedOffset
  case motifAEnabled, motifADensity, motifARange, motifAPattern, motifASeedOffset
  case motifBEnabled, motifBDensity, motifBRange, motifBPattern, motifBSeedOffset

  var component: String {
    switch self {
    case .terrainDetail, .terrainZoom: "Surface"
    case .traversalRadiusX, .traversalRadiusY, .traversalTranslationX: "Traversal"
    case .attackSeconds, .releaseSeconds, .gain: "Articulation"
    case .droneEnabled, .droneDensity, .droneRange, .dronePattern, .droneSeedOffset,
         .padEnabled, .padDensity, .padRange, .padPattern, .padSeedOffset,
         .motifAEnabled, .motifADensity, .motifARange, .motifAPattern, .motifASeedOffset,
         .motifBEnabled, .motifBDensity, .motifBRange, .motifBPattern, .motifBSeedOffset: "Lanes"
    }
  }

  var range: ClosedRange<Double> {
    switch self {
    case .terrainDetail, .terrainZoom, .traversalRadiusX, .traversalRadiusY, .traversalTranslationX: 0...1
    case .attackSeconds: 0.001...1
    case .releaseSeconds: 0.001...2
    case .gain: 0...1.5
    case .droneEnabled, .padEnabled, .motifAEnabled, .motifBEnabled: 0...1
    case .droneDensity, .droneRange, .padDensity, .padRange, .motifADensity, .motifARange, .motifBDensity, .motifBRange: 0...1
    case .dronePattern, .padPattern: 0...3
    case .motifAPattern, .motifBPattern: 0...7
    case .droneSeedOffset, .padSeedOffset, .motifASeedOffset, .motifBSeedOffset: 0...9999
    }
  }

  var roleIndex: Int? {
    switch self {
    case .droneEnabled, .droneDensity, .droneRange, .dronePattern, .droneSeedOffset: 0
    case .padEnabled, .padDensity, .padRange, .padPattern, .padSeedOffset: 1
    case .motifAEnabled, .motifADensity, .motifARange, .motifAPattern, .motifASeedOffset: 2
    case .motifBEnabled, .motifBDensity, .motifBRange, .motifBPattern, .motifBSeedOffset: 3
    default: nil
    }
  }

  var requiresWholeNumber: Bool {
    switch self {
    case .droneEnabled, .padEnabled, .motifAEnabled, .motifBEnabled,
         .dronePattern, .padPattern, .motifAPattern, .motifBPattern,
         .droneSeedOffset, .padSeedOffset, .motifASeedOffset, .motifBSeedOffset: true
    default: false
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

struct AgentProposalReceiptV1: Codable, Equatable, Identifiable {
  static let schema = "latticewake-agent-proposal-receipt-v1"
  let schemaVersion: String
  let proposalID: String
  let provider: String
  let baseSceneSHA256: String
  let candidateSceneSHA256: String
  let frozenComponents: [String]
  let patchedFields: [String]
  var id: String { proposalID }

  init(proposal: ScenePatchProposalV1, candidateSceneSHA256: String) {
    schemaVersion = Self.schema
    proposalID = proposal.proposalID
    provider = proposal.provider
    baseSceneSHA256 = proposal.baseSceneSHA256
    self.candidateSceneSHA256 = candidateSceneSHA256
    frozenComponents = proposal.frozenComponents.sorted()
    patchedFields = proposal.patches.map(\.field.rawValue).sorted()
  }
}

struct ValidatedAgentProposal: Equatable {
  let proposal: ScenePatchProposalV1
  let editorCandidate: SceneEditorControls
  let roleCandidate: [RoleControl]
}

enum LocalProposalIntent: String, CaseIterable, Identifiable {
  case surfaceLift = "Surface Lift"
  case orbitPath = "Orbit Path"
  case softArrival = "Soft Arrival"
  case droneFoundation = "Drone Foundation"
  case motifPulse = "Motif Pulse"
  case motifEuclid = "Motif Euclid"
  case motifCell = "Motif Cellular"
  var id: String { rawValue }
  /// Contract IDs are deliberately independent of the artist-facing label.
  /// Keep them ASCII-safe so local and external providers obey the exact same
  /// identity rule.
  var proposalSlug: String { rawValue.lowercased().replacingOccurrences(of: " ", with: "-") }
  var component: String {
    switch self {
    case .surfaceLift: "Surface"
    case .orbitPath: "Traversal"
    case .softArrival: "Articulation"
    case .droneFoundation, .motifPulse, .motifEuclid, .motifCell: "Lanes"
    }
  }
}

enum LocalProposalProvider {
  static func propose(intent: LocalProposalIntent, sceneHash: String, frozen: FrozenComponents) -> ScenePatchProposalV1? {
    guard !frozen.names.contains(intent.component) else { return nil }
    let patches: [ProposalPatchV1] = switch intent {
    case .surfaceLift: [ProposalPatchV1(field: .terrainDetail, value: 0.68), ProposalPatchV1(field: .terrainZoom, value: 0.42)]
    case .orbitPath: [ProposalPatchV1(field: .traversalRadiusX, value: 0.72), ProposalPatchV1(field: .traversalRadiusY, value: 0.38)]
    case .softArrival: [ProposalPatchV1(field: .attackSeconds, value: 0.045), ProposalPatchV1(field: .releaseSeconds, value: 0.38)]
    case .droneFoundation: [ProposalPatchV1(field: .droneEnabled, value: 1), ProposalPatchV1(field: .droneDensity, value: 0.30), ProposalPatchV1(field: .droneRange, value: 0.18), ProposalPatchV1(field: .dronePattern, value: 0)]
    case .motifPulse: [ProposalPatchV1(field: .motifAEnabled, value: 1), ProposalPatchV1(field: .motifADensity, value: 0.72), ProposalPatchV1(field: .motifARange, value: 0.58), ProposalPatchV1(field: .motifAPattern, value: 3)]
    case .motifEuclid: [ProposalPatchV1(field: .motifAEnabled, value: 1), ProposalPatchV1(field: .motifADensity, value: 0.68), ProposalPatchV1(field: .motifARange, value: 0.55), ProposalPatchV1(field: .motifAPattern, value: 5)]
    case .motifCell: [ProposalPatchV1(field: .motifBEnabled, value: 1), ProposalPatchV1(field: .motifBDensity, value: 0.64), ProposalPatchV1(field: .motifBRange, value: 0.62), ProposalPatchV1(field: .motifBPattern, value: 4)]
    }
    return ScenePatchProposalV1(schemaVersion: ScenePatchProposalV1.schema,
                                proposalID: "local-\(intent.proposalSlug)-\(String(sceneHash.prefix(12)))",
                                provider: "latticewake-local-palette-v1",
                                baseSceneSHA256: sceneHash,
                                frozenComponents: frozen.names.sorted(), patches: patches)
  }
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

struct ProposalStudioView: View {
  @Binding var json: String
  @Binding var localIntent: LocalProposalIntent
  let validated: ValidatedAgentProposal?
  let status: String
  let validate: () -> Void
  let preview: () -> Void
  let accept: () -> Void
  let reject: () -> Void
  let sample: () -> Void
  let prepareLocal: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Proposal Studio").font(.caption.bold()).foregroundStyle(.purple)
      Text("Paste a bounded ScenePatch proposal. Validation never changes the scene.").font(.caption2).foregroundStyle(.secondary)
      Picker("Local palette", selection: $localIntent) { ForEach(LocalProposalIntent.allCases) { Text($0.rawValue).tag($0) } }.pickerStyle(.segmented)
      Button("Prepare Local Proposal", action: prepareLocal).buttonStyle(.bordered)
      TextEditor(text: $json).font(.caption.monospaced()).frame(minHeight: 90).border(.secondary.opacity(0.4))
      HStack { Button("Sample Proposal", action: sample); Button("Validate", action: validate).buttonStyle(.borderedProminent); Button("Clear") { json = ""; reject() }.buttonStyle(.bordered) }
      if !status.isEmpty { Text(status).font(.caption2).foregroundStyle(validated == nil ? .orange : .mint) }
      if let validated {
        Text("Ready: \(validated.proposal.provider) • \(validated.proposal.patches.count) patch\(validated.proposal.patches.count == 1 ? "" : "es")").font(.caption2.monospaced())
        HStack { Button("Preview", action: preview); Button("Accept", action: accept); Button("Reject", action: reject) }.buttonStyle(.bordered)
      }
    }
  }
}

enum ProposalContractV1 {
  static func decode(_ bytes: Data) throws -> ScenePatchProposalV1 {
    try JSONDecoder().decode(ScenePatchProposalV1.self, from: bytes)
  }

  /// Compatibility helper for callers that only permit Surface, Traversal, or
  /// Articulation patches. Lane patches need the current role controls and use
  /// `validatedProposal` below.
  static func validatedCandidate(_ proposal: ScenePatchProposalV1, base: SceneEditorControls,
                                 sceneHash: String, frozen: FrozenComponents) throws -> SceneEditorControls {
    let validated = try validatedProposal(proposal, base: base, roles: [], sceneHash: sceneHash, frozen: frozen)
    return validated.editorCandidate
  }

  static func validatedProposal(_ proposal: ScenePatchProposalV1, base: SceneEditorControls,
                                roles: [RoleControl], sceneHash: String,
                                frozen: FrozenComponents) throws -> ValidatedAgentProposal {
    guard proposal.schemaVersion == ScenePatchProposalV1.schema else { throw ProposalContractError.schema }
    guard validIdentity(proposal.proposalID) else { throw ProposalContractError.identity("id") }
    guard validIdentity(proposal.provider) else { throw ProposalContractError.identity("provider") }
    guard proposal.baseSceneSHA256 == sceneHash else { throw ProposalContractError.baseScene }
    guard Set(proposal.frozenComponents) == frozen.names else { throw ProposalContractError.frozenState }
    guard (1...16).contains(proposal.patches.count) else { throw ProposalContractError.patchCount }
    var candidate = base; var roleCandidate = roles; var fields = Set<ProposalPatchField>()
    for patch in proposal.patches {
      guard fields.insert(patch.field).inserted else { throw ProposalContractError.duplicateField }
      guard patch.value.isFinite, patch.field.range.contains(patch.value),
            !patch.field.requiresWholeNumber || patch.value.rounded() == patch.value else { throw ProposalContractError.invalidValue(patch.field.rawValue) }
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
      case .droneEnabled, .padEnabled, .motifAEnabled, .motifBEnabled:
        guard let roleIndex = patch.field.roleIndex, roleCandidate.indices.contains(roleIndex) else { throw ProposalContractError.invalidValue(patch.field.rawValue) }
        roleCandidate[roleIndex].enabled = patch.value == 1
      case .droneDensity, .padDensity, .motifADensity, .motifBDensity:
        guard let roleIndex = patch.field.roleIndex, roleCandidate.indices.contains(roleIndex) else { throw ProposalContractError.invalidValue(patch.field.rawValue) }
        roleCandidate[roleIndex].density = patch.value
      case .droneRange, .padRange, .motifARange, .motifBRange:
        guard let roleIndex = patch.field.roleIndex, roleCandidate.indices.contains(roleIndex) else { throw ProposalContractError.invalidValue(patch.field.rawValue) }
        roleCandidate[roleIndex].range = patch.value
      case .dronePattern, .padPattern, .motifAPattern, .motifBPattern:
        guard let roleIndex = patch.field.roleIndex, roleCandidate.indices.contains(roleIndex) else { throw ProposalContractError.invalidValue(patch.field.rawValue) }
        roleCandidate[roleIndex].pattern = Int(patch.value)
      case .droneSeedOffset, .padSeedOffset, .motifASeedOffset, .motifBSeedOffset:
        guard let roleIndex = patch.field.roleIndex, roleCandidate.indices.contains(roleIndex) else { throw ProposalContractError.invalidValue(patch.field.rawValue) }
        roleCandidate[roleIndex].seedOffset = UInt64(patch.value)
      }
    }
    return ValidatedAgentProposal(proposal: proposal, editorCandidate: candidate, roleCandidate: roleCandidate)
  }

  static func fixtureJSON(sceneHash: String, frozen: FrozenComponents) throws -> String? {
    let fields = ProposalPatchField.allCases.filter { !frozen.names.contains($0.component) }
    guard let field = fields.first else { return nil }
    let value: Double = switch field {
    case .terrainDetail, .terrainZoom, .traversalRadiusX, .traversalRadiusY, .traversalTranslationX: 0.62
    case .attackSeconds: 0.04
    case .releaseSeconds: 0.32
    case .gain: 0.8
    case .droneEnabled, .padEnabled, .motifAEnabled, .motifBEnabled: 1
    case .droneDensity, .droneRange, .padDensity, .padRange, .motifADensity, .motifARange, .motifBDensity, .motifBRange: 0.5
    case .dronePattern, .padPattern, .motifAPattern, .motifBPattern: 0
    case .droneSeedOffset, .padSeedOffset, .motifASeedOffset, .motifBSeedOffset: 0
    }
    let proposal = ScenePatchProposalV1(schemaVersion: ScenePatchProposalV1.schema,
                                        proposalID: "local-fixture-\(String(sceneHash.prefix(12)))",
                                        provider: "latticewake-local-fixture",
                                        baseSceneSHA256: sceneHash,
                                        frozenComponents: frozen.names.sorted(),
                                        patches: [ProposalPatchV1(field: field, value: value)])
    let encoder = JSONEncoder(); encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
    return String(decoding: try encoder.encode(proposal), as: UTF8.self)
  }

  private static func validIdentity(_ value: String) -> Bool {
    !value.isEmpty && value.count <= 128 && value.allSatisfy { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == "." }
  }
}

extension FrozenComponents {
  var names: Set<String> {
    [surface ? "Surface" : nil, traversal ? "Traversal" : nil,
     articulation ? "Articulation" : nil, lanes ? "Lanes" : nil]
      .compactMap { $0 }.reduce(into: Set<String>()) { $0.insert($1) }
  }
}
