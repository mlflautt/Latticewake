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

bool RenderPlanBuilder::build(const SceneV1& scene, const double sampleRate, RenderPlan& output,
                              RenderPlanError& error) const {
  const ValidationIssues validation = validateSceneV1(scene);
  if (!validation.empty()) {
    error = {validation.front().field, validation.front().message};
    return false;
  }
  if (!build(scene.compatibilityScene, sampleRate, output, error)) return false;
  const auto& articulation = scene.articulation;
  output.terrain.attackSeconds = std::max(0.001F, static_cast<float>(articulation.attackSeconds));
  output.terrain.releaseSeconds = std::max(0.001F, static_cast<float>(articulation.releaseSeconds));
  output.terrain.gain = static_cast<float>(articulation.gain);
  output.terrain.glideSemitones = static_cast<float>(articulation.glideSemitones);
  output.terrain.velocityResponse = static_cast<float>(articulation.velocityResponse);
  output.terrain.pressureResponse = static_cast<float>(articulation.pressureResponse);
  output.terrain.slideResponse = static_cast<float>(articulation.slideResponse);
  // An empty graph preserves the direct-play mappings used by Scene v0. Once a
  // Scene v1 route is present, the graph explicitly owns the three supported
  // per-note expression destinations.
  if (!scene.modulation.routes.empty()) {
    output.terrain.gesturePitchDepth = 0.0F;
    output.terrain.gestureTimbreDepth = 0.0F;
    output.terrain.pressureGainDepth = 0.0F;
    for (const auto& route : scene.modulation.routes) {
      if (route.source == "gesture-x") output.terrain.gesturePitchDepth = static_cast<float>(route.depth);
      else if (route.source == "gesture-y") output.terrain.gestureTimbreDepth = static_cast<float>(route.depth);
      else if (route.source == "pressure") output.terrain.pressureGainDepth = static_cast<float>(route.depth);
    }
  }
  return true;
}

}  // namespace latticewake
