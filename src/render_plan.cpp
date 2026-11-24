#include "render_plan.hpp"

#include "role_event_generator.hpp"
#include "terrain_evaluator.hpp"

#include <algorithm>
#include <cmath>
#include <limits>

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

float sampleField(const SurfaceFieldView& field, const double x, const double y) noexcept {
  const double px = std::clamp((x + 1.0) * 0.5, 0.0, 1.0) * (field.width - 1U);
  const double py = std::clamp((1.0 - y) * 0.5, 0.0, 1.0) * (field.height - 1U);
  const auto x0 = static_cast<std::uint32_t>(px);
  const auto y0 = static_cast<std::uint32_t>(py);
  const auto x1 = std::min(x0 + 1U, field.width - 1U);
  const auto y1 = std::min(y0 + 1U, field.height - 1U);
  const double tx = px - x0;
  const double ty = py - y0;
  const auto value = [&field](const std::uint32_t sx, const std::uint32_t sy) {
    const auto index = static_cast<std::size_t>(sy) * field.width + sx;
    return static_cast<double>(field.samples[index]) / 65535.0;
  };
  const double top = value(x0, y0) + (value(x1, y0) - value(x0, y0)) * tx;
  const double bottom = value(x0, y1) + (value(x1, y1) - value(x0, y1)) * tx;
  return static_cast<float>(top + (bottom - top) * ty);
}

bool prepareImageSurface(const Scene& pathScene, const SurfaceFieldView& field,
                         const double sampleRate, PreparedTerrainPlan& plan) noexcept {
  if (!field.valid() || !std::isfinite(sampleRate) || sampleRate < 8000.0 || sampleRate > 192000.0)
    return false;
  float mean = 0.0F;
  for (std::size_t i = 0; i < plan.terrainTable.size(); ++i) {
    const double phase = static_cast<double>(i) / static_cast<double>(plan.terrainTable.size());
    const auto path = evaluateAnalyticTerrain(pathScene, {phase, 0.0, 0.0});
    const float value = static_cast<float>(2.0 * sampleField(field, path.pathX, path.pathY) - 1.0);
    plan.terrainTable[i] = std::isfinite(value) ? value : 0.0F;
    mean += plan.terrainTable[i] / static_cast<float>(plan.terrainTable.size());
  }
  const auto bounds = std::minmax_element(plan.terrainTable.begin(), plan.terrainTable.end());
  plan.variation = *bounds.second - *bounds.first;
  float peak = 0.0F;
  for (auto& value : plan.terrainTable) {
    value -= mean;
    peak = std::max(peak, std::fabs(value));
  }
  for (auto& value : plan.terrainTable)
    value = plan.variation > 1.0e-6F && peak > 1.0e-6F ? value / peak : 0.0F;
  for (std::size_t i = 0; i < plan.morphTable.size(); ++i)
    plan.morphTable[i] = 0.35F * plan.terrainTable[i] + 0.65F * plan.terrainTable[(2U * i) % plan.terrainTable.size()];
  plan.sampleRate = static_cast<float>(sampleRate);
  plan.ready = true;
  return true;
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
  return build(scene, sampleRate, std::array<SurfaceFieldView, 2>{}, output, error);
}

bool RenderPlanBuilder::build(const SceneV1& scene, const double sampleRate,
                              const std::array<SurfaceFieldView, 2>& fields,
                              RenderPlan& output, RenderPlanError& error) const {
  const ValidationIssues validation = validateSceneV1(scene);
  if (!validation.empty()) {
    error = {validation.front().field, validation.front().message};
    return false;
  }
  RenderPlan candidate;
  if (!build(scene.compatibilityScene, sampleRate, candidate, error)) return false;
  Scene layerScene = scene.compatibilityScene;
  layerScene.path = scene.traversal.path;
  const auto prepareLayer = [&](const std::size_t index, PreparedTerrainPlan& prepared) {
    const auto& layer = scene.surface.layers[index];
    if (layer.sourceType == SurfaceSourceType::analytic) {
      layerScene.terrain = layer.analytic;
      return prepareTerrainPlan(layerScene, sampleRate, prepared);
    }
    if (layer.sourceType != SurfaceSourceType::image) {
      error = {"surface.layers[" + std::to_string(index) + "]", "audio-derived Surface preparation is not implemented"};
      return false;
    }
    if (!layer.asset || !fields[index].valid() || fields[index].contentHash != layer.asset->contentHash) {
      error = {"surface.layers[" + std::to_string(index) + "].asset", "image Surface field is missing, invalid, or has a different content hash"};
      return false;
    }
    if (!prepareImageSurface(layerScene, fields[index], sampleRate, prepared)) {
      error = {"surface.layers[" + std::to_string(index) + "]", "image Surface field could not be prepared"};
      return false;
    }
    return true;
  };
  PreparedTerrainPlan layerA;
  if (!prepareLayer(0, layerA)) return false;
  PreparedTerrainPlan layerB;
  if (!prepareLayer(1, layerB)) return false;
  candidate.terrain.terrainTable = layerA.terrainTable;
  candidate.terrain.morphTable = layerB.terrainTable;
  candidate.terrain.surfaceMorph = static_cast<float>(scene.surface.morph);
  const auto morph = candidate.terrain.surfaceMorph;
  float mixedMinimum = std::numeric_limits<float>::infinity();
  float mixedMaximum = -std::numeric_limits<float>::infinity();
  for (std::size_t index = 0; index < candidate.terrain.terrainTable.size(); ++index) {
    const float value = candidate.terrain.terrainTable[index] * (1.0F - morph) +
                        candidate.terrain.morphTable[index] * morph;
    mixedMinimum = std::min(mixedMinimum, value);
    mixedMaximum = std::max(mixedMaximum, value);
  }
  candidate.terrain.variation = mixedMaximum - mixedMinimum;
  candidate.terrain.tempoBPM = static_cast<float>(scene.harmony.context.tempoBPM);
  const auto& articulation = scene.articulation;
  candidate.terrain.attackSeconds = std::max(0.001F, static_cast<float>(articulation.attackSeconds));
  candidate.terrain.releaseSeconds = std::max(0.001F, static_cast<float>(articulation.releaseSeconds));
  candidate.terrain.gain = static_cast<float>(articulation.gain);
  candidate.terrain.glideSemitones = static_cast<float>(articulation.glideSemitones);
  candidate.terrain.velocityResponse = static_cast<float>(articulation.velocityResponse);
  candidate.terrain.pressureResponse = static_cast<float>(articulation.pressureResponse);
  candidate.terrain.slideResponse = static_cast<float>(articulation.slideResponse);
  candidate.terrain.tone = static_cast<float>(articulation.tone);
  candidate.terrain.drive = static_cast<float>(articulation.drive);
  candidate.terrain.space = static_cast<float>(articulation.space);
  candidate.terrain.stereoMotion = static_cast<float>(articulation.stereoMotion);
  // An empty graph preserves the direct-play mappings used by Scene v0. Once a
  // Scene v1 route is present, the graph explicitly owns the three supported
  // per-note expression destinations.
  if (!scene.modulation.routes.empty()) {
    candidate.terrain.gesturePitchDepth = 0.0F;
    candidate.terrain.gestureTimbreDepth = 0.0F;
    candidate.terrain.pressureGainDepth = 0.0F;
    for (const auto& route : scene.modulation.routes) {
      if (route.source == "gesture-x") candidate.terrain.gesturePitchDepth = static_cast<float>(route.depth);
      else if (route.source == "gesture-y") candidate.terrain.gestureTimbreDepth = static_cast<float>(route.depth);
      else if (route.source == "pressure") candidate.terrain.pressureGainDepth = static_cast<float>(route.depth);
    }
  }
  candidate.diagnostic = candidate.terrain.variation <= 1.0e-6F
                             ? TraversalDiagnostic::flat
                             : TraversalDiagnostic::pitched;
  candidate.ready = true;
  output = std::move(candidate);
  return true;
}

}  // namespace latticewake
