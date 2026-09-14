#include "event_trace.hpp"
#include "scene.hpp"

#include <cassert>
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

}  // namespace

int main() {
  testSceneValidation();
  testTraceDeterminismAndOrdering();
  return 0;
}
