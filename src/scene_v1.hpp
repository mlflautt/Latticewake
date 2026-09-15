#pragma once

#include "scene.hpp"

#include <array>
#include <cstdint>
#include <optional>
#include <string>
#include <vector>

namespace latticewake {

inline constexpr std::string_view kSceneV1SchemaVersion = "latticewake-scene-v1";
inline constexpr std::size_t kMaximumLanes = 16;
inline constexpr std::size_t kMaximumEngineSlots = 4;
inline constexpr std::size_t kMaximumModulationRoutes = 32;

enum class SurfaceSourceType { analytic, image, audio };

struct AssetDescriptor {
  std::string assetId;
  std::string contentHash;
  std::string mediaType;
};

struct SurfaceLayer {
  std::string componentId;
  SurfaceSourceType sourceType{SurfaceSourceType::analytic};
  Terrain analytic;
  std::optional<AssetDescriptor> asset;
};

struct SurfaceComponent {
  std::string componentId;
  std::array<SurfaceLayer, 2> layers;
  double morph{};
};

struct TraversalComponent {
  std::string componentId;
  Path path;
  std::string samplingDistribution{"uniform"};
  double deformation{};
  std::uint64_t seed{};
};

struct ArticulationComponent {
  std::string componentId;
  double attackSeconds{0.010};
  double releaseSeconds{0.120};
  double gain{1.0};
  double glideSemitones{12.0};
  double velocityResponse{1.0};
  double pressureResponse{1.0};
  double slideResponse{1.0};
  std::string voiceBehavior{"polyphonic-oldest-steal"};
};

struct HarmonyComponent {
  std::string componentId;
  HarmonicContext context;
  std::string transportDivision{"1/16"};
};

struct LaneComponent {
  std::string componentId;
  std::string name;
  RoleLane role;
};

struct ModulationRoute {
  std::string routeId;
  std::string source;
  std::string target;
  std::string scope;
  double depth{};
};

struct ModulationGraphComponent {
  std::string componentId;
  std::vector<ModulationRoute> routes;
};

struct RoutingComponent {
  std::string componentId;
  std::vector<std::string> engineSlots;
  std::vector<std::string> performanceGroups;
};

struct LineageComponent {
  std::string componentId;
  std::optional<std::string> parentSceneHash;
  std::string migratedFromSchema;
  std::string sourceSceneHash;
};

struct SceneV1 {
  std::string schemaVersion{std::string(kSceneV1SchemaVersion)};
  std::string sceneId;
  std::uint64_t seed{};
  std::string title;
  SurfaceComponent surface;
  TraversalComponent traversal;
  ArticulationComponent articulation;
  HarmonyComponent harmony;
  std::vector<LaneComponent> lanes;
  ModulationGraphComponent modulation;
  RoutingComponent routing;
  LineageComponent lineage;
  Scene compatibilityScene;
};

[[nodiscard]] SceneV1 migrateSceneV0(const Scene& scene, std::string sourceSceneHash);
[[nodiscard]] ValidationIssues validateSceneV1(const SceneV1& scene);

}  // namespace latticewake
