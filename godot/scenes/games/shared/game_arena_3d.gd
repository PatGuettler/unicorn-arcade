extends SubViewportContainer

signal choice_picked(value: String)
signal enemy_destroyed
signal player_hit

const PICK_LAYER := 8

var _viewport: SubViewport
var _world: Node3D
var _camera: Camera3D
var _targets: Node3D
var _accent := Color("#a78bfa")
var _mode := "idle"
var _spawn_clock := 0.0
var _fire_clock := 0.0
var _level := 1
var _companion: Node3D
var _anim_time := 0.0
var _companion_base_y := -1.0


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(0, 210)
	gui_input.connect(_on_gui_input)
	_build_world()


func configure(unicorn_id: String) -> void:
	_accent = World3DHelpers.unicorn_accent(unicorn_id)
	World3DHelpers.build_game_backdrop(_world, _accent)

	_companion = World3DHelpers.build_unicorn_model(unicorn_id, 0.52)
	_companion.position = Vector3(-3.6, _companion_base_y, 0.4)
	_companion.rotation_degrees.y = 18
	_world.add_child(_companion)


func present_choices(values: Array) -> void:
	_mode = "choices"
	_clear_targets()
	var count := mini(values.size(), 6)
	for i in count:
		var col := i % 3
		var row := i / 3
		var pos := Vector3((col - 1) * 2.3, 1.15 - row * 1.6, -1.0 - row)
		_spawn_choice(str(values[i]), pos)


func present_currency(values: Array, coins: bool) -> void:
	_mode = "currency"
	_clear_targets()
	var count := mini(values.size(), 6)
	for i in count:
		var col := i % 3
		var row := i / 3
		var pos := Vector3((col - 1) * 2.25, 1.0 - row * 1.5, -1.0 - row)
		_spawn_currency(int(values[i]), coins, pos)


func clear_action() -> void:
	_mode = "idle"
	_clear_targets()


func start_space(level: int) -> void:
	_mode = "space"
	_level = level
	_spawn_clock = 0.0
	_fire_clock = 0.15
	_clear_targets()
	if _companion:
		_companion.position.x = 0.0
	for i in 3:
		_spawn_enemy(-2.0 - i * 2.0)


func stop_space() -> void:
	if _mode == "space":
		_mode = "idle"
	if _companion:
		_companion.position.x = -3.6
	_clear_targets()


func fire_magic() -> void:
	if _companion == null:
		return
	var projectile := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.13
	sphere.height = 0.26
	projectile.mesh = sphere
	projectile.material_override = World3DHelpers.toon_mat(Color("#fde68a"))
	projectile.position = _companion.position + Vector3(0.8, 1.4, 0)
	_world.add_child(projectile)
	var destination := Vector3(0.8, 1.0, -1.8)
	var tween := create_tween()
	tween.tween_property(projectile, "position", destination, 0.24)
	tween.tween_callback(func():
		_burst_at(destination)
		projectile.queue_free()
	)


func set_companion_progress(progress: float) -> void:
	if _companion:
		_companion_base_y = -1.0 + clampf(progress, 0.0, 1.0) * 2.0
		_companion.position.y = _companion_base_y


func _process(delta: float) -> void:
	_anim_time += delta
	if _companion and not bool(SaveManager.get_setting("reduced_motion", false)):
		_companion.position.y = _companion_base_y + sin(_anim_time * 2.2) * 0.08
		_companion.rotation_degrees.z = sin(_anim_time * 1.4) * 1.5
	if _mode != "space":
		return
	_fire_clock -= delta
	if _fire_clock <= 0.0:
		_fire_clock = maxf(0.18, 0.48 - _level * 0.012)
		_auto_fire()
	_spawn_clock -= delta
	if _spawn_clock <= 0.0 and _targets.get_child_count() < 6:
		_spawn_enemy(-8.0)
		_spawn_clock = maxf(0.38, 0.95 - _level * 0.035)

	for enemy_variant in _targets.get_children():
		var enemy := enemy_variant as Node3D
		if enemy == null or not enemy.has_meta("speed"):
			continue
		var speed: float = float(enemy.get_meta("speed"))
		enemy.position.z += speed * delta
		enemy.position.x += sin(Time.get_ticks_msec() * 0.003 + float(enemy.get_instance_id())) * delta
		enemy.rotate_y(delta * 1.8)
		if enemy.position.z > 5.5:
			enemy.queue_free()
			player_hit.emit()


func _build_world() -> void:
	_viewport = SubViewport.new()
	_viewport.handle_input_locally = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.size = Vector2i(780, 420)
	add_child(_viewport)

	_world = Node3D.new()
	_viewport.add_child(_world)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#020617")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#c4b5fd")
	env.ambient_light_energy = 0.7
	env_node.environment = env
	_world.add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -25, 0)
	sun.light_energy = 1.3
	_world.add_child(sun)

	_camera = Camera3D.new()
	_camera.position = Vector3(0, 2.2, 8.5)
	_world.add_child(_camera)
	_camera.look_at(Vector3(0, 0.5, -1.5))

	_targets = Node3D.new()
	_targets.name = "Targets"
	_world.add_child(_targets)


func _spawn_choice(value: String, pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	root.set_meta("value", value)

	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.85, 1.15, 0.28)
	mesh.mesh = box
	mesh.material_override = World3DHelpers.toon_mat(_accent)
	root.add_child(mesh)

	var label := Label3D.new()
	label.text = value
	label.font_size = 42
	label.outline_size = 10
	label.position = Vector3(0, 0, 0.18)
	label.fixed_size = true
	label.width = 180
	root.add_child(label)

	_add_pick_area(root, Vector3(1.9, 1.2, 0.7))
	_targets.add_child(root)


func _spawn_currency(value: int, coins: bool, pos: Vector3) -> void:
	var root := Node3D.new()
	root.position = pos
	root.set_meta("value", str(value))

	var mesh := MeshInstance3D.new()
	if coins:
		var coin := CylinderMesh.new()
		coin.top_radius = 0.55
		coin.bottom_radius = 0.55
		coin.height = 0.12
		mesh.mesh = coin
		mesh.rotation_degrees.x = 74
		mesh.material_override = World3DHelpers.toon_mat(
			Color("#fbbf24") if value >= 10 else Color("#d1d5db")
		)
	else:
		var bill := BoxMesh.new()
		bill.size = Vector3(1.8, 0.9, 0.09)
		mesh.mesh = bill
		mesh.material_override = World3DHelpers.toon_mat(Color("#34d399"))
	root.add_child(mesh)

	var label := Label3D.new()
	label.text = "%d¢" % value if coins else "$%d" % value
	label.font_size = 42
	label.outline_size = 8
	label.position.z = 0.18
	root.add_child(label)
	_add_pick_area(root, Vector3(1.9, 1.15, 0.8))
	_targets.add_child(root)


func _spawn_enemy(z_pos: float) -> void:
	var root := Node3D.new()
	root.position = Vector3(randf_range(-3.0, 3.0), randf_range(-0.4, 2.2), z_pos)
	root.set_meta("enemy", true)
	root.set_meta("speed", randf_range(1.7, 2.7) + _level * 0.08)
	root.set_meta("hp", 2 if _level >= 6 and randf() < 0.35 else 1)

	var mesh := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = randf_range(0.35, 0.62)
	shape.height = shape.radius * 2.0
	mesh.mesh = shape
	mesh.material_override = World3DHelpers.toon_mat(
		Color("#fb7185") if randi() % 2 == 0 else Color("#fbbf24")
	)
	root.add_child(mesh)

	var eye := Label3D.new()
	eye.text = "👾"
	eye.font_size = 48
	eye.position.z = 0.45
	root.add_child(eye)

	_add_pick_area(root, Vector3(1.4, 1.4, 1.4))
	_targets.add_child(root)


func _add_pick_area(root: Node3D, size: Vector3) -> void:
	var area := Area3D.new()
	area.collision_layer = PICK_LAYER
	area.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	area.add_child(collision)
	root.add_child(area)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_pick(event.position)
	elif event is InputEventMouseMotion and _mode == "space":
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_move_ship(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		_pick(event.position)
	elif event is InputEventScreenDrag and _mode == "space":
		_move_ship(event.position)


func _move_ship(local_pos: Vector2) -> void:
	if _companion == null or size.x <= 0.0:
		return
	var normalized := clampf(local_pos.x / size.x, 0.0, 1.0)
	_companion.position.x = lerpf(-3.5, 3.5, normalized)


func _auto_fire() -> void:
	if _companion == null:
		return
	var target: Node3D
	var best_distance := INF
	for enemy_variant in _targets.get_children():
		var enemy := enemy_variant as Node3D
		if enemy == null or not enemy.has_meta("enemy") or enemy.is_queued_for_deletion():
			continue
		var lane_distance := absf(enemy.position.x - _companion.position.x)
		if lane_distance < 0.9 and lane_distance < best_distance:
			best_distance = lane_distance
			target = enemy
	if target == null:
		return

	var projectile := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.09
	sphere.height = 0.28
	projectile.mesh = sphere
	projectile.material_override = World3DHelpers.toon_mat(UiFactory.CYAN)
	projectile.position = _companion.position + Vector3(0, 1.2, -0.2)
	_world.add_child(projectile)
	var destination := target.position
	var tween := create_tween()
	tween.tween_property(projectile, "position", destination, 0.16)
	tween.tween_callback(func():
		projectile.queue_free()
		if not is_instance_valid(target) or target.is_queued_for_deletion():
			return
		var hp := int(target.get_meta("hp", 1)) - 1
		target.set_meta("hp", hp)
		if hp <= 0:
			_burst_at(target.position)
			target.queue_free()
			enemy_destroyed.emit()
	)


func _pick(local_pos: Vector2) -> void:
	var screen_pos := local_pos
	if size.x > 0.0 and size.y > 0.0:
		screen_pos *= Vector2(_viewport.size) / size
	var from := _camera.project_ray_origin(screen_pos)
	var to := from + _camera.project_ray_normal(screen_pos) * 100.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = PICK_LAYER
	var hit := _viewport.world_3d.direct_space_state.intersect_ray(query)
	if not hit.has("collider"):
		return
	var area := hit.collider as Area3D
	if area == null:
		return
	var target := area.get_parent() as Node3D
	if target == null:
		return
	if bool(target.get_meta("enemy", false)):
		_burst_at(target.position)
		target.queue_free()
		enemy_destroyed.emit()
	else:
		choice_picked.emit(str(target.get_meta("value", "")))


func _burst_at(pos: Vector3) -> void:
	for i in 5:
		var spark := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.08
		sphere.height = 0.16
		spark.mesh = sphere
		spark.position = pos + Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), 0.0)
		spark.material_override = World3DHelpers.toon_mat(Color("#fde68a"))
		_world.add_child(spark)
		var tween := create_tween()
		tween.tween_property(spark, "scale", Vector3.ZERO, 0.28)
		tween.tween_callback(spark.queue_free)


func _clear_targets() -> void:
	for child in _targets.get_children():
		child.queue_free()
