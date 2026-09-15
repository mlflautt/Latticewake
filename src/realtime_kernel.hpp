#pragma once
#include "scene.hpp"
#include <array>
#include <cstddef>
#include <span>
namespace latticewake {
struct KernelEvent { std::size_t frame{}; bool noteOn{}; int note{}; float velocity{}; float glide{}; float press{1.0F}; float slide{}; bool expression{}; std::uint32_t source{}; };
struct PreparedTerrainPlan {
  std::array<float, 2048> terrainTable{};
  std::array<float, 2048> morphTable{};
  float sampleRate{};
  float variation{};
  bool ready{};
};
bool prepareTerrainPlan(const Scene& scene, double sampleRate, PreparedTerrainPlan& plan) noexcept;
class RealtimeKernel {
 public:
  static constexpr std::size_t kTableSize=2048, kMaxVoices=8, kMaxEvents=256;
  bool prepare(const Scene& scene, double sampleRate) noexcept;
  bool activate(const PreparedTerrainPlan& plan) noexcept;
  bool render(std::span<float> mono, std::span<const KernelEvent> events) noexcept;
  void reset() noexcept;
 private:
  struct Voice { bool active{}; int note{}; std::uint32_t source{}; float phase{}; float increment{}; float gain{}; float glide{}; float press{1.0F}; float slide{}; float envelope{}; bool releasing{}; float releaseStep{}; std::size_t age{}; float smoothGlide{}; float smoothSlide{}; };
  std::size_t nextAge_{};
  PreparedTerrainPlan ownedPlan_{}; const PreparedTerrainPlan* activePlan_{}; std::array<Voice,kMaxVoices> voices_{};
  float sampleRate_{48000}, previousInput_{}, previousOutput_{}, glide_{}, press_{1.0F}, slide_{}; bool ready_{};
}; }
