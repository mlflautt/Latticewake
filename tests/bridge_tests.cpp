#include "LatticewakeBridge.h"

#include <array>
#include <atomic>
#include <cassert>
#include <cstdlib>
#include <new>

namespace {

std::atomic<bool> countAllocations{false};
std::atomic<unsigned long long> allocations{0};

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
  return 0;
}
