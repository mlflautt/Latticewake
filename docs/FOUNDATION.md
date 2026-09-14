# Latticewake foundation

## Purpose

Latticewake is a playable generative lab, not an image-sonification utility or
an NDLR emulation. Its central idea is that a musician can directly play and
steer a changing terrain while four musical roles generate coherent material
around a shared harmonic context.

The system has three planes that must remain separate:

1. The real-time plane renders audio, accepts/produces MIDI and MPE, advances
   transport, and evaluates bounded generator state.
2. The creative plane creates candidate melodies or scene changes asynchronously.
3. The human plane previews, commits, undoes, and publishes. It is the only
   plane allowed to make a proposal durable or externally audible.

## Research evidence and interpretation

These user-supplied reports were read as design evidence:

| Report | SHA-256 | Decisions it supports |
| --- | --- | --- |
| [`Wave-Terrain Synthesis DSP Research.md`](../research/source-reports/Wave-Terrain%20Synthesis%20DSP%20Research.md) | `f5a263c7fed4b546b839ea01cc3e5abcb635d05443deb489f293b101306f1d84` | Analytic terrain-first kernel, smooth escape values, bounded iteration, oversampling, spatial feedback bounds, DC removal, and separate buffered-terrain support. |
| [`Latticewake Generative Music Research.md`](../research/source-reports/Latticewake%20Generative%20Music%20Research.md) | `e4e695c504cc0225d493b4957305e668ff7cd75698dd34a591eab8c85161569e` | Generator placement, deterministic seeds, bounded chaos, asynchronous grammar expansion, and Metal-only dynamic-field simulation. |
| [`Latticewake Audio Architecture Research.md`](../research/source-reports/Latticewake%20Audio%20Architecture%20Research.md) | `baaf34a326402ea7f3e7ea609a2017f478e9239b1fd8c6202259c6c7f7db7e68` | C++/Swift isolation, MPE expression semantics, sample-clocked transport, triple-buffered visual state, and proposal-preview-commit. |

The reports' mathematical and technical recommendations are useful hypotheses
and implementation inputs, not runtime proof, legal advice, or evidence that a
specific sound is desirable. Source claims and Apple API behavior must be
rechecked against primary documentation when their implementation begins.

The third report also found that `lauri.fm` currently resolves to unrelated
audio content. It is therefore removed from Latticewake's reference set; the
keyboard/trackpad design will be specified from first principles and tested on
the target Mac rather than reverse-engineered from that domain.

## Product model

### Musical roles

Latticewake has four named role lanes. All listen to one `HarmonicContext`, but
retain their own range, density, pattern, rhythm, modulation, and output route.

| Lane | First generator families | Player-facing function |
| --- | --- | --- |
| Drone | root/chord cadence, slow fractal-Brownian drift | harmonic floor |
| Pad | voiced chord field, bounded density and register spread | harmonic body |
| Motif A | Euclidean/manual rhythm plus degree pattern | primary motion |
| Motif B | cellular-automaton variation, rotated/coprime rhythm, optional recursive phrase | contrast and detail |

The lanes can drive the internal terrain voice, external MIDI/MPE destinations,
or both. They are functional inspiration from generative sequencers, not a
copy of any specific product's UI or code.

The current implementation emits deterministic, bounded offline traces for
these lanes. It does not schedule audio, allocate voices, or send MIDI.

MPE expression has three stable semantic inputs: `glide` (per-note pitch),
`press` (per-note pressure), and `slide` (per-note timbre). QWERTY supplies
note events; trackpad gestures are a low-rate source for these inputs and are
smoothed by the DSP core before they affect audio. Standard MIDI receives a
single-channel compatibility route, rather than a fabricated MPE zone.

### Terrain voice

The initial sound source is an analytic, normalized scalar field sampled by a
bounded trajectory:

```text
audio[n] = TerrainField(Trajectory(phase[n], gesture, scene), scene)
```

Initial fields are smooth-potential Mandelbrot/Julia variants, fractal noise,
and bounded recursive transforms. The field family is a plug-in point; image
buffers, attractor-density tables, and simulation frames are later field
providers, not alternate instrument architectures.

Initial paths are ellipse, Lissajous, spiral, and bounded meander. Feedback is
feedback into *coordinates*, not an unbounded audio loop. A radial spatial
limiter constrains position before terrain evaluation.

### Generator placement

| Technique | Placement | Non-negotiable bound |
| --- | --- | --- |
| Euclidean rhythm, fixed-depth cellular automata, logistic map | event/control engine | integer/domain validation and deterministic seed |
| Fractal Brownian motion | control engine | fixed PRNG, range, rate, smoothing |
| L-system/substitution grammar | background worker | depth, token, time, and memory caps; results enter through a queue |
| Lorenz/Rossler | control engine first; audio-rate only after profiling | stable parameter domain, fixed integration step, finite-state reset |
| Attractor-density transitions | offline/precomputed table | table identity and seed recorded in scene |
| Gray-Scott/reaction-diffusion | Metal compute at visual/control rate | bounded parameters; snapshot handoff, never audio-thread evaluation |

## Real-time contract

The audio callback may only read preallocated state and emit audio. It must not
allocate, lock, perform file/network I/O, invoke an LLM, expand a grammar, or
wait for UI/Metal work. UI, MIDI setup, generator workers, and Metal publish
immutable snapshots through single-producer/single-consumer queues.

The audio engine is the authority for sample time. Tempo, phase, note starts,
and generative pattern positions derive from sample count and an explicit
transport state—not wall-clock timers. Visual state is published through a
separate rotating snapshot set so a delayed Metal frame never blocks audio.

For the first kernel:

- support 48 kHz stereo validation and up to eight terrain voices;
- use a selectable 1x/2x/4x oversampling policy, with 4x as the first
  anti-aliasing test target rather than an unverified performance promise;
- apply DC removal before a conservative output limiter;
- require hard iteration limits and finite-output checks for every analytic
  field; an exhausted/invalid evaluation returns a documented neutral value;
- reset any non-finite trajectory or dynamical state to its scene seed state;
- use smooth escape values rather than raw integer escape counts for the first
  fractal fields.

## Intelligence boundary

Apple Intelligence is an optional, on-device-first proposal provider. It may
produce a `MelodyProposal` or an allowlisted `SceneProposal`; it never calls
the audio engine or commits state itself. A proposal is validated, rendered as
a temporary preview, and then explicitly accepted or discarded by the person.

If Apple Intelligence is unavailable, Latticewake remains fully playable and
uses ordinary deterministic generator templates. No implicit cloud fallback is
permitted. Any future co-performance mode must add a visible change queue,
rate limits, undo, trace capture, and an explicit user enablement.

Proposal schemas remain deliberately small and flat: one melody proposal or
one allowlisted scene patch per response. Prompt templates and proposal schema
versions are recorded in receipts. Model availability, prewarming behavior,
context limits, and any Private Cloud Compute route remain implementation-time
probes; no network use is implied by this foundation.

The current core implements typed, preview-only melody and allowlisted scene
patch proposals. It has no Apple Intelligence connector, no other model
provider, and no pathway that lets a proposal mutate a Scene.

## Licensing and provenance

Do not copy source code, UI assets, presets, or implementation text from GPL or
LGPL projects. Mathematics, documented behavior, and independently implemented
algorithms may inform original work, but every external dependency requires a
recorded license and approval before inclusion. This policy is an engineering
precaution, not a legal opinion.

Keep exploratory performance mutable. At an explicit publish boundary, bind the
scene bytes, seed, source IDs, performance trace, program version, device
identity, and hashes. Technical validation may reject broken, silent, non-finite,
or clipping output; it must not select an aesthetically preferred result.

## First build sequence

1. Implement the `Scene v0` parser/validator and deterministic event trace.
2. Build one mono analytic terrain voice with smooth escape, path bounds, DC
   removal, 1x/2x/4x rendering tests, and an offline render harness.
3. Add direct keyboard/trackpad control and a shared 2D terrain/path state.
4. Add the four role lanes with deterministic Euclidean/manual pattern support
   and internal routing.
5. Add MPE MIDI input/output and scene recovery.
6. Add visual snapshot publication and MPE glide/press/slide smoothing tests.
7. Add asynchronous grammar, density-table, Metal-field, and Apple Intelligence
   proposal providers one at a time, each behind its own validation tests.

The next implementation task is intentionally limited to steps 1 and 2. It is
not authorized to package a plugin, add a third-party dependency, install
software, connect a cloud model, or make a creative selection.

The current offline terrain-voice scaffold completes only the trace-to-mono
DC-blocking and finite-output portion of step 2. It has no audio device,
oversampling, render-file, or listening evidence.
