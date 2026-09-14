#include "role_event_generator.hpp"

#include <algorithm>
#include <cmath>
#include <limits>
#include <map>
#include <vector>

namespace latticewake {
namespace {
constexpr std::size_t kMaximumGeneratedEvents = 4096;
bool validTransport(const SampleTransportConfig& config) { return std::isfinite(config.sampleRate) && config.sampleRate >= 8000.0 && config.sampleRate <= 192000.0 && std::isfinite(config.tempoBPM) && config.tempoBPM > 0.0 && config.tempoBPM <= 1000.0; }
double beatAt(const std::uint64_t sample, const SampleTransportConfig& config) { return static_cast<double>(sample) * config.tempoBPM / (60.0 * config.sampleRate); }
std::uint64_t sampleAt(const double beat, const SampleTransportConfig& config) { return static_cast<std::uint64_t>(std::round(beat * 60.0 * config.sampleRate / config.tempoBPM)); }
std::uint64_t mix(std::uint64_t value) { value ^= value >> 30U; value *= 0xbf58476d1ce4e5b9ULL; value ^= value >> 27U; value *= 0x94d049bb133111ebULL; return value ^ (value >> 31U); }
int degreeFor(const RoleLane& role, const std::uint64_t seed, const std::size_t index) { if(role.pattern.empty()) return 0; const std::uint64_t state=mix(seed+index); const std::size_t base=index%role.pattern.size(); const int variation=role.variation==0.0?0:static_cast<int>(state%3U)-1; return role.pattern[base]+variation; }
}  // namespace

std::optional<EventTrace> generateRoleEvents(
    const Scene& scene, const std::uint64_t startSampleOffset, const std::uint64_t frames,
    const SampleTransportConfig& transport, RoleEventGenerationError& error) {
  if (!isValidScene(scene)) { error={"scene","must satisfy Scene v0 validation"}; return std::nullopt; }
  if (!validTransport(transport)) { error={"transport","must use a valid sample rate and tempo"}; return std::nullopt; }
  if (frames > std::numeric_limits<std::uint64_t>::max() - startSampleOffset) { error={"frames","would overflow sample offset"}; return std::nullopt; }
  const std::uint64_t endSample=startSampleOffset+frames; const double beginBeat=beatAt(startSampleOffset,transport); const double endBeat=beatAt(endSample,transport);
  std::vector<PerformanceEvent> events;
  for(const auto& role:scene.roles){ if(!role.enabled||role.density==0.0||role.rhythm.empty()) continue; const double stepBeats=1.0/(0.25+3.75*role.density); const std::int64_t first=static_cast<std::int64_t>(std::ceil(beginBeat/stepBeats)); const std::int64_t last=static_cast<std::int64_t>(std::ceil(endBeat/stepBeats)); for(std::int64_t step=first;step<last;++step){const auto index=static_cast<std::size_t>(step);const RhythmStepKind rhythm=role.rhythm[index%role.rhythm.size()].kind;if(rhythm!=RhythmStepKind::note)continue;const double beat=static_cast<double>(step)*stepBeats;const std::uint64_t on=sampleAt(beat,transport);const std::uint64_t off=sampleAt(std::min(beat+stepBeats*0.8,endBeat),transport);if(on<startSampleOffset||on>=endSample)continue;if(events.size()+2U>kMaximumGeneratedEvents){error={"events","exceeds 4096-event window cap"};return std::nullopt;}const std::map<std::string,std::string> payload={{"degree",std::to_string(degreeFor(role,scene.seed^role.seedOffset,index))},{"lane",std::string(roleIdName(role.id))}};events.push_back({on,EventOrigin::generator,EventType::noteOn,payload});events.push_back({std::max(on,off),EventOrigin::generator,EventType::noteOff,payload});}}
  std::stable_sort(events.begin(),events.end(),[](const PerformanceEvent& a,const PerformanceEvent& b){return a.sampleOffset<b.sampleOffset;}); EventTrace trace;for(auto& event:events)if(!trace.append(std::move(event))){error={"events","could not create a monotonic trace"};return std::nullopt;}return trace;
}

}  // namespace latticewake
