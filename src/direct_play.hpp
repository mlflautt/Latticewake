#pragma once

#include <cstdint>
#include <optional>
#include <string_view>

namespace latticewake {
enum class DirectPlayType { noteOn, noteOff, glide, press, slide };
struct DirectPlayEvent { std::uint64_t sampleOffset{}; DirectPlayType type{DirectPlayType::noteOn}; int note{}; double value{}; };
struct TrackpadState { double glide{}; double press{}; double slide{}; };
// Maps a US-layout QWERTY key into a chromatic note event around MIDI note 60.
[[nodiscard]] std::optional<DirectPlayEvent> qwertyEvent(std::string_view key, bool down, std::uint64_t sampleOffset);
// Smooths normalized x/y/pressure into semantic glide/slide/press values.
[[nodiscard]] std::optional<TrackpadState> smoothTrackpad(
    TrackpadState previous, double x, double y, double pressure, double smoothing);
}  // namespace latticewake
