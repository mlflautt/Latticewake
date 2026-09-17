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
  float attackSeconds{0.010F};
  float releaseSeconds{0.120F};
  float gain{1.0F};
  float glideSemitones{12.0F};
  float velocityResponse{1.0F};
  float pressureResponse{1.0F};
  float slideResponse{1.0F};
  float gesturePitchDepth{1.0F};
  float gestureTimbreDepth{1.0F};
  float pressureGainDepth{1.0F};
  float surfaceMorph{};
  float tone{1.0F};
  float drive{};
  float space{};
  float stereoMotion{};
  float tempoBPM{120.0F};
  bool ready{};
};
bool prepareTerrainPlan(const Scene& scene, double sampleRate, PreparedTerrainPlan& plan) noexcept;
class RealtimeKernel {
 public:
  static constexpr std::size_t kTableSize=2048, kMaxVoices=8, kMaxEvents=256;
  bool prepare(const Scene& scene, double sampleRate) noexcept;
  bool activate(const PreparedTerrainPlan& plan) noexcept;
  bool render(std::span<float> mono, std::span<const KernelEvent> events) noexcept;
  bool renderStereo(std::span<float> left, std::span<float> right,
                    std::span<const KernelEvent> events) noexcept;
  void reset() noexcept;
 private:
  struct Voice { bool active{}; int note{}; std::uint32_t source{}; float phase{}; float increment{}; float gain{}; float glide{}; float press{1.0F}; float slide{}; float envelope{}; bool releasing{}; float releaseStep{}; std::size_t age{}; float smoothGlide{}; float smoothSlide{}; };
  static constexpr std::size_t kMaximumDelaySamples=192000;
  bool renderInternal(std::span<float> left, std::span<float> right,
                      std::span<const KernelEvent> events) noexcept;
  std::size_t nextAge_{};
  PreparedTerrainPlan ownedPlan_{}; const PreparedTerrainPlan* activePlan_{}; std::array<Voice,kMaxVoices> voices_{};
  std::array<float,kMaximumDelaySamples> delayLeft_{}, delayRight_{};
  std::size_t delayWrite_{}, delayWarmup_{};
  float sampleRate_{48000}, previousInput_{}, previousOutput_{}, filterLeft_{}, filterRight_{},
        motionPhase_{}, glide_{}, press_{1.0F}, slide_{}; bool ready_{};
}; }
