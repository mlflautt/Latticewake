#include "terrain_evaluator.hpp"

#include <algorithm>
#include <cmath>
#include <numbers>
#include <string_view>

namespace latticewake {
namespace {

constexpr double kBailoutSquared = 16.0;
constexpr double kLogTwo = 0.69314718055994530942;

bool finite(const double value) { return std::isfinite(value); }

double clampUnit(const double value) { return std::clamp(value, 0.0, 1.0); }

bool isSupportedPath(const std::string_view kind) {
  return kind == "ellipse" || kind == "lissajous" || kind == "spiral" ||
         kind == "meander";
}

bool isSupportedTerrain(const std::string_view kind) {
  return kind == "mandelbrot" || kind == "julia";
}

TerrainEvaluation neutral() { return {}; }

}  // namespace

TerrainEvaluation evaluateAnalyticTerrain(const Scene& scene,
                                          const TerrainSampleInput& input) noexcept {
  if (!isValidScene(scene) || !finite(input.phase) || input.phase < 0.0 ||
      input.phase > 1.0 || !finite(input.feedbackX) || !finite(input.feedbackY) ||
      !isSupportedPath(scene.path.kind) || !isSupportedTerrain(scene.terrain.kind)) {
    return neutral();
  }

  const double tau = 2.0 * std::numbers::pi_v<double>;
  const double theta = tau * (input.phase * scene.path.rateRatio + scene.path.angle);
  const double limit = 2.0 * scene.path.spatialLimit;
  double x = 0.0;
  double y = 0.0;
  if (scene.path.kind == "ellipse") {
    x = scene.path.radiusX * std::cos(theta);
    y = scene.path.radiusY * std::sin(theta);
  } else if (scene.path.kind == "lissajous") {
    x = scene.path.radiusX * std::sin(theta);
    y = scene.path.radiusY * std::sin(2.0 * theta + tau * scene.path.angle);
  } else if (scene.path.kind == "spiral") {
    const double radius = input.phase;
    x = radius * scene.path.radiusX * std::cos(theta);
    y = radius * scene.path.radiusY * std::sin(theta);
  } else {
    const double meanderPhase = tau * scene.path.meander;
    x = scene.path.radiusX * (0.7 * std::sin(theta) +
                               0.3 * std::sin(3.0 * theta + meanderPhase));
    y = scene.path.radiusY * (0.7 * std::cos(theta) +
                               0.3 * std::cos(2.0 * theta + meanderPhase));
  }
  x += 2.0 * scene.path.translationX - 1.0;
  y += 2.0 * scene.path.translationY - 1.0;
  x += scene.path.feedback * input.feedbackX;
  y += scene.path.feedback * input.feedbackY;
  x = std::clamp(x, -limit, limit);
  y = std::clamp(y, -limit, limit);
  if (!finite(x) || !finite(y)) {
    return neutral();
  }

  const double rotation = tau * scene.terrain.rotation;
  const double cosRotation = std::cos(rotation);
  const double sinRotation = std::sin(rotation);
  const double zoom = 0.25 + (3.75 * scene.terrain.zoom);
  const double offsetX = 2.0 * scene.terrain.offsetX - 1.0;
  const double offsetY = 2.0 * scene.terrain.offsetY - 1.0;
  const double mappedX = ((x * cosRotation) - (y * sinRotation) + offsetX) / zoom;
  const double mappedY = ((x * sinRotation) + (y * cosRotation) + offsetY) / zoom;
  if (!finite(mappedX) || !finite(mappedY)) {
    return neutral();
  }

  double zx = 0.0;
  double zy = 0.0;
  double cx = mappedX;
  double cy = mappedY;
  if (scene.terrain.kind == "julia") {
    zx = mappedX;
    zy = mappedY;
    cx = -0.8 + 0.4 * scene.terrain.motion;
    cy = 0.156 + 0.2 * scene.terrain.detail;
  }

  for (std::uint32_t iteration = 0; iteration < scene.terrain.maxIterations; ++iteration) {
    const double nextX = (zx * zx) - (zy * zy) + cx;
    const double nextY = (2.0 * zx * zy) + cy;
    zx = nextX;
    zy = nextY;
    const double magnitudeSquared = (zx * zx) + (zy * zy);
    if (!finite(zx) || !finite(zy) || !finite(magnitudeSquared)) {
      return neutral();
    }
    if (magnitudeSquared > kBailoutSquared) {
      const double magnitude = std::sqrt(magnitudeSquared);
      const double smoothIteration = static_cast<double>(iteration) + 1.0 -
                                     (std::log(std::log(magnitude)) / kLogTwo);
      if (!finite(smoothIteration)) {
        return neutral();
      }
      const double normalizedEscape = clampUnit(
          smoothIteration / static_cast<double>(scene.terrain.maxIterations));
      const double detailExponent = 0.5 + (3.5 * scene.terrain.detail);
      const double value = std::pow(1.0 - normalizedEscape, detailExponent) *
                           scene.terrain.normalization;
      if (!finite(value)) {
        return neutral();
      }
      return {clampUnit(value), x, y, iteration + 1U, true};
    }
  }
  return {0.0, x, y, scene.terrain.maxIterations, false};
}

}  // namespace latticewake
