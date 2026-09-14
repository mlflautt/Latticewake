#include "event_trace.hpp"

#include <sstream>
#include <utility>

namespace latticewake {
namespace {

const char* originName(const EventOrigin origin) {
  switch (origin) {
    case EventOrigin::player:
      return "player";
    case EventOrigin::generator:
      return "generator";
    case EventOrigin::proposal:
      return "proposal";
  }
  return "unknown";
}

const char* typeName(const EventType type) {
  switch (type) {
    case EventType::noteOn:
      return "noteOn";
    case EventType::noteOff:
      return "noteOff";
    case EventType::control:
      return "control";
    case EventType::transport:
      return "transport";
    case EventType::scene:
      return "scene";
  }
  return "unknown";
}

std::string escape(const std::string& value) {
  std::string escaped;
  escaped.reserve(value.size());
  for (const char character : value) {
    if (character == '\\' || character == '|' || character == '\n') {
      escaped.push_back('\\');
    }
    escaped.push_back(character == '\n' ? 'n' : character);
  }
  return escaped;
}

}  // namespace

bool EventTrace::append(PerformanceEvent event) {
  if (!events_.empty() && event.sampleOffset < events_.back().sampleOffset) {
    return false;
  }
  events_.push_back(std::move(event));
  return true;
}

const std::vector<PerformanceEvent>& EventTrace::events() const noexcept { return events_; }

std::vector<TraceValidationIssue> EventTrace::validate() const {
  std::vector<TraceValidationIssue> issues;
  for (std::size_t index = 1; index < events_.size(); ++index) {
    if (events_[index].sampleOffset < events_[index - 1].sampleOffset) {
      issues.push_back({index, "sample offsets must be monotonic"});
    }
  }
  return issues;
}

std::string EventTrace::canonicalBytes() const {
  std::ostringstream output;
  for (const PerformanceEvent& event : events_) {
    output << event.sampleOffset << '|' << originName(event.origin) << '|'
           << typeName(event.type);
    for (const auto& [key, value] : event.payload) {
      output << '|' << escape(key) << '=' << escape(value);
    }
    output << '\n';
  }
  return output.str();
}

}  // namespace latticewake
