#include "LatticewakeBridge.h"

#include <array>
#include <algorithm>
#include <atomic>
#include <cassert>
#include <cmath>
#include <cstdlib>
#include <new>
#include <string_view>

namespace {

std::atomic<bool> countAllocations{false};
std::atomic<unsigned long long> allocations{0};

constexpr const char* kCanonicalScene = R"({"schemaVersion":"latticewake-scene-v0","sceneID":"bridge-frame","seed":"1","title":"Bridge Frame","createdFrom":null,"harmonicContext":{"tonic":"c","mode":"dorian","scaleDegrees":[0,2,3,5,7,9,10],"chordDegree":0,"chordQuality":"minor","inversion":0,"octaveReference":4,"tempoBPM":120,"tuningID":null},"terrain":{"kind":"mandelbrot","detail":0.5,"zoom":0.5,"offsetX":0.5,"offsetY":0.5,"rotation":0,"motion":0,"maxIterations":128,"normalization":1},"path":{"kind":"ellipse","rateRatio":0.5,"radiusX":0.5,"radiusY":0.5,"angle":0,"translationX":0.5,"translationY":0.5,"meander":0,"feedback":0,"spatialLimit":1},"roles":[{"id":"drone","enabled":true,"range":0.5,"density":0.5,"pattern":[0],"rhythm":["note"],"variation":0,"seedOffset":"0","voiceRoute":"internal","midiRoute":""},{"id":"pad","enabled":true,"range":0.5,"density":0.5,"pattern":[0],"rhythm":["note"],"variation":0,"seedOffset":"1","voiceRoute":"internal","midiRoute":""},{"id":"motifA","enabled":true,"range":0.5,"density":0.5,"pattern":[0],"rhythm":["note"],"variation":0,"seedOffset":"2","voiceRoute":"internal","midiRoute":""},{"id":"motifB","enabled":true,"range":0.5,"density":0.5,"pattern":[0],"rhythm":["note"],"variation":0,"seedOffset":"3","voiceRoute":"internal","midiRoute":""}]})";

void testBoundedQueueAndRender() {
  LWKernelRef* const kernel = lw_kernel_create();
  assert(kernel != nullptr);
  assert(lw_kernel_prepare_demo(kernel, 48000.0) == 1);
  assert(lw_kernel_event_queue_capacity() > 0U);

  for (unsigned int index = 0; index < lw_kernel_event_queue_capacity(); ++index) {
    assert(lw_kernel_note_on(kernel, 60 + static_cast<int>(index % 8U), 0.5F) == 1);
  }
  assert(lw_kernel_note_on(kernel, 60, 0.5F) == 0);

  LWKernelStatus before{};
  assert(lw_kernel_status(kernel, &before) == 1);
  assert(before.pending_events == lw_kernel_event_queue_capacity());
  assert(before.dropped_events == 1U);
  assert(before.active_plan_generation == 1U);
  assert(before.pending_plan_generation == 0U);

  std::array<float, 128> output{};
  allocations.store(0, std::memory_order_relaxed);
  countAllocations.store(true, std::memory_order_relaxed);
  assert(lw_kernel_render(kernel, output.data(), static_cast<unsigned int>(output.size())) == 1);
  countAllocations.store(false, std::memory_order_relaxed);
  assert(allocations.load(std::memory_order_relaxed) == 0U);
  for (const float sample : output) {
    assert(sample >= -1.0F && sample <= 1.0F);
  }

  LWKernelStatus after{};
  assert(lw_kernel_status(kernel, &after) == 1);
  assert(after.pending_events == before.pending_events - 256U);
  assert(after.dropped_events == before.dropped_events);
  assert(lw_kernel_prepare_demo(kernel, 48000.0) == 0);
  assert(lw_kernel_publish_demo(kernel, 48000.0) == 1);
  assert(lw_kernel_publish_demo(kernel, 48000.0) == 0);
  LWKernelStatus pending{};
  assert(lw_kernel_status(kernel, &pending) == 1);
  assert(pending.active_plan_generation == 1U);
  assert(pending.pending_plan_generation == 2U);
  allocations.store(0, std::memory_order_relaxed);
  countAllocations.store(true, std::memory_order_relaxed);
  assert(lw_kernel_render(kernel, output.data(), static_cast<unsigned int>(output.size())) == 1);
  countAllocations.store(false, std::memory_order_relaxed);
  assert(allocations.load(std::memory_order_relaxed) == 0U);
  LWKernelStatus adopted{};
  assert(lw_kernel_status(kernel, &adopted) == 1);
  assert(adopted.active_plan_generation == 2U);
  assert(adopted.pending_plan_generation == 0U);
  lw_kernel_destroy(kernel);
}

void testQueueResetAndInvalidStatus() {
  LWKernelRef* const kernel = lw_kernel_create();
  assert(kernel != nullptr);
  assert(lw_kernel_note_on(kernel, 60, 0.7F) == 1);
  lw_kernel_reset(kernel);
  LWKernelStatus status{};
  assert(lw_kernel_status(kernel, &status) == 1);
  assert(status.pending_events == 0U && status.dropped_events == 0U);
  assert(lw_kernel_status(nullptr, &status) == 0);
  assert(lw_kernel_status(kernel, nullptr) == 0);
  lw_kernel_destroy(kernel);
}

void testCallbackOwnedPanicRecoversOverload() {
  LWKernelRef* const kernel = lw_kernel_create();
  assert(kernel != nullptr);
  assert(lw_kernel_prepare_demo(kernel, 48000.0) == 1);
  for (unsigned int index = 0; index < lw_kernel_event_queue_capacity(); ++index) {
    assert(lw_kernel_note_on(kernel, 60 + static_cast<int>(index % 8U), 0.7F) == 1);
  }
  assert(lw_kernel_note_on(kernel, 60, 0.7F) == 0);
  assert(lw_kernel_panic(kernel) == 1);
  std::array<float, 256> output{};
  assert(lw_kernel_render(kernel, output.data(), static_cast<unsigned int>(output.size())) == 1);
  for (const float sample : output) { assert(sample == 0.0F); }
  LWKernelStatus status{};
  assert(lw_kernel_status(kernel, &status) == 1);
  assert(status.pending_events == 0U);
  assert(lw_kernel_note_on_source(kernel, 60, 0.7F, 17U) == 1);
  assert(lw_kernel_render(kernel, output.data(), static_cast<unsigned int>(output.size())) == 1);
  assert(std::any_of(output.begin(), output.end(), [](const float sample) { return std::abs(sample) > 0.0F; }));
  lw_kernel_destroy(kernel);
}

void testTerrainFrameSnapshotBoundary() {
  std::array<LWTerrainFramePoint, 32> first{};
  std::array<LWTerrainFramePoint, 32> repeated{};
  unsigned int firstCount = 0;
  unsigned int repeatedCount = 0;
  assert(lw_terrain_frame_scene_json(kCanonicalScene, 480, 0.0, 1.0 / 31.0,
                                     first.data(), static_cast<unsigned int>(first.size()), &firstCount) == 1);
  assert(lw_terrain_frame_scene_json(kCanonicalScene, 480, 0.0, 1.0 / 31.0,
                                     repeated.data(), static_cast<unsigned int>(repeated.size()), &repeatedCount) == 1);
  assert(firstCount == first.size() && firstCount == repeatedCount);
  for (unsigned int index = 0; index < firstCount; ++index) {
    assert(std::isfinite(first[index].value));
    assert(first[index].value >= 0.0F && first[index].value <= 1.0F);
    assert(first[index].value == repeated[index].value);
    assert(first[index].path_x == repeated[index].path_x);
    assert(first[index].path_y == repeated[index].path_y);
  }
  assert(lw_terrain_frame_scene_json(kCanonicalScene, 0, 0.0, 0.0,
                                     first.data(), 0, &firstCount) == 0);
}

void testSceneV1BridgeMigrationAndPreparation() {
  char* first = nullptr;
  char* repeated = nullptr;
  assert(lw_scene_migrate_v1_json(kCanonicalScene, "sha256:fixture", &first) == 1);
  assert(first != nullptr);
  assert(lw_scene_migrate_v1_json(kCanonicalScene, "sha256:fixture", &repeated) == 1);
  assert(repeated != nullptr);
  assert(std::string_view(first) == std::string_view(repeated));
  assert(std::string_view(first).find("\"schemaVersion\":\"latticewake-scene-v1\"") != std::string_view::npos);

  LWKernelRef* const kernel = lw_kernel_create();
  LWKernelRef* const legacyKernel = lw_kernel_create();
  assert(kernel != nullptr && legacyKernel != nullptr);
  assert(lw_kernel_prepare_scene_json(kernel, first, 48000.0) == 1);
  assert(lw_kernel_prepare_scene_json(legacyKernel, kCanonicalScene, 48000.0) == 1);
  std::array<float, 512> output{};
  std::array<float, 512> legacyOutput{};
  assert(lw_kernel_note_on(kernel, 60, 0.7F) == 1);
  assert(lw_kernel_note_on(legacyKernel, 60, 0.7F) == 1);
  assert(lw_kernel_render(kernel, output.data(), static_cast<unsigned int>(output.size())) == 1);
  assert(lw_kernel_render(legacyKernel, legacyOutput.data(), static_cast<unsigned int>(legacyOutput.size())) == 1);
  assert(output == legacyOutput);

  LWSceneEditorControls editor{};
  assert(lw_scene_editor_controls(first, &editor) == 1);
  assert(editor.attack_seconds == 0.010);
  editor.terrain_detail = 0.75;
  editor.terrain_zoom = 0.0;
  editor.traversal_rate_ratio = 1.0;
  editor.traversal_radius_y = 0.20;
  editor.traversal_translation_x = 0.60;
  editor.attack_seconds = 0.040;
  editor.release_seconds = 0.240;
  editor.gain = 0.5;
  char* editedEditor = nullptr;
  assert(lw_scene_apply_editor_controls(first, &editor, &editedEditor) == 1);
  assert(editedEditor != nullptr);
  LWSceneEditorControls roundTripEditor{};
  assert(lw_scene_editor_controls(editedEditor, &roundTripEditor) == 1);
  assert(roundTripEditor.terrain_detail == editor.terrain_detail);
  assert(roundTripEditor.traversal_radius_y == editor.traversal_radius_y);
  assert(roundTripEditor.attack_seconds == editor.attack_seconds);
  assert(roundTripEditor.gain == editor.gain);
  LWKernelRef* const editedKernel = lw_kernel_create();
  assert(editedKernel != nullptr);
  assert(lw_kernel_prepare_scene_json(editedKernel, editedEditor, 48000.0) == 1);
  std::array<float, 512> editedOutput{};
  assert(lw_kernel_note_on(editedKernel, 60, 0.7F) == 1);
  assert(lw_kernel_render(editedKernel, editedOutput.data(), static_cast<unsigned int>(editedOutput.size())) == 1);
  assert(editedOutput != output);
  lw_kernel_destroy(editedKernel);
  lw_string_destroy(editedEditor);

  LWModulationControls modulation{};
  assert(lw_scene_modulation_controls(first, &modulation) == 1);
  assert(modulation.pitch_enabled == 1U && modulation.pitch_depth == 1.0F);
  modulation.pitch_depth = 0.5F;
  modulation.timbre_enabled = 0U;
  modulation.gain_depth = -0.25F;
  char* editedModulation = nullptr;
  assert(lw_scene_apply_modulation_controls(first, &modulation, &editedModulation) == 1);
  LWModulationControls modulationRoundTrip{};
  assert(lw_scene_modulation_controls(editedModulation, &modulationRoundTrip) == 1);
  assert(modulationRoundTrip.pitch_depth == 0.5F);
  assert(modulationRoundTrip.timbre_enabled == 0U);
  assert(modulationRoundTrip.gain_depth == -0.25F);
  lw_string_destroy(editedModulation);

  LWRoleControl control{};
  assert(lw_scene_role_control(first, 0, &control) == 1);
  control.density = 0.75F;
  char* edited = nullptr;
  assert(lw_scene_apply_role_control(first, 0, &control, &edited) == 1);
  assert(edited != nullptr);
  assert(std::string_view(edited).find("\"schemaVersion\":\"latticewake-scene-v1\"") != std::string_view::npos);
  lw_string_destroy(edited);
  lw_kernel_destroy(legacyKernel);
  lw_kernel_destroy(kernel);
  lw_string_destroy(repeated);
  lw_string_destroy(first);
}

void testMpeBridgeState() {
  LWMpeStateRef* const lower = lw_mpe_state_create(1, 1, 2);
  assert(lower != nullptr);
  assert(lw_mpe_note_on(lower, 1, 60) == 0);
  assert(lw_mpe_note_on(lower, 2, 60) == 1);
  assert(lw_mpe_expression(lower, 2, 0.25F, 0.5F, 0.75F) == 1);
  int note = 0;
  assert(lw_mpe_active_note(lower, 2, &note) == 1 && note == 60);
  assert(lw_mpe_note_off(lower, 2, 60) == 1);
  lw_mpe_reset(lower);
  lw_mpe_state_destroy(lower);
  assert(lw_mpe_state_create(3, 1, 1) == nullptr);
}

void testRoleControlCanonicalBoundary() {
  LWRoleControl control{};
  assert(lw_scene_role_control(kCanonicalScene, 2, &control) == 1);
  control.enabled = 0;
  control.density = 0.75F;
  control.seed_offset = 99;
  control.pattern = 5;
  char* updated = nullptr;
  assert(lw_scene_apply_role_control(kCanonicalScene, 2, &control, &updated) == 1);
  LWRoleControl repeated{};
  assert(lw_scene_role_control(updated, 2, &repeated) == 1);
  assert(repeated.enabled == 0U && repeated.density == 0.75F && repeated.seed_offset == 99U && repeated.pattern == 5U);
  lw_string_destroy(updated);
}

void testRolePreviewBoundary() {
  LWRoleTraceSummary first{};
  LWRoleTraceSummary repeated{};
  assert(lw_role_preview_scene_json(kCanonicalScene, 0, 48000, 48000.0, &first) == 1);
  assert(lw_role_preview_scene_json(kCanonicalScene, 0, 48000, 48000.0, &repeated) == 1);
  assert(first.event_count > 0U);
  assert(first.event_count == repeated.event_count);
  assert(first.first_sample == repeated.first_sample);
  assert(first.last_sample == repeated.last_sample);
  assert(first.receipt == repeated.receipt);
  unsigned long long laneCounts[4]{};
  assert(lw_role_preview_lane_event_counts_scene_json(kCanonicalScene, 0, 48000, 48000.0, laneCounts) == 1);
  assert(laneCounts[0] + laneCounts[1] + laneCounts[2] + laneCounts[3] == first.event_count);
  assert(lw_role_preview_scene_json(kCanonicalScene, 0, 0, 48000.0, &first) == 0);
}

void testPreparedRoleTransportAndSourceOwnership() {
  LWKernelRef* const kernel = lw_kernel_create();
  assert(kernel != nullptr);
  assert(lw_kernel_prepare_demo(kernel, 48000.0) == 1);
  LWRoleStatus ready{};
  assert(lw_kernel_role_status(kernel, &ready) == 1);
  assert(ready.running == 0U && ready.loop_frames == 192000U);
  // Two direct sources may own the same pitch. Releasing one must not release
  // the other, and role sources are a separate address space again.
  assert(lw_kernel_note_on_source(kernel, 60, 0.7F, 1) == 1);
  assert(lw_kernel_note_on_source(kernel, 60, 0.7F, 2) == 1);
  assert(lw_kernel_note_off_source(kernel, 60, 1) == 1);
  std::array<float, 256> output{};
  assert(lw_kernel_render(kernel, output.data(), static_cast<unsigned int>(output.size())) == 1);
  double directEnergy = 0;
  for(const float sample: output) directEnergy += std::abs(sample);
  assert(directEnergy > 0.01);

  lw_kernel_set_roles_running(kernel, 1);
  allocations.store(0, std::memory_order_relaxed);
  countAllocations.store(true, std::memory_order_relaxed);
  assert(lw_kernel_render(kernel, output.data(), static_cast<unsigned int>(output.size())) == 1);
  countAllocations.store(false, std::memory_order_relaxed);
  assert(allocations.load(std::memory_order_relaxed) == 0U);
  LWRoleStatus playing{};
  assert(lw_kernel_role_status(kernel, &playing) == 1);
  assert(playing.running == 1U && playing.active_lanes == 4U && playing.loop_frames == ready.loop_frames);
  double roleEnergy = 0;
  for(const float sample: output) roleEnergy += std::abs(sample);
  assert(roleEnergy > 0.01);

  lw_kernel_set_roles_running(kernel, 0);
  for(unsigned int block=0; block<64U; ++block) {
    assert(lw_kernel_render(kernel, output.data(), static_cast<unsigned int>(output.size())) == 1);
  }
  LWRoleStatus stopped{};
  assert(lw_kernel_role_status(kernel, &stopped) == 1);
  assert(stopped.running == 0U && stopped.active_lanes == 0U);
  lw_kernel_destroy(kernel);
}

void testCallbackRouteStressAndBounds() {
  assert(lw_kernel_maximum_callback_frames() == 4096U);
  std::array<float, 4096> output{};
  constexpr std::array<unsigned int, 6> frameCounts{32U, 64U, 128U, 256U, 512U, 1024U};
  constexpr std::array<double, 3> sampleRates{44100.0, 48000.0, 96000.0};
  std::array<LWKernelRef*, sampleRates.size()> kernels{};
  for (std::size_t index = 0; index < kernels.size(); ++index) {
    kernels[index] = lw_kernel_create();
    assert(kernels[index] != nullptr);
    assert(lw_kernel_prepare_demo(kernels[index], sampleRates[index]) == 1);
  }
  allocations.store(0, std::memory_order_relaxed);
  countAllocations.store(true, std::memory_order_relaxed);
  for (LWKernelRef* const kernel : kernels) {
    unsigned long long expectedFrames = 0;
    for (unsigned int iteration = 0; iteration < 400U; ++iteration) {
      assert(lw_kernel_note_on(kernel, 60 + static_cast<int>(iteration % 8U), 0.6F) == 1);
      const unsigned int frames = frameCounts[iteration % frameCounts.size()];
      assert(lw_kernel_render(kernel, output.data(), frames) == 1);
      expectedFrames += frames;
    }
    LWCallbackStatus status{};
    assert(lw_kernel_callback_status(kernel, &status) == 1);
    assert(status.callback_count == 400U);
    assert(status.rendered_frames == expectedFrames);
    assert(status.render_failures == 0U);
    assert(status.maximum_render_nanoseconds > 0U);
    assert(status.maximum_callback_frames == output.size());
    assert(lw_kernel_render(kernel, output.data(), status.maximum_callback_frames + 1U) == 0);
    assert(lw_kernel_callback_status(kernel, &status) == 1);
    assert(status.render_failures == 1U);
  }
  countAllocations.store(false, std::memory_order_relaxed);
  assert(allocations.load(std::memory_order_relaxed) == 0U);
  for (LWKernelRef* const kernel : kernels) { lw_kernel_destroy(kernel); }
}

}  // namespace

void* operator new(const std::size_t size) {
  if (countAllocations.load(std::memory_order_relaxed)) {
    allocations.fetch_add(1, std::memory_order_relaxed);
  }
  if (void* const result = std::malloc(size)) {
    return result;
  }
  throw std::bad_alloc();
}

void operator delete(void* const pointer) noexcept { std::free(pointer); }

void* operator new[](const std::size_t size) {
  return ::operator new(size);
}

void operator delete[](void* const pointer) noexcept { ::operator delete(pointer); }

int main() {
  testBoundedQueueAndRender();
  testQueueResetAndInvalidStatus();
  testCallbackOwnedPanicRecoversOverload();
  testTerrainFrameSnapshotBoundary();
  testSceneV1BridgeMigrationAndPreparation();
  testMpeBridgeState();
  testRoleControlCanonicalBoundary();
  testRolePreviewBoundary();
  testPreparedRoleTransportAndSourceOwnership();
  testCallbackRouteStressAndBounds();
  return 0;
}
