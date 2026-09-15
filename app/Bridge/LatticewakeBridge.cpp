#include "LatticewakeBridge.h"
#include <array>
#include <atomic>
#include <cstdint>
#include <new>
#include <span>
#include "../../../src/scene.cpp"
#include "../../../src/terrain_evaluator.cpp"
#include "../../../src/scene_serialization.cpp"
#include "../../../src/realtime_kernel.cpp"
#include "../../../src/realtime_event_queue.hpp"
#include "../../../src/terrain_frame.cpp"

namespace {
constexpr std::uint32_t kNoPlan = 2;
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
int lw_kernel_note_on(LWKernelRef* k,int n,float v) { return k&&k->events.tryPush({0,true,n,v}) ? 1 : 0; }
int lw_kernel_note_off(LWKernelRef* k,int n) { return k&&k->events.tryPush({0,false,n,0}) ? 1 : 0; }
int lw_kernel_expression(LWKernelRef* k,float glide,float press,float slide) { return k&&k->events.tryPush({0,false,0,0,glide,press,slide,true}) ? 1 : 0; }
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
