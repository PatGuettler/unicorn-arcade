extends Node
## Shared 3D alley, room, and viewport helpers (autoload: World3DHelpers).

const ALLEY_HOUSE_LAYOUT := [
	{"id": "sparkle", "left": 0.60, "top": 0.65},
	{"id": "rainbow", "left": 0.82, "top": 0.80},
	{"id": "star", "left": 0.18, "top": 0.75},
	{"id": "cloud", "left": 0.55, "top": 0.15},
	{"id": "dream", "left": 0.30, "top": 0.50},
	{"id": "mystic", "left": 0.45, "top": 0.80},
]

const FLOOR_HALF := 4.0
const ALLEY_WIDTH := 48.0
const ALLEY_DEPTH := 36.0


static func toon_mat(color: Color) -> ShaderMaterial:
	var sh: Shader = load("res://shaders/toon_magical.gdshader")
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("albedo", color)
	mat.set_shader_parameter("rim_color", UiFactory.CYAN)
	return mat


static func unicorn_accent(unicorn_id: String) -> Color:
	var u: Dictionary = GameCatalog.get_unicorn(unicorn_id)
	var hex: String = String(u.get("accent", "#f472b6"))
	if hex.begins_with("#") and hex.length() >= 7:
		return Color(hex)
	return UiFactory.PINK


static func make_viewport_stack(parent: Control, top_inset: int = 88) -> Dictionary:
	var container := SubViewportContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.offset_top = top_inset
	container.stretch = true
	parent.add_child(container)

	var viewport := SubViewport.new()
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.size = Vector2i(390, 700)
	container.add_child(viewport)

	var world := Node3D.new()
	world.name = "World"
	viewport.add_child(world)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#020617")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#a78bfa")
	env.ambient_light_energy = 0.45
	env_node.environment = env
	world.add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 35, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	world.add_child(sun)

	var camera_rig := Node3D.new()
	camera_rig.name = "CameraRig"
	world.add_child(camera_rig)

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 9, 14)
	camera.rotation_degrees = Vector3(-32, 0, 0)
	camera_rig.add_child(camera)

	return {
		"container": container,
		"viewport": viewport,
		"world": world,
		"camera": camera,
		"camera_rig": camera_rig,
	}


static func alley_pct_to_pos(left: float, top: float) -> Vector3:
	var x := (left - 0.5) * ALLEY_WIDTH
	var z := (top - 0.5) * ALLEY_DEPTH
	return Vector3(x, 0.0, z)


static func build_unicorn_model(
	unicorn_id: String,
	model_scale: float = 1.0,
	muted: bool = false
) -> Node3D:
	var root := Node3D.new()
	root.name = "%sUnicorn3D" % unicorn_id.capitalize()
	root.scale = Vector3.ONE * model_scale

	var accent := unicorn_accent(unicorn_id)
	var body_color := Color("#f8fafc").lerp(accent, 0.14)
	var mane_color := accent
	var hoof_color := accent.darkened(0.45)
	if muted:
		body_color = Color("#94a3b8")
		mane_color = Color("#64748b")
		hoof_color = Color("#475569")

	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.56
	body_mesh.height = 1.85
	var body := _unicorn_part(root, body_mesh, body_color, Vector3(0, 1.05, 0))
	body.rotation_degrees.x = 90

	var chest_mesh := SphereMesh.new()
	chest_mesh.radius = 0.58
	chest_mesh.height = 1.16
	var chest := _unicorn_part(root, chest_mesh, body_color, Vector3(0, 1.15, 0.52))
	chest.scale = Vector3(0.95, 1.1, 0.9)

	var neck_mesh := CylinderMesh.new()
	neck_mesh.top_radius = 0.33
	neck_mesh.bottom_radius = 0.45
	neck_mesh.height = 1.1
	var neck := _unicorn_part(root, neck_mesh, body_color, Vector3(0, 1.65, 0.58))
	neck.rotation_degrees.x = -18

	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.47
	head_mesh.height = 0.94
	var head := _unicorn_part(root, head_mesh, body_color, Vector3(0, 2.2, 0.78))
	head.scale = Vector3(0.9, 1.0, 1.15)

	var muzzle_mesh := SphereMesh.new()
	muzzle_mesh.radius = 0.3
	muzzle_mesh.height = 0.6
	var muzzle := _unicorn_part(root, muzzle_mesh, body_color.darkened(0.04), Vector3(0, 2.05, 1.2))
	muzzle.scale = Vector3(0.92, 0.72, 1.0)

	for x_side in [-1.0, 1.0]:
		var ear_mesh := CylinderMesh.new()
		ear_mesh.top_radius = 0.0
		ear_mesh.bottom_radius = 0.14
		ear_mesh.height = 0.42
		var ear := _unicorn_part(
			root,
			ear_mesh,
			body_color,
			Vector3(0.24 * x_side, 2.72, 0.7)
		)
		ear.rotation_degrees.z = -12.0 * x_side

		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.075
		eye_mesh.height = 0.15
		var eye := _unicorn_part(
			root,
			eye_mesh,
			Color("#0f172a"),
			Vector3(0.31 * x_side, 2.3, 1.12)
		)
		eye.scale.z = 0.55

	var horn_mesh := CylinderMesh.new()
	horn_mesh.top_radius = 0.0
	horn_mesh.bottom_radius = 0.13
	horn_mesh.height = 0.72
	var horn := _unicorn_part(root, horn_mesh, Color("#fde68a"), Vector3(0, 2.86, 0.93))
	horn.rotation_degrees.x = 14

	for leg_pos in [
		Vector3(-0.38, 0.42, -0.55),
		Vector3(0.38, 0.42, -0.55),
		Vector3(-0.38, 0.42, 0.55),
		Vector3(0.38, 0.42, 0.55),
	]:
		var leg_mesh := CylinderMesh.new()
		leg_mesh.top_radius = 0.14
		leg_mesh.bottom_radius = 0.11
		leg_mesh.height = 0.85
		_unicorn_part(root, leg_mesh, body_color, leg_pos)

		var hoof_mesh := CylinderMesh.new()
		hoof_mesh.top_radius = 0.16
		hoof_mesh.bottom_radius = 0.18
		hoof_mesh.height = 0.2
		_unicorn_part(root, hoof_mesh, hoof_color, leg_pos + Vector3(0, -0.44, 0.03))

	for i in 5:
		var mane_mesh := SphereMesh.new()
		mane_mesh.radius = 0.2
		mane_mesh.height = 0.4
		var mane := _unicorn_part(
			root,
			mane_mesh,
			mane_color.lightened(float(i) * 0.035),
			Vector3(0, 2.42 - i * 0.28, 0.37 - i * 0.12)
		)
		mane.scale = Vector3(0.62, 1.0, 0.72)

	var tail_mesh := CylinderMesh.new()
	tail_mesh.top_radius = 0.1
	tail_mesh.bottom_radius = 0.18
	tail_mesh.height = 1.15
	var tail := _unicorn_part(root, tail_mesh, mane_color, Vector3(0, 0.95, -1.05))
	tail.rotation_degrees.x = -55
	var tail_tip_mesh := SphereMesh.new()
	tail_tip_mesh.radius = 0.28
	tail_tip_mesh.height = 0.65
	var tail_tip := _unicorn_part(root, tail_tip_mesh, mane_color.lightened(0.12), Vector3(0, 0.48, -1.45))
	tail_tip.rotation_degrees.x = -20

	return root


static func _unicorn_part(
	parent: Node3D,
	mesh: Mesh,
	color: Color,
	position: Vector3
) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = position
	part.material_override = toon_mat(color)
	part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(part)
	return part


static func build_alley_world(world: Node3D) -> Dictionary:
	var houses: Dictionary = {}

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(ALLEY_WIDTH + 8, ALLEY_DEPTH + 8)
	ground.mesh = plane
	ground.material_override = toon_mat(Color("#1e1b4b"))
	ground.position = Vector3(0, -0.05, 0)
	world.add_child(ground)

	var path := MeshInstance3D.new()
	var path_mesh := BoxMesh.new()
	path_mesh.size = Vector3(8, 0.08, ALLEY_DEPTH * 0.85)
	path.mesh = path_mesh
	path.material_override = toon_mat(Color("#312e81"))
	path.position = Vector3(0, 0.02, 0)
	world.add_child(path)

	for i in range(6):
		var lamp := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.08
		cyl.bottom_radius = 0.12
		cyl.height = 2.4
		lamp.mesh = cyl
		lamp.material_override = toon_mat(Color("#64748b"))
		lamp.position = Vector3(-10 + i * 4.0, 1.2, -6 + (i % 3) * 6.0)
		world.add_child(lamp)
		var bulb := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.22
		sph.height = 0.44
		bulb.mesh = sph
		bulb.material_override = toon_mat(Color("#fde68a"))
		bulb.position = lamp.position + Vector3(0, 1.35, 0)
		world.add_child(bulb)

	for entry in ALLEY_HOUSE_LAYOUT:
		var uid: String = entry.id
		var pos := alley_pct_to_pos(float(entry.left), float(entry.top))
		var owned: bool = uid in SaveManager.user_data.ownedUnicorns
		var house_root := _build_house(uid, owned)
		house_root.position = pos
		world.add_child(house_root)
		houses[uid] = house_root

	return {"houses": houses}


static func _build_house(unicorn_id: String, owned: bool) -> Node3D:
	var root := Node3D.new()
	root.name = unicorn_id

	var base := MeshInstance3D.new()
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(3.2, 2.2, 2.8)
	base.mesh = base_mesh
	var col := unicorn_accent(unicorn_id) if owned else Color("#475569")
	base.material_override = toon_mat(col.darkened(0.25 if owned else 0.0))
	base.position = Vector3(0, 1.1, 0)
	root.add_child(base)

	var roof := MeshInstance3D.new()
	var roof_mesh := PrismMesh.new()
	roof_mesh.size = Vector3(3.6, 1.4, 3.2)
	roof.mesh = roof_mesh
	roof.material_override = toon_mat(col.lightened(0.15 if owned else 0.0))
	roof.position = Vector3(0, 2.6, 0)
	roof.rotation_degrees = Vector3(0, 90, 0)
	root.add_child(roof)

	var door := MeshInstance3D.new()
	var door_mesh := BoxMesh.new()
	door_mesh.size = Vector3(0.9, 1.4, 0.12)
	door.mesh = door_mesh
	door.material_override = toon_mat(Color("#0f172a"))
	door.position = Vector3(0, 0.75, 1.45)
	root.add_child(door)

	var unicorn := build_unicorn_model(unicorn_id, 0.42, not owned)
	unicorn.position = Vector3(0, 0.08, 2.0)
	root.add_child(unicorn)

	var label := Label3D.new()
	var uni: Dictionary = GameCatalog.get_unicorn(unicorn_id)
	label.text = String(uni.get("name", unicorn_id))
	label.font_size = 42
	label.outline_size = 8
	label.modulate = col if owned else Color("#94a3b8")
	label.position = Vector3(0, 3.6, 0)
	root.add_child(label)

	var area := Area3D.new()
	area.set_meta("unicorn_id", unicorn_id)
	var col_shape := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4, 5, 4)
	col_shape.shape = shape
	area.add_child(col_shape)
	area.position = Vector3(0, 2.0, 0)
	area.collision_layer = 4
	area.collision_mask = 0
	root.add_child(area)

	if not owned:
		var lock := Label3D.new()
		lock.text = "🔒"
		lock.font_size = 64
		lock.position = Vector3(0, 2.2, 2.0)
		root.add_child(lock)

	return root


static func build_room_shell(world: Node3D, unicorn_id: String) -> StaticBody3D:
	var accent := unicorn_accent(unicorn_id)

	var floor_body := StaticBody3D.new()
	floor_body.name = "FloorBody"
	floor_body.collision_layer = 1
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(FLOOR_HALF * 2, FLOOR_HALF * 2)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	var tex_path := "res://assets/rooms/%s.png" % unicorn_id
	if unicorn_id == "dream":
		tex_path = "res://assets/rooms/dreamer.png"
	if ResourceLoader.exists(tex_path):
		floor_mat.albedo_texture = load(tex_path)
		floor_mat.uv1_scale = Vector3(0.35, 0.35, 0.35)
	else:
		floor_mat.albedo_color = accent.darkened(0.55)
	floor_mesh.material_override = floor_mat
	floor_body.add_child(floor_mesh)
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(FLOOR_HALF * 2, 0.2, FLOOR_HALF * 2)
	floor_col.shape = floor_shape
	floor_col.position = Vector3(0, -0.1, 0)
	floor_body.add_child(floor_col)
	world.add_child(floor_body)

	for side in 4:
		var wall := MeshInstance3D.new()
		var wbox := BoxMesh.new()
		wbox.size = Vector3(FLOOR_HALF * 2, 3.0, 0.15)
		wall.mesh = wbox
		wall.material_override = toon_mat(accent.darkened(0.35))
		match side:
			0:
				wall.position = Vector3(0, 1.5, -FLOOR_HALF)
			1:
				wall.position = Vector3(0, 1.5, FLOOR_HALF)
			2:
				wall.position = Vector3(-FLOOR_HALF, 1.5, 0)
				wall.rotation_degrees = Vector3(0, 90, 0)
			3:
				wall.position = Vector3(FLOOR_HALF, 1.5, 0)
				wall.rotation_degrees = Vector3(0, 90, 0)
		world.add_child(wall)

	var room_unicorn := build_unicorn_model(unicorn_id, 0.5)
	room_unicorn.position = Vector3(-2.7, 0.0, -2.65)
	room_unicorn.rotation_degrees.y = -18
	world.add_child(room_unicorn)

	return floor_body


static func furniture_mesh_for(item_id: String) -> Node3D:
	var def: Dictionary = GameCatalog.get_furniture_def(item_id)
	var cat: String = String(def.get("category", "cozy"))
	var root := Node3D.new()
	root.name = String(def.get("name", item_id)).validate_node_name()
	root.set_meta("catalog_id", item_id)
	var palette := [
		Color("#f472b6"),
		Color("#a78bfa"),
		Color("#22d3ee"),
		Color("#34d399"),
		Color("#fde68a"),
		Color("#fb7185"),
	]
	var color: Color = palette[absi(item_id.hash()) % palette.size()]
	var variant := 0.88 + float(absi(item_id.hash() / 7) % 25) / 100.0

	match cat:
		"beds":
			var mattress := BoxMesh.new()
			mattress.size = Vector3(1.45 * variant, 0.38, 2.0)
			_furniture_part(root, mattress, color.lightened(0.18), Vector3(0, 0.32, 0))
			var frame := BoxMesh.new()
			frame.size = Vector3(1.55 * variant, 0.22, 2.1)
			_furniture_part(root, frame, color.darkened(0.32), Vector3(0, 0.12, 0))
			var headboard := BoxMesh.new()
			headboard.size = Vector3(1.55 * variant, 1.0, 0.16)
			_furniture_part(root, headboard, color, Vector3(0, 0.65, -1.0))
		"rugs":
			var rug := CylinderMesh.new()
			rug.top_radius = 0.95 * variant
			rug.bottom_radius = 0.95 * variant
			rug.height = 0.055
			_furniture_part(root, rug, color, Vector3(0, 0.03, 0))
		"lighting":
			var pole := CylinderMesh.new()
			pole.top_radius = 0.07
			pole.bottom_radius = 0.12
			pole.height = 1.25 * variant
			_furniture_part(root, pole, color.darkened(0.3), Vector3(0, 0.63, 0))
			var shade := CylinderMesh.new()
			shade.top_radius = 0.23
			shade.bottom_radius = 0.42
			shade.height = 0.48
			_furniture_part(root, shade, Color("#fde68a"), Vector3(0, 1.35 * variant, 0))
		"pets", "toys":
			var body := SphereMesh.new()
			body.radius = 0.34 * variant
			body.height = 0.68 * variant
			_furniture_part(root, body, color, Vector3(0, 0.36, 0))
			var head := SphereMesh.new()
			head.radius = 0.24 * variant
			head.height = 0.48 * variant
			_furniture_part(root, head, color.lightened(0.13), Vector3(0, 0.78, 0.12))
		"tables":
			var top := BoxMesh.new()
			top.size = Vector3(1.25 * variant, 0.16, 0.85 * variant)
			_furniture_part(root, top, color, Vector3(0, 0.72, 0))
			for leg_x in [-0.48, 0.48]:
				for leg_z in [-0.3, 0.3]:
					var leg := BoxMesh.new()
					leg.size = Vector3(0.12, 0.7, 0.12)
					_furniture_part(root, leg, color.darkened(0.3), Vector3(leg_x * variant, 0.35, leg_z * variant))
		"nature":
			var trunk := CylinderMesh.new()
			trunk.top_radius = 0.13
			trunk.bottom_radius = 0.18
			trunk.height = 0.72
			_furniture_part(root, trunk, Color("#92400e"), Vector3(0, 0.36, 0))
			var leaves := SphereMesh.new()
			leaves.radius = 0.5 * variant
			leaves.height = 0.9 * variant
			_furniture_part(root, leaves, Color("#34d399"), Vector3(0, 0.95, 0))
		"electronics":
			var case := BoxMesh.new()
			case.size = Vector3(1.0 * variant, 0.72 * variant, 0.28)
			_furniture_part(root, case, Color("#334155"), Vector3(0, 0.48, 0))
			var screen := BoxMesh.new()
			screen.size = Vector3(0.78 * variant, 0.5 * variant, 0.04)
			_furniture_part(root, screen, color, Vector3(0, 0.52, 0.17))
		"kitchen":
			var cabinet := BoxMesh.new()
			cabinet.size = Vector3(1.05 * variant, 0.9, 0.65)
			_furniture_part(root, cabinet, color.darkened(0.2), Vector3(0, 0.45, 0))
			var counter := BoxMesh.new()
			counter.size = Vector3(1.12 * variant, 0.12, 0.72)
			_furniture_part(root, counter, color.lightened(0.25), Vector3(0, 0.95, 0))
		"wall":
			var frame := BoxMesh.new()
			frame.size = Vector3(1.0 * variant, 0.82 * variant, 0.1)
			_furniture_part(root, frame, color.darkened(0.25), Vector3(0, 0.65, 0))
			var art := BoxMesh.new()
			art.size = Vector3(0.78 * variant, 0.6 * variant, 0.04)
			_furniture_part(root, art, color.lightened(0.18), Vector3(0, 0.65, 0.08))
		"luxury", "unicorn":
			var pedestal := CylinderMesh.new()
			pedestal.top_radius = 0.45 * variant
			pedestal.bottom_radius = 0.55 * variant
			pedestal.height = 0.28
			_furniture_part(root, pedestal, color.darkened(0.28), Vector3(0, 0.14, 0))
			var jewel := SphereMesh.new()
			jewel.radius = 0.38 * variant
			jewel.height = 0.76 * variant
			_furniture_part(root, jewel, color, Vector3(0, 0.62, 0))
		"seasonal":
			var gift := BoxMesh.new()
			gift.size = Vector3(0.75 * variant, 0.75 * variant, 0.75 * variant)
			_furniture_part(root, gift, color, Vector3(0, 0.38, 0))
			var ribbon := BoxMesh.new()
			ribbon.size = Vector3(0.16, 0.82 * variant, 0.82 * variant)
			_furniture_part(root, ribbon, Color("#fde68a"), Vector3(0, 0.4, 0))
		_:
			var seat := BoxMesh.new()
			seat.size = Vector3(0.8 * variant, 0.22, 0.75 * variant)
			_furniture_part(root, seat, color, Vector3(0, 0.45, 0))
			var back := BoxMesh.new()
			back.size = Vector3(0.8 * variant, 0.9, 0.18)
			_furniture_part(root, back, color.darkened(0.12), Vector3(0, 0.82, -0.3))

	return root


static func _furniture_part(
	parent: Node3D,
	mesh: Mesh,
	color: Color,
	position: Vector3
) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = position
	part.material_override = toon_mat(color)
	parent.add_child(part)
	return part


static func percent_to_room(x_pct: float, y_pct: float) -> Vector3:
	var x := (x_pct / 100.0 - 0.5) * FLOOR_HALF * 2.0
	var z := (y_pct / 100.0 - 0.5) * FLOOR_HALF * 2.0
	return Vector3(x, 0.0, z)


static func room_to_percent(pos: Vector3) -> Vector2:
	var x_pct := (pos.x / (FLOOR_HALF * 2.0) + 0.5) * 100.0
	var y_pct := (pos.z / (FLOOR_HALF * 2.0) + 0.5) * 100.0
	return Vector2(clampf(x_pct, 2, 98), clampf(y_pct, 2, 98))


static func viewport_event_pos(container: SubViewportContainer, viewport: SubViewport, local_pos: Vector2) -> Vector2:
	if container.size.x < 1.0 or container.size.y < 1.0:
		return local_pos
	return local_pos * (Vector2(viewport.size) / container.size)


static func raycast_floor(camera: Camera3D, viewport: SubViewport, screen_pos: Vector2) -> Dictionary:
	if not is_instance_valid(camera) or not is_instance_valid(viewport):
		return {}
	if not camera.is_inside_tree() or not viewport.is_inside_tree():
		return {}
	var world: World3D = viewport.world_3d
	if world == null:
		return {}
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 80.0
	var space := world.direct_space_state
	if space == null:
		return {}
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 1
	return space.intersect_ray(query)


static func raycast_area(camera: Camera3D, viewport: SubViewport, screen_pos: Vector2, layer: int) -> Dictionary:
	if not is_instance_valid(camera) or not is_instance_valid(viewport):
		return {}
	if not camera.is_inside_tree() or not viewport.is_inside_tree():
		return {}
	var world: World3D = viewport.world_3d
	if world == null:
		return {}
	var from := camera.project_ray_origin(screen_pos)
	var to := from + camera.project_ray_normal(screen_pos) * 80.0
	var space := world.direct_space_state
	if space == null:
		return {}
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = layer
	return space.intersect_ray(query)


static func build_game_backdrop(world: Node3D, accent: Color = Color("#a78bfa")) -> void:
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(24, 8)
	floor.mesh = plane
	floor.material_override = toon_mat(accent.darkened(0.5))
	floor.rotation_degrees = Vector3(-8, 0, 0)
	floor.position = Vector3(0, -1.2, -4)
	world.add_child(floor)
	for i in range(8):
		var star := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.12 + (i % 3) * 0.05
		sph.height = sph.radius * 2
		star.mesh = sph
		star.material_override = toon_mat(Color("#fde68a") if i % 2 == 0 else UiFactory.CYAN)
		star.position = Vector3(-8 + i * 2.2, 1.5 + (i % 2) * 0.8, -3 - (i % 3))
		world.add_child(star)


static func build_pedestal(world: Node3D, unicorn_id: String) -> Dictionary:
	var plat := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.1
	cyl.bottom_radius = 1.25
	cyl.height = 0.35
	plat.mesh = cyl
	plat.material_override = toon_mat(Color("#1e293b"))
	plat.position = Vector3(0, 0.15, 0)
	world.add_child(plat)

	var glow := MeshInstance3D.new()
	var ring := CylinderMesh.new()
	ring.top_radius = 1.45
	ring.bottom_radius = 1.45
	ring.height = 0.05
	glow.mesh = ring
	glow.material_override = toon_mat(unicorn_accent(unicorn_id))
	glow.position = Vector3(0, 0.05, 0)
	world.add_child(glow)

	var spin := Node3D.new()
	spin.name = "SpinRoot"
	var unicorn := build_unicorn_model(unicorn_id, 0.72)
	unicorn.position = Vector3(0, 0.24, 0)
	spin.add_child(unicorn)
	world.add_child(spin)

	var cam := Camera3D.new()
	cam.position = Vector3(0, 2.2, 5.8)
	world.add_child(cam)
	cam.look_at(Vector3(0, 1.35, 0))

	return {"spin_root": spin, "camera": cam}
