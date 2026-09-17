#include "scene_v1.hpp"

#include <cmath>
#include <set>

namespace latticewake {
namespace {
void requireId(ValidationIssues& issues, const std::string& field, const std::string& value,
               std::set<std::string>& ids) {
  if (value.empty()) issues.push_back({field, "must not be empty"});
  else if (!ids.insert(value).second) issues.push_back({field, "must be unique"});
}
}  // namespace

SceneV1 migrateSceneV0(const Scene& source, std::string sourceSceneHash) {
  SceneV1 result;
  result.sceneId = source.sceneId;
  result.seed = source.seed;
  result.title = source.title;
  result.surface.componentId = source.sceneId + ":surface";
  result.surface.layers = {{{source.sceneId + ":surface:a", SurfaceSourceType::analytic,
                             source.terrain, std::nullopt},
                            {source.sceneId + ":surface:b", SurfaceSourceType::analytic,
                             source.terrain, std::nullopt}}};
  result.surface.morph = 0.0;
  result.traversal = {source.sceneId + ":traversal", source.path, "uniform", 0.0, source.seed};
  result.articulation.componentId = source.sceneId + ":articulation";
  result.harmony = {source.sceneId + ":harmony", source.harmonicContext, "1/16"};
  result.lanes.reserve(source.roles.size());
  for (const RoleLane& role : source.roles) {
    const std::string name(roleIdName(role.id));
    result.lanes.push_back({source.sceneId + ":lane:" + name, name, role});
  }
  result.modulation.componentId = source.sceneId + ":modulation";
  result.routing = {source.sceneId + ":routing", {"terrain"}, {"direct", "lanes"}};
  result.lineage = {source.sceneId + ":lineage", source.createdFrom,
                    std::string(kSceneSchemaVersion), std::move(sourceSceneHash)};
  result.compatibilityScene = source;
  return result;
}

ValidationIssues validateSceneV1(const SceneV1& scene) {
  ValidationIssues issues;
  if (scene.schemaVersion != kSceneV1SchemaVersion)
    issues.push_back({"schemaVersion", "must equal latticewake-scene-v1"});
  if (scene.sceneId.empty()) issues.push_back({"sceneID", "must not be empty"});
  if (scene.title.empty()) issues.push_back({"title", "must not be empty"});
  if (scene.lanes.empty() || scene.lanes.size() > kMaximumLanes)
    issues.push_back({"laneCollection", "must contain between 1 and 16 lanes"});
  if (scene.modulation.routes.size() > kMaximumModulationRoutes)
    issues.push_back({"modulationGraph.routes", "must contain at most 32 routes"});
  if (scene.routing.engineSlots.empty() || scene.routing.engineSlots.size() > kMaximumEngineSlots)
    issues.push_back({"routing.engineSlots", "must contain between 1 and 4 slots"});
  if (!std::isfinite(scene.surface.morph) || scene.surface.morph < 0.0 || scene.surface.morph > 1.0)
    issues.push_back({"surface.morph", "must be finite and in [0, 1]"});
  for (std::size_t index = 0; index < scene.surface.layers.size(); ++index) {
    const auto& layer = scene.surface.layers[index];
    const std::string field = "surface.layers[" + std::to_string(index) + "].asset";
    if (layer.sourceType == SurfaceSourceType::analytic && layer.asset)
      issues.push_back({field, "analytic layers must not reference an asset"});
    if (layer.sourceType != SurfaceSourceType::analytic && !layer.asset)
      issues.push_back({field, "image and audio layers require an asset"});
    if (layer.asset && (layer.asset->assetId.empty() || layer.asset->contentHash.empty() ||
                        layer.asset->mediaType.empty()))
      issues.push_back({field, "descriptor fields must not be empty"});
    if (layer.sourceType == SurfaceSourceType::analytic) {
      Scene layerScene = scene.compatibilityScene;
      layerScene.terrain = layer.analytic;
      const auto layerIssues = validateScene(layerScene);
      for (const auto& issue : layerIssues)
        if (issue.field.starts_with("terrain."))
          issues.push_back({"surface.layers[" + std::to_string(index) + "].analytic." +
                                issue.field.substr(8), issue.message});
    }
  }
  if (scene.traversal.samplingDistribution != "uniform")
    issues.push_back({"traversal.samplingDistribution", "only uniform is supported in Scene v1"});
  if (!std::isfinite(scene.traversal.deformation) || scene.traversal.deformation < 0.0 ||
      scene.traversal.deformation > 1.0)
    issues.push_back({"traversal.deformation", "must be finite and in [0, 1]"});
  const std::pair<std::string_view, double> articulationValues[] = {
      {"articulation.attackSeconds", scene.articulation.attackSeconds},
      {"articulation.releaseSeconds", scene.articulation.releaseSeconds},
      {"articulation.gain", scene.articulation.gain},
      {"articulation.glideSemitones", scene.articulation.glideSemitones},
      {"articulation.velocityResponse", scene.articulation.velocityResponse},
      {"articulation.pressureResponse", scene.articulation.pressureResponse},
      {"articulation.slideResponse", scene.articulation.slideResponse}};
  for (const auto& [field, value] : articulationValues)
    if (!std::isfinite(value) || value < 0.0)
      issues.push_back({std::string(field), "must be finite and nonnegative"});
  const std::pair<std::string_view, double> outputValues[] = {
      {"articulation.tone", scene.articulation.tone},
      {"articulation.drive", scene.articulation.drive},
      {"articulation.space", scene.articulation.space},
      {"articulation.stereoMotion", scene.articulation.stereoMotion}};
  for (const auto& [field, value] : outputValues)
    if (!std::isfinite(value) || value < 0.0 || value > 1.0)
      issues.push_back({std::string(field), "must be finite and in [0, 1]"});
  if (scene.articulation.voiceBehavior != "polyphonic-oldest-steal")
    issues.push_back({"articulation.voiceBehavior", "unsupported voice behavior"});
  if (scene.lineage.sourceSceneHash.empty())
    issues.push_back({"lineage.sourceSceneHash", "must not be empty"});
  if (scene.compatibilityScene.sceneId != scene.sceneId ||
      scene.compatibilityScene.seed != scene.seed || scene.compatibilityScene.title != scene.title)
    issues.push_back({"compatibilitySceneV0", "identity must match Scene v1"});
  const ValidationIssues compatibilityIssues = validateScene(scene.compatibilityScene);
  for (const auto& issue : compatibilityIssues)
    issues.push_back({"compatibilitySceneV0." + issue.field, issue.message});

  std::set<std::string> ids;
  requireId(issues, "surface.componentID", scene.surface.componentId, ids);
  requireId(issues, "surface.layers[0].componentID", scene.surface.layers[0].componentId, ids);
  requireId(issues, "surface.layers[1].componentID", scene.surface.layers[1].componentId, ids);
  requireId(issues, "traversal.componentID", scene.traversal.componentId, ids);
  requireId(issues, "articulation.componentID", scene.articulation.componentId, ids);
  requireId(issues, "harmony.componentID", scene.harmony.componentId, ids);
  requireId(issues, "modulationGraph.componentID", scene.modulation.componentId, ids);
  requireId(issues, "routing.componentID", scene.routing.componentId, ids);
  requireId(issues, "lineage.componentID", scene.lineage.componentId, ids);
  for (std::size_t index = 0; index < scene.lanes.size(); ++index)
    requireId(issues, "laneCollection.componentID", scene.lanes[index].componentId, ids);
  for (const auto& lane : scene.lanes)
    if (lane.name.empty()) issues.push_back({"laneCollection.name", "must not be empty"});
  for (const auto& route : scene.modulation.routes) {
    requireId(issues, "modulationGraph.routes.routeID", route.routeId, ids);
    if (route.source.empty() || route.target.empty())
      issues.push_back({"modulationGraph.routes", "source and target must not be empty"});
    if (route.scope != "per-note" && route.scope != "per-lane" &&
        route.scope != "per-engine" && route.scope != "global")
      issues.push_back({"modulationGraph.routes.scope", "unsupported scope"});
    const bool supportedRoute = (route.source == "gesture-x" && route.target == "pitch") ||
                                (route.source == "gesture-y" && route.target == "timbre") ||
                                (route.source == "pressure" && route.target == "gain");
    if (!supportedRoute || route.scope != "per-note")
      issues.push_back({"modulationGraph.routes", "unsupported source, target, or scope"});
    if (!std::isfinite(route.depth) || route.depth < -1.0 || route.depth > 1.0)
      issues.push_back({"modulationGraph.routes.depth", "must be finite and in [-1, 1]"});
  }
  std::set<std::string> routingNames;
  for (const auto& slot : scene.routing.engineSlots)
    if (slot.empty() || !routingNames.insert("slot:" + slot).second)
      issues.push_back({"routing.engineSlots", "entries must be non-empty and unique"});
  for (const auto& group : scene.routing.performanceGroups)
    if (group.empty() || !routingNames.insert("group:" + group).second)
      issues.push_back({"routing.performanceGroups", "entries must be non-empty and unique"});
  return issues;
}

}  // namespace latticewake
