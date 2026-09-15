#include "event_trace.hpp"
#include "direct_play.hpp"
#include "offline_terrain_voice.hpp"
#include "mpe_state.hpp"
#include "realtime_kernel.hpp"
#include "offline_oversampling.hpp"
#include "proposals.hpp"
#include "role_event_generator.hpp"
#include "sample_transport.hpp"
#include "scene.hpp"
#include "scene_serialization.hpp"
#include "terrain_evaluator.hpp"
#include "terrain_frame.hpp"

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

void testOfflineTerrainVoice() {
  using namespace latticewake;
  std::vector<TerrainEvaluation> trace;
  trace.reserve(4800);
  for (int index = 0; index < 4800; ++index) {
    trace.push_back({1.0, 0.0, 0.0, 1, true});
  }
  OfflineTerrainVoiceError error;
  const OfflineTerrainVoiceConfig config{48000.0, 1.0, 20.0};
  const auto rendered = renderOfflineTerrainVoice(trace, config, error);
  const auto repeated = renderOfflineTerrainVoice(trace, config, error);
  assert(rendered.has_value());
  assert(repeated.has_value());
  assert(*rendered == *repeated);
  assert(rendered->size() == trace.size());
  double tailSum = 0.0;
  for (std::size_t index = 0; index < rendered->size(); ++index) {
    assert(std::isfinite((*rendered)[index]));
    assert((*rendered)[index] >= -1.0 && (*rendered)[index] <= 1.0);
    if (index >= rendered->size() - 480U) {
      tailSum += std::abs((*rendered)[index]);
    }
  }
  assert(tailSum / 480.0 < 0.001);

  OfflineTerrainVoiceConfig invalidConfig = config;
  invalidConfig.sampleRate = 0.0;
  assert(!renderOfflineTerrainVoice(trace, invalidConfig, error).has_value());
  assert(error.field == "sampleRate");

  trace[10].value = std::numeric_limits<double>::quiet_NaN();
  assert(!renderOfflineTerrainVoice(trace, config, error).has_value());
  assert(error.field == "trace[10].value");
}

void testSampleClockTransport() {
  using namespace latticewake;
  SampleTransportError error;
  const SampleTransportConfig config{48000.0, 120.0};
  const auto position = advanceSampleTransport({}, 48000, config, error);
  assert(position.has_value());
  assert(position->sampleOffset == 48000);
  assert(position->beatPosition == 2.0);
  assert(position->beatPhase == 0.0);
  const auto oneBeat = sampleOffsetForBeat(1.0, config, error);
  assert(oneBeat.has_value() && *oneBeat == 24000);
  assert(!sampleOffsetForBeat(-1.0, config, error).has_value());
}

void testProposalPreviewBoundary() {
  using namespace latticewake;
  MelodyProposal proposal{"proposal-001", "scene-001", "test", {{0.0, 1.0, 0, 0.7}, {0.5, 0.5, 2, 0.6}}};
  assert(validateMelodyProposal(proposal).empty());
  ProposalValidationIssue error;
  const auto preview = previewMelodyProposal(proposal, {48000.0, 120.0}, error);
  assert(preview.has_value());
  assert(preview->events().size() == 4);
  assert(preview->events()[0].sampleOffset == 0);
  assert(preview->events()[1].sampleOffset == 12000);
  assert(preview->events()[0].origin == EventOrigin::proposal);
  assert(preview->validate().empty());

  proposal.notes[0].velocity = 2.0;
  assert(!validateMelodyProposal(proposal).empty());
  assert(!previewMelodyProposal(proposal, {48000.0, 120.0}, error).has_value());

  SceneProposal sceneProposal{"scene-proposal", "scene-001", "test", {{ScenePatchTarget::terrainDetail, 0.4}}};
  assert(validateSceneProposal(sceneProposal).empty());
  sceneProposal.patches[0].value = -0.1;
  assert(!validateSceneProposal(sceneProposal).empty());
}

void testOfflineOversamplingHarness() {
  using namespace latticewake;
  const std::vector<TerrainEvaluation> trace = {{0.0}, {1.0}, {0.0}, {1.0}};
  const OfflineTerrainVoiceConfig config{48000.0, 0.5, 20.0};
  OfflineTerrainVoiceError error;
  const auto direct = renderOfflineTerrainVoice(trace, config, error);
  const auto one = renderOversampledTerrainVoice(trace, config, OversamplingFactor::x1, error);
  assert(direct.has_value() && one.has_value());
  assert(*direct == one->samples);
  for (const OversamplingFactor factor : {OversamplingFactor::x2, OversamplingFactor::x4}) {
    const auto result = renderOversampledTerrainVoice(trace, config, factor, error);
    assert(result.has_value());
    assert(result->samples.size() == trace.size());
    assert(std::isfinite(result->transitionEnergy) && result->transitionEnergy >= 0.0);
    for (const double sample : result->samples) {
      assert(std::isfinite(sample));
      assert(sample >= -1.0 && sample <= 1.0);
    }
  }
}

void testFourRoleEventGeneration() {
  using namespace latticewake;
  Scene scene = validScene();
  scene.roles[1].enabled = false;
  RoleEventGenerationError error;
  const SampleTransportConfig transport{48000.0, 120.0};
  const auto trace = generateRoleEvents(scene, 0, 48000, transport, error);
  const auto repeated = generateRoleEvents(scene, 0, 48000, transport, error);
  assert(trace.has_value() && repeated.has_value());
  assert(!trace->events().empty());
  assert(trace->canonicalBytes() == repeated->canonicalBytes());
  assert(trace->validate().empty());
  for (const auto& event : trace->events()) {
    assert(event.origin == EventOrigin::generator);
    assert(event.payload.at("lane") != "pad");
  }

  for (auto& role : scene.roles) role.enabled = false;
  const auto silent = generateRoleEvents(scene, 0, 48000, transport, error);
  assert(silent.has_value() && silent->events().empty());

  scene = validScene();
  for (auto& role : scene.roles) {
    role.density = 1.0;
    role.rhythm = {{RhythmStepKind::note}};
  }
  assert(!generateRoleEvents(scene, 0, 48000U * 1000U, transport, error).has_value());
  assert(error.field == "events");
}

void testDirectPlayAndTerrainFrames() {
  using namespace latticewake;
  const auto key = qwertyEvent("a", true, 42);
  const auto release = qwertyEvent("a", false, 42);
  assert(key.has_value() && release.has_value());
  assert(key->note == 60 && key->type == DirectPlayType::noteOn);
  assert(release->type == DirectPlayType::noteOff);
  assert(!qwertyEvent("z", true, 0).has_value());
  const auto trackpad = smoothTrackpad({}, 1.0, 0.25, 0.5, 0.5);
  assert(trackpad.has_value());
  assert(trackpad->glide == 0.5 && trackpad->slide == 0.125 && trackpad->press == 0.25);
  assert(!smoothTrackpad({}, 2.0, 0.0, 0.0, 0.0).has_value());

  Scene scene = validScene();
  scene.terrain.kind = "mandelbrot";
  TerrainFrameError error;
  const TerrainFrameRequest request{128, 0.0, 0.1, 5};
  const auto frame = buildTerrainFrame(scene, request, error);
  const auto repeated = buildTerrainFrame(scene, request, error);
  assert(frame.has_value() && repeated.has_value());
  assert(frame->sceneId == "scene-001" && frame->sampleOffset == 128);
  assert(frame->points.size() == 5 && frame->points[2].value == repeated->points[2].value);
  assert(!buildTerrainFrame(scene, {0, 0.9, 0.1, 3}, error).has_value());
}
void testMpeState() { using namespace latticewake; MpeState lower({MpeMode::lower,1,2}); assert(!lower.noteOn(1,60)); assert(lower.noteOn(2,60)); assert(lower.expression(2,{0.2,0.3,0.4})); assert(lower.active(2)->expression.press==0.3); assert(!lower.noteOn(2,61)); assert(lower.noteOff(2,60)); MpeState upper({MpeMode::upper,16,2}); assert(upper.noteOn(15,62)); MpeState legacy({MpeMode::legacy,4,1}); assert(legacy.noteOn(4,64)); assert(!legacy.noteOn(5,64)); }
void testRealtimeKernel() { using namespace latticewake; Scene scene=validScene();scene.terrain.kind="mandelbrot";RealtimeKernel kernel;assert(kernel.prepare(scene,48000));std::array<float,128> buffer{};const std::array<KernelEvent,2> events={{{0,true,60,0.5F},{96,false,60,0}}};assert(kernel.render(buffer,events));for(float s:buffer)assert(std::isfinite(s)&&s>=-1&&s<=1);std::array<KernelEvent,RealtimeKernel::kMaxEvents+1> tooMany{};assert(!kernel.render(buffer,tooMany));kernel.reset();const std::array<KernelEvent,3> independentNotes={{{0,true,60,0.5F},{0,true,64,0.5F},{1,false,64,0}}};assert(kernel.render(buffer,independentNotes)); }

}  // namespace

int main() {
  testSceneValidation();
  testTraceDeterminismAndOrdering();
  testAnalyticTerrainFixtures();
  testAnalyticTerrainRejectsInvalidInput();
  testSceneSerializationBoundary();
  testOfflineTerrainVoice();
  testSampleClockTransport();
  testProposalPreviewBoundary();
  testOfflineOversamplingHarness();
  testFourRoleEventGeneration();
  testDirectPlayAndTerrainFrames();
  testMpeState();
  testRealtimeKernel();
  return 0;
}
