extends Control

const GRID_SNAP := 0.08
const FLOOR_SIZE := 8.0

var _unicorn_id: String
var _props_root: Node3D
var _selected: Node3D


func _ready() -> void:
	_unicorn_id = SceneRouter.get_room_unicorn_id()
	var uni := GameCatalog.get_unicorn(_unicorn_id)
	UiFactory.make_header(self, "%s Room" % uni.get("name", "Room"), func(): SceneRouter.pop())

	_props_root = $ViewportContainer/SubViewport/World/Props
	var floor: MeshInstance3D = $ViewportContainer/SubViewport/World/Floor
	var plane := PlaneMesh.new()
	plane.size = Vector2(FLOOR_SIZE, FLOOR_SIZE)
	floor.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#312e81")
	floor.material_override = mat

	_load_placements()
	_build_toolbar()


func _load_placements() -> void:
	var placements: Array = SaveManager.user_data.furniture.placements.get(_unicorn_id, [])
	for item in placements:
		_add_prop_mesh(item)


func _add_prop_mesh(item: Dictionary) -> void:
	var def := GameCatalog.get_furniture_def(item.get("itemId", ""))
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.5, 0.5, 0.5) * float(item.get("scale", 1.0))
	mesh_inst.mesh = box
	var m := StandardMaterial3D.new()
	m.albedo_color = UiFactory.VIOLET
	mesh_inst.material_override = m
	mesh_inst.position = _percent_to_world(float(item.x), float(item.y))
	mesh_inst.rotation.y = deg_to_rad(float(item.get("rotation", 0)))
	mesh_inst.set_meta("placement", item)
	_props_root.add_child(mesh_inst)


func _percent_to_world(x_pct: float, y_pct: float) -> Vector3:
	var x := (x_pct / 100.0 - 0.5) * FLOOR_SIZE
	var z := (y_pct / 100.0 - 0.5) * FLOOR_SIZE
	return Vector3(x, 0.25, z)


func _world_to_percent(pos: Vector3) -> Vector2:
	var x_pct := (pos.x / FLOOR_SIZE + 0.5) * 100.0
	var y_pct := (pos.z / FLOOR_SIZE + 0.5) * 100.0
	return Vector2(clampf(x_pct, 0, 100), clampf(y_pct, 0, 100))


func _build_toolbar() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_bottom = -DisplayProfile.content_margin()
	bar.add_theme_constant_override("separation", 8)
	add_child(bar)

	var add := UiFactory.make_button("Place lamp")
	add.pressed.connect(func(): _place_from_inventory("lamp"))
	bar.add_child(add)

	var snap := UiFactory.make_button("Snap grid")
	snap.pressed.connect(_snap_selected)
	bar.add_child(snap)


func _place_from_inventory(item_id: String) -> void:
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
	_add_prop_mesh(item)


func _snap_selected() -> void:
	if _selected == null:
		return
	var p := _selected.position
	p.x = snappedf(p.x, GRID_SNAP * FLOOR_SIZE)
	p.z = snappedf(p.z, GRID_SNAP * FLOOR_SIZE)
	_selected.position = p
	_persist_selected()


func _persist_selected() -> void:
	if _selected == null:
		return
	var item: Dictionary = _selected.get_meta("placement")
	var pct := _world_to_percent(_selected.position)
	item.x = pct.x
	item.y = pct.y
	item.rotation = rad_to_deg(_selected.rotation.y)
	SaveManager.persist_user()
