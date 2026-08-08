class_name MeadowCompanionStage3D
extends Node

const Preview = preload("res://scripts/meta/room_item_preview_3d.gd")
const IdleAnimator = preload("res://scripts/meta/unicorn_idle_animator.gd")

var viewport: SubViewport


func setup(equipped_id: String, companion_ids: Array) -> void:
	viewport = SubViewport.new()
	viewport.name = "MeadowSharedViewport"
	viewport.size = Vector2i(720, 420)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var stage := Node3D.new()
	stage.name = "MeadowSharedStage"
	viewport.add_child(stage)
	var camera := Camera3D.new()
	camera.name = "MeadowSharedCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 13.0
	stage.add_child(camera)
	camera.look_at_from_position(Vector3(-12.0, 6.0, 3.0), Vector3(0.0, 1.4, 0.0), Vector3.UP)
	_add_lights(stage)
	var positions := [Vector3(-4.0, 0.0, -1.8), Vector3(4.2, 0.0, -1.4), Vector3(-2.7, 0.0, 0.8), Vector3(2.8, 0.0, 0.9), Vector3(0.0, 0.0, -2.5)]
	var background_index := 0
	for raw_id in companion_ids:
		var id := str(raw_id)
		var front := id == equipped_id
		var position: Vector3 = Vector3(0.0, 0.0, 2.0) if front else positions[background_index]
		if not front:
			background_index += 1
		_add_companion(stage, id, position, front)


func create_display() -> TextureRect:
	var display := TextureRect.new()
	display.name = "MeadowCompanionDisplay"
	display.texture = viewport.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return display


func _add_companion(stage: Node3D, id: String, position: Vector3, hero: bool) -> void:
	var root := Node3D.new()
	root.name = "MeadowTravelRoot_%s" % id
	root.position = position
	root.set_meta("source_model_id", id)
	root.set_meta("hero", hero)
	stage.add_child(root)
	var model := Preview.CHARACTER_SCENES[id].instantiate() as Node3D
	model.name = "LiveUnicornModel_%s" % id
	model.scale = Vector3.ONE * float(Preview.CHARACTER_SCALES.get(id, 1.0)) * (3.4 if hero else 1.7)
	model.position.y = -0.25
	root.add_child(model)
	var shadow := MeshInstance3D.new()
	shadow.name = "MeadowContactShadow"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.75 if hero else 0.42
	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.02
	shadow.mesh = mesh
	shadow.position = Vector3(0.0, 0.02, -0.06)
	shadow.scale.z = 0.55
	root.add_child(shadow)
	var animator := IdleAnimator.new()
	animator.name = "IdleAnimator"
	stage.add_child(animator)
	animator.setup(root, {"seed": "meadow:%s" % id, "roam_radius": 0.65 if hero else 0.95})


func _add_lights(stage: Node3D) -> void:
	var key := DirectionalLight3D.new()
	key.name = "MeadowSharedKeyLight"
	key.rotation_degrees = Vector3(-52.0, -28.0, 0.0)
	key.light_energy = 1.2
	stage.add_child(key)
	var fill := OmniLight3D.new()
	fill.name = "MeadowSharedFillLight"
	fill.position = Vector3(-2.0, 5.0, 4.0)
	fill.light_energy = 0.7
	fill.omni_range = 18.0
	stage.add_child(fill)


func set_active(active: bool) -> void:
	if is_instance_valid(viewport):
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	for animator in find_children("*", "UnicornIdleAnimator", true, false):
		animator.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED


func _exit_tree() -> void:
	if is_instance_valid(viewport):
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
