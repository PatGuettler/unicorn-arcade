extends Control

var _container: SubViewportContainer
var _viewport: SubViewport
var _camera: Camera3D
var _camera_rig: Node3D
var _dragging_cam := false
var _last_mouse := Vector2.ZERO
var _yaw := 0.6
var _navigating := false


func _ready() -> void:
	UiFactory.add_background(self)
	UiFactory.make_header_bar(self, {
		"subscreen": true,
		"title": "Unicorn Alley",
		"coins": int(SaveManager.user_data.get("coins", 0)),
		"on_back": func(): SceneRouter.pop(),
		"on_profile": func(): SceneRouter.go_home(false),
	})

	var stack: Dictionary = World3DHelpers.make_viewport_stack(self, 88)
	_container = stack.container
	_viewport = stack.viewport
	_camera = stack.camera
	_camera_rig = stack.camera_rig
	_container.gui_input.connect(_on_viewport_input)

	var world: Node3D = stack.world
	World3DHelpers.build_alley_world(world)
	_update_camera()

	var hint := UiFactory.make_subtitle("Drag to look around · Tap a house")
	hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_bottom = -12
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)


func _process(delta: float) -> void:
	if _dragging_cam or bool(SaveManager.get_setting("reduced_motion", false)):
		return
	_yaw += delta * 0.08
	_update_camera()


func _update_camera() -> void:
	var dist := 22.0
	var pitch := 0.55
	_camera_rig.position = Vector3(0, 0, 0)
	_camera.position = Vector3(
		sin(_yaw) * cos(pitch) * dist,
		sin(pitch) * dist * 0.55 + 4.0,
		cos(_yaw) * cos(pitch) * dist
	)
	_camera.look_at(Vector3(0, 1.5, 0))


func _on_viewport_input(event: InputEvent) -> void:
	if _navigating or not is_instance_valid(_viewport) or not _viewport.is_inside_tree():
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging_cam = false
				var vp_pos := World3DHelpers.viewport_event_pos(_container, _viewport, event.position)
				var hit := World3DHelpers.raycast_area(_camera, _viewport, vp_pos, 4)
				if hit.has("collider"):
					var area := hit.collider as Area3D
					if area:
						var uid: String = String(area.get_meta("unicorn_id", ""))
						_on_house(uid)
						return
				_dragging_cam = true
				_last_mouse = event.position
			else:
				_dragging_cam = false
	elif event is InputEventMouseMotion:
		if _dragging_cam or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var delta_x: float = event.relative.x
			_yaw -= delta_x * 0.008
			_update_camera()
	elif event is InputEventScreenTouch and event.pressed:
		_handle_tap(event.position)


func _handle_tap(local_pos: Vector2) -> void:
	if _navigating:
		return
	var vp_pos := World3DHelpers.viewport_event_pos(_container, _viewport, local_pos)
	var hit := World3DHelpers.raycast_area(_camera, _viewport, vp_pos, 4)
	if hit.has("collider"):
		var area := hit.collider as Area3D
		if area:
			var uid: String = String(area.get_meta("unicorn_id", ""))
			_on_house(uid)


func _on_house(unicorn_id: String) -> void:
	if unicorn_id.is_empty() or _navigating:
		return
	_navigating = true
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if unicorn_id in SaveManager.user_data.ownedUnicorns:
		SceneRouter.go_room(unicorn_id)
	else:
		SceneRouter.go_shop()
