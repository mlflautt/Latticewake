# Cycle 060 — image-derived terrain Surface

## Objective

Import a bounded image interpretation as a project-owned Surface asset, let the
artist preview it before replacing either Scene v1 Surface layer, and prepare
image-derived terrain tables through the portable `RenderPlanBuilder`.

## Owned paths

- Swift image import, asset/library, presentation, and app controls.
- C ABI Surface field bridge and portable RenderPlan image sampling.
- Scene contract, user-facing media documentation, tests, and cycle handoff.

## Non-goals

- Audio-derived Surfaces or multiple image interpretation providers.
- Reading image data or files from the audio callback.
- Automatic scene mutation, image overwrite, or aesthetic ranking.
- Claiming target-device admission or human listening approval.

## Acceptance checks

- The image provider is deterministic for a given decoded result, bounded, and
  records source and generated-field hashes separately.
- Candidate preview does not mutate the saved scene; Replace A/B explicitly
  accepts it.
- Scene Library save/load and undo preserve embedded Surface assets.
- `RenderPlanBuilder` validates asset identity and copies sampled tables before
  publication; malformed or mismatched fields fail without replacing a plan.
- Normal, sanitizer, Swift, app packaging, and bundle verification pass.
