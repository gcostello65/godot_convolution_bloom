extends Node3D

## Medieval bloom test scene built from the POLYGON Knights Synty pack.
## Wires the (still-stubbed) BloomGlareEffect into the WorldEnvironment's
## Compositor so this scene is ready to visually test bloom once the real
## convolution math lands. See README.md for controls.
##
## Set use_builtin_glow to compare Godot's stock mip-based glow against the
## custom BloomGlareEffect (or against neither, with both left off) without
## touching anything else in the scene.

## Enable Godot's built-in glow at scene start, for a three-way comparison:
## this on (stock bloom), this off with BloomGlareEffect enabled (ours), or
## both off (no bloom at all). Also live-toggleable at runtime with G.
@export var use_builtin_glow: bool = false

const SYNTY_SCENE_PATH := "res://assets/synty_knights/models/POLYGON_Knights_Pack_DemoScene_Export.fbx"
const BRAZIER_PATH := "res://assets/synty_knights/models/SM_Prop_Brazier_01.fbx"
const TRIM_TEXTURE_PATH := "res://assets/synty_knights/textures/POLYGON_Knights_Texture_01.png"

const GROUND_CENTER := Vector3(20.0, -0.05, 10.0)
const GROUND_SIZE := Vector2(500.0, 500.0)

const CAMPFIRE_POS := Vector3(29.9, 0.1, 9.78)
const BRAZIER_POSITIONS := [Vector3(26.5, 0.0, 9.0), Vector3(33.5, 0.0, 10.5)]

## Top of the westernmost in-scene lamppost (SM_Prop_Lampost_2), measured via
## its baked world-space AABB — its base sits at (6.75, 0.1, 42.8), ~3.97m tall.
const LANTERN_POS := Vector3(6.75, 3.6, 42.8)

const VIEWPOINTS := [
	{"name": "CastleApproach", "pos": Vector3(22.0, 9.0, 62.0), "look_at": Vector3(25.0, 10.0, -15.0)},
	{"name": "VillageSquare", "pos": Vector3(5.0, 18.0, 98.0), "look_at": Vector3(9.5, 3.0, 50.0)},
	{"name": "CourtyardHearth", "pos": Vector3(10.0, 9.0, -5.0), "look_at": CAMPFIRE_POS},
	{"name": "BattlementOverlook", "pos": Vector3(95.0, 48.0, -25.0), "look_at": Vector3(20.0, 8.0, 5.0)},
]

const RAIL_POINTS := [
	Vector3(140.0, 55.0, 90.0),
	Vector3(70.0, 30.0, 40.0),
	Vector3(30.0, 10.0, -5.0),
	Vector3(18.0, 6.0, 15.0),
	Vector3(8.0, 5.0, 40.0),
	Vector3(0.0, 12.0, 75.0),
]
const RAIL_DURATION := 32.0
const RAIL_LOOKAHEAD := 4.0

const FREE_CAM_SPEED := 12.0
const FREE_CAM_SPRINT_MULT := 3.0
const FREE_CAM_MOUSE_SENSITIVITY := 0.0025

var _viewpoint_cameras: Array[Camera3D] = []
var _rail_camera: Camera3D
var _rail_curve: Curve3D
var _rail_time := 0.0

var _free_camera: Camera3D
var _free_cam_yaw := 0.0
var _free_cam_pitch := 0.0

var _world_environment: WorldEnvironment
var _bloom_effect: BloomGlareEffect

var _trim_material: StandardMaterial3D


func _ready() -> void:
	_setup_environment()
	_setup_ground()
	_setup_village()
	_setup_lighting_accents()
	_setup_cameras()
	_setup_compositor()
	_setup_ui()
	_rail_camera.current = true


func _process(delta: float) -> void:
	_update_rail_camera(delta)
	if _free_camera != null and _free_camera.current:
		_update_free_camera(delta)


func _update_free_camera(delta: float) -> void:
	var basis := _free_camera.global_transform.basis
	var move := Vector3.ZERO
	if Input.is_key_pressed(KEY_W):
		move -= basis.z
	if Input.is_key_pressed(KEY_S):
		move += basis.z
	if Input.is_key_pressed(KEY_A):
		move -= basis.x
	if Input.is_key_pressed(KEY_D):
		move += basis.x
	if Input.is_key_pressed(KEY_E):
		move += Vector3.UP
	if Input.is_key_pressed(KEY_Q):
		move -= Vector3.UP

	if move.length() > 0.0:
		move = move.normalized()

	var speed := FREE_CAM_SPEED
	if Input.is_key_pressed(KEY_SHIFT):
		speed *= FREE_CAM_SPRINT_MULT

	_free_camera.global_position += move * speed * delta


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _free_camera != null and _free_camera.current \
			and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_free_cam_yaw -= event.relative.x * FREE_CAM_MOUSE_SENSITIVITY
		_free_cam_pitch -= event.relative.y * FREE_CAM_MOUSE_SENSITIVITY
		_free_cam_pitch = clamp(_free_cam_pitch, deg_to_rad(-89.0), deg_to_rad(89.0))
		_free_camera.rotation = Vector3(_free_cam_pitch, _free_cam_yaw, 0.0)
		return

	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				_viewpoint_cameras[0].current = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_2:
				_viewpoint_cameras[1].current = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_3:
				_viewpoint_cameras[2].current = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_4:
				_viewpoint_cameras[3].current = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_5:
				_rail_camera.current = true
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_6:
				_free_camera.current = true
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_G:
				_world_environment.environment.glow_enabled = not _world_environment.environment.glow_enabled
			KEY_B:
				if _bloom_effect != null:
					_bloom_effect.enabled = not _bloom_effect.enabled


func _setup_environment() -> void:
	_world_environment = WorldEnvironment.new()
	_world_environment.name = "WorldEnvironment"

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY

	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.24, 0.44, 0.74)
	sky_material.sky_horizon_color = Color(0.95, 0.65, 0.38)
	sky_material.sky_curve = 0.15
	sky_material.ground_bottom_color = Color(0.2, 0.17, 0.14)
	sky_material.ground_horizon_color = Color(0.95, 0.65, 0.38)
	sky_material.sun_angle_max = 30.0
	sky_material.sun_curve = 0.15

	var sky := Sky.new()
	sky.sky_material = sky_material
	env.sky = sky

	env.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	env.glow_enabled = use_builtin_glow
	env.glow_hdr_threshold = 1.0
	env.glow_intensity = 0.8
	env.glow_strength = 1.2
	env.glow_bloom = 0.1
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE

	env.fog_enabled = true
	env.fog_light_color = Color(0.85, 0.7, 0.55)
	env.fog_density = 0.0015
	env.fog_sun_scatter = 0.3

	_world_environment.environment = env
	add_child(_world_environment)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color(1.0, 0.86, 0.64)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-35.0, -50.0, 0.0)
	add_child(sun)


func _setup_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "Ground"

	var plane := PlaneMesh.new()
	plane.size = GROUND_SIZE
	ground.mesh = plane
	ground.position = GROUND_CENTER

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.32, 0.15)
	mat.roughness = 1.0
	ground.material_override = mat

	add_child(ground)


func _get_trim_material() -> StandardMaterial3D:
	if _trim_material == null:
		_trim_material = StandardMaterial3D.new()
		_trim_material.albedo_texture = load(TRIM_TEXTURE_PATH)
		_trim_material.vertex_color_use_as_albedo = true
		_trim_material.roughness = 0.9
		_trim_material.metallic = 0.0
	return _trim_material


func _apply_material_recursive(node: Node, mat: Material) -> void:
	if node is MeshInstance3D:
		node.material_override = mat
	for child in node.get_children():
		_apply_material_recursive(child, mat)


func _setup_village() -> void:
	var packed: PackedScene = load(SYNTY_SCENE_PATH)
	var inst := packed.instantiate()
	inst.name = "PolygonKnightsVillage"
	add_child(inst)
	_apply_material_recursive(inst, _get_trim_material())


func _add_fire_glow(pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = Color(1.0, 0.55, 0.2)
	light.light_energy = 6.0
	light.omni_range = 7.0
	light.shadow_enabled = false
	add_child(light)

	var glow := MeshInstance3D.new()
	glow.position = pos
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	glow.mesh = sphere

	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(1.0, 0.55, 0.15)
	glow_mat.emission_energy_multiplier = 6.0
	glow_mat.albedo_color = Color(1.0, 0.55, 0.15)
	glow.material_override = glow_mat
	add_child(glow)


## A large, deliberately overbright bonfire — bright enough that its own
## surface should be near-guaranteed to blow past any reasonable bloom
## threshold, so it reads clearly against both the built-in glow and
## BloomGlareEffect once real math lands.
func _add_big_flame(pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0.0, 0.8, 0.0)
	light.light_color = Color(1.0, 0.45, 0.08)
	light.light_energy = 22.0
	light.omni_range = 14.0
	light.shadow_enabled = true
	add_child(light)

	var flame := MeshInstance3D.new()
	flame.position = pos + Vector3(0.0, 0.9, 0.0)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 0.55
	cone.height = 1.8
	flame.mesh = cone
	var flame_mat := StandardMaterial3D.new()
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flame_mat.emission_enabled = true
	flame_mat.emission = Color(1.0, 0.65, 0.1)
	flame_mat.emission_energy_multiplier = 16.0
	flame_mat.albedo_color = Color(1.0, 0.5, 0.1)
	flame.material_override = flame_mat
	add_child(flame)

	var core := MeshInstance3D.new()
	core.position = pos + Vector3(0.0, 0.5, 0.0)
	var core_sphere := SphereMesh.new()
	core_sphere.radius = 0.35
	core_sphere.height = 0.7
	core.mesh = core_sphere
	var core_mat := StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.emission_enabled = true
	core_mat.emission = Color(1.0, 0.9, 0.6)
	core_mat.emission_energy_multiplier = 24.0
	core_mat.albedo_color = Color(1.0, 0.9, 0.6)
	core.material_override = core_mat
	add_child(core)


## A warmer, whiter, dimmer accent than the fire glow — meant to sit at a
## lamppost head and read as a lit lantern rather than an open flame.
func _add_lantern_glow(pos: Vector3) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = Color(1.0, 0.85, 0.55)
	light.light_energy = 10.0
	light.omni_range = 8.0
	light.shadow_enabled = false
	add_child(light)

	var glow := MeshInstance3D.new()
	glow.position = pos
	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	glow.mesh = sphere
	var glow_mat := StandardMaterial3D.new()
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(1.0, 0.9, 0.6)
	glow_mat.emission_energy_multiplier = 14.0
	glow_mat.albedo_color = Color(1.0, 0.9, 0.6)
	glow.material_override = glow_mat
	add_child(glow)


func _setup_lighting_accents() -> void:
	_add_big_flame(CAMPFIRE_POS)
	_add_lantern_glow(LANTERN_POS)

	for pos in BRAZIER_POSITIONS:
		var brazier_packed: PackedScene = load(BRAZIER_PATH)
		var brazier := brazier_packed.instantiate()
		brazier.position = pos
		add_child(brazier)
		_apply_material_recursive(brazier, _get_trim_material())
		_add_fire_glow(pos + Vector3(0.0, 1.1, 0.0))


func _build_smooth_curve(curve: Curve3D, points: Array) -> void:
	var n := points.size()
	for i in range(n):
		var prev: Vector3 = points[max(i - 1, 0)]
		var next: Vector3 = points[min(i + 1, n - 1)]
		var tangent := (next - prev) * 0.25
		curve.add_point(points[i], -tangent, tangent)


func _setup_cameras() -> void:
	for vp in VIEWPOINTS:
		var cam := Camera3D.new()
		cam.name = vp["name"]
		cam.fov = 60.0
		add_child(cam)
		cam.global_position = vp["pos"]
		cam.look_at(vp["look_at"], Vector3.UP)
		_viewpoint_cameras.append(cam)

	_rail_camera = Camera3D.new()
	_rail_camera.name = "CinematicRailCamera"
	_rail_camera.fov = 55.0
	add_child(_rail_camera)

	_rail_curve = Curve3D.new()
	_build_smooth_curve(_rail_curve, RAIL_POINTS)
	_rail_camera.global_position = RAIL_POINTS[0]

	_free_camera = Camera3D.new()
	_free_camera.name = "FreeCamera"
	_free_camera.fov = 70.0
	add_child(_free_camera)
	_free_camera.global_position = VIEWPOINTS[0]["pos"]
	_free_camera.look_at(VIEWPOINTS[0]["look_at"], Vector3.UP)
	_free_cam_yaw = _free_camera.rotation.y
	_free_cam_pitch = _free_camera.rotation.x


func _update_rail_camera(delta: float) -> void:
	if _rail_curve == null or _rail_curve.point_count < 2:
		return

	_rail_time += delta
	var length := _rail_curve.get_baked_length()
	var cycle := fmod(_rail_time, RAIL_DURATION * 2.0)
	var t := cycle
	var forward := true
	if cycle > RAIL_DURATION:
		t = RAIL_DURATION * 2.0 - cycle
		forward = false

	var ratio := t / RAIL_DURATION
	var offset := ratio * length
	var pos := _rail_curve.sample_baked(offset, true)

	var lookahead: float = RAIL_LOOKAHEAD if forward else -RAIL_LOOKAHEAD
	var target_offset: float = clamp(offset + lookahead, 0.0, length)
	var target := _rail_curve.sample_baked(target_offset, true)

	_rail_camera.global_position = pos
	if pos.distance_to(target) > 0.01:
		_rail_camera.look_at(target, Vector3.UP)


func _setup_compositor() -> void:
	var compositor := Compositor.new()
	_bloom_effect = BloomGlareEffect.new()
	_bloom_effect.psf = PSFProvider.new()
	_bloom_effect.intensity = 1.0
	compositor.compositor_effects = [_bloom_effect]
	_world_environment.compositor = compositor


func _setup_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var label := Label.new()
	label.text = "1-4: Viewpoints   5: Cinematic rail camera   6: Free camera (WASD+mouse, Shift sprint, Q/E up/down, Esc releases mouse)   G: toggle built-in glow   B: toggle BloomGlareEffect"
	label.position = Vector2(16.0, 16.0)
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	label.add_theme_constant_override("outline_size", 4)
	layer.add_child(label)
