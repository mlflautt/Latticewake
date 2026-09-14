#pragma once

#include <cstdint>
#include <optional>
#include <string>

namespace latticewake {

struct SampleTransportConfig { double sampleRate{48000.0}; double tempoBPM{120.0}; };
struct SampleTransportPosition { std::uint64_t sampleOffset{}; double beatPosition{}; double beatPhase{}; };
struct SampleTransportError { std::string field; std::string message; };

[[nodiscard]] std::optional<SampleTransportPosition> advanceSampleTransport(
    SampleTransportPosition position, std::uint64_t frames,
    const SampleTransportConfig& config, SampleTransportError& error);

[[nodiscard]] std::optional<std::uint64_t> sampleOffsetForBeat(
    double beat, const SampleTransportConfig& config, SampleTransportError& error);

}  // namespace latticewake
