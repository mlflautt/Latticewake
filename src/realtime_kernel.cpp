#include "realtime_kernel.hpp"
#include "terrain_evaluator.hpp"
#include <algorithm>
#include <cmath>
namespace latticewake {
bool RealtimeKernel::prepare(const Scene& scene,const double rate) noexcept { if(!isValidScene(scene)||!std::isfinite(rate)||rate<8000||rate>192000)return false; for(std::size_t i=0;i<kTableSize;++i){const auto e=evaluateAnalyticTerrain(scene,{double(i)/double(kTableSize),0,0});table_[i]=std::isfinite(e.value)?float(2*e.value-1):0;} sampleRate_=float(rate);reset();ready_=true;return true; }
void RealtimeKernel::reset() noexcept { for(auto& v:voices_)v={};previousInput_=previousOutput_=glide_=slide_=0;press_=1; }
bool RealtimeKernel::render(std::span<float> out,std::span<const KernelEvent> events) noexcept { if(!ready_||events.size()>kMaxEvents)return false;std::size_t next=0;for(std::size_t f=0;f<out.size();++f){while(next<events.size()&&events[next].frame==f){const auto&e=events[next++];if(e.expression){glide_=std::clamp(e.glide,-1.0F,1.0F);press_=std::clamp(e.press,0.0F,1.0F);slide_=std::clamp(e.slide,0.0F,1.0F);continue;}if(e.noteOn&&e.note>=0&&e.note<=127&&e.velocity>=0&&e.velocity<=1){for(auto&v:voices_)if(!v.active){v.active=true;v.phase=0;v.increment=440.0F*std::pow(2.0F,(float(e.note)-69+glide_)/12)/sampleRate_;v.gain=e.velocity;break;}}else for(auto&v:voices_)if(v.active){v.active=false;break;}}float input=0;for(auto&v:voices_)if(v.active){const auto idx=(std::size_t(v.phase*kTableSize)+std::size_t(slide_*(kTableSize-1)))%kTableSize;input+=table_[idx]*v.gain*press_;v.phase+=v.increment;if(v.phase>=1)v.phase-=1;}const float dc=input-previousInput_+0.997F*previousOutput_;out[f]=dc/(1+std::fabs(dc));previousInput_=input;previousOutput_=dc;if(!std::isfinite(out[f])){reset();out[f]=0;}}return next==events.size(); }
}
