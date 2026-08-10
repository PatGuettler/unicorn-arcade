class_name RoomItemPreview3D
extends SubViewportContainer

const CompanionAssets = preload("res://scripts/meta/companion_asset_catalog.gd")
const RoomAuthoredFurnitureLoader = preload("res://scripts/meta/room_authored_furniture_loader.gd")
const RoomProceduralFurnitureBuilder = preload("res://scripts/meta/room_procedural_furniture_builder.gd")
const CHARACTER_SCALE_MULTIPLIER := 3.0
const ANIMATED_CAMERA_SIZE := 6.80
const STATIC_CAMERA_SIZE := 6.80
const HERO_CAMERA_SIZE := 6.60
const BACKGROUND_CAMERA_SIZE := 8.40
const GAME_HUD_CAMERA_SIZE := 8.80
const ANIMATION_FRAME_LIFT := Vector3(0.0, 1.10, 0.0)
const STATIC_FRAME_LIFT := Vector3(0.0, 1.10, 0.0)
const HERO_FRAME_LIFT := Vector3(0.0, 1.10, 0.0)
const BACKGROUND_FRAME_LIFT := Vector3(0.0, 0.92, 0.0)
const SIDE_CAMERA_POSITION := Vector3(-8.40, 3.18, 0.90)
const SIDE_CAMERA_TARGET := Vector3(0.0, 1.72, -0.15)
const UnicornIdleAnimatorScene = preload("res://scripts/meta/unicorn_idle_animator.gd")
const RoomPreviewViewportScene = preload("res://scripts/meta/room_preview_viewport.gd")


var item_id := ""
var category := "cozy"
var mesh_count := 0
var uses_character_model := false
var source_model_id := ""
var animate_character := true
var presentation_context := "room"
var uses_authored_furniture_model := false
var source_furniture_model_id := ""
var display_rotation_root: Node3D
var preview_viewport
var display_yaw_degrees := 0.0
var _companion_request_generation := 0
var _idle_animator: UnicornIdleAnimator


func setup(definition: Dictionary) -> void:
	item_id = str(definition.get("id", definition.get("item_id", "decor")))
	category = str(definition.get("category", "cozy"))
	uses_character_model = item_id.begins_with("companion_") or category == "companions"
	animate_character = bool(definition.get("animate", true))
	presentation_context = str(definition.get("presentation", "room" if animate_character else "marketplace"))
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_viewport()


func _exit_tree() -> void:
	if preview_viewport != null:
		preview_viewport.shutdown()


func _build_viewport() -> void:
	preview_viewport = RoomPreviewViewportScene.new()
	var viewport_size := Vector2i(448, 320) if uses_character_model else Vector2i(192, 192)
	var update_mode := SubViewport.UPDATE_ALWAYS if animate_character else SubViewport.UPDATE_ONCE
	preview_viewport.mount(self, viewport_size, update_mode, display_yaw_degrees)
	var stage: Node3D = preview_viewport.stage
	display_rotation_root = preview_viewport.display_rotation_root
	if uses_character_model:
		_build_companion(stage)
	else:
		_build_furniture(stage)
	preview_viewport.add_lighting()


func set_display_yaw(degrees: float) -> void:
	display_yaw_degrees = fposmod(degrees, 360.0)
	if preview_viewport != null:
		preview_viewport.set_yaw(display_yaw_degrees, not animate_character)


func set_motion_state(walking: bool) -> void:
	var animator: Node = _idle_animator if is_instance_valid(_idle_animator) else find_child("IdleAnimator", true, false)
	if is_instance_valid(animator) and animator.has_method("set_motion_state"):
		animator.call("set_motion_state", walking)


func _build_companion(stage: Node3D) -> void:
	var companion_id := CompanionAssets.normalized_id(item_id.trim_prefix("companion_"))
	source_model_id = companion_id
	var travel_root := Node3D.new()
	travel_root.name = "CompanionTravelRoot"
	display_rotation_root.add_child(travel_root)
	if animate_character:
		var animator := UnicornIdleAnimatorScene.new()
		animator.name = "IdleAnimator"
		_idle_animator = animator
		# Keep the controller under this preview control so room interaction can
		# address it reliably even though the model itself lives in a SubViewport.
		add_child(animator)
	# The portrait remains visible in surrounding chrome while this request runs.
	# Do not preload a GLB here: Home and Marketplace can exist without loading
	# any unowned companion model into CPU or GPU memory.
	var generation := _companion_request_generation + 1
	_companion_request_generation = generation
	var model_path := CompanionAssets.model_path(companion_id)
	if animate_character:
		# The sole room/meadow actor is interactive immediately. This is still
		# lazy (only its requested companion is loaded), while avoiding a visible
		# no-animation window during room entry.
		var active_scene := RuntimeAssetLoader.cached_packed_scene(model_path)
		if active_scene == null:
			active_scene = ResourceLoader.load(model_path, "PackedScene") as PackedScene
		if active_scene != null:
			_instantiate_companion(active_scene, companion_id, travel_root)
	else:
		RuntimeAssetLoader.load_packed_scene(model_path, func(packed_scene: PackedScene) -> void:
			if generation != _companion_request_generation or not is_instance_valid(travel_root) or packed_scene == null:
				return
			_instantiate_companion(packed_scene, companion_id, travel_root)
		)
	_add_companion_shadow(travel_root)
	var camera_size := STATIC_CAMERA_SIZE
	if not animate_character:
		camera_size = GAME_HUD_CAMERA_SIZE if presentation_context == "game_hud" else STATIC_CAMERA_SIZE
	elif presentation_context == "hero":
		camera_size = HERO_CAMERA_SIZE
	elif presentation_context == "meadow_background":
		camera_size = BACKGROUND_CAMERA_SIZE
	else:
		camera_size = ANIMATED_CAMERA_SIZE
	var frame_lift := STATIC_FRAME_LIFT
	if animate_character:
		if presentation_context == "hero":
			frame_lift = HERO_FRAME_LIFT
		elif presentation_context == "meadow_background":
			frame_lift = BACKGROUND_FRAME_LIFT
		else:
			frame_lift = ANIMATION_FRAME_LIFT
	preview_viewport.add_camera(camera_size, SIDE_CAMERA_POSITION + frame_lift, SIDE_CAMERA_TARGET + frame_lift)


func _instantiate_companion(packed_scene: PackedScene, companion_id: String, travel_root: Node3D) -> void:
	var model := packed_scene.instantiate() as Node3D
	if model == null:
		return
	model.name = "LiveUnicornModel"
	model.position.y = -0.25
	model.scale = Vector3.ONE * CompanionAssets.scale_for(companion_id) * CHARACTER_SCALE_MULTIPLIER
	travel_root.add_child(model)
	mesh_count = _count_meshes(model)
	if animate_character:
		var animator := _idle_animator
		if is_instance_valid(animator):
			var roam_radius := 1.15
			if presentation_context == "meadow_background":
				roam_radius = 1.65
			elif presentation_context == "hero":
				roam_radius = 0.85
			animator.setup(travel_root, {"seed": "%s:%s" % [companion_id, presentation_context], "roam_radius": roam_radius})
	else:
		_pose_companion(model)


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
	display_rotation_root.add_child(model)
	_add_shadow(model)
	var authored_result := RoomAuthoredFurnitureLoader.build(item_id, model)
	uses_authored_furniture_model = bool(authored_result.get("built", false))
	source_furniture_model_id = str(authored_result.get("source_model_id", ""))
	if not uses_authored_furniture_model:
		RoomProceduralFurnitureBuilder.new().build(model, item_id, category)
	mesh_count = _count_meshes(model)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.85
	stage.add_child(camera)
	camera.look_at_from_position(Vector3(3.7, 2.75, 4.8), Vector3(0.0, 0.62, 0.0), Vector3.UP)
	camera.current = true


func _add_shadow(parent: Node3D) -> void:
	var shadow := _cylinder(parent, "ContactShadow", 0.92, 0.92, 0.025, Vector3(0, 0.015, 0), Color(0.04, 0.03, 0.12, 0.2))
	shadow.scale.z = 0.58


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


func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count
