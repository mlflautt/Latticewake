#pragma once
#ifdef __cplusplus
extern "C" {
#endif
const char* latticewake_core_version(void);
typedef struct LWKernelRef LWKernelRef;
typedef struct LWMpeStateRef LWMpeStateRef;
float lw_kernel_output_peak(const LWKernelRef* kernel);
typedef struct LWKernelStatus {
  unsigned int pending_events;
  unsigned int dropped_events;
  unsigned long long active_plan_generation;
  unsigned long long pending_plan_generation;
} LWKernelStatus;
typedef struct LWRoleStatus { unsigned int running; unsigned int active_lanes; unsigned long long loop_frames; } LWRoleStatus;
typedef struct LWCallbackStatus {
  unsigned long long callback_count;
  unsigned long long rendered_frames;
  unsigned long long render_failures;
  unsigned long long maximum_render_nanoseconds;
  unsigned long long deadline_misses;
  unsigned int maximum_callback_frames;
} LWCallbackStatus;
typedef struct LWTerrainFramePoint {
  float value;
  float path_x;
  float path_y;
  unsigned int iterations;
  unsigned int escaped;
} LWTerrainFramePoint;
typedef struct LWRoleControl {
  unsigned int enabled;
  float range;
  float density;
  unsigned long long seed_offset;
  unsigned int pattern;
} LWRoleControl;
typedef struct LWRoleTraceSummary {
  unsigned long long event_count;
  unsigned long long first_sample;
  unsigned long long last_sample;
  unsigned long long receipt;
} LWRoleTraceSummary;
typedef struct LWSceneEditorControls {
  double terrain_detail;
  double terrain_zoom;
  double terrain_offset_x;
  double terrain_offset_y;
  double traversal_rate_ratio;
  double traversal_radius_x;
  double traversal_radius_y;
  double traversal_angle;
  double traversal_translation_x;
  double traversal_translation_y;
  double attack_seconds;
  double release_seconds;
  double gain;
  double glide_semitones;
  double velocity_response;
  double pressure_response;
  double slide_response;
} LWSceneEditorControls;
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
int lw_scene_role_control(const char* json, unsigned int role_index, LWRoleControl* control);
int lw_scene_apply_role_control(const char* json, unsigned int role_index,
                                const LWRoleControl* control, char** canonical_json);
int lw_scene_editor_controls(const char* json, LWSceneEditorControls* controls);
int lw_scene_apply_editor_controls(const char* json, const LWSceneEditorControls* controls,
                                   char** canonical_json);
int lw_role_preview_scene_json(const char* json, unsigned long long start_sample,
                               unsigned long long frames, double sample_rate,
                               LWRoleTraceSummary* summary);
int lw_scene_migrate_v1_json(const char* json, const char* source_hash, char** canonical_json);
void lw_string_destroy(char* value);
int lw_kernel_note_on(LWKernelRef* kernel, int note, float velocity);
int lw_kernel_note_off(LWKernelRef* kernel, int note);
int lw_kernel_note_on_source(LWKernelRef* kernel, int note, float velocity, unsigned int source);
int lw_kernel_note_off_source(LWKernelRef* kernel, int note, unsigned int source);
int lw_kernel_expression(LWKernelRef* kernel, float glide, float press, float slide);
int lw_kernel_note_expression(LWKernelRef* kernel, int note, float glide, float press, float slide);
int lw_kernel_note_expression_source(LWKernelRef* kernel, int note, float glide, float press, float slide, unsigned int source);
int lw_kernel_panic(LWKernelRef* kernel);
int lw_kernel_render(LWKernelRef* kernel, float* output, unsigned int frames);
int lw_kernel_status(const LWKernelRef* kernel, LWKernelStatus* status);
void lw_kernel_set_roles_running(LWKernelRef* kernel, unsigned int running);
int lw_kernel_role_status(const LWKernelRef* kernel, LWRoleStatus* status);
int lw_kernel_callback_status(const LWKernelRef* kernel, LWCallbackStatus* status);
unsigned int lw_kernel_maximum_callback_frames(void);
unsigned int lw_kernel_event_queue_capacity(void);
void lw_kernel_reset(LWKernelRef* kernel);
LWMpeStateRef* lw_mpe_state_create(unsigned int mode, int master_channel, int member_count);
void lw_mpe_state_destroy(LWMpeStateRef* state);
int lw_mpe_note_on(LWMpeStateRef* state, int channel, int note);
int lw_mpe_note_off(LWMpeStateRef* state, int channel, int note);
int lw_mpe_expression(LWMpeStateRef* state, int channel, float glide, float press, float slide);
int lw_mpe_active_note(const LWMpeStateRef* state, int channel, int* note);
void lw_mpe_reset(LWMpeStateRef* state);
#ifdef __cplusplus
}
#endif
