#include "realtime_kernel.hpp"
#include "terrain_evaluator.hpp"
#include <algorithm>
#include <cmath>

namespace latticewake {
bool prepareTerrainPlan(const Scene& scene, double rate, PreparedTerrainPlan& plan) noexcept {
  if (!isValidScene(scene) || !std::isfinite(rate) || rate < 8000 || rate > 192000) return false;
  float mean = 0;
  for (std::size_t i = 0; i < plan.terrainTable.size(); ++i) {
    const auto e = evaluateAnalyticTerrain(scene, {double(i) / double(plan.terrainTable.size()), 0, 0});
    plan.terrainTable[i] = std::isfinite(e.value) ? float(2 * e.value - 1) : 0;
    mean += plan.terrainTable[i] / float(plan.terrainTable.size());
  }
  const auto bounds = std::minmax_element(plan.terrainTable.begin(), plan.terrainTable.end());
  plan.variation = *bounds.second - *bounds.first;
  float peak = 0;
  for (auto& value : plan.terrainTable) { value -= mean; peak = std::max(peak, std::fabs(value)); }
  for (auto& value : plan.terrainTable) value = plan.variation > 1e-6F && peak > 1e-6F ? value / peak : 0;
  // A second terrain-derived spectrum: traverse the same periodic table twice.
  // Both immutable tables share the scene and require no callback preparation.
  for (std::size_t i=0; i<plan.morphTable.size(); ++i)
    plan.morphTable[i] = .35F * plan.terrainTable[i] + .65F * plan.terrainTable[(2*i)%plan.terrainTable.size()];
  plan.sampleRate = float(rate); plan.ready = true;
  return true;
}
bool RealtimeKernel::prepare(const Scene& scene, double rate) noexcept {
  return prepareTerrainPlan(scene, rate, ownedPlan_) && activate(ownedPlan_);
}
bool RealtimeKernel::activate(const PreparedTerrainPlan& plan) noexcept {
  if (!plan.ready || !std::isfinite(plan.sampleRate) || plan.sampleRate < 8000 || plan.sampleRate > 192000) return false;
  activePlan_ = &plan; sampleRate_ = plan.sampleRate; reset(); ready_ = true; return true;
}
void RealtimeKernel::reset() noexcept {
  for (auto& v : voices_) v = {};
  nextAge_ = 0; previousInput_ = previousOutput_ = filterLeft_ = filterRight_ = 0;
  motionPhase_ = glide_ = slide_ = 0; press_ = 1; delayWrite_ = delayWarmup_ = 0;
}
bool RealtimeKernel::render(std::span<float> out, std::span<const KernelEvent> events) noexcept {
  return renderInternal(out, {}, events);
}
bool RealtimeKernel::renderStereo(std::span<float> left, std::span<float> right,
                                  std::span<const KernelEvent> events) noexcept {
  if (left.size() != right.size()) return false;
  return renderInternal(left, right, events);
}
bool RealtimeKernel::renderInternal(std::span<float> out, std::span<float> right,
                                    std::span<const KernelEvent> events) noexcept {
  if (!ready_ || !activePlan_ || events.size() > kMaxEvents ||
      (!right.empty() && right.size() != out.size())) return false;
  std::size_t next = 0;
  const float smoothing = 1.0F - std::exp(-1.0F / (.010F * sampleRate_));
  const float cutoff = 180.0F + 17820.0F * activePlan_->tone * activePlan_->tone;
  const float filterCoefficient = activePlan_->tone >= 0.999F
                                      ? 1.0F
                                      : 1.0F - std::exp(-6.28318530718F * cutoff / sampleRate_);
  const float driveGain = 1.0F + 7.0F * activePlan_->drive;
  const float driveNormalization = std::tanh(driveGain);
  const std::size_t delaySamples = std::clamp<std::size_t>(
      static_cast<std::size_t>(sampleRate_ * 45.0F / std::max(30.0F, activePlan_->tempoBPM)),
      1U, kMaximumDelaySamples - 1U);
  const float wet = 0.34F * activePlan_->space;
  const float feedback = 0.18F + 0.42F * activePlan_->space;
  for (std::size_t f = 0; f < out.size(); ++f) {
    while (next < events.size() && events[next].frame == f) {
      const auto& e = events[next++];
      if (e.expression) {
        const float glide = std::clamp(e.glide, -1.0F, 1.0F);
        const float press = std::clamp(e.press, 0.0F, 1.0F);
        const float slide = std::clamp(e.slide, 0.0F, 1.0F);
        if (e.note < 0) { glide_ = glide; press_ = press; slide_ = slide; }
        for (auto& v : voices_) if (v.active && (e.note < 0 || (v.note == e.note && (e.source == 0 || v.source == e.source)))) {
          v.glide = glide; v.press = press; v.slide = slide;
        }
        continue;
      }
      if (e.noteOn && e.note >= 0 && e.note <= 127 && e.velocity >= 0 && e.velocity <= 1) {
        Voice* target = nullptr;
        bool held = false;
        for (auto& v : voices_) if (v.active && v.note == e.note && v.source == e.source && !v.releasing) held = true;
        if (held) continue;
        for (auto& v : voices_) if (!v.active) { target = &v; break; }
        if (!target) target = &*std::min_element(voices_.begin(), voices_.end(), [](const Voice& a, const Voice& b) { return a.age < b.age; });
        *target = {};
        target->active = true; target->note = e.note; target->source = e.source;
        target->gain = (1.0F - activePlan_->velocityResponse) + e.velocity * activePlan_->velocityResponse;
        target->increment = 440.0F * std::pow(2.0F, (float(e.note) - 69) / 12) / sampleRate_;
        target->glide = glide_; target->press = press_; target->slide = slide_; target->age = nextAge_++;
      } else {
        for (auto& v : voices_) if (v.active && v.note == e.note && (e.source == 0 || v.source == e.source) && !v.releasing) {
          v.releasing = true;
          v.releaseStep = v.envelope / (activePlan_->releaseSeconds * sampleRate_);
        }
      }
    }
    float input = 0;
    for (auto& v : voices_) if (v.active) {
      if (v.releasing) { v.envelope = std::max(0.0F, v.envelope - v.releaseStep); if (v.envelope <= 1e-6F) { v = {}; continue; } }
      else v.envelope = std::min(1.0F, v.envelope + 1.0F / (activePlan_->attackSeconds * sampleRate_));
      v.smoothGlide += smoothing * (v.glide-v.smoothGlide);
      v.smoothSlide += smoothing * (v.slide-v.smoothSlide);
      const float position = v.phase * kTableSize;
      const auto index = std::size_t(position);
      const float fraction = position - float(index);
      const float a = activePlan_->terrainTable[index % kTableSize];
      const float b = activePlan_->terrainTable[(index + 1) % kTableSize];
      const float ma = activePlan_->morphTable[index % kTableSize];
      const float mb = activePlan_->morphTable[(index+1) % kTableSize];
      const float base = a + fraction * (b-a);
      const float morph = ma + fraction * (mb-ma);
      const float routedSlide = activePlan_->gestureTimbreDepth >= 0.0F
                                    ? v.smoothSlide * activePlan_->gestureTimbreDepth
                                    : (1.0F - v.smoothSlide) * -activePlan_->gestureTimbreDepth;
      const float expressionMorph = std::clamp(routedSlide * activePlan_->slideResponse, 0.0F, 1.0F);
      const float slide = std::clamp(activePlan_->surfaceMorph +
                                     expressionMorph * (1.0F - activePlan_->surfaceMorph), 0.0F, 1.0F);
      const float pressure = activePlan_->pressureResponse == 0.0F
                                 ? 1.0F
                                 : std::pow(std::max(0.0F, v.press), activePlan_->pressureResponse);
      const float routedPressure = std::max(0.0F, 1.0F + activePlan_->pressureGainDepth * (pressure - 1.0F));
      input += (base + slide*(morph-base)) * v.gain * routedPressure * v.envelope * activePlan_->gain * 0.125F;
      v.phase += v.increment * std::pow(2.0F, v.smoothGlide * activePlan_->gesturePitchDepth * activePlan_->glideSemitones / 12.0F);
      v.phase -= std::floor(v.phase);
    }
    const float dc = input - previousInput_ + 0.997F * previousOutput_;
    previousInput_ = input; previousOutput_ = dc;
    const float shaped = activePlan_->drive <= 0.0001F
                             ? dc
                             : std::tanh(dc * driveGain) / std::max(0.001F, driveNormalization);
    filterLeft_ += filterCoefficient * (shaped - filterLeft_);
    filterRight_ += filterCoefficient * (shaped - filterRight_);
    const std::size_t readIndex = (delayWrite_ + kMaximumDelaySamples - delaySamples) % kMaximumDelaySamples;
    const bool delayReady = delayWarmup_ >= delaySamples;
    const float delayedLeft = delayReady ? delayLeft_[readIndex] : 0.0F;
    const float delayedRight = delayReady ? delayRight_[readIndex] : 0.0F;
    const float motion = std::sin(motionPhase_) * activePlan_->stereoMotion;
    motionPhase_ += 6.28318530718F * 0.083F / sampleRate_;
    if (motionPhase_ >= 6.28318530718F) motionPhase_ -= 6.28318530718F;
    const float dryLeft = filterLeft_ * (1.0F - 0.22F * motion);
    const float dryRight = filterRight_ * (1.0F + 0.22F * motion);
    const float leftValue = (dryLeft + wet * delayedRight) / (1.0F + std::fabs(dryLeft + wet * delayedRight));
    const float rightValue = (dryRight + wet * delayedLeft) / (1.0F + std::fabs(dryRight + wet * delayedLeft));
    delayLeft_[delayWrite_] = dryLeft + feedback * delayedRight;
    delayRight_[delayWrite_] = dryRight + feedback * delayedLeft;
    delayWrite_ = (delayWrite_ + 1U) % kMaximumDelaySamples;
    if (delayWarmup_ < delaySamples) ++delayWarmup_;
    out[f] = leftValue;
    if (!right.empty()) right[f] = rightValue;
    if (!std::isfinite(out[f]) || (!right.empty() && !std::isfinite(right[f]))) {
      reset(); out[f] = 0; if (!right.empty()) right[f] = 0;
    }
  }
  return next == events.size();
}
}
