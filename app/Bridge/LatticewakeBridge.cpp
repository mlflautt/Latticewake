#include "LatticewakeBridge.h"
#include <array>
#include <atomic>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <chrono>
#include <cmath>
#include <new>
#include <span>
#include <string_view>
#include "../../../src/scene.cpp"
#include "../../../src/scene_v1.cpp"
#include "../../../src/terrain_evaluator.cpp"
#include "../../../src/scene_serialization.cpp"
#include "../../../src/event_trace.cpp"
#include "../../../src/sample_transport.cpp"
#include "../../../src/role_event_generator.cpp"
#include "../../../src/realtime_kernel.cpp"
#include "../../../src/render_plan.cpp"
#include "../../../src/realtime_event_queue.hpp"
#include "../../../src/terrain_frame.cpp"
#include "../../../src/mpe_state.cpp"

namespace {
constexpr std::uint32_t kNoPlan = 2;
constexpr std::uint32_t kMaximumCallbackFrames = 4096;
constexpr std::uint32_t kRoleSourceBase = 100;
std::uint64_t fnv1a64(const std::string_view bytes) {
  std::uint64_t value = 14695981039346656037ULL;
  for (const unsigned char byte : bytes) {
    value ^= byte;
    value *= 1099511628211ULL;
  }
  return value;
}
void updateMaximum(std::atomic<std::uint64_t>& target, const std::uint64_t candidate) {
  std::uint64_t observed=target.load(std::memory_order_relaxed);
  while(observed<candidate&&!target.compare_exchange_weak(observed,candidate,std::memory_order_relaxed)) {}
}
struct RenderPlanSlot {
  latticewake::RealtimeKernel kernel;
  latticewake::RenderPlan plan;
  std::atomic<std::uint64_t> generation{0};
};
struct RolePlanSlot {
  std::array<latticewake::PreparedRoleEvent, latticewake::RenderPlan::kMaximumRoleEvents> events{};
  std::uint32_t eventCount{};
  std::uint64_t loopFrames{};
  std::atomic<std::uint64_t> generation{0};
};

void copyRolePlan(const latticewake::RenderPlan& source, RolePlanSlot& destination) noexcept {
  destination.eventCount=source.roleEventCount;
  destination.loopFrames=source.roleLoopFrames;
  std::copy_n(source.roleEvents.begin(),source.roleEventCount,destination.events.begin());
}
}

struct LWKernelRef {
  std::array<RenderPlanSlot, 2> plans{};
  std::array<RolePlanSlot, 2> rolePlans{};
  latticewake::RealtimeEventQueue events;
  alignas(64) std::atomic<std::uint32_t> activePlan{0};
  alignas(64) std::atomic<std::uint32_t> pendingPlan{kNoPlan};
  std::atomic<std::uint64_t> nextGeneration{1};
  alignas(64) std::atomic<std::uint32_t> activeRolePlan{0};
  alignas(64) std::atomic<std::uint32_t> pendingRolePlan{kNoPlan};
  std::atomic<std::uint64_t> nextRoleGeneration{1};
  std::atomic<bool> renderBegun{false};
  alignas(64) std::atomic<bool> panicRequested{false};
  alignas(64) std::atomic<std::uint64_t> callbackCount{0};
  std::atomic<std::uint64_t> renderedFrames{0};
  std::atomic<std::uint64_t> renderFailures{0};
  std::atomic<float> outputPeak{0};
  std::atomic<std::uint64_t> maximumRenderNanoseconds{0};
  std::atomic<std::uint64_t> deadlineMisses{0};
  std::atomic<bool> rolesRunning{false};
  std::atomic<bool> roleStartRequested{false};
  std::atomic<bool> roleStopRequested{false};
  std::atomic<std::uint32_t> activeRoleLanes{0};
  std::atomic<std::uint64_t> roleSampleOffset{0};
  bool roleBoundaryReleaseRequested{};
  std::array<int, 4> activeRoleNotes{{-1,-1,-1,-1}};
  double callbackSampleRate{0.0};
};

struct LWMpeStateRef {
  explicit LWMpeStateRef(const latticewake::MpeConfig config) : state(config) {}
  latticewake::MpeState state;
};

static latticewake::Scene demoScene() {
  using namespace latticewake;
  Scene scene; scene.sceneId="demo"; scene.title="Latticewake Demo"; scene.seed=1;
  scene.harmonicContext={"c","dorian",{0,2,3,5,7,9,10},0,"minor",0,4,120.0,std::nullopt};
  scene.terrain={"mandelbrot",0.5,0.0,0.5,0.5,0.0,0.0,128,1.0};
  scene.path={"ellipse",1.0,0.5,0.3,0.0,0.6,0.5,0.0,0.0,1.0};
  scene.roles={{RoleId::drone,true,0.5,0.5,{0},{{RhythmStepKind::note}},0,0,"internal",""},{RoleId::pad,true,0.5,0.5,{0},{{RhythmStepKind::note}},0,1,"internal",""},{RoleId::motifA,true,0.5,0.5,{0},{{RhythmStepKind::note}},0,2,"internal",""},{RoleId::motifB,true,0.5,0.5,{0},{{RhythmStepKind::note}},0,3,"internal",""}};
  return scene;
}
const char* latticewake_core_version(void) { return "portable-core-boundary-v1"; }
LWKernelRef* lw_kernel_create(void) { return new (std::nothrow) LWKernelRef; }
void lw_kernel_destroy(LWKernelRef* kernel) { delete kernel; }
static int prepareInitial(LWKernelRef* kernel,const latticewake::Scene& scene,const double rate) {
  latticewake::RenderPlanError error;
  latticewake::RenderPlanBuilder builder;
  if(!kernel||kernel->renderBegun.load(std::memory_order_acquire)||!builder.build(scene,rate,kernel->plans[0].plan,error)||!kernel->plans[0].kernel.activate(kernel->plans[0].plan.terrain))return 0;
  kernel->plans[0].generation.store(kernel->nextGeneration.fetch_add(1,std::memory_order_relaxed),std::memory_order_release);
  copyRolePlan(kernel->plans[0].plan,kernel->rolePlans[0]);
  kernel->rolePlans[0].generation.store(kernel->nextRoleGeneration.fetch_add(1,std::memory_order_relaxed),std::memory_order_release);
  kernel->activePlan.store(0,std::memory_order_release);
  kernel->pendingPlan.store(kNoPlan,std::memory_order_release);
  kernel->activeRolePlan.store(0,std::memory_order_release);
  kernel->pendingRolePlan.store(kNoPlan,std::memory_order_release);
  kernel->callbackSampleRate=rate;
  kernel->rolesRunning.store(false,std::memory_order_release);
  kernel->roleStartRequested.store(false,std::memory_order_release);
  kernel->roleStopRequested.store(false,std::memory_order_release);
  kernel->activeRoleLanes.store(0,std::memory_order_release);
  kernel->roleSampleOffset=0; kernel->roleBoundaryReleaseRequested=false; kernel->activeRoleNotes={{-1,-1,-1,-1}};
  return 1;
}

static bool buildSceneDocumentPlan(const char* json, const double rate, latticewake::RenderPlan& output) {
  if(!json) return false;
  latticewake::SceneSerializationError parseError;
  latticewake::RenderPlanError renderError;
  latticewake::RenderPlanBuilder builder;
  if(const auto sceneV1=latticewake::parseSceneV1(json,parseError))
    return builder.build(*sceneV1,rate,output,renderError);
  if(const auto sceneV0=latticewake::parseSceneV0(json,parseError))
    return builder.build(*sceneV0,rate,output,renderError);
  return false;
}

static int prepareInitialDocument(LWKernelRef* kernel, const char* json, const double rate) {
  if(!kernel||kernel->renderBegun.load(std::memory_order_acquire)||
     !buildSceneDocumentPlan(json,rate,kernel->plans[0].plan)||
     !kernel->plans[0].kernel.activate(kernel->plans[0].plan.terrain)) return 0;
  kernel->plans[0].generation.store(kernel->nextGeneration.fetch_add(1,std::memory_order_relaxed),std::memory_order_release);
  copyRolePlan(kernel->plans[0].plan,kernel->rolePlans[0]);
  kernel->rolePlans[0].generation.store(kernel->nextRoleGeneration.fetch_add(1,std::memory_order_relaxed),std::memory_order_release);
  kernel->activePlan.store(0,std::memory_order_release);
  kernel->pendingPlan.store(kNoPlan,std::memory_order_release);
  kernel->activeRolePlan.store(0,std::memory_order_release);
  kernel->pendingRolePlan.store(kNoPlan,std::memory_order_release);
  kernel->callbackSampleRate=rate;
  kernel->rolesRunning.store(false,std::memory_order_release);
  kernel->roleStartRequested.store(false,std::memory_order_release);
  kernel->roleStopRequested.store(false,std::memory_order_release);
  kernel->activeRoleLanes.store(0,std::memory_order_release);
  kernel->roleSampleOffset=0; kernel->roleBoundaryReleaseRequested=false; kernel->activeRoleNotes={{-1,-1,-1,-1}};
  return 1;
}
static int publishPlan(LWKernelRef* kernel,const latticewake::Scene& scene,const double rate) {
  if(!kernel||kernel->pendingPlan.load(std::memory_order_acquire)!=kNoPlan||kernel->pendingRolePlan.load(std::memory_order_acquire)!=kNoPlan)return 0;
  const std::uint32_t active=kernel->activePlan.load(std::memory_order_acquire);
  const std::uint32_t candidate=1U-active;
  latticewake::RenderPlanError error;
  latticewake::RenderPlanBuilder builder;
  if(!builder.build(scene,rate,kernel->plans[candidate].plan,error)||!kernel->plans[candidate].kernel.activate(kernel->plans[candidate].plan.terrain))return 0;
  kernel->plans[candidate].generation.store(kernel->nextGeneration.fetch_add(1,std::memory_order_relaxed),std::memory_order_release);
  const std::uint32_t activeRole=kernel->activeRolePlan.load(std::memory_order_acquire);
  const std::uint32_t candidateRole=1U-activeRole;
  copyRolePlan(kernel->plans[candidate].plan,kernel->rolePlans[candidateRole]);
  kernel->rolePlans[candidateRole].generation.store(kernel->nextRoleGeneration.fetch_add(1,std::memory_order_relaxed),std::memory_order_release);
  kernel->pendingPlan.store(candidate,std::memory_order_release);
  kernel->pendingRolePlan.store(candidateRole,std::memory_order_release);
  return 1;
}
static int publishDocumentPlan(LWKernelRef* kernel,const char* json,const double rate) {
  if(!kernel||kernel->pendingPlan.load(std::memory_order_acquire)!=kNoPlan||kernel->pendingRolePlan.load(std::memory_order_acquire)!=kNoPlan)return 0;
  const std::uint32_t active=kernel->activePlan.load(std::memory_order_acquire);
  const std::uint32_t candidate=1U-active;
  if(!buildSceneDocumentPlan(json,rate,kernel->plans[candidate].plan)||
     !kernel->plans[candidate].kernel.activate(kernel->plans[candidate].plan.terrain)) return 0;
  kernel->plans[candidate].generation.store(kernel->nextGeneration.fetch_add(1,std::memory_order_relaxed),std::memory_order_release);
  const std::uint32_t activeRole=kernel->activeRolePlan.load(std::memory_order_acquire);
  const std::uint32_t candidateRole=1U-activeRole;
  copyRolePlan(kernel->plans[candidate].plan,kernel->rolePlans[candidateRole]);
  kernel->rolePlans[candidateRole].generation.store(kernel->nextRoleGeneration.fetch_add(1,std::memory_order_relaxed),std::memory_order_release);
  kernel->pendingPlan.store(candidate,std::memory_order_release);
  kernel->pendingRolePlan.store(candidateRole,std::memory_order_release);
  return 1;
}
static int publishRoleDocumentPlan(LWKernelRef* kernel,const char* json,const double rate) {
  if(!kernel||kernel->pendingRolePlan.load(std::memory_order_acquire)!=kNoPlan)return 0;
  latticewake::RenderPlan candidatePlan;
  if(!buildSceneDocumentPlan(json,rate,candidatePlan))return 0;
  const std::uint32_t active=kernel->activeRolePlan.load(std::memory_order_acquire);
  const std::uint32_t candidate=1U-active;
  copyRolePlan(candidatePlan,kernel->rolePlans[candidate]);
  kernel->rolePlans[candidate].generation.store(kernel->nextRoleGeneration.fetch_add(1,std::memory_order_relaxed),std::memory_order_release);
  kernel->pendingRolePlan.store(candidate,std::memory_order_release);
  return 1;
}
int lw_kernel_prepare_demo(LWKernelRef* kernel,double rate) { return prepareInitial(kernel,demoScene(),rate); }
int lw_kernel_prepare_scene_json(LWKernelRef* kernel,const char* json,double rate) { return prepareInitialDocument(kernel,json,rate); }
int lw_kernel_publish_demo(LWKernelRef* kernel,double rate) { return publishPlan(kernel,demoScene(),rate); }
int lw_kernel_publish_scene_json(LWKernelRef* kernel,const char* json,double rate) { return publishDocumentPlan(kernel,json,rate); }
int lw_kernel_publish_role_scene_json(LWKernelRef* kernel,const char* json,double rate) { return publishRoleDocumentPlan(kernel,json,rate); }
int lw_terrain_frame_scene_json(const char* json,const unsigned long long sampleOffset,const double startPhase,const double phaseStep,LWTerrainFramePoint* points,const unsigned int capacity,unsigned int* pointCount) {
  if(!json||!points||!pointCount||capacity==0)return 0;
  latticewake::SceneSerializationError parseError;
  const auto scene=latticewake::parseSceneDocument(json,parseError);
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
static unsigned int rolePatternIndex(const unsigned int roleIndex, const latticewake::RoleLane& role) {
  if (role.pattern == std::vector<int>{0}) return 0U;
  if (role.pattern == std::vector<int>{0, 2, 4}) return 1U;
  if (role.pattern == std::vector<int>{4, 2, 0}) return 2U;
  if (roleIndex == 2U) {
    if (role.pattern == std::vector<int>{0, 2, 4, 2}) return 4U;
    if (role.pattern == std::vector<int>{0, 2, 4, 5}) return 5U;
    if (role.pattern == std::vector<int>{0, 2, 4, 5, 7, 5, 4, 2}) return 6U;
    if (role.pattern == std::vector<int>{0, 4, 2, 5}) return 7U;
  }
  if (roleIndex == 3U) {
    if (role.pattern == std::vector<int>{0, 1, 3, 2}) return 4U;
    if (role.pattern == std::vector<int>{0, 3, 1, 4, 2}) return 5U;
    if (role.pattern == std::vector<int>{0, 2, 1, 3, 5, 3, 1, 2}) return 6U;
    if (role.pattern == std::vector<int>{0, 4, 1, 5, 2, 6, 3}) return 7U;
  }
  // The only remaining supported UI pattern is Pulse. Classifying unknown
  // imported material as Pulse retains a non-held shape rather than silently
  // rewriting it to Held when the role controls are round-tripped.
  return 3U;
}
int lw_scene_role_control(const char* json,const unsigned int roleIndex,LWRoleControl* control) { if(!json||!control)return 0;latticewake::SceneSerializationError error;const auto scene=latticewake::parseSceneDocument(json,error);if(!scene||roleIndex>=scene->roles.size())return 0;const auto& role=scene->roles[roleIndex];*control={role.enabled?1U:0U,static_cast<float>(role.range),static_cast<float>(role.density),static_cast<float>(role.variation),role.seedOffset,rolePatternIndex(roleIndex,role)};return 1; }
static bool applyRolePattern(const unsigned int roleIndex, const unsigned int pattern, latticewake::RoleLane& role) {
  switch(pattern) {
    case 0: role.pattern={0}; role.rhythm={{latticewake::RhythmStepKind::note}}; return true;
    case 1: role.pattern={0,2,4}; role.rhythm={{latticewake::RhythmStepKind::note}}; return true;
    case 2: role.pattern={4,2,0}; role.rhythm={{latticewake::RhythmStepKind::note}}; return true;
    case 3: role.pattern={0,1,2,1}; role.rhythm={{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest}}; return true;
    default: break;
  }
  if (roleIndex == 2U) {
    switch(pattern) {
      case 4: role.pattern={0,2,4,2}; role.rhythm={{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest}}; return true;
      case 5: role.pattern={0,2,4,5}; role.rhythm={{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest}}; return true;
      case 6: role.pattern={0,2,4,5,7,5,4,2}; role.rhythm={{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::note}}; return true;
      case 7: role.pattern={0,4,2,5}; role.rhythm={{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note}}; return true;
      default: return false;
    }
  }
  if (roleIndex == 3U) {
    switch(pattern) {
      case 4: role.pattern={0,1,3,2}; role.rhythm={{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note}}; return true;
      case 5: role.pattern={0,3,1,4,2}; role.rhythm={{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest}}; return true;
      case 6: role.pattern={0,2,1,3,5,3,1,2}; role.rhythm={{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note}}; return true;
      case 7: role.pattern={0,4,1,5,2,6,3}; role.rhythm={{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::note},{latticewake::RhythmStepKind::rest}}; return true;
      default: return false;
    }
  }
  return false;
}
int lw_scene_apply_role_control(const char* json,const unsigned int roleIndex,const LWRoleControl* control,char** canonicalJson) {
  if(!json||!control||!canonicalJson||control->pattern>7U||!std::isfinite(control->variation)||control->variation<0.0F||control->variation>1.0F)return 0;
  latticewake::SceneSerializationError error;
  auto v1=latticewake::parseSceneV1(json,error);
  auto scene=v1?std::optional<latticewake::Scene>(v1->compatibilityScene):latticewake::parseSceneV0(json,error);
  if(!scene||roleIndex>=scene->roles.size())return 0;
  auto& role=scene->roles[roleIndex];
  role.enabled=control->enabled!=0;role.range=control->range;role.density=control->density;role.variation=control->variation;role.seedOffset=control->seed_offset;
  if(!applyRolePattern(roleIndex,control->pattern,role))return 0;
  std::optional<std::string> serialized;
  if(v1){v1->compatibilityScene=*scene;v1->lanes[roleIndex].role=role;serialized=latticewake::serializeSceneV1(*v1,error);}
  else serialized=latticewake::serializeSceneV0(*scene,error);
  if(!serialized)return 0;
  char* result=static_cast<char*>(std::malloc(serialized->size()+1U));if(!result)return 0;
  std::memcpy(result,serialized->c_str(),serialized->size()+1U);*canonicalJson=result;return 1;
}
int lw_scene_editor_controls(const char* json,LWSceneEditorControls* controls) {
  if(!json||!controls)return 0;
  latticewake::SceneSerializationError error;
  const auto v1=latticewake::parseSceneV1(json,error);
  const auto v0=v1?std::optional<latticewake::Scene>(v1->compatibilityScene):latticewake::parseSceneV0(json,error);
  if(!v0)return 0;
  const auto& terrain=v0->terrain; const auto& path=v0->path;
  const auto articulation=v1?v1->articulation:latticewake::ArticulationComponent{};
  *controls={terrain.detail,terrain.zoom,terrain.offsetX,terrain.offsetY,path.rateRatio,path.radiusX,path.radiusY,path.angle,path.translationX,path.translationY,
             articulation.attackSeconds,articulation.releaseSeconds,articulation.gain,articulation.glideSemitones,
             articulation.velocityResponse,articulation.pressureResponse,articulation.slideResponse};
  return 1;
}
int lw_scene_apply_editor_controls(const char* json,const LWSceneEditorControls* controls,char** canonicalJson) {
  if(!json||!controls||!canonicalJson)return 0;
  const double values[]={controls->terrain_detail,controls->terrain_zoom,controls->terrain_offset_x,controls->terrain_offset_y,
                         controls->traversal_rate_ratio,controls->traversal_radius_x,controls->traversal_radius_y,controls->traversal_angle,
                         controls->traversal_translation_x,controls->traversal_translation_y,controls->attack_seconds,controls->release_seconds,
                         controls->gain,controls->glide_semitones,controls->velocity_response,controls->pressure_response,controls->slide_response};
  for(const double value:values) if(!std::isfinite(value))return 0;
  latticewake::SceneSerializationError error;
  auto v1=latticewake::parseSceneV1(json,error);
  if(!v1)return 0;
  auto& scene=v1->compatibilityScene;
  scene.terrain.detail=controls->terrain_detail; scene.terrain.zoom=controls->terrain_zoom;
  scene.terrain.offsetX=controls->terrain_offset_x; scene.terrain.offsetY=controls->terrain_offset_y;
  scene.path.rateRatio=controls->traversal_rate_ratio; scene.path.radiusX=controls->traversal_radius_x;
  scene.path.radiusY=controls->traversal_radius_y; scene.path.angle=controls->traversal_angle;
  scene.path.translationX=controls->traversal_translation_x; scene.path.translationY=controls->traversal_translation_y;
  for(auto& layer:v1->surface.layers) if(layer.sourceType==latticewake::SurfaceSourceType::analytic) layer.analytic=scene.terrain;
  v1->traversal.path=scene.path;
  v1->articulation.attackSeconds=controls->attack_seconds; v1->articulation.releaseSeconds=controls->release_seconds;
  v1->articulation.gain=controls->gain; v1->articulation.glideSemitones=controls->glide_semitones;
  v1->articulation.velocityResponse=controls->velocity_response; v1->articulation.pressureResponse=controls->pressure_response;
  v1->articulation.slideResponse=controls->slide_response;
  const auto serialized=latticewake::serializeSceneV1(*v1,error);
  if(!serialized)return 0;
  char* result=static_cast<char*>(std::malloc(serialized->size()+1U));if(!result)return 0;
  std::memcpy(result,serialized->c_str(),serialized->size()+1U);*canonicalJson=result;return 1;
}
int lw_scene_modulation_controls(const char* json,LWModulationControls* controls) {
  if(!json||!controls)return 0;
  latticewake::SceneSerializationError error;
  const auto v1=latticewake::parseSceneV1(json,error);
  if(!v1) {
    if(!latticewake::parseSceneV0(json,error)) return 0;
    *controls={1U,1.0F,1U,1.0F,1U,1.0F}; return 1;
  }
  *controls={0U,0.0F,0U,0.0F,0U,0.0F};
  if(v1->modulation.routes.empty()) { *controls={1U,1.0F,1U,1.0F,1U,1.0F}; return 1; }
  for(const auto& route:v1->modulation.routes) {
    if(route.source=="gesture-x") { controls->pitch_enabled=1U; controls->pitch_depth=static_cast<float>(route.depth); }
    else if(route.source=="gesture-y") { controls->timbre_enabled=1U; controls->timbre_depth=static_cast<float>(route.depth); }
    else if(route.source=="pressure") { controls->gain_enabled=1U; controls->gain_depth=static_cast<float>(route.depth); }
  }
  return 1;
}
int lw_scene_apply_modulation_controls(const char* json,const LWModulationControls* controls,char** canonicalJson) {
  if(!json||!controls||!canonicalJson||controls->pitch_enabled>1U||controls->timbre_enabled>1U||controls->gain_enabled>1U||
     !std::isfinite(controls->pitch_depth)||!std::isfinite(controls->timbre_depth)||!std::isfinite(controls->gain_depth)||
     controls->pitch_depth < -1.0F||controls->pitch_depth > 1.0F||controls->timbre_depth < -1.0F||controls->timbre_depth > 1.0F||controls->gain_depth < -1.0F||controls->gain_depth > 1.0F)return 0;
  latticewake::SceneSerializationError error;
  auto v1=latticewake::parseSceneV1(json,error);
  if(!v1)return 0;
  v1->modulation.routes.clear();
  const auto add=[&](const unsigned int enabled,const float depth,const char* suffix,const char* source,const char* target) {
    if(enabled!=0U) v1->modulation.routes.push_back({v1->sceneId+":route:"+suffix,source,target,"per-note",depth});
  };
  add(controls->pitch_enabled,controls->pitch_depth,"gesture-x-pitch","gesture-x","pitch");
  add(controls->timbre_enabled,controls->timbre_depth,"gesture-y-timbre","gesture-y","timbre");
  add(controls->gain_enabled,controls->gain_depth,"pressure-gain","pressure","gain");
  const auto serialized=latticewake::serializeSceneV1(*v1,error);
  if(!serialized)return 0;
  char* result=static_cast<char*>(std::malloc(serialized->size()+1U));if(!result)return 0;
  std::memcpy(result,serialized->c_str(),serialized->size()+1U);*canonicalJson=result;return 1;
}
int lw_role_preview_scene_json(const char* json,const unsigned long long startSample,const unsigned long long frames,const double sampleRate,LWRoleTraceSummary* summary) {
  if(!json||!summary||frames==0)return 0;
  latticewake::SceneSerializationError parseError;
  const auto scene=latticewake::parseSceneDocument(json,parseError);
  if(!scene)return 0;
  latticewake::RoleEventGenerationError generationError;
  const auto trace=latticewake::generateRoleEvents(*scene,startSample,frames,{sampleRate,scene->harmonicContext.tempoBPM},generationError);
  if(!trace)return 0;
  const auto& events=trace->events();
  const std::string bytes=trace->canonicalBytes();
  *summary={static_cast<unsigned long long>(events.size()),events.empty()?0ULL:events.front().sampleOffset,events.empty()?0ULL:events.back().sampleOffset,fnv1a64(bytes)};
  return 1;
}
int lw_role_preview_lane_event_counts_scene_json(const char* json,const unsigned long long startSample,const unsigned long long frames,const double sampleRate,unsigned long long laneEventCounts[4]) {
  if(!json||!laneEventCounts||frames==0)return 0;
  latticewake::SceneSerializationError parseError;
  const auto scene=latticewake::parseSceneDocument(json,parseError);
  if(!scene)return 0;
  latticewake::RoleEventGenerationError generationError;
  const auto trace=latticewake::generateRoleEvents(*scene,startSample,frames,{sampleRate,scene->harmonicContext.tempoBPM},generationError);
  if(!trace)return 0;
  for(unsigned int index=0;index<4U;++index)laneEventCounts[index]=0ULL;
  for(const auto& event:trace->events()) {
    const auto lane=event.payload.find("lane");
    if(lane==event.payload.end())continue;
    if(lane->second=="drone")++laneEventCounts[0];
    else if(lane->second=="pad")++laneEventCounts[1];
    else if(lane->second=="motifA")++laneEventCounts[2];
    else if(lane->second=="motifB")++laneEventCounts[3];
  }
  return 1;
}
int lw_scene_migrate_v1_json(const char* json,const char* sourceHash,char** canonicalJson) {
  if(!json||!sourceHash||sourceHash[0]=='\0'||!canonicalJson)return 0;
  latticewake::SceneSerializationError error;
  if(const auto existing=latticewake::parseSceneV1(json,error)) {
    const auto serialized=latticewake::serializeSceneV1(*existing,error);
    if(!serialized)return 0;
    char* result=static_cast<char*>(std::malloc(serialized->size()+1U));
    if(!result)return 0;
    std::memcpy(result,serialized->c_str(),serialized->size()+1U);*canonicalJson=result;return 1;
  }
  const auto scene=latticewake::parseSceneV0(json,error);
  if(!scene)return 0;
  const auto canonicalV0=latticewake::serializeSceneV0(*scene,error);
  if(!canonicalV0)return 0;
  const auto migrated=latticewake::migrateSceneV0(*scene,sourceHash);
  const auto serialized=latticewake::serializeSceneV1(migrated,error);
  if(!serialized)return 0;
  char* result=static_cast<char*>(std::malloc(serialized->size()+1U));
  if(!result)return 0;
  std::memcpy(result,serialized->c_str(),serialized->size()+1U);*canonicalJson=result;return 1;
}
void lw_string_destroy(char* value) { std::free(value); }
int lw_kernel_note_on_source(LWKernelRef* k,int n,float v,unsigned int source) { return k&&k->events.tryPush({0,true,n,v,0,1,0,false,source}) ? 1 : 0; }
int lw_kernel_note_off_source(LWKernelRef* k,int n,unsigned int source) { return k&&k->events.tryPush({0,false,n,0,0,0,0,false,source}) ? 1 : 0; }
int lw_kernel_note_on(LWKernelRef* k,int n,float v) { return lw_kernel_note_on_source(k,n,v,1U); }
int lw_kernel_note_off(LWKernelRef* k,int n) { return lw_kernel_note_off_source(k,n,1U); }
int lw_kernel_expression(LWKernelRef* k,float glide,float press,float slide) { return k&&k->events.tryPush({0,false,-1,0,glide,press,slide,true}) ? 1 : 0; }
int lw_kernel_note_expression(LWKernelRef* k,int note,float glide,float press,float slide) { return k&&note>=0&&note<=127&&k->events.tryPush({0,false,note,0,glide,press,slide,true}) ? 1 : 0; }
int lw_kernel_note_expression_source(LWKernelRef* k,int note,float glide,float press,float slide,unsigned int source) { return k&&note>=0&&note<=127&&k->events.tryPush({0,false,note,0,glide,press,slide,true,source}) ? 1 : 0; }
int lw_kernel_panic(LWKernelRef* k) {
  if(!k) return 0;
  k->panicRequested.store(true,std::memory_order_release);
  return 1;
}
void lw_kernel_set_roles_running(LWKernelRef* k,unsigned int running) {
  if(!k) return;
  if(running!=0U) { k->rolesRunning.store(true,std::memory_order_release); k->roleStartRequested.store(true,std::memory_order_release); }
  else { k->rolesRunning.store(false,std::memory_order_release); k->roleStopRequested.store(true,std::memory_order_release); }
}
int lw_kernel_role_status(const LWKernelRef* k,LWRoleStatus* status) {
  if(!k||!status) return 0;
  const auto active=k->activeRolePlan.load(std::memory_order_acquire);
  const auto pending=k->pendingRolePlan.load(std::memory_order_acquire);
  *status={k->rolesRunning.load(std::memory_order_acquire)?1U:0U,
           k->activeRoleLanes.load(std::memory_order_acquire),pending==kNoPlan?0U:1U,
           k->rolePlans[active].loopFrames,k->roleSampleOffset.load(std::memory_order_acquire),
           k->rolePlans[active].generation.load(std::memory_order_acquire),
           pending==kNoPlan?0U:k->rolePlans[pending].generation.load(std::memory_order_acquire)};
  return 1;
}
int lw_kernel_render(LWKernelRef* k,float* out,unsigned int frames) {
  if(!k||!out)return 0;
  if(frames==0||frames>kMaximumCallbackFrames) { k->renderFailures.fetch_add(1,std::memory_order_relaxed); return 0; }
  const auto started=std::chrono::steady_clock::now();
  k->renderBegun.store(true,std::memory_order_release);
  if(k->panicRequested.exchange(false,std::memory_order_acq_rel)) {
    const auto active=k->activePlan.load(std::memory_order_acquire);
    k->plans[active].kernel.reset();
    k->events.discardPendingConsumerSide();
    k->rolesRunning.store(false,std::memory_order_release);
    k->roleStartRequested.store(false,std::memory_order_release);
    k->roleStopRequested.store(false,std::memory_order_release);
    k->activeRoleNotes={{-1,-1,-1,-1}};
    k->activeRoleLanes.store(0,std::memory_order_release);
    k->roleBoundaryReleaseRequested=false;
  }
  const std::uint32_t pending=k->pendingPlan.load(std::memory_order_acquire);
  if(pending!=kNoPlan) {
    k->activePlan.store(pending,std::memory_order_release);
    k->pendingPlan.store(kNoPlan,std::memory_order_release);
  }
  std::array<latticewake::KernelEvent,latticewake::RealtimeKernel::kMaxEvents> events{};
  std::size_t count=0;
  auto pushRole=[&](const latticewake::PreparedRoleEvent& scheduled,const unsigned int frame) {
    if(count>=events.size()) return;
    events[count++]={frame,scheduled.noteOn,scheduled.note,scheduled.noteOn?0.35F:0.0F,0,1,0,false,scheduled.source};
    const auto lane=scheduled.source-kRoleSourceBase;
    if(lane<k->activeRoleNotes.size()) k->activeRoleNotes[lane]=scheduled.noteOn?scheduled.note:-1;
  };
  auto releaseRoles=[&](const unsigned int frame) {
    bool releasedAll=true;
    for(std::size_t lane=0;lane<k->activeRoleNotes.size();++lane) {
      const int note=k->activeRoleNotes[lane];
      if(note<0) continue;
      if(count>=events.size()) { releasedAll=false; continue; }
      events[count++]={frame,false,note,0,0,0,0,false,kRoleSourceBase+static_cast<std::uint32_t>(lane)};
      k->activeRoleNotes[lane]=-1;
    }
    return releasedAll;
  };
  if(k->roleBoundaryReleaseRequested) {
    k->roleBoundaryReleaseRequested=!releaseRoles(0);
  }
  if(k->roleStopRequested.exchange(false,std::memory_order_acq_rel)) {
    if(!releaseRoles(0)) k->roleBoundaryReleaseRequested=true;
    k->activeRoleLanes.store(0,std::memory_order_release);
  }
  const bool roleStart=k->roleStartRequested.exchange(false,std::memory_order_acq_rel);
  if(!k->rolesRunning.load(std::memory_order_acquire)||roleStart) {
    const std::uint32_t pendingRole=k->pendingRolePlan.exchange(kNoPlan,std::memory_order_acq_rel);
    if(pendingRole!=kNoPlan) k->activeRolePlan.store(pendingRole,std::memory_order_release);
    if(roleStart) k->roleSampleOffset=0;
  }
  if(k->rolesRunning.load(std::memory_order_acquire)) {
    std::uint32_t currentRole=k->activeRolePlan.load(std::memory_order_acquire);
    auto* rolePlan=&k->rolePlans[currentRole];
    if(rolePlan->loopFrames>0) {
      const std::uint64_t begin=k->roleSampleOffset.load(std::memory_order_relaxed);
      const std::uint64_t end=begin+frames;
      const bool reachesBoundary=end>=rolePlan->loopFrames;
      if(!reachesBoundary) {
        for(std::uint32_t index=0;index<rolePlan->eventCount&&count<events.size();++index) {
          const auto& scheduled=rolePlan->events[index];
          if(scheduled.frame>=begin&&scheduled.frame<end) pushRole(scheduled,static_cast<unsigned int>(scheduled.frame-begin));
        }
        k->roleSampleOffset=end;
      } else {
        const std::uint64_t boundaryFrame=rolePlan->loopFrames-begin;
        for(std::uint32_t index=0;index<rolePlan->eventCount&&count<events.size();++index) {
          const auto& scheduled=rolePlan->events[index];
          if(scheduled.frame>=begin) pushRole(scheduled,static_cast<unsigned int>(scheduled.frame-begin));
        }
        const std::uint32_t pendingRole=k->pendingRolePlan.exchange(kNoPlan,std::memory_order_acq_rel);
        if(pendingRole!=kNoPlan) {
          if(boundaryFrame<frames) k->roleBoundaryReleaseRequested=!releaseRoles(static_cast<unsigned int>(boundaryFrame));
          else k->roleBoundaryReleaseRequested=true;
          k->activeRolePlan.store(pendingRole,std::memory_order_release);
          currentRole=pendingRole;
          rolePlan=&k->rolePlans[currentRole];
        }
        const std::uint64_t remaining=frames-boundaryFrame;
        if(remaining>0&&rolePlan->loopFrames>0) {
          for(std::uint32_t index=0;index<rolePlan->eventCount&&count<events.size();++index) {
            const auto& scheduled=rolePlan->events[index];
            if(scheduled.frame<remaining) pushRole(scheduled,static_cast<unsigned int>(boundaryFrame+scheduled.frame));
          }
          k->roleSampleOffset=remaining%rolePlan->loopFrames;
        } else {
          k->roleSampleOffset=0;
        }
      }
    }
  }
  latticewake::KernelEvent event;
  while(count<events.size()&&k->events.tryPop(event)) {
    std::size_t insertion=count;
    while(insertion>0&&events[insertion-1].frame>event.frame) {
      events[insertion]=events[insertion-1];
      --insertion;
    }
    events[insertion]=event;
    ++count;
  }
  const std::uint32_t active=k->activePlan.load(std::memory_order_acquire);
  const bool rendered=k->plans[active].kernel.render(std::span<float>(out,frames),std::span<const latticewake::KernelEvent>(events.data(),count));
  float peak=0;
  if(rendered) for(unsigned int i=0;i<frames;++i) peak=std::max(peak,std::fabs(out[i]));
  std::uint32_t activeLanes=0;
  for(const int note:k->activeRoleNotes) if(note>=0) ++activeLanes;
  k->activeRoleLanes.store(activeLanes,std::memory_order_release);
  k->outputPeak.store(peak,std::memory_order_relaxed);
  const auto elapsed=static_cast<std::uint64_t>(std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::steady_clock::now()-started).count());
  updateMaximum(k->maximumRenderNanoseconds,elapsed);
  const auto deadline=static_cast<std::uint64_t>(static_cast<double>(frames)*1000000000.0/k->callbackSampleRate);
  if(elapsed>deadline)k->deadlineMisses.fetch_add(1,std::memory_order_relaxed);
  if(!rendered) { k->renderFailures.fetch_add(1,std::memory_order_relaxed); return 0; }
  k->callbackCount.fetch_add(1,std::memory_order_relaxed);
  k->renderedFrames.fetch_add(frames,std::memory_order_relaxed);
  return 1;
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
float lw_kernel_output_peak(const LWKernelRef* k) { return k?k->outputPeak.load(std::memory_order_relaxed):0; }
int lw_kernel_callback_status(const LWKernelRef* k,LWCallbackStatus* status) {
  if(!k||!status)return 0;
  *status={k->callbackCount.load(std::memory_order_relaxed),k->renderedFrames.load(std::memory_order_relaxed),k->renderFailures.load(std::memory_order_relaxed),k->maximumRenderNanoseconds.load(std::memory_order_relaxed),k->deadlineMisses.load(std::memory_order_relaxed),kMaximumCallbackFrames};
  return 1;
}
unsigned int lw_kernel_maximum_callback_frames(void) { return kMaximumCallbackFrames; }
unsigned int lw_kernel_event_queue_capacity(void) { return latticewake::RealtimeEventQueue::kUsableCapacity; }
void lw_kernel_reset(LWKernelRef* k) {
  if(!k) return;
  if(k->renderBegun.load(std::memory_order_acquire)) { (void)lw_kernel_panic(k); return; }
  const std::uint32_t active=k->activePlan.load(std::memory_order_acquire);
  k->plans[active].kernel.reset();
  k->events.resetProducerSide();
  k->rolesRunning.store(false,std::memory_order_release);
  k->roleStartRequested.store(false,std::memory_order_release);
  k->roleStopRequested.store(false,std::memory_order_release);
  k->activeRoleNotes={{-1,-1,-1,-1}};
  k->activeRoleLanes.store(0,std::memory_order_release);
  k->roleSampleOffset=0;
  k->roleBoundaryReleaseRequested=false;
}
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
