#include "LatticewakeBridge.h"

#include <array>
#include <atomic>
#include <cassert>
#include <cmath>
#include <cstdlib>
#include <new>

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
  control.pattern = 2;
  char* updated = nullptr;
  assert(lw_scene_apply_role_control(kCanonicalScene, 2, &control, &updated) == 1);
  LWRoleControl repeated{};
  assert(lw_scene_role_control(updated, 2, &repeated) == 1);
  assert(repeated.enabled == 0U && repeated.density == 0.75F && repeated.seed_offset == 99U);
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
  assert(lw_role_preview_scene_json(kCanonicalScene, 0, 0, 48000.0, &first) == 0);
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
  testTerrainFrameSnapshotBoundary();
  testMpeBridgeState();
  testRoleControlCanonicalBoundary();
  testRolePreviewBoundary();
  return 0;
}
