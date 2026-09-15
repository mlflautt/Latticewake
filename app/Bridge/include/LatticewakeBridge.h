#pragma once
#ifdef __cplusplus
extern "C" {
#endif
const char* latticewake_core_version(void);
typedef struct LWKernelRef LWKernelRef;
typedef struct LWMpeStateRef LWMpeStateRef;
typedef struct LWKernelStatus {
  unsigned int pending_events;
  unsigned int dropped_events;
  unsigned long long active_plan_generation;
  unsigned long long pending_plan_generation;
} LWKernelStatus;
typedef struct LWTerrainFramePoint {
  float value;
  float path_x;
  float path_y;
  unsigned int iterations;
  unsigned int escaped;
} LWTerrainFramePoint;
LWKernelRef* lw_kernel_create(void);
void lw_kernel_destroy(LWKernelRef* kernel);
int lw_kernel_prepare_demo(LWKernelRef* kernel, double sample_rate);
int lw_kernel_prepare_scene_json(LWKernelRef* kernel, const char* json, double sample_rate);
int lw_kernel_publish_demo(LWKernelRef* kernel, double sample_rate);
int lw_kernel_publish_scene_json(LWKernelRef* kernel, const char* json, double sample_rate);
int lw_terrain_frame_scene_json(const char* json, unsigned long long sample_offset,
                                double start_phase, double phase_step,
                                LWTerrainFramePoint* points, unsigned int capacity,
                                unsigned int* point_count);
int lw_kernel_note_on(LWKernelRef* kernel, int note, float velocity);
int lw_kernel_note_off(LWKernelRef* kernel, int note);
int lw_kernel_expression(LWKernelRef* kernel, float glide, float press, float slide);
int lw_kernel_render(LWKernelRef* kernel, float* output, unsigned int frames);
int lw_kernel_status(const LWKernelRef* kernel, LWKernelStatus* status);
unsigned int lw_kernel_event_queue_capacity(void);
void lw_kernel_reset(LWKernelRef* kernel);
LWMpeStateRef* lw_mpe_state_create(unsigned int mode, int master_channel, int member_count);
void lw_mpe_state_destroy(LWMpeStateRef* state);
int lw_mpe_note_on(LWMpeStateRef* state, int channel, int note);
int lw_mpe_note_off(LWMpeStateRef* state, int channel, int note);
int lw_mpe_expression(LWMpeStateRef* state, int channel, float glide, float press, float slide);
void lw_mpe_reset(LWMpeStateRef* state);
#ifdef __cplusplus
}
#endif
