#pragma once

#include "event_trace.hpp"
#include "sample_transport.hpp"

#include <optional>
#include <string>
#include <vector>

namespace latticewake {

struct MelodyNoteProposal { double startBeat{}; double durationBeats{}; int scaleDegree{}; double velocity{}; };
struct MelodyProposal { std::string proposalId; std::string sceneId; std::string source; std::vector<MelodyNoteProposal> notes; };
enum class ScenePatchTarget { terrainDetail, terrainMotion, pathRateRatio, pathRadiusX, pathRadiusY };
struct ScenePatch { ScenePatchTarget target{ScenePatchTarget::terrainDetail}; double value{}; };
struct SceneProposal { std::string proposalId; std::string sceneId; std::string source; std::vector<ScenePatch> patches; };
struct ProposalValidationIssue { std::string field; std::string message; };

[[nodiscard]] std::vector<ProposalValidationIssue> validateMelodyProposal(const MelodyProposal& proposal);
[[nodiscard]] std::vector<ProposalValidationIssue> validateSceneProposal(const SceneProposal& proposal);
// Produces a temporary trace only; it does not mutate or commit a Scene.
[[nodiscard]] std::optional<EventTrace> previewMelodyProposal(const MelodyProposal& proposal,
    const SampleTransportConfig& transport, ProposalValidationIssue& error);

}  // namespace latticewake
