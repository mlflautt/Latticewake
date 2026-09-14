#pragma once

#include <cstddef>
#include <cstdint>
#include <map>
#include <string>
#include <vector>

namespace latticewake {

enum class EventOrigin { player, generator, proposal };
enum class EventType { noteOn, noteOff, control, transport, scene };

struct PerformanceEvent {
  std::uint64_t sampleOffset{};
  EventOrigin origin{EventOrigin::player};
  EventType type{EventType::control};
  std::map<std::string, std::string> payload;
};

struct TraceValidationIssue {
  std::size_t eventIndex{};
  std::string message;
};

class EventTrace {
 public:
  [[nodiscard]] bool append(PerformanceEvent event);
  [[nodiscard]] const std::vector<PerformanceEvent>& events() const noexcept;
  [[nodiscard]] std::vector<TraceValidationIssue> validate() const;
  [[nodiscard]] std::string canonicalBytes() const;

 private:
  std::vector<PerformanceEvent> events_;
};

}  // namespace latticewake
