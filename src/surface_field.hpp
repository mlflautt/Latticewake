#pragma once

#include <cstdint>
#include <span>
#include <string_view>

namespace latticewake {

// Version 1's canonical working field is a bounded row-major grid of unsigned
// 16-bit normalized heights. Coordinates use a top-left origin. The asset is
// decoded and verified by the host before this view reaches the builder.
inline constexpr std::uint32_t kSurfaceFieldMaximumEdge = 1024;
inline constexpr std::uint64_t kSurfaceFieldMaximumSamples =
    static_cast<std::uint64_t>(kSurfaceFieldMaximumEdge) * kSurfaceFieldMaximumEdge;

struct SurfaceFieldView {
  std::uint32_t width{};
  std::uint32_t height{};
  std::span<const std::uint16_t> samples;
  std::string_view contentHash;

  [[nodiscard]] bool valid() const noexcept {
    return width > 1 && height > 1 && width <= kSurfaceFieldMaximumEdge &&
           height <= kSurfaceFieldMaximumEdge &&
           static_cast<std::uint64_t>(width) * height == samples.size() &&
           !contentHash.empty();
  }
};

}  // namespace latticewake
