#include "scene.hpp"

#include <algorithm>
#include <array>
#include <cmath>
#include <utility>

namespace latticewake {
namespace {

constexpr std::uint32_t kMaximumIterations = 4096;

bool isNormalized(const double value) {
  return std::isfinite(value) && value >= 0.0 && value <= 1.0;
}

void requireNonEmpty(ValidationIssues& issues, const std::string_view field,
                     const std::string& value) {
  if (value.empty()) {
    issues.push_back({std::string(field), "must not be empty"});
  }
}

void requireNormalized(ValidationIssues& issues, const std::string_view field,
                       const double value) {
  if (!isNormalized(value)) {
    issues.push_back({std::string(field), "must be finite and in [0, 1]"});
  }
}

}  // namespace

std::string_view roleIdName(const RoleId roleId) noexcept {
  switch (roleId) {
    case RoleId::drone:
      return "drone";
    case RoleId::pad:
      return "pad";
    case RoleId::motifA:
      return "motifA";
    case RoleId::motifB:
      return "motifB";
  }
  return "unknown";
}

ValidationIssues validateScene(const Scene& scene) {
  ValidationIssues issues;
  if (scene.schemaVersion != kSceneSchemaVersion) {
    issues.push_back({"schemaVersion", "must equal latticewake-scene-v0"});
  }
  requireNonEmpty(issues, "sceneId", scene.sceneId);
  requireNonEmpty(issues, "title", scene.title);

  requireNonEmpty(issues, "harmonicContext.tonic", scene.harmonicContext.tonic);
  requireNonEmpty(issues, "harmonicContext.mode", scene.harmonicContext.mode);
  requireNonEmpty(issues, "harmonicContext.chordQuality", scene.harmonicContext.chordQuality);
  if (scene.harmonicContext.scaleDegrees.empty()) {
    issues.push_back({"harmonicContext.scaleDegrees", "must not be empty"});
  }
  if (!std::isfinite(scene.harmonicContext.tempoBPM) ||
      scene.harmonicContext.tempoBPM <= 0.0) {
    issues.push_back({"harmonicContext.tempoBPM", "must be finite and greater than zero"});
  }

  requireNonEmpty(issues, "terrain.kind", scene.terrain.kind);
  const std::array<std::pair<std::string_view, double>, 7> terrainControls = {{
      {"terrain.detail", scene.terrain.detail},
      {"terrain.zoom", scene.terrain.zoom},
      {"terrain.offsetX", scene.terrain.offsetX},
      {"terrain.offsetY", scene.terrain.offsetY},
      {"terrain.rotation", scene.terrain.rotation},
      {"terrain.motion", scene.terrain.motion},
      {"terrain.normalization", scene.terrain.normalization},
  }};
  for (const auto& [name, value] : terrainControls) {
    requireNormalized(issues, name, value);
  }
  if (scene.terrain.maxIterations == 0 || scene.terrain.maxIterations > kMaximumIterations) {
    issues.push_back({"terrain.maxIterations", "must be in [1, 4096]"});
  }

  requireNonEmpty(issues, "path.kind", scene.path.kind);
  const std::array<std::pair<std::string_view, double>, 9> pathControls = {{
      {"path.rateRatio", scene.path.rateRatio},
      {"path.radiusX", scene.path.radiusX},
      {"path.radiusY", scene.path.radiusY},
      {"path.angle", scene.path.angle},
      {"path.translationX", scene.path.translationX},
      {"path.translationY", scene.path.translationY},
      {"path.meander", scene.path.meander},
      {"path.feedback", scene.path.feedback},
      {"path.spatialLimit", scene.path.spatialLimit},
  }};
  for (const auto& [name, value] : pathControls) {
    requireNormalized(issues, name, value);
  }

  if (scene.roles.size() != 4) {
    issues.push_back({"roles", "must contain exactly four lanes"});
  }
  constexpr std::array<RoleId, 4> kRequiredRoles = {
      RoleId::drone, RoleId::pad, RoleId::motifA, RoleId::motifB};
  for (const RoleId requiredRole : kRequiredRoles) {
    const auto count = std::count_if(scene.roles.begin(), scene.roles.end(),
                                     [requiredRole](const RoleLane& role) {
                                       return role.id == requiredRole;
                                     });
    if (count != 1) {
      issues.push_back({"roles", std::string(roleIdName(requiredRole)) +
                                     " must appear exactly once"});
    }
  }
  for (const RoleLane& role : scene.roles) {
    const std::string prefix = "roles." + std::string(roleIdName(role.id)) + ".";
    requireNormalized(issues, prefix + "range", role.range);
    requireNormalized(issues, prefix + "density", role.density);
    requireNormalized(issues, prefix + "variation", role.variation);
  }
  return issues;
}

bool isValidScene(const Scene& scene) { return validateScene(scene).empty(); }

}  // namespace latticewake
