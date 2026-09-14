#pragma once

#include "offline_terrain_voice.hpp"

#include <optional>

namespace latticewake {
enum class OversamplingFactor : unsigned int { x1 = 1, x2 = 2, x4 = 4 };
struct OfflineOversamplingResult { std::vector<double> samples; double transitionEnergy{}; };
// Offline interpolation plus average-decimation harness. transitionEnergy is a
// sample-difference metric, not a perceptual or complete alias measurement.
[[nodiscard]] std::optional<OfflineOversamplingResult> renderOversampledTerrainVoice(
    std::span<const TerrainEvaluation> trace, const OfflineTerrainVoiceConfig& config,
    OversamplingFactor factor, OfflineTerrainVoiceError& error);
}  // namespace latticewake
