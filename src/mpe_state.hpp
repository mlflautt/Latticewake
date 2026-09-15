#pragma once
#include <optional>
#include <string>
#include <vector>
namespace latticewake {
enum class MpeMode { legacy, lower, upper };
struct MpeConfig { MpeMode mode{MpeMode::legacy}; int masterChannel{1}; int memberCount{1}; };
struct MpeExpression { double glide{}; double press{}; double slide{}; };
struct MpeNoteState { int channel{}; int note{}; MpeExpression expression; };
class MpeState {
 public:
  explicit MpeState(MpeConfig config) : config_(config) {}
  bool noteOn(int channel, int note); bool noteOff(int channel, int note);
  bool expression(int channel, MpeExpression value);
  void reset() noexcept;
  [[nodiscard]] std::optional<MpeNoteState> active(int channel) const;
 private: bool member(int channel) const; MpeConfig config_; std::vector<MpeNoteState> notes_;
}; }
