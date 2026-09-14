#include "LatticewakeBridge.h"
#include <array>
#include <new>
#include <span>
#include "../../../src/scene.cpp"
#include "../../../src/terrain_evaluator.cpp"
#include "../../../src/realtime_kernel.cpp"

struct LWKernelRef {
  latticewake::RealtimeKernel kernel;
  std::array<latticewake::KernelEvent, latticewake::RealtimeKernel::kMaxEvents> events{};
  std::size_t count{};
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
int lw_kernel_note_on(LWKernelRef* k,int n,float v) { if(!k||k->count==k->events.size())return 0;k->events[k->count++]={0,true,n,v};return 1; }
int lw_kernel_note_off(LWKernelRef* k,int n) { if(!k||k->count==k->events.size())return 0;k->events[k->count++]={0,false,n,0};return 1; }
int lw_kernel_render(LWKernelRef* k,float* out,unsigned int frames) { if(!k||!out)return 0;const auto ok=k->kernel.render(std::span<float>(out,frames),std::span<const latticewake::KernelEvent>(k->events.data(),k->count));k->count=0;return ok; }
void lw_kernel_reset(LWKernelRef* k) { if(k){k->kernel.reset();k->count=0;} }
