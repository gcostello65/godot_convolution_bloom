# godot_convolution_bloom

GDExtension scaffolding for a Godot 4 convolution-based bloom/glare
`CompositorEffect`, based on Kawase & Spencer's 1995 physically-based glare
model. This is boilerplate only: it builds, loads in the editor, registers
`BloomGlareEffect` and `PSFProvider`, and proves the render callback fires
once per frame. No bright-pass, FFT, complex multiply, or convolution math
is implemented yet — see the `// TODO` blocks in
`src/BloomGlareEffect/bloom_glare_effect.cpp` and
`src/PSFProvider/psf_provider.cpp`.

## Setup

```sh
git clone --recurse-submodules git@github.com:gcostello65/godot_convolution_bloom.git
# or, if already cloned:
git submodule update --init --recursive
```

## Build

Requires [SCons](https://scons.org/) and a C++17-capable compiler.

```sh
scons target=template_debug
```

This builds against the `godot-cpp` submodule and drops the shared
library/framework into `demo/bin/`. Use `scons target=template_release` for
a release build.

## Verify

1. Open `demo/` as a project in Godot **4.3+** (developed against 4.6.3).
2. Confirm the Output panel shows no missing-symbol or failed-extension-load
   errors on startup.
3. In the `main.tscn` scene, select the `WorldEnvironment` node, open its
   `Environment` resource, and add a `Compositor` resource under
   `Rendering > Compositor`. Add a `BloomGlareEffect` entry to the
   Compositor's `compositor_effects` array — confirm `BloomGlareEffect` and
   `PSFProvider` both appear as selectable resource types in the Inspector.
4. Run the scene (F6). Confirm `BloomGlareEffect render callback fired,
   frame N` prints to the log periodically (every 60 frames) with no crash.

No visual bloom is expected yet — success is "loads, registers, callback
fires, no crash," per `docs/project_outline.md`.
