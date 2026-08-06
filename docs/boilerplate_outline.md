# Task: Barebones GDExtension boilerplate for a Godot 4 bloom CompositorEffect

## Objective

Generate a **compilable, loadable** GDExtension skeleton for a custom
Godot 4 bloom post-processing effect. This is scaffolding only — it must
build, load in the editor, register a custom `CompositorEffect` class
that appears in the Inspector, and prove `_render_callback` fires once
per frame. That's the entire success criterion.

## Hard constraint — read this first

**Do NOT implement any of the following.** Leave them as clearly marked
`// TODO` stubs with a one-line comment describing what will eventually
go there, but no actual math or algorithm:

- Bright-pass / threshold extraction
- Any FFT (forward or inverse), Stockham or otherwise
- Complex multiply / Hadamard product
- PSF kernel baking, loading, or normalization
- Any convolution of any kind
- Any Vulkan queue/device interop beyond what's needed to fetch and log
  the `RenderingDevice` handle (see Phase 4)

If a step in this plan would require you to write that logic to make
something "work properly," stop and leave a stub with a `// TODO`
instead. The only functional requirement is that the extension loads,
registers its classes, and the render callback fires without crashing.

## Target environment

- Godot version: **4.3 or later** (`CompositorEffect` does not exist
  before 4.3 — verify this against the actual installed Godot version
  before assuming 4.2 compatibility).
- Renderer: Forward+ (the Compositor feature does not work under the
  Compatibility/GLES3 renderer — this only matters for later testing,
  not for the boilerplate itself).
- Language: C++ via godot-cpp.
- Platform: whichever the developer is building on; default the build
  script to auto-detect, don't hardcode a single platform.

## Phase 1 — Project scaffolding

1. Create this directory structure:
   ```
   bloom_extension/
   ├── godot-cpp/              (submodule, see below)
   ├── src/
   │   ├── register_types.h
   │   ├── register_types.cpp
   │   ├── bloom_glare_effect.h
   │   ├── bloom_glare_effect.cpp
   │   ├── psf_provider.h
   │   └── psf_provider.cpp
   ├── demo/                   (a scratch Godot project for manual testing)
   │   └── bloom_extension.gdextension
   ├── SConstruct
   └── README.md
   ```
2. Add `godot-cpp` as a git submodule pointing at the branch matching
   the target Godot version (e.g. `4.3` branch/tag — confirm the exact
   tag against whatever Godot version is actually installed).
3. Write a standard SConstruct that: builds against the godot-cpp
   submodule, produces a shared library per-platform into
   `demo/bin/`, and supports `scons target=template_debug` /
   `scons target=template_release` the normal godot-cpp way.

## Phase 2 — Extension entry point

1. `register_types.h` / `register_types.cpp`: standard GDExtension
   init/uninit boilerplate. Register two classes at the
   `MODULE_INITIALIZATION_LEVEL_SCENE` level:
   - `BloomGlareEffect` (extends `CompositorEffect`)
   - `PSFProvider` (extends `Resource`)
2. `demo/bloom_extension.gdextension`: standard descriptor pointing at
   the built binaries per platform, `entry_symbol` matching
   `register_types.cpp`, `compatibility_minimum = "4.3"`.

## Phase 3 — `PSFProvider` resource stub

A `Resource` subclass with:
- `GDCLASS(PSFProvider, Resource)`
- One exported property: `kernel_texture` (`Ref<Texture2D>`), with
  getter/setter and `_bind_methods` registration. This is just a plain
  data-holding property — no processing.
- A stub virtual method `bake()` that does nothing but
  `// TODO: normalize kernel_texture and produce a padded, centered
  kernel buffer here (see implementation guide Part 5 S5.1)` and
  returns an empty/null result for now.

## Phase 4 — `BloomGlareEffect` CompositorEffect stub

A `CompositorEffect` subclass with:
- `GDCLASS(BloomGlareEffect, CompositorEffect)`
- Exported properties (data only, no logic):
  - `psf: Ref<PSFProvider>`
  - `intensity: float` (default 1.0)
- `_init()`: set `effect_callback_type` to
  `EFFECT_CALLBACK_TYPE_POST_TRANSPARENT` and call
  `set_needs_motion_vectors(false)` / whatever minimal setup
  godot-cpp's `CompositorEffect` requires at init.
- `_render_callback(effect_callback_type, render_data)`:
  - Fetch the `RenderingDevice*` via
    `RenderingServer::get_singleton()->get_rendering_device()`.
  - Fetch the render scene buffers from `render_data` (whatever
    godot-cpp exposes as the Forward+ equivalent —
    `RenderSceneBuffersRD`) just enough to confirm you can retrieve a
    valid color texture RID. Do not read or write its contents.
  - Log something observable exactly once every N frames (e.g. every
    60 calls, `UtilityFunctions::print("BloomGlareEffect render
    callback fired, frame ", counter)`), so the developer has a plain,
    simple way to confirm the callback is actually executing once the
    extension is loaded in a real project.
  - Everything after fetching the device and the color RID is a
    `// TODO` block describing the eventual pipeline (bright-pass →
    forward FFT → complex multiply → inverse FFT → composite) without
    implementing it.

## Phase 5 — Build verification

1. Confirm `scons` builds cleanly against the godot-cpp submodule with
   no warnings treated as errors.
2. Open (or create) the `demo/` Godot project, confirm:
   - The editor does not report missing symbols or failed extension
     load in the output panel on startup.
   - `BloomGlareEffect` and `PSFProvider` appear as selectable resource
     types in the Inspector (e.g. when creating a new `Compositor`
     resource's effects array entry).
   - Adding a `Compositor` resource to a `WorldEnvironment` or
     `Camera3D`, adding a `BloomGlareEffect` to its effects array, and
     running the demo project produces the periodic print statement in
     the output log with no crash.
3. Do not attempt to visually verify any bloom effect — there isn't
   one yet. Success is "loads, registers, callback fires, no crash."

## Deliverable

The complete `bloom_extension/` directory (minus the `godot-cpp`
submodule contents itself, which should just be a proper git submodule
reference) plus a short `README.md` covering: how to init the
submodule, how to build for the current platform, and how to open the
`demo/` project to verify Phase 5.
