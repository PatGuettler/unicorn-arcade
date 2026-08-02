class_name RoomItemPreview3D
extends SubViewportContainer

const CHARACTER_SCENES := {
	"sparkle": preload("res://assets/characters/unicorns/unicorn_sparkle_v1.glb"),
	"rainbow": preload("res://assets/characters/unicorns/unicorn_rainbow_v1.glb"),
	"star": preload("res://assets/characters/unicorns/unicorn_star_v1.glb"),
	"cloud": preload("res://assets/characters/unicorns/unicorn_cloud_v1.glb"),
	"dream": preload("res://assets/characters/unicorns/unicorn_dreamer_v1.glb"),
	"mystic": preload("res://assets/characters/unicorns/unicorn_mystic_v1.glb"),
}
const CHARACTER_SCALES := {"sparkle": 1.28, "rainbow": 1.28, "star": 1.28, "cloud": 1.28, "dream": 1.28, "mystic": 1.12}
const CHARACTER_SCALE_MULTIPLIER := 3.0
const ANIMATED_CAMERA_SIZE := 6.80
const STATIC_CAMERA_SIZE := 6.80
const HERO_CAMERA_SIZE := 5.80
const BACKGROUND_CAMERA_SIZE := 8.40
const ANIMATION_FRAME_LIFT := Vector3(0.0, 1.10, 0.0)
const STATIC_FRAME_LIFT := Vector3(0.0, 1.10, 0.0)
const HERO_FRAME_LIFT := Vector3(0.0, 0.92, 0.0)
const BACKGROUND_FRAME_LIFT := Vector3(0.0, 0.92, 0.0)
const SIDE_CAMERA_POSITION := Vector3(-8.40, 3.18, 0.90)
const SIDE_CAMERA_TARGET := Vector3(0.0, 1.72, -0.15)
const UnicornIdleAnimatorScene = preload("res://scripts/meta/unicorn_idle_animator.gd")

var item_id := ""
var category := "cozy"
var mesh_count := 0
var uses_character_model := false
var source_model_id := ""
var animate_character := true
var presentation_context := "room"


func setup(definition: Dictionary) -> void:
	item_id = str(definition.get("id", definition.get("item_id", "decor")))
	category = str(definition.get("category", "cozy"))
	uses_character_model = item_id.begins_with("companion_") or category == "companions"
	animate_character = bool(definition.get("animate", true))
	presentation_context = str(definition.get("presentation", "room" if animate_character else "marketplace"))
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_viewport()


func _build_viewport() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(448, 320) if uses_character_model else Vector2i(192, 192)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if uses_character_model else SubViewport.UPDATE_ONCE
	add_child(viewport)
	var stage := Node3D.new()
	stage.name = "PreviewStage"
	viewport.add_child(stage)
	if uses_character_model:
		_build_companion(stage)
	else:
		_build_furniture(stage)
	_build_lighting(stage)


func _build_companion(stage: Node3D) -> void:
	var companion_id := item_id.trim_prefix("companion_")
	if not CHARACTER_SCENES.has(companion_id):
		companion_id = "sparkle"
	source_model_id = companion_id
	var packed_scene: PackedScene = CHARACTER_SCENES[companion_id]
	var travel_root := Node3D.new()
	travel_root.name = "CompanionTravelRoot"
	stage.add_child(travel_root)
	var model: Node3D = packed_scene.instantiate() as Node3D
	model.name = "LiveUnicornModel"
	model.position.y = -0.25
	model.scale = Vector3.ONE * float(CHARACTER_SCALES.get(companion_id, 1.28)) * CHARACTER_SCALE_MULTIPLIER
	travel_root.add_child(model)
	mesh_count = _count_meshes(model)
	_add_companion_shadow(travel_root)
	if animate_character:
		var animator := UnicornIdleAnimatorScene.new()
		animator.name = "IdleAnimator"
		stage.add_child(animator)
		animator.setup(travel_root)
	else:
		_pose_companion(model)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	if not animate_character:
		camera.size = STATIC_CAMERA_SIZE
	elif presentation_context == "hero":
		camera.size = HERO_CAMERA_SIZE
	elif presentation_context == "meadow_background":
		camera.size = BACKGROUND_CAMERA_SIZE
	else:
		camera.size = ANIMATED_CAMERA_SIZE
	stage.add_child(camera)
	var frame_lift := STATIC_FRAME_LIFT
	if animate_character:
		if presentation_context == "hero":
			frame_lift = HERO_FRAME_LIFT
		elif presentation_context == "meadow_background":
			frame_lift = BACKGROUND_FRAME_LIFT
		else:
			frame_lift = ANIMATION_FRAME_LIFT
	camera.look_at_from_position(SIDE_CAMERA_POSITION + frame_lift, SIDE_CAMERA_TARGET + frame_lift, Vector3.UP)
	camera.current = true


func _pose_companion(model: Node) -> void:
	var animation_player := _find_animation_player(model)
	if animation_player == null:
		return
	var fallback := StringName()
	for animation_name in animation_player.get_animation_list():
		var simple_name := String(animation_name).get_file().get_basename().to_lower()
		if simple_name == "walk":
			fallback = animation_name
		if simple_name == "idle":
			animation_player.play(animation_name)
			animation_player.seek(0.0, true)
			animation_player.pause()
			_reset_skeleton_poses(model)
			return
	if fallback != &"":
		animation_player.play(fallback)
		animation_player.seek(0.0, true)
		animation_player.pause()
	_reset_skeleton_poses(model)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation_player(child)
		if found != null:
			return found
	return null


func _reset_skeleton_poses(node: Node) -> void:
	if node is Skeleton3D:
		(node as Skeleton3D).reset_bone_poses()
	for child in node.get_children():
		_reset_skeleton_poses(child)


func _add_companion_shadow(stage: Node3D) -> void:
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.88
	shadow_mesh.bottom_radius = 0.88
	shadow_mesh.height = 0.025
	shadow_mesh.material = _material(Color(0.12, 0.10, 0.24, 0.20), false)
	var shadow := MeshInstance3D.new()
	shadow.name = "MeadowContactShadow"
	shadow.mesh = shadow_mesh
	shadow.position = Vector3(0.0, 0.02, -0.05)
	shadow.scale.z = 0.58
	stage.add_child(shadow)


func _build_furniture(stage: Node3D) -> void:
	var model := Node3D.new()
	model.name = "FurnitureModel"
	model.rotation_degrees.y = -18.0
	stage.add_child(model)
	var palette := _palette()
	_add_shadow(model)
	if item_id == "lamp":
		_build_lava_lamp(model, palette)
	elif category == "rugs" or item_id == "rug":
		_build_rug(model, palette)
	elif category == "nature" or item_id == "plant":
		_build_plant(model, palette)
	elif category == "beds":
		_build_bed(model, palette)
	elif category == "tables":
		_build_table(model, palette)
	elif category == "lighting":
		_build_lamp(model, palette)
	elif category == "pets":
		_build_pet(model, palette)
	elif category == "toys":
		_build_toy(model, palette)
	elif category == "electronics":
		_build_electronics(model, palette)
	elif category == "seasonal":
		_build_seasonal(model, palette)
	elif category == "kitchen":
		_build_kitchen(model, palette)
	elif category == "wall":
		_build_wall_art(model, palette)
	elif category == "luxury":
		_build_luxury(model, palette)
	elif category == "unicorn":
		_build_unicorn_decor(model, palette)
	else:
		_build_chair(model, palette)
	mesh_count = _count_meshes(model)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.85
	stage.add_child(camera)
	camera.look_at_from_position(Vector3(3.7, 2.75, 4.8), Vector3(0.0, 0.62, 0.0), Vector3.UP)
	camera.current = true


func _build_lighting(stage: Node3D) -> void:
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, 38, -22)
	key.light_color = Color("ffe9d2")
	key.light_energy = 0.68
	key.shadow_enabled = true
	stage.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(30, 140, 12)
	fill.light_color = Color("b8a5ff")
	fill.light_energy = 0.24
	stage.add_child(fill)
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0, 0, 0, 0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("d8d1ed")
	environment.ambient_light_energy = 0.38
	environment_node.environment = environment
	stage.add_child(environment_node)


func _build_lava_lamp(parent: Node3D, palette: Dictionary) -> void:
	_cylinder(parent, "Base", 0.34, 0.24, 0.14, Vector3(0, 0.1, 0), palette.dark)
	_cylinder(parent, "Glass", 0.22, 0.34, 1.05, Vector3(0, 0.68, 0), Color(palette.accent, 0.78), true)
	_cylinder(parent, "Cap", 0.24, 0.34, 0.14, Vector3(0, 1.28, 0), palette.dark)
	for bubble in [[-0.08, 0.5, 0.03, 0.10], [0.09, 0.82, -0.03, 0.13], [-0.04, 1.03, 0.02, 0.08]]:
		_sphere(parent, "LavaBubble", float(bubble[3]), Vector3(bubble[0], bubble[1], bubble[2]), palette.light)


func _build_rug(parent: Node3D, palette: Dictionary) -> void:
	if item_id == "rug_bear":
		var body := _sphere(parent, "FauxBearPelt", 0.68, Vector3(0, 0.09, 0), Color("a97455"))
		body.scale = Vector3(1.35, 0.12, 0.78)
		_sphere(parent, "BearHead", 0.38, Vector3(-0.76, 0.12, 0), Color("b98561"))
		for z in [-0.28, 0.28]:
			_sphere(parent, "BearEar", 0.13, Vector3(-0.88, 0.18, z), Color("795039"))
		for x in [-0.48, 0.48]:
			for z in [-0.58, 0.58]:
				var paw := _sphere(parent, "BearPaw", 0.22, Vector3(x, 0.08, z), Color("a97455"))
				paw.scale = Vector3(1.55, 0.12, 0.7)
		return
	if item_id == "rug_puzzle":
		for x in [-0.55, 0.0, 0.55]:
			for z in [-0.36, 0.36]:
				_box(parent, "PuzzleTile", Vector3(0.52, 0.08, 0.68), Vector3(x, 0.08, z), Color.from_hsv(fmod(palette.hue + (x + z + 1.0) * 0.16, 1.0), 0.58, 0.96))
		return
	_box(parent, "Rug", Vector3(1.75, 0.08, 1.18), Vector3(0, 0.08, 0), palette.accent)
	if item_id == "rug_welcome":
		for x in [-0.48, -0.16, 0.16, 0.48]:
			_box(parent, "WelcomeStripe", Vector3(0.08, 0.03, 0.72), Vector3(x, 0.135, 0), palette.dark)
	elif item_id == "rug_magic":
		for x in [-0.74, 0.74]:
			_box(parent, "FlyingCorner", Vector3(0.22, 0.13, 1.08), Vector3(x, 0.19, 0), palette.light, Vector3(0, 0, 12 if x > 0 else -12))
		for z in [-0.48, 0.48]:
			for x in [-0.65, -0.4, -0.15, 0.1, 0.35, 0.6]:
				_cylinder(parent, "CarpetTassel", 0.025, 0.025, 0.23, Vector3(x, 0.08, z), Color("ffd166"))
	elif item_id == "rug_persian":
		_box(parent, "PersianBorder", Vector3(1.5, 0.035, 0.94), Vector3(0, 0.135, 0), palette.dark)
		for x in [-0.48, 0.0, 0.48]:
			for z in [-0.27, 0.27]: _sphere(parent, "PersianMedallion", 0.13, Vector3(x, 0.17, z), palette.light)
	else:
		for x in [-0.55, 0.0, 0.55]:
			_box(parent, "RugInlay", Vector3(0.18, 0.035, 1.05), Vector3(x, 0.135, 0), palette.light)


func _build_plant(parent: Node3D, palette: Dictionary) -> void:
	if item_id == "mush_stool":
		_cylinder(parent, "LogStump", 0.38, 0.46, 0.72, Vector3(0, 0.38, 0), Color("865d43"))
		var cap := _sphere(parent, "MushroomCap", 0.58, Vector3(0, 0.91, 0), Color("ef6e86"))
		cap.scale.y = 0.42
		for x in [-0.28, 0.0, 0.26]: _sphere(parent, "CapSpot", 0.07, Vector3(x, 1.08, 0.18), Color("fff3d6"))
		return
	if item_id == "bamboo_speaker":
		for x in [-0.32, 0.0, 0.32]: _cylinder(parent, "BambooTube", 0.18, 0.2, 1.1 - absf(x) * 0.7, Vector3(x, 0.58, 0), Color("77a866"))
		for y in [0.42, 0.82]: _box(parent, "BambooBand", Vector3(1.05, 0.08, 0.48), Vector3(0, y, 0), Color("476b45"))
		return
	if item_id == "butterfly_model":
		_cylinder(parent, "DisplayPin", 0.04, 0.04, 1.25, Vector3(0, 0.68, 0), palette.dark)
		_sphere(parent, "ButterflyBody", 0.1, Vector3(0, 1.1, 0), Color("33234c"))
		for x in [-0.33, 0.33]:
			var wing := _sphere(parent, "ShimmerWing", 0.35, Vector3(x, 1.18, 0), palette.accent, true)
			wing.scale = Vector3(0.82, 1.2, 0.14)
		return
	if item_id == "moss_ball":
		var moss := _sphere(parent, "GlowingMossBall", 0.62, Vector3(0, 0.65, 0), Color("55d48b"), true)
		moss.scale.y = 0.9
		for index in 8:
			var angle := TAU * index / 8.0
			_sphere(parent, "MossTuft", 0.17, Vector3(cos(angle) * 0.48, 0.72, sin(angle) * 0.48), Color("32845b"))
		return
	if item_id == "zen_garden":
		_box(parent, "ZenTray", Vector3(1.75, 0.18, 1.1), Vector3(0, 0.12, 0), Color("8a5f49"))
		_box(parent, "RakedSand", Vector3(1.56, 0.06, 0.92), Vector3(0, 0.24, 0), Color("f1ddad"))
		for x in [-0.5, 0.0, 0.5]: _box(parent, "RakeLine", Vector3(0.04, 0.025, 0.74), Vector3(x, 0.285, 0), Color("c5a978"))
		_sphere(parent, "ZenStone", 0.2, Vector3(0.45, 0.38, 0.18), Color("70788b"))
		return
	if item_id == "terrarium":
		_cylinder(parent, "GlassTerrarium", 0.55, 0.72, 1.22, Vector3(0, 0.66, 0), Color(0.55, 0.9, 0.92, 0.28), true)
		_cylinder(parent, "TerrariumSoil", 0.58, 0.62, 0.2, Vector3(0, 0.14, 0), Color("6b4c39"))
		for x in [-0.3, 0.0, 0.3]: _sphere(parent, "TinyForest", 0.2, Vector3(x, 0.5 + absf(x), 0), Color("4eb879"))
		_box(parent, "FairyDoor", Vector3(0.28, 0.38, 0.05), Vector3(0, 0.43, 0.62), Color("f4b86a"), Vector3.ZERO, true)
		return
	_cylinder(parent, "Planter", 0.35, 0.48, 0.55, Vector3(0, 0.3, 0), palette.accent)
	var leaf_color := Color("277b55") if item_id == "ac_anthurium" else Color("5bc881")
	for index in 7:
		var angle := TAU * float(index) / 7.0
		var tip := Vector3(cos(angle) * 0.38, 1.05 + (index % 2) * 0.18, sin(angle) * 0.38)
		_cylinder(parent, "Stem", 0.035, 0.035, 0.72, Vector3(tip.x * 0.45, 0.75, tip.z * 0.45), Color("397756"))
		var leaf := _sphere(parent, "Leaf", 0.27, tip, leaf_color)
		leaf.scale = Vector3(0.58, 1.0, 0.34)
		if item_id == "ac_anthurium" and index % 2 == 0: _sphere(parent, "AnthuriumBloom", 0.12, tip + Vector3(0, 0.17, 0), Color("ef5f74"))


func _build_bed(parent: Node3D, palette: Dictionary) -> void:
	if item_id == "bed_race":
		_box(parent, "RaceCarBody", Vector3(1.9, 0.48, 1.05), Vector3(0, 0.38, 0), Color("ef5f74"))
		_box(parent, "RaceMattress", Vector3(1.42, 0.2, 0.78), Vector3(-0.05, 0.69, 0), palette.light)
		_box(parent, "RaceNose", Vector3(0.42, 0.38, 0.82), Vector3(1.02, 0.33, 0), Color("ffd166"), Vector3(0, 0, -12))
		for x in [-0.62, 0.62]:
			for z in [-0.58, 0.58]:
				var wheel := _cylinder(parent, "RaceWheel", 0.2, 0.2, 0.15, Vector3(x, 0.24, z), Color("24243c"))
				wheel.rotation_degrees.x = 90
		return
	if item_id == "bed_cloud":
		for x in [-0.6, -0.2, 0.2, 0.6]:
			var cloud := _sphere(parent, "CloudBase", 0.48, Vector3(x, 0.38 + absf(x) * 0.12, 0), Color("ecf6ff"))
			cloud.scale.z = 1.3
		_box(parent, "CloudMattress", Vector3(1.55, 0.22, 0.92), Vector3(0, 0.67, 0), Color("d6efff"))
		_sphere(parent, "CloudPillow", 0.3, Vector3(-0.52, 0.86, 0), Color("fff8fb"))
		return
	if item_id == "bed_bunk":
		for y in [0.42, 1.23]:
			_box(parent, "BunkFrame", Vector3(1.7, 0.16, 1.0), Vector3(0, y, 0), palette.dark)
			_box(parent, "BunkMattress", Vector3(1.52, 0.18, 0.86), Vector3(0, y + 0.17, 0), palette.light)
		for x in [-0.76, 0.76]:
			for z in [-0.42, 0.42]: _cylinder(parent, "BunkPost", 0.055, 0.055, 1.65, Vector3(x, 0.83, z), palette.dark)
		for y in [0.35, 0.7, 1.05]: _box(parent, "LadderRung", Vector3(0.08, 0.08, 0.74), Vector3(0.88, y, 0), palette.accent)
		return
	if item_id == "bed_coffin":
		_box(parent, "CoffinBase", Vector3(1.85, 0.28, 0.92), Vector3(0, 0.3, 0), Color("32213f"))
		_box(parent, "VelvetLining", Vector3(1.55, 0.18, 0.72), Vector3(0, 0.53, 0), Color("8f315c"))
		for x in [-0.78, 0.78]: _box(parent, "CoffinShoulder", Vector3(0.38, 0.38, 1.06), Vector3(x, 0.33, 0), Color("32213f"), Vector3(0, 0, 28 if x > 0 else -28))
		return
	var king_scale := 1.14 if item_id == "bed_king" else 1.0
	_box(parent, "BedFrame", Vector3(1.85, 0.25, 1.2), Vector3(0, 0.25, 0), palette.dark)
	_box(parent, "Mattress", Vector3(1.68, 0.28, 1.05), Vector3(0, 0.5, 0), palette.light)
	_box(parent, "Blanket", Vector3(0.98, 0.08, 1.06), Vector3(0.32, 0.69, 0), palette.accent)
	_box(parent, "Pillow", Vector3(0.52, 0.16, 0.72), Vector3(-0.55, 0.73, 0), Color("f7f1ff"))
	_box(parent, "Headboard", Vector3(0.16, 1.12, 1.28), Vector3(-0.91, 0.72, 0), palette.dark)
	if king_scale > 1.0:
		for child in parent.get_children():
			if child is MeshInstance3D and child.name != "ContactShadow": child.scale.z *= king_scale


func _build_table(parent: Node3D, palette: Dictionary) -> void:
	if item_id == "table_pool":
		_box(parent, "PoolTable", Vector3(1.82, 0.25, 1.08), Vector3(0, 0.86, 0), Color("277a67"))
		_box(parent, "PoolRail", Vector3(1.95, 0.12, 1.2), Vector3(0, 1.01, 0), Color("6d4535"))
		_box(parent, "PoolFelt", Vector3(1.68, 0.05, 0.92), Vector3(0, 1.09, 0), Color("3ba486"))
		for index in 7:
			_sphere(parent, "PoolBall", 0.075, Vector3(-0.25 + (index % 3) * 0.16, 1.16, -0.16 + (index / 3) * 0.16), Color.from_hsv(index * 0.14, 0.75, 0.95))
		for x in [-0.7, 0.7]:
			for z in [-0.35, 0.35]: _cylinder(parent, "PoolLeg", 0.09, 0.13, 0.82, Vector3(x, 0.43, z), Color("5a382c"))
		return
	if item_id == "desk_office":
		_box(parent, "WritingDesk", Vector3(1.78, 0.18, 0.88), Vector3(0, 0.92, 0), Color("976647"))
		for x in [-0.66, 0.66]: _box(parent, "DeskDrawer", Vector3(0.48, 0.5, 0.76), Vector3(x, 0.65, 0), Color("74503e"))
		_box(parent, "DeskPad", Vector3(0.72, 0.04, 0.52), Vector3(0, 1.04, 0), palette.accent)
		return
	if item_id == "table_night":
		_box(parent, "Nightstand", Vector3(0.9, 0.84, 0.76), Vector3(0, 0.46, 0), palette.accent)
		for y in [0.38, 0.67]: _box(parent, "NightDrawer", Vector3(0.72, 0.22, 0.05), Vector3(0, y, 0.41), palette.light)
		_sphere(parent, "DrawerKnob", 0.055, Vector3(0, 0.67, 0.47), Color("ffd166"), true)
		return
	_box(parent, "TableTop", Vector3(1.75, 0.18, 1.05), Vector3(0, 0.9, 0), palette.accent)
	for x in [-0.68, 0.68]:
		for z in [-0.34, 0.34]:
			_cylinder(parent, "TableLeg", 0.09, 0.09, 0.85, Vector3(x, 0.44, z), palette.dark)


func _build_lamp(parent: Node3D, palette: Dictionary) -> void:
	if item_id == "chandelier":
		_cylinder(parent, "ChandelierChain", 0.035, 0.035, 0.7, Vector3(0, 1.48, 0), Color("e1ae4f"), true)
		_cylinder(parent, "CrystalHub", 0.16, 0.28, 0.35, Vector3(0, 0.99, 0), palette.light, true)
		for index in 6:
			var angle := TAU * index / 6.0
			var pos := Vector3(cos(angle) * 0.62, 0.78, sin(angle) * 0.62)
			var arm := _cylinder(parent, "GoldArm", 0.035, 0.035, 0.68, pos * Vector3(0.5, 1, 0.5) + Vector3(0, 0.18, 0), Color("e1ae4f"), true)
			arm.rotation_degrees = Vector3(0, -rad_to_deg(angle), 62)
			_sphere(parent, "CrystalDrop", 0.16, pos, Color("d9f5ff"), true)
		return
	if item_id == "candle":
		_cylinder(parent, "CandleJar", 0.42, 0.42, 0.72, Vector3(0, 0.38, 0), Color("fff1d0"))
		var flame := _sphere(parent, "CandleFlame", 0.16, Vector3(0, 0.91, 0), Color("ffd166"), true)
		flame.scale = Vector3(0.55, 1.5, 0.55)
		return
	if item_id == "lantern":
		_cylinder(parent, "LanternGlow", 0.48, 0.48, 0.82, Vector3(0, 0.62, 0), Color("ffdc88"), true)
		for y in [0.18, 1.06]: _cylinder(parent, "LanternRim", 0.52, 0.52, 0.12, Vector3(0, y, 0), palette.dark)
		for x in [-0.46, 0.46]: _box(parent, "LanternFrame", Vector3(0.06, 0.96, 0.06), Vector3(x, 0.62, 0), palette.dark)
		return
	if item_id == "disco":
		_cylinder(parent, "DiscoChain", 0.035, 0.035, 0.7, Vector3(0, 1.48, 0), Color("555c72"))
		_sphere(parent, "DiscoBall", 0.61, Vector3(0, 0.86, 0), Color("d9e7ff"), true)
		for y in [-0.3, 0.0, 0.3]: _box(parent, "MirrorBand", Vector3(1.18 - absf(y) * 0.5, 0.035, 0.04), Vector3(0, 0.86 + y, 0.6), Color("8edff2"), Vector3.ZERO, true)
		return
	if item_id in ["flashlight", "lamp_desk", "studio_spot"]:
		var body := _cylinder(parent, "SpotBody", 0.3, 0.2, 0.78, Vector3(0, 0.72, 0), palette.dark)
		body.rotation_degrees.z = 58 if item_id == "flashlight" else 28
		_cylinder(parent, "SpotLens", 0.34, 0.34, 0.12, Vector3(0.32, 0.92, 0), Color("fff2a8"), true).rotation_degrees.z = 58 if item_id == "flashlight" else 28
		if item_id != "flashlight":
			_cylinder(parent, "SpotStand", 0.07, 0.12, 0.82, Vector3(-0.22, 0.42, 0), palette.dark)
		return
	_cylinder(parent, "LampBase", 0.42, 0.32, 0.12, Vector3(0, 0.08, 0), palette.dark)
	_cylinder(parent, "LampStem", 0.07, 0.07, 1.05, Vector3(0, 0.65, 0), palette.dark)
	_cylinder(parent, "LampShade", 0.28, 0.58, 0.62, Vector3(0, 1.35, 0), palette.accent)
	_sphere(parent, "LampGlow", 0.2, Vector3(0, 1.25, 0), Color("fff0a8"), true)


func _build_pet(parent: Node3D, palette: Dictionary) -> void:
	if item_id == "pet_paw":
		for index in 3:
			var x := -0.58 + index * 0.55
			_sphere(parent, "PawPad", 0.2, Vector3(x, 0.08, (index % 2) * 0.25), palette.accent).scale = Vector3(1.0, 0.16, 0.8)
			for toe in [-0.14, 0.0, 0.14]: _sphere(parent, "ToePrint", 0.07, Vector3(x + toe, 0.08, 0.18 + (index % 2) * 0.25), palette.light).scale.y = 0.18
		return
	if item_id in ["pet_fish", "ac_fish_tank"]:
		if item_id == "ac_fish_tank":
			_box(parent, "AquariumGlass", Vector3(1.55, 1.12, 0.82), Vector3(0, 0.68, 0), Color(0.4, 0.82, 0.94, 0.24), Vector3.ZERO, true)
			_box(parent, "AquariumBase", Vector3(1.66, 0.18, 0.92), Vector3(0, 0.12, 0), palette.dark)
			for x in [-0.42, 0.35]: _build_tiny_fish(parent, Vector3(x, 0.72 + x * 0.2, 0.44), Color("ffd166") if x < 0 else Color("ef6fa7"))
			for x in [-0.55, 0.0, 0.55]: _sphere(parent, "AquariumGravel", 0.12, Vector3(x, 0.28, 0), Color("b99ad9"))
		else:
			_sphere(parent, "FishBowl", 0.72, Vector3(0, 0.7, 0), Color(0.48, 0.86, 0.96, 0.28), true)
			_cylinder(parent, "BowlRim", 0.52, 0.52, 0.11, Vector3(0, 1.3, 0), Color("bdeeff"), true)
			_build_tiny_fish(parent, Vector3(0.05, 0.76, 0.45), Color("f5a13b"))
		return
	if item_id == "pet_hamster":
		_cylinder(parent, "HamsterWheel", 0.58, 0.58, 0.12, Vector3(0, 0.71, 0), Color("8bdff0")).rotation_degrees.x = 90
		_cylinder(parent, "WheelInner", 0.43, 0.43, 0.14, Vector3(0, 0.71, 0), Color("17254d")).rotation_degrees.x = 90
		_sphere(parent, "Hamster", 0.25, Vector3(0, 0.52, 0.1), Color("d6a06f"))
		for x in [-0.13, 0.13]: _sphere(parent, "HamsterEar", 0.07, Vector3(x, 0.74, 0.12), Color("f0b7a3"))
		return
	if item_id == "pet_frog":
		var frog := _sphere(parent, "FrogBody", 0.5, Vector3(0, 0.45, 0), Color("64c978"))
		frog.scale = Vector3(1.2, 0.75, 0.9)
		for z in [-0.28, 0.28]:
			_sphere(parent, "FrogEye", 0.16, Vector3(0.3, 0.78, z), Color("9bea93"))
			_sphere(parent, "FrogPupil", 0.055, Vector3(0.43, 0.8, z), Color("172143"))
		for z in [-0.45, 0.45]: _sphere(parent, "FrogFoot", 0.2, Vector3(-0.25, 0.18, z), Color("4bab66"))
		return
	if item_id == "pet_turtle":
		var shell := _sphere(parent, "TurtleShell", 0.55, Vector3(0, 0.48, 0), Color("5c9b62"))
		shell.scale = Vector3(1.15, 0.65, 0.9)
		_sphere(parent, "TurtleHead", 0.24, Vector3(0.65, 0.43, 0), Color("8bcf74"))
		for x in [-0.34, 0.36]:
			for z in [-0.42, 0.42]: _sphere(parent, "TurtleFoot", 0.14, Vector3(x, 0.2, z), Color("7bb968"))
		return
	if item_id == "pet_chick":
		_sphere(parent, "ChickBody", 0.48, Vector3(0, 0.5, 0), Color("ffe070"))
		_sphere(parent, "ChickHead", 0.34, Vector3(0.36, 0.87, 0), Color("ffec8c"))
		_cylinder(parent, "ChickBeak", 0.02, 0.15, 0.28, Vector3(0.69, 0.86, 0), Color("ef8b35")).rotation_degrees.z = 90
		for z in [-0.2, 0.2]: _cylinder(parent, "ChickLeg", 0.025, 0.025, 0.28, Vector3(0, 0.17, z), Color("d77c2b"))
		return
	if item_id == "pet_mouse":
		var mouse := _sphere(parent, "MouseBody", 0.45, Vector3(0, 0.4, 0), Color("a6a9b8"))
		mouse.scale = Vector3(1.25, 0.76, 0.72)
		_sphere(parent, "MouseHead", 0.29, Vector3(0.52, 0.58, 0), Color("c0c4d0"))
		for z in [-0.2, 0.2]: _sphere(parent, "MouseEar", 0.15, Vector3(0.42, 0.84, z), Color("e7a4b8"))
		_cylinder(parent, "MouseTail", 0.025, 0.025, 1.0, Vector3(-0.78, 0.35, 0), Color("d792a8")).rotation_degrees.z = 72
		return
	if item_id == "pet_dragon":
		var dragon := _sphere(parent, "TinyDragonBody", 0.5, Vector3(0, 0.52, 0), Color("9b74d6"))
		dragon.scale = Vector3(1.15, 0.85, 0.75)
		_sphere(parent, "TinyDragonHead", 0.36, Vector3(0.48, 0.9, 0), Color("b58be3"))
		for z in [-0.38, 0.38]: _box(parent, "DragonWing", Vector3(0.5, 0.08, 0.46), Vector3(-0.12, 0.92, z), Color("62d6d0"), Vector3(0, 0, 24 if z > 0 else -24))
		for x in [-0.3, 0.0, 0.3]: _cylinder(parent, "BackSpike", 0.02, 0.13, 0.28, Vector3(x, 1.02, 0), Color("ffd166"))
		return
	var is_cat := item_id.begins_with("pet_cat")
	var coat: Color = Color("29283a") if item_id == "pet_cat_blk" else (Color("e0a05c") if item_id == "pet_cat_org" else Color(palette.accent))
	var body := _sphere(parent, "CatBody" if is_cat else "DogBody", 0.5, Vector3(0, 0.55, 0), coat)
	body.scale = Vector3(1.18, 0.82, 0.72)
	_sphere(parent, "CatHead" if is_cat else "DogHead", 0.4, Vector3(0.48, 0.92, 0), coat.lightened(0.18))
	for z in [-0.21, 0.21]:
		_box(parent, "Ear", Vector3(0.16, 0.34, 0.12), Vector3(0.49, 1.31, z), palette.dark, Vector3(0, 0, -18 if z < 0 else 18))
	for x in [-0.34, 0.34]:
		for z in [-0.22, 0.22]:
			_cylinder(parent, "Paw", 0.09, 0.1, 0.42, Vector3(x, 0.23, z), palette.dark)
	var tail := _cylinder(parent, "CatTail" if is_cat else "DogTail", 0.07, 0.1, 0.9, Vector3(-0.62, 0.72, 0), coat)
	tail.rotation_degrees.z = -55
	if item_id == "pet_dog_pud":
		for p in [Vector3(-0.3, 0.72, 0.32), Vector3(0.4, 1.18, 0), Vector3(-0.52, 0.92, 0)]: _sphere(parent, "PoodleFluff", 0.24, p, Color("f2e5ed"))
	if item_id == "pet_dog_ser": _box(parent, "ServiceVest", Vector3(0.72, 0.38, 0.78), Vector3(-0.05, 0.78, 0), Color("3b79c4"))


func _build_tiny_fish(parent: Node3D, position: Vector3, color: Color) -> void:
	var fish := _sphere(parent, "FishBody", 0.18, position, color)
	fish.scale = Vector3(1.45, 0.75, 0.35)
	_box(parent, "FishTail", Vector3(0.22, 0.24, 0.05), position + Vector3(-0.28, 0, 0), color.darkened(0.1), Vector3(0, 0, 45))


func _build_toy(parent: Node3D, palette: Dictionary) -> void:
	if "robot" in item_id:
		_box(parent, "RobotBody", Vector3(0.85, 0.72, 0.58), Vector3(0, 0.55, 0), palette.accent)
		_box(parent, "RobotHead", Vector3(0.68, 0.5, 0.52), Vector3(0, 1.17, 0), palette.light)
		for z in [-0.18, 0.18]: _sphere(parent, "RobotEye", 0.07, Vector3(0.35, 1.2, z), Color("6ef3ff"), true)
		return
	if item_id == "toy_bear":
		_sphere(parent, "TeddyBody", 0.48, Vector3(0, 0.57, 0), Color("b77a50"))
		_sphere(parent, "TeddyHead", 0.4, Vector3(0.22, 1.04, 0), Color("c98a5b"))
		for z in [-0.29, 0.29]: _sphere(parent, "TeddyEar", 0.17, Vector3(0.18, 1.34, z), Color("9d6345"))
		for z in [-0.42, 0.42]: _sphere(parent, "TeddyArm", 0.22, Vector3(0, 0.66, z), Color("c98a5b"))
		_sphere(parent, "TeddyMuzzle", 0.18, Vector3(0.56, 1.0, 0), Color("edc59a"))
		return
	if item_id == "toy_doll":
		_cylinder(parent, "DollDress", 0.2, 0.58, 0.78, Vector3(0, 0.52, 0), palette.accent)
		_sphere(parent, "DollHead", 0.28, Vector3(0, 1.14, 0), Color("f2c3a5"))
		for z in [-0.26, 0.26]: _cylinder(parent, "DollBraid", 0.08, 0.11, 0.56, Vector3(0, 0.98, z), Color("704c3d"))
		return
	if item_id == "toy_kite":
		_box(parent, "Kite", Vector3(0.92, 0.08, 0.92), Vector3(0, 0.94, 0), palette.accent, Vector3(0, 45, 45))
		for y in [0.55, 0.3, 0.08]: _box(parent, "KiteBow", Vector3(0.16, 0.05, 0.34), Vector3(0, y, 0), palette.light, Vector3(0, 0, 35))
		return
	if item_id == "toy_yoyo":
		for x in [-0.12, 0.12]: _cylinder(parent, "YoyoHalf", 0.42, 0.32, 0.2, Vector3(x, 0.56, 0), palette.accent).rotation_degrees.z = 90
		_cylinder(parent, "YoyoAxle", 0.08, 0.08, 0.34, Vector3(0, 0.56, 0), palette.dark).rotation_degrees.z = 90
		_cylinder(parent, "YoyoString", 0.015, 0.015, 0.82, Vector3(0, 1.12, 0), Color("fff3d6"))
		return
	if item_id == "toy_train":
		_box(parent, "TrainEngine", Vector3(0.86, 0.58, 0.62), Vector3(0.42, 0.5, 0), Color("ef6f7a"))
		_cylinder(parent, "TrainBoiler", 0.3, 0.3, 0.72, Vector3(0.38, 0.83, 0), Color("4da9d5")).rotation_degrees.z = 90
		_box(parent, "TrainCar", Vector3(0.66, 0.48, 0.62), Vector3(-0.52, 0.43, 0), Color("ffd166"))
		for x in [-0.62, -0.28, 0.22, 0.58]:
			for z in [-0.35, 0.35]: _cylinder(parent, "TrainWheel", 0.14, 0.14, 0.1, Vector3(x, 0.18, z), Color("28304d")).rotation_degrees.x = 90
		return
	if item_id == "toy_ball":
		_sphere(parent, "SoccerBall", 0.66, Vector3(0, 0.68, 0), Color("f4f2e9"))
		for p in [Vector3(0.52, 0.85, 0), Vector3(-0.45, 0.48, 0.15), Vector3(0.05, 0.25, 0.5), Vector3(0.1, 1.18, 0.3)]: _sphere(parent, "SoccerPatch", 0.14, p, Color("25304a"))
		return
	for index in 4:
		var x := -0.55 + float(index % 2) * 0.72
		var z := -0.28 + float(index / 2) * 0.62
		_box(parent, "ToyBlock", Vector3(0.56, 0.56, 0.56), Vector3(x, 0.3 + (index % 2) * 0.25, z), Color.from_hsv(fmod(float(index) * 0.21 + palette.hue, 1.0), 0.56, 0.95))


func _build_electronics(parent: Node3D, palette: Dictionary) -> void:
	if item_id in ["tv_retro", "tv_flat"]:
		var flat := item_id == "tv_flat"
		_box(parent, "FlatScreen" if flat else "RetroTelevision", Vector3(1.55, 0.92, 0.18 if flat else 0.72), Vector3(0, 0.87, 0), Color("333852"))
		_box(parent, "TelevisionPicture", Vector3(1.3 if flat else 1.05, 0.7, 0.05), Vector3(0.1 if not flat else 0, 0.9, 0.39 if not flat else 0.12), Color("62cee3"), Vector3.ZERO, true)
		if not flat:
			for z in [-0.22, 0.22]:
				var antenna := _cylinder(parent, "Antenna", 0.02, 0.025, 0.62, Vector3(-0.05, 1.55, z), Color("aeb7c5"))
				antenna.rotation_degrees.z = -24 if z < 0 else 24
		return
	if item_id == "pc_gamer":
		_box(parent, "GamingTower", Vector3(0.62, 1.25, 0.82), Vector3(-0.52, 0.68, 0), Color("242541"))
		for y in [0.42, 0.84]: _sphere(parent, "RgbFan", 0.2, Vector3(-0.18, y, 0.43), Color("61e6dd") if y < 0.5 else Color("ef6fa7"), true)
		_box(parent, "GamingMonitor", Vector3(1.05, 0.72, 0.12), Vector3(0.42, 1.0, 0), Color("272c48"))
		_box(parent, "MonitorGlow", Vector3(0.88, 0.56, 0.05), Vector3(0.42, 1.0, 0.09), Color("875fe0"), Vector3.ZERO, true)
		_box(parent, "Keyboard", Vector3(0.84, 0.08, 0.36), Vector3(0.42, 0.28, 0.2), Color("5b6380"), Vector3(-8, 0, 0))
		return
	if item_id == "console":
		_box(parent, "GameConsole", Vector3(1.05, 0.24, 0.72), Vector3(0, 0.34, 0), palette.dark)
		for x in [-0.48, 0.48]:
			var controller := _sphere(parent, "Controller", 0.32, Vector3(x, 0.72, 0), palette.accent)
			controller.scale = Vector3(1.3, 0.45, 0.72)
			for z in [-0.1, 0.1]: _sphere(parent, "ControllerButton", 0.04, Vector3(x + 0.14, 0.86, z), Color("ffd166"), true)
		return
	if item_id == "radio":
		_box(parent, "RadioCabinet", Vector3(1.45, 0.82, 0.58), Vector3(0, 0.56, 0), palette.accent)
		_sphere(parent, "RadioSpeaker", 0.33, Vector3(-0.35, 0.56, 0.32), palette.dark)
		_box(parent, "RadioDial", Vector3(0.48, 0.18, 0.05), Vector3(0.38, 0.7, 0.32), Color("fff1b3"), Vector3.ZERO, true)
		var handle := _box(parent, "RadioHandle", Vector3(0.85, 0.08, 0.08), Vector3(0, 1.12, 0), palette.dark)
		handle.rotation_degrees.z = 0
		return
	if item_id == "phone_retro":
		_box(parent, "RotaryPhoneBase", Vector3(1.15, 0.42, 0.85), Vector3(0, 0.34, 0), palette.accent)
		_cylinder(parent, "RotaryDial", 0.32, 0.32, 0.08, Vector3(0, 0.61, 0.38), Color("f2e6d4")).rotation_degrees.x = 90
		for index in 8:
			var angle := TAU * index / 8.0
			_sphere(parent, "DialHole", 0.045, Vector3(cos(angle) * 0.22, 0.63 + sin(angle) * 0.22, 0.44), palette.dark)
		_cylinder(parent, "Handset", 0.13, 0.13, 1.24, Vector3(0, 0.91, 0), palette.dark).rotation_degrees.z = 90
		return
	if item_id == "camera":
		_box(parent, "CameraBody", Vector3(1.22, 0.82, 0.62), Vector3(0, 0.62, 0), Color("37394b"))
		_cylinder(parent, "CameraLens", 0.35, 0.27, 0.34, Vector3(0.32, 0.63, 0.43), Color("5a6380")).rotation_degrees.x = 90
		_sphere(parent, "LensGlass", 0.22, Vector3(0.32, 0.63, 0.64), Color("68cfe4"), true).scale.z = 0.15
		_box(parent, "CameraFlash", Vector3(0.3, 0.26, 0.12), Vector3(-0.32, 1.12, 0), Color("f2d980"), Vector3.ZERO, true)
		return
	if item_id == "record_player":
		_box(parent, "RecordPlayerCase", Vector3(1.52, 0.28, 1.12), Vector3(0, 0.24, 0), Color("8b5d43"))
		_cylinder(parent, "VinylRecord", 0.5, 0.5, 0.06, Vector3(-0.14, 0.42, 0), Color("25243a")).rotation_degrees.x = 90
		_cylinder(parent, "RecordLabel", 0.14, 0.14, 0.07, Vector3(-0.14, 0.46, 0), Color("ef6fa7")).rotation_degrees.x = 90
		var arm := _cylinder(parent, "ToneArm", 0.035, 0.035, 0.75, Vector3(0.5, 0.63, 0), Color("d6bd78"))
		arm.rotation_degrees.z = 42
		return
	_box(parent, "Cabinet", Vector3(1.28, 1.35, 0.72), Vector3(0, 0.72, 0), palette.dark)
	_box(parent, "Screen", Vector3(1.02, 0.7, 0.08), Vector3(0, 0.94, 0.4), Color("55cce7"), Vector3.ZERO, true)
	_box(parent, "ControlPanel", Vector3(0.86, 0.2, 0.44), Vector3(0, 0.42, 0.48), palette.accent, Vector3(-12, 0, 0))


func _build_seasonal(parent: Node3D, palette: Dictionary) -> void:
	if "tree" in item_id:
		_cylinder(parent, "Trunk", 0.13, 0.15, 0.55, Vector3(0, 0.3, 0), Color("79533d"))
		for y in [0.55, 0.92, 1.25]: _cylinder(parent, "Evergreen", 0.05, 0.72 - y * 0.18, 0.58, Vector3(0, y, 0), Color("3b9b68"))
		return
	if "gift" in item_id:
		_box(parent, "Gift", Vector3(1.2, 0.88, 1.0), Vector3(0, 0.46, 0), palette.accent)
		_box(parent, "Ribbon", Vector3(0.18, 0.94, 1.05), Vector3(0, 0.5, 0), palette.light)
		return
	if item_id == "xmas_santa":
		_cylinder(parent, "SantaCoat", 0.28, 0.58, 0.86, Vector3(0, 0.55, 0), Color("d94655"))
		_sphere(parent, "SantaHead", 0.3, Vector3(0, 1.15, 0), Color("efc4a3"))
		var beard := _sphere(parent, "SantaBeard", 0.34, Vector3(0.18, 1.02, 0), Color("fff8ef"))
		beard.scale = Vector3(0.75, 1.2, 0.82)
		_cylinder(parent, "SantaHat", 0.03, 0.34, 0.6, Vector3(-0.1, 1.55, 0), Color("d94655")).rotation_degrees.z = -14
		return
	if item_id == "xmas_sock":
		_box(parent, "StockingLeg", Vector3(0.48, 1.02, 0.2), Vector3(0, 0.85, 0), Color("d94655"), Vector3(0, 0, -9))
		_box(parent, "StockingFoot", Vector3(0.76, 0.42, 0.2), Vector3(0.2, 0.34, 0), Color("d94655"), Vector3(0, 0, -12))
		_box(parent, "StockingCuff", Vector3(0.68, 0.25, 0.28), Vector3(-0.08, 1.4, 0), Color("fff7e8"))
		return
	if item_id == "xmas_bell":
		_cylinder(parent, "JingleBell", 0.18, 0.62, 0.82, Vector3(0, 0.68, 0), Color("ffd166"), true)
		_sphere(parent, "BellClapper", 0.16, Vector3(0, 0.22, 0), Color("b87925"))
		_box(parent, "BellBow", Vector3(0.7, 0.2, 0.22), Vector3(0, 1.2, 0), Color("ef6f7a"), Vector3(0, 0, 30))
		return
	if item_id == "xmas_deer":
		var deer := _sphere(parent, "ReindeerBody", 0.48, Vector3(0, 0.64, 0), Color("9a6847"))
		deer.scale = Vector3(1.2, 0.82, 0.7)
		_sphere(parent, "ReindeerHead", 0.31, Vector3(0.52, 1.05, 0), Color("a97653"))
		_sphere(parent, "RedNose", 0.11, Vector3(0.82, 1.05, 0), Color("ef4259"), true)
		for z in [-0.2, 0.2]:
			for x in [0.42, 0.68]: _cylinder(parent, "Antler", 0.025, 0.035, 0.48, Vector3(x, 1.42, z), Color("71513b")).rotation_degrees.z = 12 if x > 0.5 else -12
		return
	if item_id == "xmas_snow":
		_sphere(parent, "SnowmanBody", 0.58, Vector3(0, 0.56, 0), Color("f0f8ff"))
		_sphere(parent, "SnowmanHead", 0.39, Vector3(0, 1.28, 0), Color("f7fbff"))
		_cylinder(parent, "CarrotNose", 0.02, 0.13, 0.42, Vector3(0.36, 1.28, 0), Color("f29a38")).rotation_degrees.z = 90
		_box(parent, "SnowmanHat", Vector3(0.75, 0.12, 0.75), Vector3(0, 1.66, 0), Color("292c42"))
		_cylinder(parent, "TopHat", 0.28, 0.28, 0.38, Vector3(0, 1.88, 0), Color("292c42"))
		return
	if item_id == "xmas_flake":
		for angle in [0.0, 60.0, 120.0]: _box(parent, "SnowflakeArm", Vector3(0.08, 1.5, 0.08), Vector3(0, 0.88, 0), Color("d9f5ff"), Vector3(0, 0, angle))
		for index in 6: _sphere(parent, "SnowflakeTip", 0.11, Vector3(cos(TAU * index / 6.0) * 0.72, 0.88 + sin(TAU * index / 6.0) * 0.72, 0), Color("a7e8f3"), true)
		return
	if item_id == "hall_ghost":
		var ghost := _sphere(parent, "FriendlyGhost", 0.62, Vector3(0, 0.86, 0), Color(0.88, 0.94, 1.0, 0.74), true)
		ghost.scale = Vector3(0.82, 1.25, 0.72)
		for z in [-0.2, 0.2]: _sphere(parent, "GhostEye", 0.075, Vector3(0.48, 1.04, z), Color("29304d"))
		return
	if item_id == "hall_skull":
		_sphere(parent, "Skull", 0.6, Vector3(0, 0.88, 0), Color("e8dfc9"))
		_box(parent, "SkullJaw", Vector3(0.62, 0.44, 0.58), Vector3(0.3, 0.45, 0), Color("ded3bb"))
		for z in [-0.23, 0.23]: _sphere(parent, "EyeSocket", 0.16, Vector3(0.5, 1.0, z), Color("323246"))
		return
	if item_id in ["hall_web", "hall_spider"]:
		for angle in [0.0, 45.0, 90.0, 135.0]: _box(parent, "WebStrand", Vector3(0.025, 1.55, 0.025), Vector3(0, 0.85, 0), Color("d9dff2"), Vector3(0, 0, angle))
		for radius in [0.3, 0.55, 0.78]:
			for index in 12: _sphere(parent, "WebArc", 0.025, Vector3(cos(TAU * index / 12.0) * radius, 0.85 + sin(TAU * index / 12.0) * radius, 0), Color("d9dff2"))
		if item_id == "hall_spider":
			_sphere(parent, "SpiderBody", 0.28, Vector3(0.2, 0.78, 0.08), Color("35253e"))
			for index in 8:
				var leg := _cylinder(parent, "SpiderLeg", 0.025, 0.035, 0.55, Vector3(0.2 + cos(TAU * index / 8.0) * 0.25, 0.78 + sin(TAU * index / 8.0) * 0.25, 0.08), Color("35253e"))
				leg.rotation_degrees.z = index * 45
		return
	if item_id == "hall_bat":
		_sphere(parent, "BatBody", 0.24, Vector3(0, 0.86, 0), Color("3c284d"))
		for x in [-0.52, 0.52]: _box(parent, "BatWing", Vector3(0.72, 0.08, 0.48), Vector3(x, 0.9, 0), Color("563468"), Vector3(0, 0, 22 if x > 0 else -22))
		for x in [-0.09, 0.09]: _box(parent, "BatEar", Vector3(0.1, 0.3, 0.1), Vector3(x, 1.17, 0), Color("3c284d"), Vector3(0, 0, 18 if x > 0 else -18))
		return
	if item_id == "hall_alien":
		var alien := _sphere(parent, "AlienHead", 0.62, Vector3(0, 0.92, 0), Color("7fd694"))
		alien.scale = Vector3(0.76, 1.12, 0.62)
		for z in [-0.24, 0.24]:
			var eye := _sphere(parent, "AlienEye", 0.2, Vector3(0.48, 1.02, z), Color("24243d"))
			eye.scale = Vector3(0.35, 1.0, 0.7)
		return
	if item_id == "hall_mask":
		var mask := _sphere(parent, "GoblinMask", 0.68, Vector3(0, 0.88, 0), Color("7eb567"))
		mask.scale = Vector3(0.28, 1.0, 0.72)
		for z in [-0.28, 0.28]: _cylinder(parent, "GoblinTusk", 0.02, 0.1, 0.35, Vector3(0.35, 0.58, z), Color("eee2bd")).rotation_degrees.z = 60
		return
	for x in [-0.24, 0.0, 0.24]: _sphere(parent, "Pumpkin", 0.42, Vector3(x, 0.46, 0), Color("ef8b35"))
	_cylinder(parent, "PumpkinStem", 0.07, 0.08, 0.28, Vector3(0, 0.93, 0), Color("4f7845"))


func _build_kitchen(parent: Node3D, palette: Dictionary) -> void:
	if item_id == "mom_tea":
		_cylinder(parent, "TeaTray", 0.72, 0.72, 0.1, Vector3(0, 0.12, 0), Color("d6b16c"))
		_sphere(parent, "TeaPot", 0.38, Vector3(0, 0.54, 0), Color("f6e6f0"))
		_cylinder(parent, "TeaLid", 0.12, 0.25, 0.14, Vector3(0, 0.91, 0), palette.accent)
		var spout := _cylinder(parent, "TeaSpout", 0.08, 0.17, 0.58, Vector3(0.35, 0.66, 0), Color("f6e6f0"))
		spout.rotation_degrees.z = 62
		for z in [-0.38, 0.38]: _cylinder(parent, "TeaCup", 0.2, 0.16, 0.28, Vector3(0.05, 0.33, z), palette.light)
		return
	if item_id == "fruit_basket":
		_cylinder(parent, "FruitBasket", 0.48, 0.68, 0.5, Vector3(0, 0.32, 0), Color("b98548"))
		for index in 7:
			var angle := TAU * index / 7.0
			_sphere(parent, "FreshFruit", 0.19, Vector3(cos(angle) * 0.38, 0.67 + (index % 2) * 0.12, sin(angle) * 0.3), [Color("ef5f64"), Color("ffd45c"), Color("73bd62")][index % 3])
		return
	if item_id == "espresso_maker":
		_cylinder(parent, "EspressoBase", 0.42, 0.5, 0.18, Vector3(0, 0.13, 0), Color("4d5261"))
		_cylinder(parent, "EspressoBody", 0.38, 0.28, 0.82, Vector3(0, 0.61, 0), Color("c6cbd2"))
		_cylinder(parent, "EspressoTop", 0.1, 0.36, 0.52, Vector3(0, 1.23, 0), Color("565d6d"))
		var handle := _cylinder(parent, "EspressoHandle", 0.05, 0.07, 0.74, Vector3(0.52, 0.68, 0), Color("303344"))
		handle.rotation_degrees.z = 90
		return
	if item_id == "brick_oven":
		_box(parent, "BrickOven", Vector3(1.62, 1.35, 0.92), Vector3(0, 0.7, 0), Color("b9634d"))
		_sphere(parent, "OvenOpening", 0.49, Vector3(0.35, 0.75, 0.5), Color("31283a"))
		_box(parent, "OvenHearth", Vector3(1.78, 0.18, 1.05), Vector3(0, 0.15, 0), Color("6c4537"))
		for x in [-0.5, 0.0, 0.5]:
			for y in [0.32, 0.68, 1.04]: _box(parent, "Brick", Vector3(0.42, 0.18, 0.06), Vector3(x, y, 0.5), Color("dd8066"))
		return
	if item_id == "ac_menu_board":
		_box(parent, "MenuFrame", Vector3(1.55, 1.5, 0.14), Vector3(0, 0.85, 0), Color("86573d"))
		_box(parent, "Chalkboard", Vector3(1.28, 1.22, 0.08), Vector3(0, 0.85, 0.1), Color("25443f"))
		for y in [0.55, 0.82, 1.09]: _box(parent, "ChalkLine", Vector3(0.78, 0.035, 0.04), Vector3(0, y, 0.17), Color("f3ecd4"))
		return
	_box(parent, "KitchenCabinet", Vector3(1.55, 1.0, 0.78), Vector3(0, 0.53, 0), palette.accent)
	_box(parent, "Counter", Vector3(1.72, 0.16, 0.92), Vector3(0, 1.08, 0), palette.light)
	for x in [-0.38, 0.38]: _box(parent, "CabinetDoor", Vector3(0.62, 0.65, 0.05), Vector3(x, 0.55, 0.42), palette.dark)


func _build_wall_art(parent: Node3D, palette: Dictionary) -> void:
	if item_id == "fairy_lights":
		for index in 15:
			var x := -0.76 + index * 0.108
			var y := 1.05 + sin(index * 0.72) * 0.22
			_sphere(parent, "FairyBulb", 0.065, Vector3(x, y, 0), [Color("ffd166"), Color("ef6fa7"), Color("62dbe6")][index % 3], true)
			if index > 0: _box(parent, "FairyWire", Vector3(0.12, 0.025, 0.025), Vector3(x - 0.054, y, 0), Color("52665a"))
		return
	if item_id == "peach_wall":
		_box(parent, "PeachWallpaper", Vector3(1.58, 1.5, 0.1), Vector3(0, 0.84, 0), Color("f5b99f"))
		for x in [-0.5, 0.0, 0.5]:
			for y in [0.42, 0.9, 1.38]:
				_sphere(parent, "PeachPattern", 0.14, Vector3(x, y, 0.08), Color("f08174"))
				_sphere(parent, "PeachLeaf", 0.07, Vector3(x + 0.12, y + 0.11, 0.09), Color("79a867"))
		return
	_box(parent, "Frame", Vector3(1.48, 1.35, 0.12), Vector3(0, 0.82, 0), palette.dark)
	_box(parent, "Painting", Vector3(1.22, 1.08, 0.08), Vector3(0, 0.82, 0.1), palette.light)
	_box(parent, "Landscape", Vector3(0.95, 0.38, 0.06), Vector3(0, 0.57, 0.16), palette.accent, Vector3(0, 0, 12))


func _build_luxury(parent: Node3D, palette: Dictionary) -> void:
	if item_id == "moon_chair":
		for index in 11:
			var angle := deg_to_rad(-105.0 + index * 21.0)
			_sphere(parent, "MoonCushion", 0.25, Vector3(cos(angle) * 0.62, 0.9 + sin(angle) * 0.62, 0), Color("8d77d7"))
		_box(parent, "MoonSeat", Vector3(0.9, 0.22, 0.82), Vector3(0, 0.48, 0), Color("d9c5f4"))
		return
	if item_id == "golden_toilet":
		_cylinder(parent, "GoldenBowl", 0.46, 0.58, 0.62, Vector3(0.22, 0.45, 0), Color("e1ae4f"), true)
		_cylinder(parent, "GoldenSeat", 0.58, 0.58, 0.12, Vector3(0.22, 0.78, 0), Color("ffd875"), true)
		_box(parent, "GoldenTank", Vector3(0.65, 0.82, 0.7), Vector3(-0.52, 0.86, 0), Color("dba63f"))
		return
	if item_id == "star_lamp":
		for index in 10:
			var angle := -PI * 0.5 + index * PI / 5.0
			var radius := 0.72 if index % 2 == 0 else 0.32
			_sphere(parent, "StarRay", 0.17, Vector3(cos(angle) * radius, 0.86 + sin(angle) * radius, 0), Color("ffd166"), true)
		_sphere(parent, "StarCore", 0.4, Vector3(0, 0.86, 0), Color("fff1a6"), true)
		return
	if "trophy" in item_id:
		_cylinder(parent, "TrophyBase", 0.5, 0.58, 0.18, Vector3(0, 0.12, 0), Color("e0a82e"), true)
		_cylinder(parent, "TrophyStem", 0.11, 0.16, 0.62, Vector3(0, 0.48, 0), Color("ffd166"), true)
		_sphere(parent, "TrophyCup", 0.43, Vector3(0, 1.05, 0), Color("ffd166"), true)
		return
	if item_id == "crown_display":
		_box(parent, "CrownCase", Vector3(1.35, 1.5, 0.96), Vector3(0, 0.82, 0), Color(0.68, 0.9, 1.0, 0.22), Vector3.ZERO, true)
		_cylinder(parent, "CrownCushion", 0.52, 0.62, 0.25, Vector3(0, 0.3, 0), Color("8d315f"))
		for x in [-0.48, -0.24, 0.0, 0.24, 0.48]: _cylinder(parent, "CrownPoint", 0.02, 0.14, 0.62 - absf(x) * 0.35, Vector3(x, 0.78, 0), Color("ffd166"), true)
		_box(parent, "CrownBand", Vector3(1.15, 0.28, 0.5), Vector3(0, 0.5, 0), Color("e1ae4f"))
		return
	var crystal := _cylinder(parent, "Crystal", 0.08, 0.5, 1.45, Vector3(0, 0.78, 0), palette.accent, true)
	crystal.rotation_degrees.z = 8


func _build_unicorn_decor(parent: Node3D, palette: Dictionary) -> void:
	if item_id == "uni_rainbow_shelf":
		for index in 6:
			var angle := deg_to_rad(180.0 + index * 30.0)
			_box(parent, "RainbowShelf", Vector3(0.24, 0.18, 0.78), Vector3(cos(angle) * 0.68, 0.82 + sin(angle) * 0.68, 0), Color.from_hsv(index / 6.0, 0.58, 0.96), Vector3(0, 0, rad_to_deg(angle) + 90))
		return
	if item_id == "uni_glitter_rug":
		_box(parent, "GlitterRug", Vector3(1.78, 0.09, 1.18), Vector3(0, 0.08, 0), Color("bf82dc"), Vector3.ZERO, true)
		for index in 14:
			var x := -0.72 + (index % 7) * 0.24
			var z := -0.36 + (index / 7) * 0.72
			_sphere(parent, "GlitterSpark", 0.05, Vector3(x, 0.16, z), Color("fff1a6"), true)
		return
	if item_id == "uni_cloud_lamp":
		for x in [-0.45, -0.15, 0.15, 0.45]: _sphere(parent, "PendantCloud", 0.38, Vector3(x, 0.92 + absf(x) * 0.2, 0), Color("eef8ff"), true)
		_cylinder(parent, "PendantCord", 0.025, 0.025, 0.72, Vector3(0, 1.48, 0), Color("b6a6d6"))
		for x in [-0.28, 0.0, 0.28]: _cylinder(parent, "RainbowDrop", 0.025, 0.025, 0.48, Vector3(x, 0.45, 0), [Color("ef6fa7"), Color("ffd166"), Color("62dbe6")][int((x + 0.28) / 0.28)], true)
		return
	if item_id == "uni_horn_planter":
		var horn := _cylinder(parent, "HornPlanter", 0.12, 0.52, 1.12, Vector3(0, 0.62, 0), Color("f1d27a"), true)
		horn.rotation_degrees.z = -12
		for x in [-0.25, 0.0, 0.25]: _sphere(parent, "HornSucculent", 0.22, Vector3(x, 1.22, 0), Color("67c68b"))
		return
	_cylinder(parent, "FountainBasin", 0.72, 0.9, 0.22, Vector3(0, 0.14, 0), Color("70dbe8"), true)
	_cylinder(parent, "Pedestal", 0.22, 0.34, 0.72, Vector3(0, 0.55, 0), palette.light)
	var horn := _cylinder(parent, "Horn", 0.04, 0.25, 0.9, Vector3(0, 1.25, 0), Color("ffd166"), true)
	horn.rotation_degrees.z = -12


func _build_chair(parent: Node3D, palette: Dictionary) -> void:
	if item_id == "book_stack":
		for index in 6:
			_box(parent, "StoryBook", Vector3(1.2 - index * 0.08, 0.18, 0.72), Vector3((index % 2) * 0.12 - 0.06, 0.15 + index * 0.2, 0), Color.from_hsv(fmod(palette.hue + index * 0.13, 1.0), 0.48, 0.86), Vector3(0, (index % 3 - 1) * 6, (index % 2) * 4 - 2))
		return
	if item_id == "bubble_machine":
		_box(parent, "BubbleMachine", Vector3(1.1, 0.72, 0.72), Vector3(0, 0.42, 0), palette.accent)
		_cylinder(parent, "BubbleWheel", 0.34, 0.34, 0.12, Vector3(0.28, 0.62, 0.4), palette.dark).rotation_degrees.x = 90
		for p in [Vector3(-0.4, 1.0, 0), Vector3(0.0, 1.3, 0.1), Vector3(0.42, 1.08, -0.1), Vector3(-0.15, 1.58, 0)]: _sphere(parent, "RainbowBubble", 0.16, p, Color(0.55, 0.9, 1.0, 0.38), true)
		return
	if item_id == "hammock":
		for x in [-0.82, 0.82]: _cylinder(parent, "HammockPost", 0.08, 0.1, 1.55, Vector3(x, 0.78, 0), Color("7f5d43"))
		for index in 9:
			var x := -0.68 + index * 0.17
			var y := 0.58 + absf(x) * 0.38
			_box(parent, "LeafHammock", Vector3(0.16, 0.06, 1.0), Vector3(x, y, 0), Color("62b879"), Vector3(0, 0, x * 22))
		return
	if item_id == "ac_typewriter":
		_box(parent, "TypewriterBody", Vector3(1.45, 0.55, 0.88), Vector3(0, 0.43, 0), Color("556079"))
		for row in 3:
			for col in 8: _sphere(parent, "TypeKey", 0.05, Vector3(-0.5 + col * 0.15, 0.68 + row * 0.12, 0.42), Color("f1e7d7"))
		_box(parent, "TypewriterPaper", Vector3(0.86, 0.72, 0.05), Vector3(0, 1.2, 0), Color("fff8e9"), Vector3(-10, 0, 0))
		return
	if item_id == "ac_cello":
		_sphere(parent, "CelloLower", 0.48, Vector3(0, 0.55, 0), Color("a96035"))
		_sphere(parent, "CelloUpper", 0.34, Vector3(0, 1.05, 0), Color("bd7241"))
		_cylinder(parent, "CelloNeck", 0.07, 0.1, 0.9, Vector3(0, 1.55, 0), Color("75422d"))
		for z in [-0.09, 0.09]: _cylinder(parent, "CelloString", 0.008, 0.008, 1.55, Vector3(0.42, 1.02, z), Color("e7d6a2")).rotation_degrees.z = 18
		return
	_box(parent, "Seat", Vector3(1.18, 0.28, 1.0), Vector3(0, 0.62, 0), palette.accent)
	_box(parent, "Back", Vector3(0.24, 1.18, 1.08), Vector3(-0.48, 1.14, 0), palette.dark, Vector3(0, 0, -8))
	for x in [-0.42, 0.42]:
		for z in [-0.34, 0.34]: _cylinder(parent, "ChairLeg", 0.07, 0.08, 0.58, Vector3(x, 0.3, z), palette.dark)


func _add_shadow(parent: Node3D) -> void:
	var shadow := _cylinder(parent, "ContactShadow", 0.92, 0.92, 0.025, Vector3(0, 0.015, 0), Color(0.04, 0.03, 0.12, 0.2))
	shadow.scale.z = 0.58


func _box(parent: Node3D, node_name: String, dimensions: Vector3, location: Vector3, color: Color, rotation: Vector3 = Vector3.ZERO, emission := false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	mesh.material = _material(color, emission)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = location
	instance.rotation_degrees = rotation
	parent.add_child(instance)
	return instance


func _sphere(parent: Node3D, node_name: String, radius: float, location: Vector3, color: Color, emission := false) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 20
	mesh.rings = 12
	mesh.material = _material(color, emission)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = location
	parent.add_child(instance)
	return instance


func _cylinder(parent: Node3D, node_name: String, top_radius: float, bottom_radius: float, height: float, location: Vector3, color: Color, emission := false) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 24
	mesh.material = _material(color, emission)
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = location
	parent.add_child(instance)
	return instance


func _material(color: Color, emission := false) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.72
	if color.a < 0.99:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission:
		material.emission_enabled = true
		material.emission = Color(color.r, color.g, color.b)
		material.emission_energy_multiplier = 0.55
	return material


func _palette() -> Dictionary:
	var hue := float(abs(item_id.hash()) % 360) / 360.0
	var accent := Color.from_hsv(hue, 0.5, 0.92)
	return {"hue": hue, "accent": accent, "dark": accent.darkened(0.58), "light": accent.lightened(0.42)}


func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count
