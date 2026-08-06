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

## Demo scene

`demo/main.tscn` is a medieval bloom test scene built from the Synty
POLYGON Knights asset pack — a castle, village, and church laid out by
Synty's own demo export, plus a flat ground plate, a procedural sky with a
low warm sun, and a couple of hand-placed brazier/campfire glow accents for
bright, bloom-worthy highlights. It's built procedurally by
`demo/scripts/bloom_test_scene.gd`, which also creates a `Compositor` on
the `WorldEnvironment` with a `BloomGlareEffect` already attached — the
scene is wired up and ready to visually test bloom the moment the real
convolution math lands.

Controls at runtime:

| Key | Action |
| --- | --- |
| `1`–`4` | Jump to a static viewpoint (castle approach, village square, courtyard hearth, battlement overlook) |
| `5` | Switch to the cinematic camera, which flies a smooth Catmull-Rom path from a mountain approach down through the castle and into the village, then reverses (ping-pong loop). This is the default camera on scene start. |
| `6` | Switch to a free-fly camera you control: WASD to move, mouse to look (captures the cursor), `Shift` to sprint, `Q`/`E` for down/up, `Esc` to release the cursor |
| `G` | Toggle Godot's built-in glow, for comparison against the custom effect |
| `B` | Toggle the `BloomGlareEffect` compositor effect on/off |

For a three-way comparison (stock bloom vs. `BloomGlareEffect` vs. neither),
flip the `use_builtin_glow` export on the scene root's script (or in the
Inspector) to set which one is on by default at start — `G`/`B` still work
at runtime on top of whatever it's set to.

**Placeholder effect note:** `BloomGlareEffect` has no real bloom math yet
(see the `// TODO` in `bloom_glare_effect.cpp`) — with it enabled (the
default), it currently flashes the whole frame through a loud color palette
every 30 frames, purely so the extension's render callback and on/off
toggle (`B`) are trivially verifiable end-to-end. It replaces the real
composite once the convolution pipeline is implemented.

**Asset note:** the Synty POLYGON Knights source files live under
`demo/assets/synty_knights/` and are copied in from a paid Synty Store
asset pack, not authored in this repo. Confirm your Synty license covers
redistributing the raw source files before pushing this folder to a public
remote — see the note below on `.gitignore`-ing it if you'd rather keep
them local-only.

## Verify

1. Open `demo/` as a project in Godot **4.3+** (developed against 4.6.3).
2. Confirm the Output panel shows no missing-symbol or failed-extension-load
   errors on startup, and that `BloomGlareEffect` / `PSFProvider` appear as
   selectable resource types in the Inspector.
3. Run the scene (F6). Confirm `BloomGlareEffect render callback fired,
   frame N` prints to the log periodically (every 60 frames) with no crash,
   and that the medieval scene renders with the castle, village, ground,
   and sky all in place.

No visual bloom is expected yet — success is "loads, registers, callback
fires, no crash," per `docs/project_outline.md`.
