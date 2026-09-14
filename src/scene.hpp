#pragma once

#include <cstdint>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

namespace latticewake {

inline constexpr std::string_view kSceneSchemaVersion = "latticewake-scene-v0";

enum class RoleId { drone, pad, motifA, motifB };
enum class RhythmStepKind { note, rest, tie };

[[nodiscard]] std::string_view roleIdName(RoleId roleId) noexcept;

struct HarmonicContext {
  std::string tonic;
  std::string mode;
  std::vector<int> scaleDegrees;
  int chordDegree{};
  std::string chordQuality;
  int inversion{};
  int octaveReference{};
  double tempoBPM{};
  std::optional<std::string> tuningId;
};

struct Terrain {
  std::string kind;
  double detail{};
  double zoom{};
  double offsetX{};
  double offsetY{};
  double rotation{};
  double motion{};
  std::uint32_t maxIterations{};
  double normalization{};
};

struct Path {
  std::string kind;
  double rateRatio{};
  double radiusX{};
  double radiusY{};
  double angle{};
  double translationX{};
  double translationY{};
  double meander{};
  double feedback{};
  double spatialLimit{};
};

struct RhythmStep { RhythmStepKind kind{RhythmStepKind::rest}; };

struct RoleLane {
  RoleId id{RoleId::drone};
  bool enabled{};
  double range{};
  double density{};
  std::vector<int> pattern;
  std::vector<RhythmStep> rhythm;
  double variation{};
  std::uint64_t seedOffset{};
  std::string voiceRoute;
  std::string midiRoute;
};

struct Scene {
  std::string schemaVersion{std::string(kSceneSchemaVersion)};
  std::string sceneId;
  std::uint64_t seed{};
  std::string title;
  std::optional<std::string> createdFrom;
  HarmonicContext harmonicContext;
  Terrain terrain;
  Path path;
  std::vector<RoleLane> roles;
};

struct ValidationIssue {
  std::string field;
  std::string message;
};

using ValidationIssues = std::vector<ValidationIssue>;

[[nodiscard]] ValidationIssues validateScene(const Scene& scene);
[[nodiscard]] bool isValidScene(const Scene& scene);

}  // namespace latticewake
