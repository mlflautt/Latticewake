#pragma once
#include "scene.hpp"
#include <array>
#include <cstddef>
#include <span>
namespace latticewake {
struct KernelEvent { std::size_t frame{}; bool noteOn{}; int note{}; float velocity{}; float glide{}; float press{1.0F}; float slide{}; bool expression{}; };
class RealtimeKernel {
 public:
  static constexpr std::size_t kTableSize=2048, kMaxVoices=8, kMaxEvents=256;
  bool prepare(const Scene& scene, double sampleRate) noexcept;
  bool render(std::span<float> mono, std::span<const KernelEvent> events) noexcept;
  void reset() noexcept;
 private:
  struct Voice { bool active{}; float phase{}; float increment{}; float gain{}; };
  std::array<float,kTableSize> table_{}; std::array<Voice,kMaxVoices> voices_{};
  float sampleRate_{48000}, previousInput_{}, previousOutput_{}, glide_{}, press_{1.0F}, slide_{}; bool ready_{};
}; }
