#include "render_plan.hpp"

#include "role_event_generator.hpp"

#include <algorithm>
#include <cmath>

namespace latticewake {
namespace {
constexpr std::uint32_t kRoleSourceBase = 100;

std::uint32_t sourceForRole(const std::string_view lane) {
  if (lane == "drone") return kRoleSourceBase;
  if (lane == "pad") return kRoleSourceBase + 1U;
  if (lane == "motifA") return kRoleSourceBase + 2U;
  return kRoleSourceBase + 3U;
}
int baseNoteForRole(const std::string_view lane) {
  if (lane == "drone") return 48;
  if (lane == "pad") return 60;
  if (lane == "motifA") return 72;
  return 76;
}
int scaleNote(const Scene& scene, const int base, const int degree) {
  const auto& scale = scene.harmonicContext.scaleDegrees;
  if (scale.empty()) return base;
  const int size = static_cast<int>(scale.size());
  int octave = degree / size;
  int index = degree % size;
  if (index < 0) { index += size; --octave; }
  return std::clamp(base + scale[static_cast<std::size_t>(index)] + 12 * octave, 0, 127);
}
}  // namespace

bool RenderPlanBuilder::build(const Scene& scene, const double sampleRate, RenderPlan& output,
                              RenderPlanError& error) const {
  RenderPlan candidate;
  if (!prepareTerrainPlan(scene, sampleRate, candidate.terrain)) {
    error = {"terrain", "could not prepare terrain tables"};
    return false;
  }
  const double tempo = scene.harmonicContext.tempoBPM;
  const auto loop = static_cast<std::uint64_t>(std::llround(sampleRate * 60.0 / tempo * 8.0));
  RoleEventGenerationError generationError;
  const auto trace = generateRoleEvents(scene, 0, loop, {sampleRate, tempo}, generationError);
  if (!trace || trace->events().size() > candidate.roleEvents.size()) {
    error = {generationError.field.empty() ? "laneCollection" : generationError.field,
             generationError.message.empty() ? "prepared role event cap exceeded" : generationError.message};
    return false;
  }
  candidate.roleLoopFrames = loop;
  for (const auto& event : trace->events()) {
    const auto lane = event.payload.find("lane");
    const auto degree = event.payload.find("degree");
    if (lane == event.payload.end() || degree == event.payload.end()) {
      error = {"laneCollection", "role event lacks lane or degree"};
      return false;
    }
    int parsedDegree{};
    try { parsedDegree = std::stoi(degree->second); }
    catch (...) { error = {"laneCollection", "role degree is invalid"}; return false; }
    candidate.roleEvents[candidate.roleEventCount++] = {
        event.sampleOffset % loop, scaleNote(scene, baseNoteForRole(lane->second), parsedDegree),
        event.type == EventType::noteOn, sourceForRole(lane->second)};
  }
  candidate.diagnostic = candidate.terrain.variation <= 1e-6F
                             ? TraversalDiagnostic::flat
                             : TraversalDiagnostic::pitched;
  candidate.sceneId = scene.sceneId;
  candidate.ready = true;
  output = std::move(candidate);
  return true;
}

}  // namespace latticewake
