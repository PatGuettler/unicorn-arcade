extends Control

const Rules = preload("res://scripts/games/gameplay_rules.gd")
const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const COLS := 8
const ROWS := 14

var board: Array[Array] = []
var falling: Array[Dictionary] = []
var cells: Array[Button] = []
var selected := Vector2i(-1, -1)
var score := 0
var level := 1
var drops_placed := 0
var active := false
var fall_accumulator := 0.0
var started_ms := 0
var last_spawn_col := -1
var hud_label: Label
var message_label: Label
var next_label: Label
var action_button: Button
var rng := RandomNumberGenerator.new()
var swipe_cell := Vector2i(-1, -1)
var swipe_start := Vector2.ZERO
var swipe_consumed := false


func _ready() -> void:
	rng.randomize()
	_build_ui()
	_start_game()


func _process(delta: float) -> void:
	if not active:
		return
	fall_accumulator += delta * 1000.0 * CompanionAbilityService.time_scale()
	var elapsed := (Time.get_ticks_msec() - started_ms) / 1000
	var interval := Rules.mathtris_drop_ms(level, drops_placed, elapsed)
	if fall_accumulator >= interval:
		fall_accumulator = 0.0
		_step_falling()


func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			swipe_cell = _cell_at(touch.position)
			swipe_start = touch.position
			swipe_consumed = false
		else:
			swipe_cell = Vector2i(-1, -1)
	elif event is InputEventScreenDrag and swipe_cell.x >= 0 and not swipe_consumed:
		var drag := event as InputEventScreenDrag
		var delta := drag.position - swipe_start
		if delta.length() >= 30.0:
			var direction := Vector2i(signi(roundi(delta.x)), 0) if absf(delta.x) > absf(delta.y) else Vector2i(0, signi(roundi(delta.y)))
			_try_swap(swipe_cell, swipe_cell + direction)
			swipe_consumed = true
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			if mouse.pressed:
				swipe_cell = _cell_at(mouse.position)
				swipe_start = mouse.position
				swipe_consumed = false
			else:
				swipe_cell = Vector2i(-1, -1)
	elif event is InputEventMouseMotion and swipe_cell.x >= 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not swipe_consumed:
		var motion := event as InputEventMouseMotion
		var delta := motion.position - swipe_start
		if delta.length() >= 30.0:
			var direction := Vector2i(signi(roundi(delta.x)), 0) if absf(delta.x) > absf(delta.y) else Vector2i(0, signi(roundi(delta.y)))
			_try_swap(swipe_cell, swipe_cell + direction)
			swipe_consumed = true


func _unhandled_key_input(event: InputEvent) -> void:
	if not active or not event is InputEventKey or not (event as InputEventKey).pressed:
		return
	match (event as InputEventKey).keycode:
		KEY_LEFT: _nudge(Vector2i.LEFT)
		KEY_RIGHT: _nudge(Vector2i.RIGHT)
		KEY_DOWN: _nudge(Vector2i.DOWN)


func _start_game() -> void:
	score = 0
	level = 1
	drops_placed = 0
	fall_accumulator = 0.0
	started_ms = Time.get_ticks_msec()
	last_spawn_col = -1
	selected = Vector2i(-1, -1)
	board = _make_board()
	_seed_bottom_pile()
	falling.clear()
	active = true
	action_button.hide()
	message_label.text = "Make true five-tile equations. Swipe neighboring settled tiles to swap."
	CompanionAbilityService.begin_level("mathtris", level)
	_spawn_wave()
	_refresh()


func _make_board() -> Array[Array]:
	var result: Array[Array] = []
	for row in ROWS:
		var line: Array[String] = []
		line.resize(COLS)
		line.fill("")
		result.append(line)
	return result


func _seed_bottom_pile() -> void:
	var fill_rows := mini(ROWS - 3, 5 + mini(2, level / 12))
	for attempt in 60:
		board = _make_board()
		var allowed := Rules.mathtris_allowed(level)
		for row in range(ROWS - fill_rows, ROWS):
			for col in COLS:
				board[row][col] = allowed[rng.randi_range(0, allowed.size() - 1)]
		if _find_matches().is_empty():
			return


func _spawn_wave() -> void:
	if not active:
		return
	var elapsed := (Time.get_ticks_msec() - started_ms) / 1000
	var wanted := Rules.mathtris_concurrent(elapsed, level)
	var open: Array[int] = []
	for col in COLS:
		if board[0][col] == "" and not _falling_at(0, col):
			open.append(col)
	if open.is_empty():
		_game_over()
		return
	for count in mini(wanted, open.size()):
		var choices := open.filter(func(col: int) -> bool: return col != last_spawn_col)
		if choices.is_empty():
			choices = open
		var col: int = choices[rng.randi_range(0, choices.size() - 1)]
		open.erase(col)
		last_spawn_col = col
		falling.append({"row": 0, "col": col, "value": _next_token()})
	_refresh()


func _next_token() -> String:
	var bag: Array[String] = []
	for token in Rules.mathtris_allowed(level):
		var copies := 2 if token in ["+", "=", "-"] else (3 if int(token) <= 5 else 1)
		for copy in copies:
			bag.append(token)
	return bag[rng.randi_range(0, bag.size() - 1)]


func _step_falling() -> void:
	if falling.is_empty():
		_spawn_wave()
		return
	var settled_cells: Array[Vector2i] = []
	falling.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["row"]) > int(b["row"]))
	for piece in falling.duplicate():
		var row := int(piece["row"])
		var col := int(piece["col"])
		if row + 1 >= ROWS or board[row + 1][col] != "" or _falling_at(row + 1, col, piece):
			# The value and its decorated tile settle together; no separate spawn box remains.
			board[row][col] = str(piece["value"])
			settled_cells.append(Vector2i(col, row))
			falling.erase(piece)
			drops_placed += 1
		else:
			piece["row"] = row + 1
	if not settled_cells.is_empty():
		var matches := _find_matches(settled_cells)
		if not matches.is_empty():
			_clear_matches(matches, 100, true)
	if active and falling.is_empty():
		_spawn_wave()
	_refresh()


func _nudge(direction: Vector2i) -> void:
	if not active or falling.is_empty():
		return
	var piece: Dictionary = falling.back()
	var target := Vector2i(int(piece["col"]), int(piece["row"])) + direction
	if target.x < 0 or target.x >= COLS or target.y < 0 or target.y >= ROWS:
		return
	if board[target.y][target.x] != "" or _falling_at(target.y, target.x, piece):
		return
	if direction.y > 0:
		piece["row"] = target.y
	else:
		piece["col"] = target.x
	_refresh()


func _cell_pressed(row: int, col: int) -> void:
	if not active or board[row][col] == "":
		return
	var here := Vector2i(col, row)
	if selected.x < 0:
		selected = here
		message_label.text = "Tap a neighbor, or slide this tile one space."
		_refresh()
		return
	if selected == here:
		selected = Vector2i(-1, -1)
		_refresh()
		return
	if not _try_swap(selected, here):
		selected = here
		_refresh()


func _try_swap(first: Vector2i, second: Vector2i) -> bool:
	if first.x < 0 or second.x < 0 or first.x >= COLS or second.x >= COLS or first.y < 0 or second.y < 0 or first.y >= ROWS or second.y >= ROWS:
		return false
	if abs(first.x - second.x) + abs(first.y - second.y) != 1:
		return false
	if board[first.y][first.x] == "" or board[second.y][second.x] == "":
		return false
	var value: String = board[first.y][first.x]
	board[first.y][first.x] = board[second.y][second.x]
	board[second.y][second.x] = value
	selected = Vector2i(-1, -1)
	_play_slide_swap(first, second, value, board[first.y][first.x])
	var matches := _find_matches([first, second])
	if matches.is_empty():
		message_label.text = "Tiles slid. No true equation yet."
	else:
		_clear_matches(matches, 150, true)
	_refresh()
	return true


func _find_matches(anchors: Array[Vector2i] = []) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	for row in ROWS:
		for start_col in range(COLS - 4):
			var cells_for_match: Array[Vector2i] = []
			var tokens: Array[String] = []
			for offset in 5:
				cells_for_match.append(Vector2i(start_col + offset, row))
				tokens.append(board[row][start_col + offset])
			if not tokens.has("") and Rules.equation_valid(tokens) and _touches_anchor(cells_for_match, anchors):
				matches.append({"cells": cells_for_match, "tokens": tokens, "orientation": "horizontal", "start": Vector2i(start_col, row)})
	for col in COLS:
		for start_row in range(ROWS - 4):
			var cells_for_match: Array[Vector2i] = []
			var tokens: Array[String] = []
			for offset in 5:
				cells_for_match.append(Vector2i(col, start_row + offset))
				tokens.append(board[start_row + offset][col])
			if not tokens.has("") and Rules.equation_valid(tokens) and _touches_anchor(cells_for_match, anchors):
				matches.append({"cells": cells_for_match, "tokens": tokens, "orientation": "vertical", "start": Vector2i(col, start_row)})
	return matches


func _touches_anchor(match_cells: Array[Vector2i], anchors: Array[Vector2i]) -> bool:
	if anchors.is_empty():
		return true
	for anchor in anchors:
		if anchor in match_cells:
			return true
	return false


func _find_equations() -> Array[Vector2i]:
	return _hits_from_matches(_find_matches())


func _hits_from_matches(matches: Array[Dictionary]) -> Array[Vector2i]:
	var unique := {}
	for equation in matches:
		for cell in equation["cells"]:
			unique[cell] = true
	var hits: Array[Vector2i] = []
	hits.assign(unique.keys())
	return hits


func _clear_matches(matches: Array[Dictionary], points_per_cell: int, allow_cascade: bool) -> void:
	if matches.is_empty():
		return
	var hits := _hits_from_matches(matches)
	var shown_tokens: Array[String] = []
	shown_tokens.assign(matches[0]["tokens"])
	message_label.text = "%s — TRUE!" % " ".join(shown_tokens)
	for hit in hits:
		board[hit.y][hit.x] = ""
	score += hits.size() * points_per_cell
	var cascade_anchors := _apply_gravity()
	level = score / 700 + 1
	if allow_cascade:
		var cascade := _find_matches(cascade_anchors)
		var guard := 0
		while not cascade.is_empty() and guard < 8:
			guard += 1
			var cascade_hits := _hits_from_matches(cascade)
			for hit in cascade_hits:
				board[hit.y][hit.x] = ""
			score += cascade_hits.size() * 175
			cascade_anchors = _apply_gravity()
			cascade = _find_matches(cascade_anchors)


func _apply_gravity() -> Array[Vector2i]:
	var settled: Array[Vector2i] = []
	for col in COLS:
		var stack: Array[String] = []
		for row in ROWS:
			if board[row][col] != "":
				stack.append(board[row][col])
		for row in ROWS:
			board[row][col] = ""
		for index in stack.size():
			var target_row := ROWS - stack.size() + index
			board[target_row][col] = stack[index]
			settled.append(Vector2i(col, target_row))
	return settled


func _activate_mystic_ability() -> void:
	if not active:
		return
	var kit: Array[String] = ["1", "+", "1", "=", "2"]
	var best_row := 0
	var most_empty := -1
	for row in ROWS:
		var empty := 0
		for col in 5:
			empty += 1 if board[row][col] == "" else 0
		if empty > most_empty:
			most_empty = empty
			best_row = row
	for col in 5:
		board[best_row][col] = kit[col]
	var matches := _find_matches([Vector2i(0, best_row)])
	_clear_matches(matches, 120, true)
	message_label.text = "Mystic completed 1 + 1 = 2 — a real equation!"
	_refresh()


func _show_hint() -> void:
	if not active or not AppState.spend_hint(level):
		return
	var example := "1 + 1 = 2"
	if "3" in Rules.mathtris_allowed(level):
		example = "1 + 2 = 3"
	if "-" in Rules.mathtris_allowed(level):
		example = "4 - 1 = 3"
	message_label.text = "Build %s across or down. Swipe only one space." % example


func _play_slide_swap(first: Vector2i, second: Vector2i, text_at_first: String, text_at_second: String) -> void:
	if AppState.setting("reduced_motion", false):
		return
	var button_a := cells[first.y * COLS + first.x]
	var button_b := cells[second.y * COLS + second.x]
	var delta := button_b.global_position - button_a.global_position
	var overlay_a := _swap_overlay(text_at_first, button_a.global_position, button_a.size)
	var overlay_b := _swap_overlay(text_at_second, button_b.global_position, button_b.size)
	add_child(overlay_a)
	add_child(overlay_b)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(overlay_a, "global_position", overlay_a.global_position + delta, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(overlay_b, "global_position", overlay_b.global_position - delta, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		overlay_a.queue_free()
		overlay_b.queue_free()
	)


func _swap_overlay(label_text: String, global_pos: Vector2, tile_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.global_position = global_pos
	panel.size = tile_size
	panel.add_theme_stylebox_override("panel", _tile_style(label_text, false, false))
	var label := Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_color", Color("172143"))
	panel.add_child(label)
	return panel


func _falling_at(row: int, col: int, except: Dictionary = {}) -> bool:
	for piece in falling:
		if piece == except:
			continue
		if int(piece["row"]) == row and int(piece["col"]) == col:
			return true
	return false


func _cell_at(global_point: Vector2) -> Vector2i:
	for row in ROWS:
		for col in COLS:
			if cells[row * COLS + col].get_global_rect().has_point(global_point):
				return Vector2i(col, row)
	return Vector2i(-1, -1)


func _game_over() -> void:
	active = false
	falling.clear()
	message_label.text = "Top out! Final score %d." % score
	action_button.text = "PLAY AGAIN"
	action_button.show()
	_refresh()


func _refresh() -> void:
	var falling_lookup := {}
	for piece in falling:
		falling_lookup[Vector2i(int(piece["col"]), int(piece["row"]))] = str(piece["value"])
	for row in ROWS:
		for col in COLS:
			var button := cells[row * COLS + col]
			var cell := Vector2i(col, row)
			var value: String = falling_lookup.get(cell, board[row][col])
			button.text = value
			button.disabled = value == "" or falling_lookup.has(cell)
			button.add_theme_stylebox_override("normal", _tile_style(value, falling_lookup.has(cell), selected == cell, row))
			button.add_theme_stylebox_override("disabled", _tile_style(value, falling_lookup.has(cell), false, row))
			button.add_theme_color_override("font_color", Color("172143"))
			button.add_theme_color_override("font_disabled_color", Color("172143") if value != "" else Color.TRANSPARENT)
	hud_label.text = "SCORE %d    •    LEVEL %d" % [score, level]
	next_label.text = "%d FALLING    •    %dms DROP" % [falling.size(), Rules.mathtris_drop_ms(level, drops_placed, (Time.get_ticks_msec() - started_ms) / 1000)]


func _tile_style(value: String, is_falling: bool, is_selected: bool, row: int = -1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var empty_spawn := value == "" and not is_falling and row == 0
	style.bg_color = Color("fff1a8") if is_falling else (Color("ffd2ed") if value != "" else Color(0.34, 0.45, 0.72, 0.08 if empty_spawn else 0.14))
	style.border_color = Color("62dce9") if is_selected else (Color("f4c75b") if value != "" else Color(0.60, 0.70, 0.92, 0.0 if empty_spawn else 0.22))
	style.set_border_width_all(3 if is_selected else (0 if empty_spawn else 2))
	style.set_corner_radius_all(9)
	style.shadow_color = Color(0.08, 0.03, 0.20, 0.45)
	style.shadow_size = 3 if value != "" else 0
	return style


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("16143f")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 6)
	add_child(root)
	hud_label = Label.new()
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	StorybookUI.apply_story_label(hud_label, Color("66e5ff"), 25, true)
	root.add_child(hud_label)
	next_label = Label.new()
	next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	StorybookUI.apply_story_label(next_label, Color("fff3d6"), 17, true)
	root.add_child(next_label)
	var grid_frame := PanelContainer.new()
	grid_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid_frame.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("221b58"), Color("e1ae4f"), 16))
	root.add_child(grid_frame)
	var grid := GridContainer.new()
	grid.columns = COLS
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	grid_frame.add_child(grid)
	for row in ROWS:
		for col in COLS:
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(44, 29)
			cell.add_theme_font_size_override("font_size", 19)
			cell.pressed.connect(_cell_pressed.bind(row, col))
			cell.set_meta("mathtris_tile", true)
			grid.add_child(cell)
			cells.append(cell)
	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	controls.add_theme_constant_override("separation", 8)
	root.add_child(controls)
	for definition in [{"label": "←", "direction": Vector2i.LEFT}, {"label": "↓", "direction": Vector2i.DOWN}, {"label": "→", "direction": Vector2i.RIGHT}]:
		var button := Button.new()
		button.text = definition["label"]
		StorybookUI.apply_game_action(button, 76)
		button.pressed.connect(_nudge.bind(definition["direction"]))
		controls.add_child(button)
	var hint := Button.new()
	hint.text = "HINT"
	StorybookUI.apply_game_action(hint, 110)
	hint.pressed.connect(_show_hint)
	controls.add_child(hint)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size.y = 52
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", Color("fff3d6"))
	root.add_child(message_label)
	action_button = Button.new()
	action_button.text = "PLAY AGAIN"
	StorybookUI.apply_game_action(action_button, 180)
	action_button.pressed.connect(_start_game)
	root.add_child(action_button)
