#pragma once

#include "realtime_kernel.hpp"

#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>

namespace latticewake {

// This queue has exactly one producer and one consumer. In the standalone app,
// SwiftUI input is the producer and the audio render callback is the consumer.
// A future Core MIDI path must feed a designated producer/multiplexer rather
// than write this queue from a second producer thread.
class RealtimeEventQueue {
 public:
  static constexpr std::uint32_t kStorageCapacity = 1024;
  static constexpr std::uint32_t kUsableCapacity = kStorageCapacity - 1;

  bool tryPush(const KernelEvent& event) noexcept {
    const std::uint32_t write = writeIndex_.load(std::memory_order_relaxed);
    const std::uint32_t next = increment(write);
    if (next == readIndex_.load(std::memory_order_acquire)) {
      dropped_.fetch_add(1, std::memory_order_relaxed);
      return false;
    }
    events_[write] = event;
    writeIndex_.store(next, std::memory_order_release);
    return true;
  }

  bool tryPop(KernelEvent& event) noexcept {
    const std::uint32_t read = readIndex_.load(std::memory_order_relaxed);
    if (read == writeIndex_.load(std::memory_order_acquire)) {
      return false;
    }
    event = events_[read];
    readIndex_.store(increment(read), std::memory_order_release);
    return true;
  }

  std::uint32_t pending() const noexcept {
    const std::uint32_t write = writeIndex_.load(std::memory_order_acquire);
    const std::uint32_t read = readIndex_.load(std::memory_order_acquire);
    return write >= read ? write - read : kStorageCapacity - read + write;
  }

  std::uint32_t dropped() const noexcept { return dropped_.load(std::memory_order_relaxed); }

  void resetProducerSide() noexcept {
    const std::uint32_t read = readIndex_.load(std::memory_order_acquire);
    writeIndex_.store(read, std::memory_order_release);
    dropped_.store(0, std::memory_order_relaxed);
  }

  // The audio consumer alone may discard pending input. Loading the producer
  // cursor before publishing the new read cursor preserves any event written
  // after that load, while removing everything already pending at the panic
  // boundary. This is deliberately not callable from the producer thread.
  void discardPendingConsumerSide() noexcept {
    const std::uint32_t write = writeIndex_.load(std::memory_order_acquire);
    readIndex_.store(write, std::memory_order_release);
  }

 private:
  static_assert(std::atomic<std::uint32_t>::is_always_lock_free,
                "Latticewake requires lock-free uint32 atomics for audio event handoff");
  static constexpr std::uint32_t increment(const std::uint32_t index) noexcept {
    return (index + 1U) & (kStorageCapacity - 1U);
  }

  std::array<KernelEvent, kStorageCapacity> events_{};
  alignas(64) std::atomic<std::uint32_t> writeIndex_{0};
  alignas(64) std::atomic<std::uint32_t> readIndex_{0};
  std::atomic<std::uint32_t> dropped_{0};
};

}  // namespace latticewake
