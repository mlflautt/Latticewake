#include "realtime_kernel.hpp"
#include "scene_serialization.hpp"
#include <algorithm>
#include <cassert>
#include <cmath>
#include <cstdint>
#include <fstream>
#include <iostream>
#include <iterator>
#include <vector>

double rms(const std::vector<float>& samples, std::size_t first, std::size_t last) {
  double energy = 0;
  for (auto i = first; i < last; ++i) energy += samples[i] * samples[i];
  return std::sqrt(energy / double(last - first));
}
int main() {
  using namespace latticewake;
  std::ifstream file("app/Sources/LatticewakeApp/DemoScene.swift");
  const std::string source{std::istreambuf_iterator<char>(file), {}};
  const auto begin = source.find("{\"schemaVersion");
  const auto end = source.find("\n", begin);
  SceneSerializationError error;
  auto scene = parseSceneV0(source.substr(begin, end - begin), error);
  assert(scene);
  PreparedTerrainPlan flat;
  assert(prepareTerrainPlan(*scene, 48000, flat));
  assert(flat.variation == 0);
  // The old implementation mapped the constant zero terrain to -1. Its
  // DC blocker produced only a transient, independently of oscillator pitch.
  double previous = 0, output = 0;
  for (int i = 0; i < 48000; ++i) { output = -1 - previous + .997 * output; previous = -1; }
  assert(std::abs(output) < 1e-20);
  scene->terrain.zoom = 0;
  scene->path.rateRatio = 1;
  scene->path.radiusX = .5;
  scene->path.radiusY = .3;
  scene->path.translationX = .6;
  PreparedTerrainPlan plan;
  assert(prepareTerrainPlan(*scene, 48000, plan));
  assert(plan.variation > .01F);
  // Nine simultaneous notes must equal the newest eight, and repeated key
  // downs must not consume voices or restart their envelopes.
  RealtimeKernel crowded, reference, repeated;
  assert(crowded.activate(plan) && reference.activate(plan) && repeated.activate(plan));
  std::array<KernelEvent,9> nine{};
  std::array<KernelEvent,8> eight{};
  for (int i=0; i<9; ++i) nine[i]={0,true,60+i,.7F};
  for (int i=0; i<8; ++i) eight[i]={0,true,61+i,.7F};
  std::vector<float> a(4096), b(4096), c(4096);
  assert(crowded.render(a,nine) && reference.render(b,eight));
  for (std::size_t i=0; i<a.size(); ++i) assert(std::abs(a[i]-b[i]) < 1e-6F);
  reference.reset();
  const std::array<KernelEvent,1> single{{{0,true,60,.7F}}};
  const std::array<KernelEvent,2> duplicate{{{0,true,60,.7F},{1000,true,60,.7F}}};
  assert(reference.render(b,single) && repeated.render(c,duplicate));
  assert(b==c);
  reference.reset(); repeated.reset();
  const std::array<KernelEvent,2> timbre{{{0,true,60,.7F},{0,false,60,0,0,1,1,true}}};
  assert(reference.render(b,single) && repeated.render(c,timbre));
  double morphDifference=0;
  for (std::size_t i=2048; i<b.size(); ++i) morphDifference += std::abs(b[i]-c[i]);
  assert(morphDifference > 1);
  auto harmonic = [](const std::vector<float>& samples, double hz) {
    double re=0, im=0;
    for (std::size_t i=2048; i<samples.size(); ++i) {
      const double phase=6.283185307179586*hz*double(i)/48000;
      re+=samples[i]*std::cos(phase); im+=samples[i]*std::sin(phase);
    }
    return std::hypot(re,im);
  };
  const double c4=440*std::pow(2.,-9./12.);
  const double baseRatio=harmonic(b,2*c4)/harmonic(b,c4);
  const double morphRatio=harmonic(c,2*c4)/harmonic(c,c4);
  assert(std::abs(morphRatio-baseRatio) > .05);
  std::vector<float> glide(72000);
  repeated.reset();
  const std::array<KernelEvent,2> glideEvents{{{0,true,60,.7F},{0,false,60,0,1,1,0,true}}};
  assert(repeated.render(glide,glideEvents));
  int bestLag=0; double bestGlideError=1e9;
  for(int lag=80;lag<105;++lag) {
    double diff=0;
    for(int i=48000;i<52000;++i) { double d=glide[i]-glide[i+lag];diff+=d*d; }
    if(diff<bestGlideError) { bestGlideError=diff;bestLag=lag; }
  }
  assert(std::abs((48000./bestLag)/(2*c4)-1) < .01);
  std::vector<float> demo;
  for (int note : {60, 64, 67}) {
    RealtimeKernel kernel;
    assert(kernel.activate(plan));
    std::vector<float> samples(72000);
    const std::array<KernelEvent, 2> events{{{0,true,note,.7F},{60000,false,note,0}}};
    assert(kernel.render(samples, events));
    assert(rms(samples,48000,59000) > .005);
    assert(rms(samples,71000,72000) < 1e-5);
    const double expected = 440 * std::pow(2., (note - 69) / 12.);
    // Estimate period from the sustained waveform by normalized difference.
    int best = 0; double bestError = 1e9;
    for (int lag = int(48000 / expected * .8); lag <= int(48000 / expected * 1.2); ++lag) {
      double difference = 0;
      for (int i = 48000; i < 52000; ++i) { double d=samples[i]-samples[i+lag]; difference += d*d; }
      if (difference < bestError) { bestError = difference; best = lag; }
    }
    const double measured = 48000. / best;
    std::cout << "note=" << note << " expected=" << expected << " measured=" << measured
              << " sustained_rms=" << rms(samples,48000,59000) << '\n';
    assert(std::abs(measured / expected - 1) < .01);
    demo.insert(demo.end(), samples.begin(), samples.end());
  }
  std::ofstream wav("build/playable-baseline.wav", std::ios::binary);
  auto u16=[&](std::uint16_t v){ wav.put(char(v)); wav.put(char(v>>8)); };
  auto u32=[&](std::uint32_t v){ u16(v&65535); u16(v>>16); };
  wav.write("RIFF",4); u32(36+std::uint32_t(demo.size()*2)); wav.write("WAVEfmt ",8);
  u32(16); u16(1); u16(1); u32(48000); u32(96000); u16(2); u16(16);
  wav.write("data",4); u32(std::uint32_t(demo.size()*2));
  for (float s : demo) u16(static_cast<std::uint16_t>(static_cast<std::int16_t>(std::clamp(s,-1.F,1.F)*32767)));
}
