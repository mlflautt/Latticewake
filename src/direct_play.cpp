#include "direct_play.hpp"

#include <array>
#include <cmath>

namespace latticewake {
std::optional<DirectPlayEvent> qwertyEvent(const std::string_view key, const bool down, const std::uint64_t sampleOffset) {
  constexpr std::array<std::pair<std::string_view,int>,13> keys={{{"a",60},{"w",61},{"s",62},{"e",63},{"d",64},{"f",65},{"t",66},{"g",67},{"y",68},{"h",69},{"u",70},{"j",71},{"k",72}}};
  for(const auto& [name,note]:keys)if(key==name)return DirectPlayEvent{sampleOffset,down?DirectPlayType::noteOn:DirectPlayType::noteOff,note,down?1.0:0.0};return std::nullopt;
}
std::optional<TrackpadState> smoothTrackpad(const TrackpadState previous, const double x, const double y, const double pressure, const double smoothing) {
  if(!std::isfinite(x)||!std::isfinite(y)||!std::isfinite(pressure)||!std::isfinite(smoothing)||x<0.0||x>1.0||y<0.0||y>1.0||pressure<0.0||pressure>1.0||smoothing<0.0||smoothing>1.0)return std::nullopt;
  const auto blend=[smoothing](const double prior,const double target){return prior+(target-prior)*(1.0-smoothing);};
  return TrackpadState{blend(previous.glide,2.0*x-1.0),blend(previous.press,pressure),blend(previous.slide,y)};
}
}  // namespace latticewake
