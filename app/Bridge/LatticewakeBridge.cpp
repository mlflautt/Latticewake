#include "LatticewakeBridge.h"
#include <array>
#include <atomic>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <new>
#include <span>
#include <string_view>
#include "../../../src/scene.cpp"
#include "../../../src/terrain_evaluator.cpp"
#include "../../../src/scene_serialization.cpp"
#include "../../../src/event_trace.cpp"
#include "../../../src/sample_transport.cpp"
#include "../../../src/role_event_generator.cpp"
#include "../../../src/realtime_kernel.cpp"
#include "../../../src/realtime_event_queue.hpp"
#include "../../../src/terrain_frame.cpp"
#include "../../../src/mpe_state.cpp"

namespace {
constexpr std::uint32_t kNoPlan = 2;
std::uint64_t fnv1a64(const std::string_view bytes) {
  std::uint64_t value = 14695981039346656037ULL;
  for (const unsigned char byte : bytes) {
    value ^= byte;
    value *= 1099511628211ULL;
  }
  return value;
}
struct RenderPlanSlot {
  latticewake::RealtimeKernel kernel;
  std::atomic<std::uint64_t> generation{0};
};
}

struct LWKernelRef {
  std::array<RenderPlanSlot, 2> plans{};
  latticewake::RealtimeEventQueue events;
  alignas(64) std::atomic<std::uint32_t> activePlan{0};
  alignas(64) std::atomic<std::uint32_t> pendingPlan{kNoPlan};
  std::atomic<std::uint64_t> nextGeneration{1};
  std::atomic<bool> renderBegun{false};
};

struct LWMpeStateRef {
  explicit LWMpeStateRef(const latticewake::MpeConfig config) : state(config) {}
  latticewake::MpeState state;
};

static latticewake::Scene demoScene() {
  using namespace latticewake;
  Scene scene; scene.sceneId="demo"; scene.title="Latticewake Demo"; scene.seed=1;
  scene.harmonicContext={"c","dorian",{0,2,3,5,7,9,10},0,"minor",0,4,120.0,std::nullopt};
  scene.terrain={"mandelbrot",0.5,0.5,0.5,0.5,0.0,0.0,128,1.0};
  scene.path={"ellipse",0.5,0.5,0.5,0.0,0.5,0.5,0.0,0.0,1.0};
  scene.roles={{RoleId::drone,true,0.5,0.5,{0},{{RhythmStepKind::note}},0,0,"internal",""},{RoleId::pad,true,0.5,0.5,{0},{{RhythmStepKind::note}},0,1,"internal",""},{RoleId::motifA,true,0.5,0.5,{0},{{RhythmStepKind::note}},0,2,"internal",""},{RoleId::motifB,true,0.5,0.5,{0},{{RhythmStepKind::note}},0,3,"internal",""}};
  return scene;
}
const char* latticewake_core_version(void) { return "portable-core-boundary-v0"; }
LWKernelRef* lw_kernel_create(void) { return new (std::nothrow) LWKernelRef; }
void lw_kernel_destroy(LWKernelRef* kernel) { delete kernel; }
static int prepareInitial(LWKernelRef* kernel,const latticewake::Scene& scene,const double rate) {
  if(!kernel||kernel->renderBegun.load(std::memory_order_acquire)||!kernel->plans[0].kernel.prepare(scene,rate))return 0;
  kernel->plans[0].generation.store(kernel->nextGeneration.fetch_add(1,std::memory_order_relaxed),std::memory_order_release);
  kernel->activePlan.store(0,std::memory_order_release);
  kernel->pendingPlan.store(kNoPlan,std::memory_order_release);
  return 1;
}
static int publishPlan(LWKernelRef* kernel,const latticewake::Scene& scene,const double rate) {
  if(!kernel||kernel->pendingPlan.load(std::memory_order_acquire)!=kNoPlan)return 0;
  const std::uint32_t active=kernel->activePlan.load(std::memory_order_acquire);
  const std::uint32_t candidate=1U-active;
  if(!kernel->plans[candidate].kernel.prepare(scene,rate))return 0;
  kernel->plans[candidate].generation.store(kernel->nextGeneration.fetch_add(1,std::memory_order_relaxed),std::memory_order_release);
  kernel->pendingPlan.store(candidate,std::memory_order_release);
  return 1;
}
int lw_kernel_prepare_demo(LWKernelRef* kernel,double rate) { return prepareInitial(kernel,demoScene(),rate); }
int lw_kernel_prepare_scene_json(LWKernelRef* kernel,const char* json,double rate) { if(!kernel||!json)return 0;latticewake::SceneSerializationError error;const auto scene=latticewake::parseSceneV0(json,error);return scene?prepareInitial(kernel,*scene,rate):0; }
int lw_kernel_publish_demo(LWKernelRef* kernel,double rate) { return publishPlan(kernel,demoScene(),rate); }
int lw_kernel_publish_scene_json(LWKernelRef* kernel,const char* json,double rate) { if(!kernel||!json)return 0;latticewake::SceneSerializationError error;const auto scene=latticewake::parseSceneV0(json,error);return scene?publishPlan(kernel,*scene,rate):0; }
int lw_terrain_frame_scene_json(const char* json,const unsigned long long sampleOffset,const double startPhase,const double phaseStep,LWTerrainFramePoint* points,const unsigned int capacity,unsigned int* pointCount) {
  if(!json||!points||!pointCount||capacity==0)return 0;
  latticewake::SceneSerializationError parseError;
  const auto scene=latticewake::parseSceneV0(json,parseError);
  if(!scene)return 0;
  latticewake::TerrainFrameError frameError;
  const auto frame=latticewake::buildTerrainFrame(*scene,{sampleOffset,startPhase,phaseStep,capacity},frameError);
  if(!frame||frame->points.size()>capacity)return 0;
  for(std::size_t index=0;index<frame->points.size();++index) {
    const auto& point=frame->points[index];
    points[index]={static_cast<float>(point.value),static_cast<float>(point.pathX),static_cast<float>(point.pathY),point.iterations,point.escaped?1U:0U};
  }
  *pointCount=static_cast<unsigned int>(frame->points.size());
  return 1;
}
int lw_scene_role_control(const char* json,const unsigned int roleIndex,LWRoleControl* control) { if(!json||!control)return 0;latticewake::SceneSerializationError error;const auto scene=latticewake::parseSceneV0(json,error);if(!scene||roleIndex>=scene->roles.size())return 0;const auto& role=scene->roles[roleIndex];*control={role.enabled?1U:0U,static_cast<float>(role.range),static_cast<float>(role.density),role.seedOffset,0};return 1; }
int lw_scene_apply_role_control(const char* json,const unsigned int roleIndex,const LWRoleControl* control,char** canonicalJson) { if(!json||!control||!canonicalJson||control->pattern>3U)return 0;latticewake::SceneSerializationError error;auto scene=latticewake::parseSceneV0(json,error);if(!scene||roleIndex>=scene->roles.size())return 0;auto& role=scene->roles[roleIndex];role.enabled=control->enabled!=0;role.range=control->range;role.density=control->density;role.seedOffset=control->seed_offset;switch(control->pattern){case 0:role.pattern={0};role.rhythm={{latticewake::RhythmStepKind::note}};break;case 1:role.pattern={0,2,4};role.rhythm={{latticewake::RhythmStepKind::note}};break;case 2:role.pattern={4,2,0};role.rhythm={{latticewake::RhythmStepKind::note}};break;default:role.pattern={0,1,2,1};role.rhythm={{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest}};break;}const auto serialized=latticewake::serializeSceneV0(*scene,error);if(!serialized)return 0;char* result=static_cast<char*>(std::malloc(serialized->size()+1U));if(!result)return 0;std::memcpy(result,serialized->c_str(),serialized->size()+1U);*canonicalJson=result;return 1; }
int lw_role_preview_scene_json(const char* json,const unsigned long long startSample,const unsigned long long frames,const double sampleRate,LWRoleTraceSummary* summary) {
  if(!json||!summary||frames==0)return 0;
  latticewake::SceneSerializationError parseError;
  const auto scene=latticewake::parseSceneV0(json,parseError);
  if(!scene)return 0;
  latticewake::RoleEventGenerationError generationError;
  const auto trace=latticewake::generateRoleEvents(*scene,startSample,frames,{sampleRate,scene->harmonicContext.tempoBPM},generationError);
  if(!trace)return 0;
  const auto& events=trace->events();
  const std::string bytes=trace->canonicalBytes();
  *summary={static_cast<unsigned long long>(events.size()),events.empty()?0ULL:events.front().sampleOffset,events.empty()?0ULL:events.back().sampleOffset,fnv1a64(bytes)};
  return 1;
}
void lw_string_destroy(char* value) { std::free(value); }
int lw_kernel_note_on(LWKernelRef* k,int n,float v) { return k&&k->events.tryPush({0,true,n,v}) ? 1 : 0; }
int lw_kernel_note_off(LWKernelRef* k,int n) { return k&&k->events.tryPush({0,false,n,0}) ? 1 : 0; }
int lw_kernel_expression(LWKernelRef* k,float glide,float press,float slide) { return k&&k->events.tryPush({0,false,-1,0,glide,press,slide,true}) ? 1 : 0; }
int lw_kernel_note_expression(LWKernelRef* k,int note,float glide,float press,float slide) { return k&&note>=0&&note<=127&&k->events.tryPush({0,false,note,0,glide,press,slide,true}) ? 1 : 0; }
int lw_kernel_render(LWKernelRef* k,float* out,unsigned int frames) {
  if(!k||!out)return 0;
  k->renderBegun.store(true,std::memory_order_release);
  const std::uint32_t pending=k->pendingPlan.load(std::memory_order_acquire);
  if(pending!=kNoPlan) {
    k->activePlan.store(pending,std::memory_order_release);
    k->pendingPlan.store(kNoPlan,std::memory_order_release);
  }
  std::array<latticewake::KernelEvent,latticewake::RealtimeKernel::kMaxEvents> events{};
  std::size_t count=0;
  latticewake::KernelEvent event;
  while(count<events.size()&&k->events.tryPop(event)) events[count++]=event;
  const std::uint32_t active=k->activePlan.load(std::memory_order_acquire);
  return k->plans[active].kernel.render(std::span<float>(out,frames),std::span<const latticewake::KernelEvent>(events.data(),count)) ? 1 : 0;
}
int lw_kernel_status(const LWKernelRef* k,LWKernelStatus* status) {
  if(!k||!status)return 0;
  status->pending_events=k->events.pending();
  status->dropped_events=k->events.dropped();
  const std::uint32_t active=k->activePlan.load(std::memory_order_acquire);
  const std::uint32_t pending=k->pendingPlan.load(std::memory_order_acquire);
  status->active_plan_generation=k->plans[active].generation.load(std::memory_order_acquire);
  status->pending_plan_generation=pending==kNoPlan?0:k->plans[pending].generation.load(std::memory_order_acquire);
  return 1;
}
unsigned int lw_kernel_event_queue_capacity(void) { return latticewake::RealtimeEventQueue::kUsableCapacity; }
void lw_kernel_reset(LWKernelRef* k) { if(k){const std::uint32_t active=k->activePlan.load(std::memory_order_acquire);k->plans[active].kernel.reset();k->events.resetProducerSide();} }
LWMpeStateRef* lw_mpe_state_create(const unsigned int mode,const int masterChannel,const int memberCount) {
  if(mode>2U||masterChannel<1||masterChannel>16||memberCount<1||memberCount>15)return nullptr;
  return new(std::nothrow) LWMpeStateRef({static_cast<latticewake::MpeMode>(mode),masterChannel,memberCount});
}
void lw_mpe_state_destroy(LWMpeStateRef* state) { delete state; }
int lw_mpe_note_on(LWMpeStateRef* state,const int channel,const int note) { return state&&state->state.noteOn(channel,note)?1:0; }
int lw_mpe_note_off(LWMpeStateRef* state,const int channel,const int note) { return state&&state->state.noteOff(channel,note)?1:0; }
int lw_mpe_expression(LWMpeStateRef* state,const int channel,const float glide,const float press,const float slide) { return state&&state->state.expression(channel,{glide,press,slide})?1:0; }
int lw_mpe_active_note(const LWMpeStateRef* state,const int channel,int* note) { if(!state||!note)return 0;const auto active=state->state.active(channel);if(!active)return 0;*note=active->note;return 1; }
void lw_mpe_reset(LWMpeStateRef* state) { if(state)state->state.reset(); }
