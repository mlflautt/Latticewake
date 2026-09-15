#include "LatticewakeBridge.h"
#include <array>
#include <cstdint>
#include <new>
#include <span>
#include "../../../src/scene.cpp"
#include "../../../src/terrain_evaluator.cpp"
#include "../../../src/scene_serialization.cpp"
#include "../../../src/realtime_kernel.cpp"
#include "../../../src/realtime_event_queue.hpp"

struct LWKernelRef {
  latticewake::RealtimeKernel kernel;
  latticewake::RealtimeEventQueue events;
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
int lw_kernel_prepare_demo(LWKernelRef* kernel,double rate) { return kernel&&kernel->kernel.prepare(demoScene(),rate); }
int lw_kernel_prepare_scene_json(LWKernelRef* kernel,const char* json,double rate) { if(!kernel||!json)return 0;latticewake::SceneSerializationError error;const auto scene=latticewake::parseSceneV0(json,error);return scene&&kernel->kernel.prepare(*scene,rate); }
int lw_kernel_note_on(LWKernelRef* k,int n,float v) { return k&&k->events.tryPush({0,true,n,v}) ? 1 : 0; }
int lw_kernel_note_off(LWKernelRef* k,int n) { return k&&k->events.tryPush({0,false,n,0}) ? 1 : 0; }
int lw_kernel_expression(LWKernelRef* k,float glide,float press,float slide) { return k&&k->events.tryPush({0,false,0,0,glide,press,slide,true}) ? 1 : 0; }
int lw_kernel_render(LWKernelRef* k,float* out,unsigned int frames) {
  if(!k||!out)return 0;
  std::array<latticewake::KernelEvent,latticewake::RealtimeKernel::kMaxEvents> events{};
  std::size_t count=0;
  latticewake::KernelEvent event;
  while(count<events.size()&&k->events.tryPop(event)) events[count++]=event;
  return k->kernel.render(std::span<float>(out,frames),std::span<const latticewake::KernelEvent>(events.data(),count)) ? 1 : 0;
}
int lw_kernel_status(const LWKernelRef* k,LWKernelStatus* status) {
  if(!k||!status)return 0;
  status->pending_events=k->events.pending();
  status->dropped_events=k->events.dropped();
  return 1;
}
unsigned int lw_kernel_event_queue_capacity(void) { return latticewake::RealtimeEventQueue::kUsableCapacity; }
void lw_kernel_reset(LWKernelRef* k) { if(k){k->kernel.reset();k->events.resetProducerSide();} }
