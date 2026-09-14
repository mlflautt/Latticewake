#pragma once

#include "scene.hpp"

#include <optional>
#include <string>
#include <string_view>

namespace latticewake {

struct SceneSerializationError {
  std::string path;
  std::string message;
};

// Serializes a valid Scene v0 as canonical UTF-8 JSON. On failure, returns
// std::nullopt and sets error. This has no filesystem behavior.
[[nodiscard]] std::optional<std::string> serializeSceneV0(
    const Scene& scene, SceneSerializationError& error);

// Parses the strict Latticewake Scene v0 JSON shape. It rejects duplicate and
// unknown fields before validating the constructed typed Scene.
[[nodiscard]] std::optional<Scene> parseSceneV0(
    std::string_view bytes, SceneSerializationError& error);

}  // namespace latticewake
