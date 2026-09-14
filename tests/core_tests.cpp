#include "event_trace.hpp"
#include "scene.hpp"
#include "scene_serialization.hpp"
#include "terrain_evaluator.hpp"

#include <cassert>
#include <cmath>
#include <limits>

namespace {

latticewake::Scene validScene() {
  using namespace latticewake;
  Scene scene;
  scene.sceneId = "scene-001";
  scene.seed = 42;
  scene.title = "Validation fixture";
  scene.harmonicContext = {"c", "dorian", {0, 2, 3, 5, 7, 9, 10}, 1, "minor7", 0, 4, 120.0,
                           std::nullopt};
  scene.terrain = {"juliaSmooth", 0.5, 0.5, 0.5, 0.5, 0.5, 0.0, 64, 0.5};
  scene.path = {"ellipse", 0.5, 0.4, 0.3, 0.0, 0.5, 0.5, 0.0, 0.0, 1.0};
  scene.roles = {
      {RoleId::drone, true, 0.2, 0.3, {0}, {{RhythmStepKind::note}}, 0.0, 0, "internal", ""},
      {RoleId::pad, true, 0.5, 0.4, {0, 2, 4}, {{RhythmStepKind::note}}, 0.0, 1, "internal", ""},
      {RoleId::motifA, true, 0.6, 0.5, {0, 1, 2}, {{RhythmStepKind::note}, {RhythmStepKind::rest}},
       0.1, 2, "internal", ""},
      {RoleId::motifB, true, 0.7, 0.5, {4, 2, 0}, {{RhythmStepKind::note}, {RhythmStepKind::tie}},
       0.2, 3, "internal", ""},
  };
  return scene;
}

bool hasField(const latticewake::ValidationIssues& issues, const char* field) {
  for (const auto& issue : issues) {
    if (issue.field == field) {
      return true;
    }
  }
  return false;
}

void testSceneValidation() {
  using namespace latticewake;
  assert(isValidScene(validScene()));

  Scene invalid = validScene();
  invalid.schemaVersion = "other";
  invalid.terrain.maxIterations = 4097;
  invalid.path.feedback = std::numeric_limits<double>::infinity();
  invalid.roles.pop_back();
  const ValidationIssues issues = validateScene(invalid);
  assert(hasField(issues, "schemaVersion"));
  assert(hasField(issues, "terrain.maxIterations"));
  assert(hasField(issues, "path.feedback"));
  assert(hasField(issues, "roles"));
}

void testTraceDeterminismAndOrdering() {
  using namespace latticewake;
  PerformanceEvent first{32, EventOrigin::player, EventType::noteOn, {{"note", "60"}}};
  PerformanceEvent second{64, EventOrigin::generator, EventType::control,
                          {{"target", "terrain.detail"}, {"value", "0.7"}}};
  EventTrace traceA;
  EventTrace traceB;
  assert(traceA.append(first));
  assert(traceA.append(second));
  assert(traceB.append(first));
  assert(traceB.append(second));
  assert(traceA.validate().empty());
  assert(traceA.canonicalBytes() == traceB.canonicalBytes());
  assert(!traceA.append({31, EventOrigin::proposal, EventType::scene, {}}));
}

void testAnalyticTerrainFixtures() {
  using namespace latticewake;
  Scene scene = validScene();
  scene.terrain.kind = "mandelbrot";
  scene.terrain.normalization = 1.0;
  scene.terrain.detail = 0.5;
  scene.terrain.zoom = 0.0;
  scene.terrain.offsetX = 0.5;
  scene.terrain.offsetY = 0.5;
  scene.terrain.rotation = 0.0;
  scene.terrain.maxIterations = 64;
  scene.path = {"ellipse", 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.0, 0.0, 1.0};

  const TerrainEvaluation interior = evaluateAnalyticTerrain(scene, {0.0, 0.0, 0.0});
  assert(!interior.escaped);
  assert(interior.value == 0.0);
  assert(interior.iterations == 64);

  scene.path.translationX = 0.6875;
  const TerrainEvaluation escaped = evaluateAnalyticTerrain(scene, {0.0, 0.0, 0.0});
  const TerrainEvaluation repeated = evaluateAnalyticTerrain(scene, {0.0, 0.0, 0.0});
  assert(escaped.escaped);
  assert(escaped.iterations == 3);
  assert(escaped.value > 0.9 && escaped.value <= 1.0);
  assert(escaped.value == repeated.value);
  assert(escaped.pathX == repeated.pathX);
  assert(escaped.pathY == repeated.pathY);

  scene.terrain.kind = "julia";
  const TerrainEvaluation julia = evaluateAnalyticTerrain(scene, {0.25, 0.0, 0.0});
  const TerrainEvaluation repeatedJulia = evaluateAnalyticTerrain(scene, {0.25, 0.0, 0.0});
  assert(std::isfinite(julia.value));
  assert(julia.value >= 0.0 && julia.value <= 1.0);
  assert(julia.value == repeatedJulia.value);
  assert(julia.iterations == repeatedJulia.iterations);

  constexpr const char* kPathKinds[] = {"ellipse", "lissajous", "spiral", "meander"};
  for (const char* pathKind : kPathKinds) {
    scene.path.kind = pathKind;
    scene.path.radiusX = 1.0;
    scene.path.radiusY = 1.0;
    scene.path.translationX = 1.0;
    scene.path.translationY = 1.0;
    scene.path.feedback = 1.0;
    scene.path.spatialLimit = 0.25;
    const TerrainEvaluation bounded = evaluateAnalyticTerrain(scene, {0.75, 100.0, -100.0});
    assert(std::isfinite(bounded.pathX));
    assert(std::isfinite(bounded.pathY));
    assert(std::abs(bounded.pathX) <= 0.5);
    assert(std::abs(bounded.pathY) <= 0.5);
  }
}

void testAnalyticTerrainRejectsInvalidInput() {
  using namespace latticewake;
  Scene scene = validScene();
  scene.terrain.kind = "mandelbrot";
  scene.path.kind = "ellipse";
  const TerrainEvaluation invalidPhase = evaluateAnalyticTerrain(scene, {-0.1, 0.0, 0.0});
  assert(!invalidPhase.escaped && invalidPhase.value == 0.0);

  scene.terrain.kind = "unimplemented";
  const TerrainEvaluation unsupported = evaluateAnalyticTerrain(scene, {0.0, 0.0, 0.0});
  assert(!unsupported.escaped && unsupported.value == 0.0);

  scene.terrain.kind = "mandelbrot";
  scene.path.kind = "unimplemented";
  const TerrainEvaluation unsupportedPath = evaluateAnalyticTerrain(scene, {0.0, 0.0, 0.0});
  assert(!unsupportedPath.escaped && unsupportedPath.value == 0.0);

  scene.path.kind = "ellipse";
  const TerrainEvaluation nonFinite =
      evaluateAnalyticTerrain(scene, {0.0, std::numeric_limits<double>::infinity(), 0.0});
  assert(!nonFinite.escaped && nonFinite.value == 0.0);
}

void testSceneSerializationBoundary() {
  using namespace latticewake;
  Scene scene = validScene();
  SceneSerializationError error;
  const auto serialized = serializeSceneV0(scene, error);
  assert(serialized.has_value());
  const auto parsed = parseSceneV0(*serialized, error);
  assert(parsed.has_value());
  const auto reserialized = serializeSceneV0(*parsed, error);
  assert(reserialized.has_value());
  assert(*serialized == *reserialized);

  assert(!parseSceneV0("{", error).has_value());

  std::string duplicate = *serialized;
  duplicate.insert(duplicate.size() - 1, ",\"title\":\"duplicate\"");
  assert(!parseSceneV0(duplicate, error).has_value());

  std::string unknown = *serialized;
  unknown.insert(unknown.size() - 1, ",\"unknownField\":true");
  assert(!parseSceneV0(unknown, error).has_value());

  std::string unsafeSeed = *serialized;
  const std::size_t seedPosition = unsafeSeed.find("\"seed\":\"42\"");
  assert(seedPosition != std::string::npos);
  unsafeSeed.replace(seedPosition, std::string("\"seed\":\"42\"").size(),
                     "\"seed\":\"18446744073709551616\"");
  assert(!parseSceneV0(unsafeSeed, error).has_value());

  std::string unknownRole = *serialized;
  const std::size_t rolePosition = unknownRole.find("\"motifA\"");
  assert(rolePosition != std::string::npos);
  unknownRole.replace(rolePosition, std::string("\"motifA\"").size(), "\"other\"");
  assert(!parseSceneV0(unknownRole, error).has_value());

  std::string outOfRange = *serialized;
  const std::size_t detailPosition = outOfRange.find("\"detail\":0.5");
  assert(detailPosition != std::string::npos);
  outOfRange.replace(detailPosition, std::string("\"detail\":0.5").size(), "\"detail\":2");
  assert(!parseSceneV0(outOfRange, error).has_value());
}

}  // namespace

int main() {
  testSceneValidation();
  testTraceDeterminismAndOrdering();
  testAnalyticTerrainFixtures();
  testAnalyticTerrainRejectsInvalidInput();
  testSceneSerializationBoundary();
  return 0;
}
