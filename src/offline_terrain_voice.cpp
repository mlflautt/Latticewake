#include "offline_terrain_voice.hpp"

#include <cmath>
#include <numbers>

namespace latticewake {
namespace {

bool finite(const double value) { return std::isfinite(value); }

std::optional<std::vector<double>> fail(OfflineTerrainVoiceError& error,
                                        const std::string_view field,
                                        const std::string_view message) {
  error = {std::string(field), std::string(message)};
  return std::nullopt;
}

}  // namespace

std::optional<std::vector<double>> renderOfflineTerrainVoice(
    const std::span<const TerrainEvaluation> trace,
    const OfflineTerrainVoiceConfig& config, OfflineTerrainVoiceError& error) {
  if (!finite(config.sampleRate) || config.sampleRate < 8000.0 ||
      config.sampleRate > 192000.0) {
    return fail(error, "sampleRate", "must be finite and in [8000, 192000]");
  }
  if (!finite(config.gain) || config.gain < 0.0 || config.gain > 1.0) {
    return fail(error, "gain", "must be finite and in [0, 1]");
  }
  if (!finite(config.dcCutoffHz) || config.dcCutoffHz <= 0.0 ||
      config.dcCutoffHz >= config.sampleRate * 0.5) {
    return fail(error, "dcCutoffHz", "must be finite, positive, and below Nyquist");
  }

  const double pole = std::exp((-2.0 * std::numbers::pi_v<double> * config.dcCutoffHz) /
                               config.sampleRate);
  std::vector<double> rendered;
  rendered.reserve(trace.size());
  double previousInput = 0.0;
  double previousOutput = 0.0;
  for (std::size_t index = 0; index < trace.size(); ++index) {
    const double terrain = trace[index].value;
    if (!finite(terrain) || terrain < 0.0 || terrain > 1.0) {
      return fail(error, "trace[" + std::to_string(index) + "].value",
                  "must be finite and in [0, 1]");
    }
    const double input = ((2.0 * terrain) - 1.0) * config.gain;
    const double dcBlocked = input - previousInput + pole * previousOutput;
    if (!finite(dcBlocked)) {
      return fail(error, "trace", "produced a non-finite DC-blocked sample");
    }
    const double limited = dcBlocked / (1.0 + std::abs(dcBlocked));
    if (!finite(limited) || limited < -1.0 || limited > 1.0) {
      return fail(error, "trace", "produced an invalid limited sample");
    }
    rendered.push_back(limited);
    previousInput = input;
    previousOutput = dcBlocked;
  }
  return rendered;
}

}  // namespace latticewake
