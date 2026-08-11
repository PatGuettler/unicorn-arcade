class_name RoomPreviewViewport
extends RefCounted

var viewport: SubViewport
var stage: Node3D
var display_rotation_root: Node3D


func mount(host: SubViewportContainer, viewport_size: Vector2i, update_mode: SubViewport.UpdateMode, yaw_degrees: float) -> void:
	viewport = SubViewport.new()
	viewport.name = "SubViewport"
	viewport.size = viewport_size
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = update_mode
	host.add_child(viewport)
	stage = Node3D.new()
	stage.name = "PreviewStage"
	viewport.add_child(stage)
	display_rotation_root = Node3D.new()
	display_rotation_root.name = "DisplayRotationRoot"
	display_rotation_root.rotation_degrees.y = yaw_degrees
	stage.add_child(display_rotation_root)


func add_camera(size: float, position: Vector3, target: Vector3) -> void:
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = size
	stage.add_child(camera)
	camera.look_at_from_position(position, target, Vector3.UP)
	camera.current = true


func add_lighting() -> void:
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


func set_yaw(degrees: float, static_preview: bool) -> void:
	if is_instance_valid(display_rotation_root):
		display_rotation_root.rotation_degrees.y = degrees
	if static_preview and is_instance_valid(viewport):
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func request_redraw() -> void:
	if is_instance_valid(viewport):
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


func shutdown() -> void:
	if is_instance_valid(viewport):
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
