#pragma once

#include "event_trace.hpp"
#include "sample_transport.hpp"
#include "scene.hpp"

#include <optional>
#include <string>

namespace latticewake {
struct RoleEventGenerationError { std::string field; std::string message; };
// Generates a bounded offline trace. It is not an audio callback or sequencer
// transport implementation, and does not mutate the supplied Scene.
[[nodiscard]] std::optional<EventTrace> generateRoleEvents(
    const Scene& scene, std::uint64_t startSampleOffset, std::uint64_t frames,
    const SampleTransportConfig& transport, RoleEventGenerationError& error);
}  // namespace latticewake
