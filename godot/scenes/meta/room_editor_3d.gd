extends Control

const GRID_SNAP := 0.08

var _unicorn_id: String
var _container: SubViewportContainer
var _viewport: SubViewport
var _camera: Camera3D
var _props_root: Node3D
var _selected: Node3D
var _dragging_prop := false
var _dragging_camera := false
var _last_pointer := Vector2.ZERO
var _camera_yaw := 0.0
var _camera_pitch := 0.62
var _camera_distance := 11.5


func _ready() -> void:
	_unicorn_id = SceneRouter.get_room_unicorn_id()
	var uni: Dictionary = GameCatalog.get_unicorn(_unicorn_id)
	UiFactory.add_background(self)
	UiFactory.make_header_bar(self, {
		"subscreen": true,
		"title": "%s Room" % uni.get("name", "Room"),
		"coins": int(SaveManager.user_data.get("coins", 0)),
		"on_back": func(): SceneRouter.pop(),
		"on_profile": func(): SceneRouter.go_home(false),
	})

	var stack: Dictionary = World3DHelpers.make_viewport_stack(self, 88)
	_container = stack.container
	_viewport = stack.viewport
	_camera = stack.camera
	_update_camera()
	_container.gui_input.connect(_on_viewport_input)

	var world: Node3D = stack.world
	World3DHelpers.build_room_shell(world, _unicorn_id)
	_props_root = Node3D.new()
	_props_root.name = "Props"
	world.add_child(_props_root)

	_load_placements()
	_build_ui()


func _load_placements() -> void:
	var placements: Array = SaveManager.user_data.furniture.placements.get(_unicorn_id, [])
	for item_variant in placements:
		_spawn_prop(item_variant)


func _spawn_prop(item: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.set_meta("placement", item)
	var mesh := World3DHelpers.furniture_mesh_for(String(item.get("itemId", "")))
	root.add_child(mesh)
	root.position = World3DHelpers.percent_to_room(float(item.x), float(item.y))
	root.position.y = float(item.get("zIndex", 0)) * 0.015
	root.rotation.y = deg_to_rad(float(item.get("rotation", 0)))
	var scale_f := float(item.get("scale", 1.0))
	root.scale = Vector3.ONE * scale_f

	var area := Area3D.new()
	area.collision_layer = 2
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1, 1, 1)
	col.shape = shape
	area.add_child(col)
	root.add_child(area)

	_props_root.add_child(root)
	return root


func _build_ui() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_bottom = -DisplayProfile.content_margin()
	panel.add_theme_stylebox_override("panel", UiFactory.stylebox_flat(Color(15.0 / 255.0, 23.0 / 255.0, 42.0 / 255.0, 0.94), 16))
	add_child(panel)

	var row := GridContainer.new()
	row.columns = 4
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 6)
	panel.add_child(row)

	var bag := UiFactory.make_button("Bag", UiFactory.VIOLET, 44)
	bag.pressed.connect(_toggle_bag)
	row.add_child(bag)

	var rot := UiFactory.make_button("Rotate", UiFactory.CYAN, 44)
	rot.pressed.connect(_rotate_selected)
	row.add_child(rot)

	var del := UiFactory.make_button("Remove", UiFactory.PINK, 44)
	del.pressed.connect(_delete_selected)
	row.add_child(del)

	var snap := UiFactory.make_button("Snap", UiFactory.SLATE_700, 44)
	snap.pressed.connect(_snap_selected)
	row.add_child(snap)

	var smaller := UiFactory.make_button("Size −", UiFactory.SLATE_700, 44)
	smaller.pressed.connect(func(): _scale_selected(0.9))
	row.add_child(smaller)

	var larger := UiFactory.make_button("Size +", UiFactory.VIOLET, 44)
	larger.pressed.connect(func(): _scale_selected(1.1))
	row.add_child(larger)

	var raise := UiFactory.make_button("Bring front", UiFactory.CYAN, 44)
	raise.pressed.connect(_raise_selected)
	row.add_child(raise)


func _toggle_bag() -> void:
	if has_node("BagSheet"):
		get_node("BagSheet").queue_free()
		return

	var sheet := PanelContainer.new()
	sheet.name = "BagSheet"
	sheet.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	sheet.offset_bottom = -120
	sheet.custom_minimum_size.y = 160
	sheet.add_theme_stylebox_override("panel", UiFactory.stylebox_flat(UiFactory.SLATE_900, 14))
	add_child(sheet)

	var scroll := ScrollContainer.new()
	sheet.add_child(scroll)
	var list := HBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	var inv: Dictionary = SaveManager.user_data.furniture.inventory
	for item_variant in GameCatalog.furniture:
		var def: Dictionary = item_variant
		var iid: String = String(def.get("id", ""))
		var qty: int = int(inv.get(iid, 0))
		if qty <= 0:
			continue
		var btn := UiFactory.make_button("%s\n(%d)" % [def.get("icon", ""), qty], UiFactory.CYAN, 56)
		btn.pressed.connect(func(): _place_from_bag(iid))
		list.add_child(btn)


func _place_from_bag(item_id: String) -> void:
	var inv: Dictionary = SaveManager.user_data.furniture.inventory
	if int(inv.get(item_id, 0)) <= 0:
		return
	var item := {
		"itemId": item_id,
		"uid": "%s_%d" % [item_id, Time.get_ticks_msec()],
		"x": 50.0,
		"y": 50.0,
		"rotation": 0.0,
		"scale": 1.0,
		"zIndex": 0,
	}
	var list: Array = SaveManager.user_data.furniture.placements.get(_unicorn_id, [])
	list.append(item)
	SaveManager.user_data.furniture.placements[_unicorn_id] = list
	inv[item_id] = int(inv[item_id]) - 1
	SaveManager.persist_user()
	_selected = _spawn_prop(item)


func _on_viewport_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_pointer_down(event.position)
			else:
				_pointer_up()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_camera_distance = maxf(7.0, _camera_distance - 0.8)
			_update_camera()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_camera_distance = minf(16.0, _camera_distance + 0.8)
			_update_camera()
	elif event is InputEventMouseMotion:
		_pointer_move(event.position, event.relative)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_pointer_down(event.position)
		else:
			_pointer_up()
	elif event is InputEventScreenDrag:
		_pointer_move(event.position, event.relative)
	elif event is InputEventMagnifyGesture:
		_camera_distance = clampf(_camera_distance / event.factor, 7.0, 16.0)
		_update_camera()


func _pointer_down(local_pos: Vector2) -> void:
	_last_pointer = local_pos
	var vp_pos := World3DHelpers.viewport_event_pos(_container, _viewport, local_pos)
	if _try_select_prop(vp_pos):
		_dragging_prop = true
		_dragging_camera = false
	else:
		_dragging_prop = false
		_dragging_camera = true


func _pointer_move(local_pos: Vector2, relative: Vector2) -> void:
	if _dragging_prop and _selected:
		var vp_pos := World3DHelpers.viewport_event_pos(_container, _viewport, local_pos)
		var hit := World3DHelpers.raycast_floor(_camera, _viewport, vp_pos)
		if hit.has("position"):
			var floor_pos: Vector3 = hit.position
			_selected.global_position.x = clampf(floor_pos.x, -3.8, 3.8)
			_selected.global_position.z = clampf(floor_pos.z, -3.8, 3.8)
	elif _dragging_camera:
		_camera_yaw -= relative.x * 0.008
		_camera_pitch = clampf(_camera_pitch + relative.y * 0.005, 0.35, 1.05)
		_update_camera()
	_last_pointer = local_pos


func _pointer_up() -> void:
	_dragging_prop = false
	_dragging_camera = false
	_persist_selected()


func _update_camera() -> void:
	var cos_pitch := cos(_camera_pitch)
	_camera.position = Vector3(
		sin(_camera_yaw) * cos_pitch * _camera_distance,
		sin(_camera_pitch) * _camera_distance,
		cos(_camera_yaw) * cos_pitch * _camera_distance
	)
	_camera.look_at(Vector3(0, 0.8, 0))


func _try_select_prop(screen_pos: Vector2) -> bool:
	var hit := World3DHelpers.raycast_area(_camera, _viewport, screen_pos, 2)
	if not hit.has("collider"):
		_selected = null
		return false
	var area := hit.collider as Area3D
	if area == null:
		return false
	_selected = area.get_parent() as Node3D
	return _selected != null


func _rotate_selected() -> void:
	if _selected == null:
		return
	_selected.rotation.y += deg_to_rad(15)
	_persist_selected()


func _delete_selected() -> void:
	if _selected == null:
		return
	var item: Dictionary = _selected.get_meta("placement")
	var list: Array = SaveManager.user_data.furniture.placements.get(_unicorn_id, [])
	list = list.filter(func(p): return p.get("uid", "") != item.get("uid", ""))
	SaveManager.user_data.furniture.placements[_unicorn_id] = list
	var inv: Dictionary = SaveManager.user_data.furniture.inventory
	var iid: String = String(item.get("itemId", ""))
	inv[iid] = int(inv.get(iid, 0)) + 1
	SaveManager.persist_user()
	_selected.queue_free()
	_selected = null


func _snap_selected() -> void:
	if _selected == null:
		return
	var p := _selected.position
	var step := GRID_SNAP * World3DHelpers.FLOOR_HALF * 2.0
	p.x = snappedf(p.x, step)
	p.z = snappedf(p.z, step)
	_selected.position = p
	_persist_selected()


func _scale_selected(multiplier: float) -> void:
	if _selected == null:
		return
	var item: Dictionary = _selected.get_meta("placement")
	var next_scale := clampf(float(item.get("scale", 1.0)) * multiplier, 0.55, 1.8)
	item.scale = next_scale
	_selected.scale = Vector3.ONE * next_scale
	_persist_selected()


func _raise_selected() -> void:
	if _selected == null:
		return
	var placements: Array = SaveManager.user_data.furniture.placements.get(_unicorn_id, [])
	var highest := 0
	for placement_variant in placements:
		var placement: Dictionary = placement_variant
		highest = maxi(highest, int(placement.get("zIndex", 0)))
	var item: Dictionary = _selected.get_meta("placement")
	item.zIndex = highest + 1
	_selected.position.y = float(item.zIndex) * 0.015
	_persist_selected()


func _persist_selected() -> void:
	if _selected == null:
		return
	var item: Dictionary = _selected.get_meta("placement")
	var pct := World3DHelpers.room_to_percent(_selected.position)
	item.x = pct.x
	item.y = pct.y
	item.rotation = rad_to_deg(_selected.rotation.y)
	SaveManager.persist_user()
