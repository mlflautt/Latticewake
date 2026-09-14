#pragma once

#include "terrain_evaluator.hpp"

#include <optional>
#include <span>
#include <string>
#include <vector>

namespace latticewake {

struct OfflineTerrainVoiceConfig {
  double sampleRate{48000.0};
  double gain{0.5};
  double dcCutoffHz{20.0};
};

struct OfflineTerrainVoiceError {
  std::string field;
  std::string message;
};

// Converts a normalized terrain trace into bounded mono samples in memory.
// This is an offline test scaffold, never an audio-device or callback API.
[[nodiscard]] std::optional<std::vector<double>> renderOfflineTerrainVoice(
    std::span<const TerrainEvaluation> trace, const OfflineTerrainVoiceConfig& config,
    OfflineTerrainVoiceError& error);

}  // namespace latticewake
