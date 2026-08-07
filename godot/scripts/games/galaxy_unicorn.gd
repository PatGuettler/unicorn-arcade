extends Control

const Rules = preload("res://scripts/games/gameplay_rules.gd")
const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const RoomItemPreviewScene = preload("res://scripts/meta/room_item_preview_3d.gd")

const ENEMIES := [
	{"kind": "storm_cloud", "hp": 1, "speed": 0.00035, "score": 10, "radius": 18.0},
	{"kind": "shadow_star", "hp": 1, "speed": 0.00050, "score": 15, "radius": 16.0, "zigzag": true},
	{"kind": "enchanted_comet", "hp": 2, "speed": 0.00028, "score": 25, "radius": 20.0},
	{"kind": "cursed_moon", "hp": 2, "speed": 0.00040, "score": 30, "radius": 18.0},
	{"kind": "eclipse_crown", "hp": 8, "speed": 0.00015, "score": 100, "radius": 32.0, "boss": true},
]

var level := 1
var target_kills := 0
var kills := 0
var score := 0
var lives := 3
var active := false
var player_x := 0.5
var bullets: Array[Dictionary] = []
var bolt_flashes: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var pickups: Array[Dictionary] = []
var fire_cooldown := 0.0
var spawn_timer := 0.0
var invulnerable := 0.0
var boss_spawned := false
var opening_left := 0
var opening_timer := 0.0
var started_ms := 0
var hud_label: Label
var message_label: Label
var action_button: Button
var player_preview: RoomItemPreview3D


func _ready() -> void:
	level = AppState.current_level("galaxy_unicorn")
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	_start_level(level)


func _process(delta: float) -> void:
	if not active or size.x < 1.0 or size.y < 1.0:
		return
	var ms := delta * 1000.0 * CompanionAbilityService.time_scale()
	fire_cooldown -= ms
	spawn_timer += ms
	invulnerable = maxf(0.0, invulnerable - ms)
	opening_timer -= ms
	if opening_left > 0 and opening_timer <= 0.0:
		_spawn_enemy(false)
		opening_left -= 1
		opening_timer = 400.0
	if fire_cooldown <= 0.0:
		fire_cooldown = Rules.galaxy_fire_ms(level)
		var muzzle := Vector2(player_x * size.x, size.y * 0.88 - 28.0)
		bullets.append({"position": muzzle, "previous_position": muzzle, "speed": -0.55 - level * 0.02})
		# The original physics speed crosses most of a tall phone in one frame. Keep
		# that gameplay timing, but retain a short visual echo so the rainbow blast is
		# legible instead of appearing for a single frame.
		bolt_flashes.append({"x": muzzle.x, "start_y": muzzle.y, "age": 0.0, "life": 260.0})
	if spawn_timer >= Rules.galaxy_spawn_ms(level) and enemies.size() < 8 + level:
		spawn_timer = 0.0
		_spawn_enemy(false)
		if randf() < 0.25 + level * 0.03:
			_spawn_enemy(false)
	_move_world(ms)
	_resolve_collisions()
	_update_hud()
	if is_instance_valid(player_preview):
		player_preview.position = Vector2(player_x * size.x - 78.0, size.y * 0.88 - 92.0)
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		player_x = clampf(event.position.x / maxf(1.0, size.x), 0.08, 0.92)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		player_x = clampf(event.position.x / maxf(1.0, size.x), 0.08, 0.92)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		player_x = clampf(event.position.x / maxf(1.0, size.x), 0.08, 0.92)


func _start_level(for_level: int) -> void:
	level = for_level
	target_kills = Rules.galaxy_target(level)
	kills = 0
	score = 0
	lives = 3
	player_x = 0.5
	bullets.clear()
	bolt_flashes.clear()
	enemies.clear()
	pickups.clear()
	fire_cooldown = 0.0
	spawn_timer = 0.0
	invulnerable = 0.0
	boss_spawned = false
	opening_left = 3 + level
	opening_timer = 0.0
	started_ms = Time.get_ticks_msec()
	active = true
	CompanionAbilityService.begin_level("galaxy_unicorn", level)
	var companion_name := str(AppState.equipped_companion()).capitalize()
	message_label.text = "Drag %s left and right. Rainbow bolts fire automatically." % companion_name
	action_button.hide()
	_update_hud()


func _spawn_enemy(force_boss: bool) -> void:
	var is_boss := force_boss or (level % 5 == 0 and not boss_spawned and kills >= target_kills * 0.6)
	var template: Dictionary
	if is_boss:
		template = ENEMIES[4]
	else:
		var roll := randf()
		var weights := [0.7, 0.2, 0.1, 0.0] if level <= 2 else ([0.4, 0.25, 0.2, 0.15] if level <= 5 else [0.25, 0.25, 0.25, 0.25])
		var accumulator := 0.0
		template = ENEMIES[0]
		for index in 4:
			accumulator += weights[index]
			if roll <= accumulator:
				template = ENEMIES[index]
				break
	var hp := int(template["hp"]) + level / 6
	var enemy := template.duplicate(true)
	enemy["speed"] = float(template["speed"]) * Rules.galaxy_enemy_speed_scale(level)
	enemy["position"] = Vector2(randf_range(0.1, 0.9) * size.x, -30.0)
	enemy["hp"] = hp
	enemy["max_hp"] = hp
	enemy["phase"] = randf() * TAU
	enemies.append(enemy)
	if is_boss:
		boss_spawned = true


func _move_world(ms: float) -> void:
	for bullet in bullets:
		var bullet_position: Vector2 = bullet["position"]
		bullet["previous_position"] = bullet_position
		bullet_position.y += float(bullet["speed"]) * size.y * (ms / 16.0)
		bullet["position"] = bullet_position
	bullets = bullets.filter(func(item: Dictionary) -> bool: return item["position"].y > -24.0)
	for flash in bolt_flashes:
		flash["age"] = float(flash["age"]) + ms
	bolt_flashes = bolt_flashes.filter(func(item: Dictionary) -> bool: return float(item["age"]) < float(item["life"]))
	var fall_factor := Rules.galaxy_fall_frame_factor()
	for enemy in enemies:
		var enemy_position: Vector2 = enemy["position"]
		enemy_position.y += float(enemy["speed"]) * size.y * (ms / 16.0) * fall_factor
		if enemy.get("zigzag", false):
			enemy_position.x += sin(float(enemy["phase"]) + Time.get_ticks_msec() * 0.003) * 0.8
		enemy["position"] = enemy_position
	for pickup in pickups:
		var pickup_position: Vector2 = pickup["position"]
		pickup_position.y += 0.0002 * size.y * (ms / 16.0) * fall_factor
		pickup["position"] = pickup_position


func _resolve_collisions() -> void:
	var spent_bullets: Array[Dictionary] = []
	for bullet in bullets:
		for enemy in enemies:
			var previous: Vector2 = bullet.get("previous_position", bullet["position"])
			if int(enemy["hp"]) > 0 and _segment_hits_circle(previous, bullet["position"], enemy["position"], float(enemy["radius"]) + 8.0):
				enemy["hp"] = int(enemy["hp"]) - 1
				spent_bullets.append(bullet)
				if int(enemy["hp"]) <= 0:
					kills += 1
					score += int(enemy["score"])
					if randf() < 0.12:
						pickups.append({"position": enemy["position"], "kind": "heal" if randf() < 0.5 else "rapid", "radius": 14.0})
				break
	for bullet in spent_bullets:
		bullets.erase(bullet)
	enemies = enemies.filter(func(item: Dictionary) -> bool: return int(item["hp"]) > 0 and item["position"].y < size.y + 50.0)
	var player := Vector2(player_x * size.x, size.y * 0.88)
	for pickup in pickups.duplicate():
		if pickup["position"].distance_to(player) < 36.0:
			if pickup["kind"] == "heal":
				lives = mini(5, lives + 1)
			else:
				fire_cooldown = -200.0
			pickups.erase(pickup)
		elif pickup["position"].y > size.y + 20.0:
			pickups.erase(pickup)
	if invulnerable <= 0.0:
		for enemy in enemies:
			if enemy["position"].distance_to(player) < float(enemy["radius"]) + 24.0:
				_lose_life(1500.0)
				break
	if active and invulnerable <= 0.0:
		for enemy in enemies:
			if enemy["position"].y > size.y * 0.92:
				enemy["hp"] = 0
				_lose_life(1200.0)
				break
	enemies = enemies.filter(func(item: Dictionary) -> bool: return int(item["hp"]) > 0)
	if active and kills >= target_kills:
		active = false
		var reward := AppState.complete_level("galaxy_unicorn", level, Time.get_ticks_msec() - started_ms)
		message_label.text = "Sector cleared! +%d coins" % reward
		action_button.text = "Next Sector"
		action_button.show()


func _segment_hits_circle(start: Vector2, finish: Vector2, center: Vector2, radius: float) -> bool:
	var segment := finish - start
	var length_squared := segment.length_squared()
	if length_squared <= 0.0001:
		return start.distance_to(center) <= radius
	var along := clampf((center - start).dot(segment) / length_squared, 0.0, 1.0)
	return (start + segment * along).distance_to(center) <= radius


func _lose_life(duration: float) -> void:
	lives -= 1
	invulnerable = duration
	if lives <= 0:
		active = false
		message_label.text = "The gloom broke through. Try this sector again."
		action_button.text = "Retry"
		action_button.show()


func _mystic_blast() -> void:
	if not active or enemies.is_empty():
		return
	var target: Dictionary = enemies[0]
	for enemy in enemies:
		if float(enemy["position"].y) > float(target["position"].y):
			target = enemy
	kills += 1
	score += int(target["score"])
	target["hp"] = 0
	enemies.erase(target)
	message_label.text = "Mystic turned the nearest threat into stardust!"
	_resolve_collisions()


func _draw() -> void:
	# Star field and nebula haze.
	draw_rect(Rect2(Vector2.ZERO, size), Color("160d3b"))
	for index in 48:
		var x := fmod(index * 97.0, 1000.0) / 1000.0 * size.x
		var y := fmod(index * 53.0 + Time.get_ticks_msec() * (0.01 + (index % 5) * 0.003), maxf(1.0, size.y))
		draw_circle(Vector2(x, y), 1.0 + index % 3, Color(1, 1, 1, 0.35 + (index % 4) * 0.12))
	for flash in bolt_flashes:
		var progress := clampf(float(flash["age"]) / float(flash["life"]), 0.0, 1.0)
		var alpha := 1.0 - smoothstep(0.72, 1.0, progress)
		var tip := Vector2(float(flash["x"]), float(flash["start_y"]) - progress * size.y * 0.92)
		draw_line(tip + Vector2(0, 30), tip - Vector2(0, 30), Color(0.35, 0.88, 1.0, alpha * 0.24), 12.0)
		draw_line(tip + Vector2(0, 24), tip + Vector2(0, 8), Color(0.13, 0.83, 0.93, alpha), 5.0)
		draw_line(tip + Vector2(0, 8), tip - Vector2(0, 8), Color(0.91, 0.47, 0.98, alpha), 5.0)
		draw_line(tip - Vector2(0, 8), tip - Vector2(0, 24), Color(0.99, 0.88, 0.28, alpha), 5.0)
		draw_circle(tip - Vector2(0, 24), 3.5, Color(1.0, 1.0, 1.0, alpha))
	for enemy in enemies:
		_draw_themed_enemy(enemy)
		if int(enemy["max_hp"]) > 1:
			var width := float(enemy["radius"]) * 1.6
			draw_rect(Rect2(enemy["position"] + Vector2(-width / 2, -float(enemy["radius"]) - 9), Vector2(width, 4)), Color("24182f"))
			draw_rect(Rect2(enemy["position"] + Vector2(-width / 2, -float(enemy["radius"]) - 9), Vector2(width * float(enemy["hp"]) / float(enemy["max_hp"]), 4)), Color("f472b6"))
	for pickup in pickups:
		_draw_themed_pickup(pickup)
	var player := Vector2(player_x * size.x, size.y * 0.88)
	draw_circle(player + Vector2(0, 31), 20.0, Color(0.04, 0.02, 0.14, 0.46))


func _draw_themed_enemy(enemy: Dictionary) -> void:
	var center: Vector2 = enemy["position"]
	var radius := float(enemy["radius"])
	match str(enemy["kind"]):
		"storm_cloud":
			for cloud in [
				[Vector2(-0.48, 0.10), 0.54], [Vector2(0.0, -0.14), 0.72],
				[Vector2(0.52, 0.10), 0.50], [Vector2(0.0, 0.24), 0.76],
			]:
				draw_circle(center + cloud[0] * radius, float(cloud[1]) * radius, Color("8d86bd"))
			draw_colored_polygon(PackedVector2Array([
				center + Vector2(-0.08, 0.34) * radius,
				center + Vector2(0.20, 0.34) * radius,
				center + Vector2(0.02, 0.72) * radius,
				center + Vector2(0.30, 0.72) * radius,
				center + Vector2(-0.18, 1.18) * radius,
			]), Color("ffe172"))
		"shadow_star":
			draw_colored_polygon(_star_points(center, radius, radius * 0.43, 5), Color("d866e7"))
			draw_circle(center, radius * 0.24, Color("5a2b7c"))
		"enchanted_comet":
			for width in [12.0, 7.0, 3.0]:
				draw_line(center + Vector2(-radius * 1.65, -radius * 0.70), center - Vector2(radius * 0.30, radius * 0.16), Color(0.45, 0.86, 1.0, 0.20 + width * 0.045), width)
			draw_circle(center, radius, Color("79dcf2"))
			draw_arc(center, radius * 0.70, 0.0, TAU, 24, Color("fff3d6"), 3.0)
		"cursed_moon":
			draw_circle(center, radius, Color("e8e4ff"))
			draw_circle(center + Vector2(radius * 0.43, -radius * 0.18), radius * 0.82, Color("58417c"))
			for crater in [Vector2(-0.46, -0.18), Vector2(-0.34, 0.38)]:
				draw_circle(center + crater * radius, radius * 0.12, Color("aaa1d2"))
		"eclipse_crown":
			draw_circle(center, radius, Color("f3b7ff"))
			draw_circle(center, radius * 0.72, Color("261240"))
			draw_arc(center, radius * 0.88, 0.0, TAU, 32, Color("ffe172"), 4.0)
			for angle in [-2.45, -1.85, -1.28, -0.70]:
				var point := center + Vector2.from_angle(angle) * radius * 1.16
				draw_colored_polygon(PackedVector2Array([
					center + Vector2.from_angle(angle - 0.18) * radius * 0.78,
					point,
					center + Vector2.from_angle(angle + 0.18) * radius * 0.78,
				]), Color("ffe172"))
		_:
			draw_colored_polygon(_star_points(center, radius, radius * 0.45, 5), Color("d866e7"))


func _draw_themed_pickup(pickup: Dictionary) -> void:
	var center: Vector2 = pickup["position"]
	if pickup["kind"] == "heal":
		draw_circle(center + Vector2(-6, -4), 7.5, Color("ff7faf"))
		draw_circle(center + Vector2(6, -4), 7.5, Color("ff7faf"))
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-13, -2), center + Vector2(13, -2), center + Vector2(0, 15),
		]), Color("ff7faf"))
	else:
		draw_circle(center, 17.0, Color(0.35, 0.88, 1.0, 0.25))
		draw_colored_polygon(_star_points(center, 14.0, 6.0, 5), Color("ffe45e"))
		draw_circle(center, 3.5, Color.WHITE)


func _star_points(center: Vector2, outer_radius: float, inner_radius: float, points: int) -> PackedVector2Array:
	var vertices := PackedVector2Array()
	for index in points * 2:
		var radius := outer_radius if index % 2 == 0 else inner_radius
		var angle := -PI * 0.5 + float(index) * PI / float(points)
		vertices.append(center + Vector2.from_angle(angle) * radius)
	return vertices


func _update_hud() -> void:
	hud_label.text = "LEVEL %d    LIVES %d    %d / %d    SCORE %d" % [level, lives, kills, target_kills, score]


func _build_ui() -> void:
	player_preview = RoomItemPreviewScene.new()
	player_preview.name = "GalaxyEquippedCompanion"
	player_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	player_preview.size = Vector2(156, 124)
	player_preview.setup({"id": "companion_%s" % AppState.equipped_companion(), "category": "companions", "animate": true, "presentation": "marketplace"})
	player_preview.z_index = 20
	add_child(player_preview)
	hud_label = Label.new()
	hud_label.name = "LegacyGalaxyHUD"
	hud_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_label.position.y = 205
	hud_label.hide()
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_label.add_theme_font_size_override("font_size", 21)
	hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud_label)
	message_label = Label.new()
	message_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	message_label.position.y = -100
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_color", Color("ffe172"))
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(message_label)
	var actions := HBoxContainer.new()
	actions.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	actions.position.y = -62
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(actions)
	action_button = Button.new()
	StorybookUI.apply_game_action(action_button, 160)
	action_button.pressed.connect(func() -> void: _start_level(level + 1 if action_button.text == "Next Sector" else level))
	actions.add_child(action_button)
	var back := Button.new()
	StorybookUI.apply_game_action(back, 150)
	back.text = "Arcade"
	back.pressed.connect(func() -> void:
		AppState.set_shell_destination("category", "Arcade")
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	actions.add_child(back)
