#pragma once
#ifdef __cplusplus
extern "C" {
#endif
const char* latticewake_core_version(void);
typedef struct LWKernelRef LWKernelRef;
LWKernelRef* lw_kernel_create(void);
void lw_kernel_destroy(LWKernelRef* kernel);
int lw_kernel_prepare_demo(LWKernelRef* kernel, double sample_rate);
int lw_kernel_note_on(LWKernelRef* kernel, int note, float velocity);
int lw_kernel_note_off(LWKernelRef* kernel, int note);
int lw_kernel_render(LWKernelRef* kernel, float* output, unsigned int frames);
void lw_kernel_reset(LWKernelRef* kernel);
#ifdef __cplusplus
}
#endif
