#include "terrain_frame.hpp"

#include <cmath>

namespace latticewake {
std::optional<TerrainFrameSnapshot> buildTerrainFrame(const Scene& scene, const TerrainFrameRequest& request, TerrainFrameError& error) {
  if(!isValidScene(scene)){error={"scene","must satisfy Scene v0 validation"};return std::nullopt;}
  if(!std::isfinite(request.startPhase)||!std::isfinite(request.phaseStep)||request.startPhase<0.0||request.startPhase>1.0||request.phaseStep<0.0||request.pointCount==0U||request.pointCount>4096U){error={"request","requires finite phases, 1 to 4096 points, and startPhase in [0, 1]"};return std::nullopt;}
  TerrainFrameSnapshot frame{scene.sceneId,request.sampleOffset,{}};frame.points.reserve(request.pointCount);for(std::size_t index=0;index<request.pointCount;++index){const double phase=request.startPhase+static_cast<double>(index)*request.phaseStep;if(phase>1.0){error={"request","phase range must remain in [0, 1]"};return std::nullopt;}frame.points.push_back(evaluateAnalyticTerrain(scene,{phase,0.0,0.0}));}return frame;
}
}  // namespace latticewake
