#include "offline_oversampling.hpp"

#include <cmath>

namespace latticewake {
std::optional<OfflineOversamplingResult> renderOversampledTerrainVoice(
    const std::span<const TerrainEvaluation> trace, const OfflineTerrainVoiceConfig& config,
    const OversamplingFactor factor, OfflineTerrainVoiceError& error) {
  const unsigned int multiplier=static_cast<unsigned int>(factor); if(multiplier!=1U&&multiplier!=2U&&multiplier!=4U){error={"factor","must be 1, 2, or 4"};return std::nullopt;}
  if(multiplier==1U){const auto rendered=renderOfflineTerrainVoice(trace,config,error);if(!rendered)return std::nullopt;double energy=0.0;for(std::size_t i=1;i<rendered->size();++i){const double d=(*rendered)[i]-(*rendered)[i-1];energy+=d*d;}return OfflineOversamplingResult{std::move(*rendered),energy};}
  std::vector<TerrainEvaluation> upsampled; upsampled.reserve(trace.size()*multiplier);
  for(std::size_t index=0;index<trace.size();++index){const double current=trace[index].value;const double next=index+1<trace.size()?trace[index+1].value:current;for(unsigned int sub=0;sub<multiplier;++sub){const double ratio=static_cast<double>(sub)/static_cast<double>(multiplier);upsampled.push_back({current+(next-current)*ratio,0.0,0.0,0,false});}}
  const auto highRate=renderOfflineTerrainVoice(upsampled,config,error);if(!highRate)return std::nullopt;std::vector<double> downsampled;downsampled.reserve(trace.size());for(std::size_t index=0;index<trace.size();++index){double sum=0.0;for(unsigned int sub=0;sub<multiplier;++sub)sum+=(*highRate)[index*multiplier+sub];downsampled.push_back(sum/static_cast<double>(multiplier));}double energy=0.0;for(std::size_t i=1;i<downsampled.size();++i){const double d=downsampled[i]-downsampled[i-1];energy+=d*d;}return OfflineOversamplingResult{std::move(downsampled),energy};
}
}  // namespace latticewake
