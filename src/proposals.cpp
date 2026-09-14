#include "proposals.hpp"

#include <algorithm>
#include <cmath>
#include <iomanip>
#include <sstream>

namespace latticewake {
namespace {
constexpr std::size_t kMaximumProposalNotes = 1024;
constexpr std::size_t kMaximumProposalPatches = 16;
bool unit(const double value) { return std::isfinite(value) && value >= 0.0 && value <= 1.0; }
std::string decimal(const double value) { std::ostringstream out; out << std::setprecision(17) << value; return out.str(); }
void requireIdentity(std::vector<ProposalValidationIssue>& issues, const std::string_view name, const std::string& value) { if(value.empty()) issues.push_back({std::string(name),"must not be empty"}); }
}  // namespace

std::vector<ProposalValidationIssue> validateMelodyProposal(const MelodyProposal& proposal) {
  std::vector<ProposalValidationIssue> issues; requireIdentity(issues,"proposalId",proposal.proposalId); requireIdentity(issues,"sceneId",proposal.sceneId); requireIdentity(issues,"source",proposal.source);
  if(proposal.notes.empty() || proposal.notes.size()>kMaximumProposalNotes) issues.push_back({"notes","must contain 1 to 1024 notes"});
  for(std::size_t i=0;i<proposal.notes.size();++i){const auto& note=proposal.notes[i];const auto prefix="notes["+std::to_string(i)+"].";if(!std::isfinite(note.startBeat)||note.startBeat<0.0)issues.push_back({prefix+"startBeat","must be finite and non-negative"});if(!std::isfinite(note.durationBeats)||note.durationBeats<=0.0||note.durationBeats>64.0)issues.push_back({prefix+"durationBeats","must be finite and in (0, 64]"});if(note.scaleDegree < -64 || note.scaleDegree > 64)issues.push_back({prefix+"scaleDegree","must be in [-64, 64]"});if(!unit(note.velocity))issues.push_back({prefix+"velocity","must be finite and in [0, 1]"});}
  return issues;
}

std::vector<ProposalValidationIssue> validateSceneProposal(const SceneProposal& proposal) {
  std::vector<ProposalValidationIssue> issues; requireIdentity(issues,"proposalId",proposal.proposalId); requireIdentity(issues,"sceneId",proposal.sceneId); requireIdentity(issues,"source",proposal.source);
  if(proposal.patches.empty()||proposal.patches.size()>kMaximumProposalPatches)issues.push_back({"patches","must contain 1 to 16 allowlisted patches"});
  for(std::size_t i=0;i<proposal.patches.size();++i)if(!unit(proposal.patches[i].value))issues.push_back({"patches["+std::to_string(i)+"].value","must be finite and in [0, 1]"});
  return issues;
}

std::optional<EventTrace> previewMelodyProposal(const MelodyProposal& proposal,
    const SampleTransportConfig& transport, ProposalValidationIssue& error) {
  const auto issues=validateMelodyProposal(proposal); if(!issues.empty()){error=issues.front();return std::nullopt;}
  std::vector<PerformanceEvent> events; events.reserve(proposal.notes.size()*2U);
  SampleTransportError transportError;
  for(const auto& note:proposal.notes){const auto on=sampleOffsetForBeat(note.startBeat,transport,transportError);const auto off=sampleOffsetForBeat(note.startBeat+note.durationBeats,transport,transportError);if(!on||!off){error={transportError.field,transportError.message};return std::nullopt;}const std::map<std::string,std::string> payload={{"degree",std::to_string(note.scaleDegree)},{"proposalId",proposal.proposalId},{"velocity",decimal(note.velocity)}};events.push_back({*on,EventOrigin::proposal,EventType::noteOn,payload});events.push_back({*off,EventOrigin::proposal,EventType::noteOff,payload});}
  std::stable_sort(events.begin(),events.end(),[](const PerformanceEvent& a,const PerformanceEvent& b){return a.sampleOffset<b.sampleOffset;}); EventTrace trace; for(auto& event:events)if(!trace.append(std::move(event))){error={"notes","could not order preview trace"};return std::nullopt;}return trace;
}

}  // namespace latticewake
