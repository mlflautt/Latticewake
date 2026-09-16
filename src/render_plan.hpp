#pragma once

#include "realtime_kernel.hpp"
#include "scene_v1.hpp"

#include <array>
#include <cstdint>
#include <string>

namespace latticewake {

enum class TraversalDiagnostic { pitched, noisy, flat, insufficientlyPeriodic, invalid };

struct PreparedRoleEvent {
  std::uint64_t frame{};
  int note{};
  bool noteOn{};
  std::uint32_t source{};
};

struct RenderPlan {
  static constexpr std::size_t kMaximumRoleEvents = 512;
  PreparedTerrainPlan terrain;
  std::array<PreparedRoleEvent, kMaximumRoleEvents> roleEvents{};
  std::uint32_t roleEventCount{};
  std::uint64_t roleLoopFrames{};
  TraversalDiagnostic diagnostic{TraversalDiagnostic::invalid};
  std::string sceneId;
  bool ready{};
};

struct RenderPlanError { std::string field; std::string message; };

class RenderPlanBuilder {
 public:
  [[nodiscard]] bool build(const Scene& scene, double sampleRate, RenderPlan& output,
                           RenderPlanError& error) const;
  [[nodiscard]] bool build(const SceneV1& scene, double sampleRate, RenderPlan& output,
                           RenderPlanError& error) const;
};

}  // namespace latticewake
