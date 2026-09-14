#include "sample_transport.hpp"

#include <cmath>
#include <limits>

namespace latticewake {
namespace {
bool valid(const SampleTransportConfig& config, SampleTransportError& error) {
  if (!std::isfinite(config.sampleRate) || config.sampleRate < 8000.0 || config.sampleRate > 192000.0) { error={"sampleRate","must be finite and in [8000, 192000]"}; return false; }
  if (!std::isfinite(config.tempoBPM) || config.tempoBPM <= 0.0 || config.tempoBPM > 1000.0) { error={"tempoBPM","must be finite and in (0, 1000]"}; return false; }
  return true;
}
double beatsAt(const std::uint64_t samples, const SampleTransportConfig& config) {
  return static_cast<double>(samples) * config.tempoBPM / (60.0 * config.sampleRate);
}
}  // namespace

std::optional<SampleTransportPosition> advanceSampleTransport(
    const SampleTransportPosition position, const std::uint64_t frames,
    const SampleTransportConfig& config, SampleTransportError& error) {
  if (!valid(config, error)) return std::nullopt;
  if (!std::isfinite(position.beatPosition) || !std::isfinite(position.beatPhase)) { error={"position","must be finite"}; return std::nullopt; }
  if (frames > std::numeric_limits<std::uint64_t>::max() - position.sampleOffset) { error={"frames","would overflow sample offset"}; return std::nullopt; }
  const std::uint64_t samples = position.sampleOffset + frames;
  const double beats = beatsAt(samples, config);
  if (!std::isfinite(beats)) { error={"position","produced non-finite beat position"}; return std::nullopt; }
  return SampleTransportPosition{samples, beats, beats - std::floor(beats)};
}

std::optional<std::uint64_t> sampleOffsetForBeat(
    const double beat, const SampleTransportConfig& config, SampleTransportError& error) {
  if (!valid(config, error)) return std::nullopt;
  if (!std::isfinite(beat) || beat < 0.0) { error={"beat","must be finite and non-negative"}; return std::nullopt; }
  const double samples = std::round(beat * 60.0 * config.sampleRate / config.tempoBPM);
  if (!std::isfinite(samples) || samples > static_cast<double>(std::numeric_limits<std::uint64_t>::max())) { error={"beat","cannot be represented as a sample offset"}; return std::nullopt; }
  return static_cast<std::uint64_t>(samples);
}

}  // namespace latticewake
