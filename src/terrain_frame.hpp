#pragma once

#include "terrain_evaluator.hpp"

#include <optional>
#include <string>
#include <vector>

namespace latticewake {
struct TerrainFrameRequest { std::uint64_t sampleOffset{}; double startPhase{}; double phaseStep{}; std::size_t pointCount{}; };
struct TerrainFrameSnapshot { std::string sceneId; std::uint64_t sampleOffset{}; std::vector<TerrainEvaluation> points; };
struct TerrainFrameError { std::string field; std::string message; };
// Builds an immutable-by-value offline snapshot; it performs no UI or Metal work.
[[nodiscard]] std::optional<TerrainFrameSnapshot> buildTerrainFrame(
    const Scene& scene, const TerrainFrameRequest& request, TerrainFrameError& error);
}  // namespace latticewake
