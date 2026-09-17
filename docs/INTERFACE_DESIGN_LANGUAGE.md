# Latticewake interface design language

## Character

The interface is **luminous cartography**: a quiet, dark instrument surface on
which terrain contours, paths, voices, and musical roles appear as precise
light. It should feel exploratory and alive without becoming ornamental,
game-like, or faux-scientific.

## Information architecture

- The Terrain Stage always remains visible and playable.
- The top bar owns scene identity, dirty state, undo, transport, tempo, panic,
  CPU, and output.
- The center owns the authoritative 2D terrain, sampling paths, pointer, direct
  voices, and lane playheads.
- The bottom role deck owns Drone, Pad, Motif A, and Motif B activity and macros.
- A right contextual drawer edits Surface, Traversal, Articulation, Harmony,
  Modulation, and Routing.
- A left contextual drawer owns Library, Grow, proposals, captures, and scene
  chains.
- Diagnostics remain collapsed unless requested or a fault needs attention.

Cycle 057 implements this as one fixed shell: the top transport and center
Stage never scroll, the left tool rail opens Library/Grow, the right drawer
switches among Scene, Motion, and Lanes, and the performance macro/lane rails
remain beside the Stage. Perform, Sculpt, and Grow are levels of disclosure
over the same instrument rather than separate pages.

## Visual grammar

- Foundation: graphite and deep navy surfaces with restrained depth changes.
- Direct traversal: cyan. Drone: amber. Pad: violet. Motif A: mint. Motif B:
  coral. Every colored state also receives a shape, label, or line-style cue.
- Use system typography for clarity and monospaced numerals only for timing,
  hashes, diagnostics, and exact values.
- Contours are thin and subordinate to active paths. Glow indicates activity,
  selection, or modulation energy; it is never permanent decoration.
- Every control has default, hover, pressed, focused, disabled, warning, and
  error states. Unsaved changes are textual as well as chromatic.

## Interaction grammar

- Clicking empty terrain begins a pointer-owned voice; dragging with keyboard
  notes held shapes those notes without creating another voice.
- Surface, Traversal, and Articulation are independently replaceable.
- Select a parameter, then assign modulation sources and bipolar depths.
- Link means edit a shared value; unlink means edit the selected lane or slot.
- Freeze locks named scene components. Grow always previews a bounded diff
  before Accept or Reject.
- Double-click resets a parameter; Option-drag provides fine adjustment; all
  destructive or broad mutations are undoable.
- An image-derived Surface appears as the registered source plane beneath its
  interpreted contours. Traversal and live samples share the same coordinates;
  a detached thumbnail never substitutes for the playable terrain. See
  [Media-derived terrain interface](MEDIA_TERRAIN_INTERFACE.md).

## Motion and accessibility

- Animation must visualize state sampled from immutable snapshots and must not
  drive audio behavior.
- Reduced Motion replaces flowing animation with stepped or static indicators.
- Support keyboard focus, scalable text, VoiceOver descriptions, and contrast
  that remains legible without glow or color.
- Target sixty visual frames per second when available, but degrade visual rate
  before consuming audio budget.

## Reference boundary

Hyperion, Novum, and Myth inform principles such as explicit modulation scope,
separable sound components, direct manipulation, contextual depth, and bounded
variation. Latticewake does not copy their layouts, terminology, assets,
presets, or visual identities.
