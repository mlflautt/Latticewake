#pragma once

#include "scene.hpp"

#include <cstdint>

namespace latticewake {

struct TerrainSampleInput {
  double phase{};
  double feedbackX{};
  double feedbackY{};
};

struct TerrainEvaluation {
  double value{};
  double pathX{};
  double pathY{};
  std::uint32_t iterations{};
  bool escaped{};
};

// Samples a validated Scene v0 without allocating or retaining state. Invalid
// input, unsupported v0 field/path kinds, interior points, and non-finite
// calculations return the neutral result: a zero-valued, non-escaped sample.
[[nodiscard]] TerrainEvaluation evaluateAnalyticTerrain(
    const Scene& scene, const TerrainSampleInput& input) noexcept;

}  // namespace latticewake
