extends Control

const Rules = preload("res://scripts/games/gameplay_rules.gd")
const COLS := 8
const ROWS := 14
const SOLVES_FOR_POWER := 3

var board: Array[Array] = []
var falling: Array[Dictionary] = []
var cells: Array[Button] = []
var selected := Vector2i(-1, -1)
var score := 0
var level := 1
var drops_placed := 0
var clear_charge := 0
var power_ready := false
var active := false
var fall_accumulator := 0.0
var started_ms := 0
var slow_until_ms := 0
var last_spawn_col := -1
var companion_id := "sparkle"
var hud_label: Label
var message_label: Label
var next_label: Label
var power_button: Button
var action_button: Button
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.randomize()
	companion_id = str(AppState.data.get("player", {}).get("equipped_companion", "sparkle"))
	_build_ui()
	_start_game()


func _unhandled_key_input(event: InputEvent) -> void:
	if not active or not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed:
		return
	if key_event.keycode == KEY_LEFT:
		_nudge(Vector2i.LEFT)
	elif key_event.keycode == KEY_RIGHT:
		_nudge(Vector2i.RIGHT)
	elif key_event.keycode == KEY_DOWN:
		_nudge(Vector2i.DOWN)


func _process(delta: float) -> void:
	if not active:
		return
	fall_accumulator += delta * 1000.0
	var elapsed := (Time.get_ticks_msec() - started_ms) / 1000
	var interval := Rules.mathtris_drop_ms(level, drops_placed, elapsed)
	if Time.get_ticks_msec() < slow_until_ms:
		interval *= 2
	if fall_accumulator >= interval:
		fall_accumulator = 0.0
		_step_falling()


func _start_game() -> void:
	score = 0
	level = 1
	drops_placed = 0
	clear_charge = 0
	power_ready = false
	fall_accumulator = 0.0
	started_ms = Time.get_ticks_msec()
	slow_until_ms = 0
	last_spawn_col = -1
	selected = Vector2i(-1, -1)
	board = _make_board()
	_seed_bottom_pile()
	falling.clear()
	active = true
	action_button.hide()
	message_label.text = "Make five-block equations across or down. Tap two neighbors to swap."
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
		if _find_equations().is_empty():
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
	var allowed := Rules.mathtris_allowed(level)
	# Match the React bag's useful bias toward digits while retaining operators.
	var bag: Array[String] = []
	for token in allowed:
		var copies := 2 if token in ["+", "=", "-"] else (3 if int(token) <= 5 else 1)
		for copy in copies:
			bag.append(token)
	return bag[rng.randi_range(0, bag.size() - 1)]


func _step_falling() -> void:
	if falling.is_empty():
		_spawn_wave()
		return
	var settled := false
	# Lowest pieces move first so simultaneous drops do not overlap.
	falling.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["row"]) > int(b["row"]))
	for piece in falling.duplicate():
		var row := int(piece["row"])
		var col := int(piece["col"])
		if row + 1 >= ROWS or board[row + 1][col] != "" or _falling_at(row + 1, col, piece):
			board[row][col] = str(piece["value"])
			falling.erase(piece)
			drops_placed += 1
			settled = true
		else:
			piece["row"] = row + 1
	if settled:
		var hits := _find_equations()
		if not hits.is_empty():
			_clear_hits(hits, 100)
		elif _top_row_full():
			_game_over()
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
		message_label.text = "Now tap a neighboring fixed block."
		_refresh()
		return
	if abs(selected.x - col) + abs(selected.y - row) != 1:
		selected = here
		_refresh()
		return
	var first: String = board[selected.y][selected.x]
	board[selected.y][selected.x] = board[row][col]
	board[row][col] = first
	selected = Vector2i(-1, -1)
	var hits := _find_equations()
	if not hits.is_empty():
		_clear_hits(hits, 150)
	else:
		message_label.text = "Blocks swapped. Keep building an equation."
	_refresh()


func _find_equations() -> Array[Vector2i]:
	var unique := {}
	for row in ROWS:
		for start_col in range(COLS - 4):
			var tokens: Array[String] = []
			for offset in 5:
				tokens.append(board[row][start_col + offset])
			if not tokens.has("") and Rules.equation_valid(tokens):
				for offset in 5:
					unique[Vector2i(start_col + offset, row)] = true
	for col in COLS:
		for start_row in range(ROWS - 4):
			var tokens: Array[String] = []
			for offset in 5:
				tokens.append(board[start_row + offset][col])
			if not tokens.has("") and Rules.equation_valid(tokens):
				for offset in 5:
					unique[Vector2i(col, start_row + offset)] = true
	var result: Array[Vector2i] = []
	result.assign(unique.keys())
	return result


func _clear_hits(hits: Array[Vector2i], points_per_cell: int) -> void:
	for hit in hits:
		board[hit.y][hit.x] = ""
	score += hits.size() * points_per_cell
	clear_charge += 1
	if clear_charge >= SOLVES_FOR_POWER:
		clear_charge = 0
		power_ready = true
		message_label.text = "Sparkle Burst is charged!"
	else:
		message_label.text = "Equation cleared!"
	_apply_gravity()
	level = score / 700 + 1
	if _top_row_full():
		_game_over()


func _apply_gravity() -> void:
	for col in COLS:
		var stack: Array[String] = []
		for row in ROWS:
			if board[row][col] != "":
				stack.append(board[row][col])
		for row in ROWS:
			board[row][col] = ""
		for index in stack.size():
			board[ROWS - stack.size() + index][col] = stack[index]


func _activate_power() -> void:
	if not active or not power_ready:
		return
	var hits: Array[Vector2i] = []
	var points := 0
	match companion_id:
		"rainbow":
			for col in COLS:
				if board[ROWS - 1][col] != "":
					hits.append(Vector2i(col, ROWS - 1))
			points = hits.size() * 35
			message_label.text = "Rainbow Row! Bottom row cleared."
		"star":
			var best_col := 0
			var best_count := -1
			for col in COLS:
				var count := 0
				for row in ROWS:
					count += 1 if board[row][col] != "" else 0
				if count > best_count:
					best_count = count
					best_col = col
			for row in ROWS:
				if board[row][best_col] != "":
					hits.append(Vector2i(best_col, row))
			points = hits.size() * 45
			message_label.text = "Star Beam! Full column cleared."
		"cloud":
			slow_until_ms = Time.get_ticks_msec() + 18000
			score += 50
			power_ready = false
			message_label.text = "Cloud Float! Drops slow for 18 seconds."
			_refresh()
			return
		"mystic":
			for row in ROWS:
				for col in COLS:
					if board[row][col] != "":
						hits.append(Vector2i(col, row))
			points = 400 + hits.size() * 25
			message_label.text = "Mystic Clear! Board cleared."
		"dream":
			hits = _force_equation()
			points = hits.size() * 120
			message_label.text = "Dream Fix! A near-equation was completed."
		_:
			hits = _find_equations()
			if hits.is_empty():
				hits = _force_equation()
			points = hits.size() * 80
			message_label.text = "Sparkle Burst! Equation fixed and cleared."
	if hits.is_empty():
		message_label.text = "No blocks for that power yet."
		return
	power_ready = false
	for hit in hits:
		board[hit.y][hit.x] = ""
	score += points
	_apply_gravity()
	level = score / 700 + 1
	_refresh()


func _force_equation() -> Array[Vector2i]:
	var kit: Array[String] = ["1", "+", "1", "=", "2"]
	for col in 5:
		board[ROWS - 1][col] = kit[col]
	return _find_equations()


func _show_hint() -> void:
	if not active or not AppState.spend_hint(level):
		return
	var allowed := Rules.mathtris_allowed(level)
	var example := "1 + 1 = 2"
	if "3" in allowed:
		example = "1 + 2 = 3"
	if "-" in allowed:
		example = "4 - 1 = 3"
	message_label.text = "Try making %s across or down." % example


func _falling_at(row: int, col: int, except: Dictionary = {}) -> bool:
	for piece in falling:
		if piece == except:
			continue
		if int(piece["row"]) == row and int(piece["col"]) == col:
			return true
	return false


func _top_row_full() -> bool:
	for col in COLS:
		if board[0][col] == "":
			return false
	return true


func _game_over() -> void:
	active = false
	message_label.text = "Top out! Final score %d." % score
	action_button.text = "Play Again"
	action_button.show()


func _refresh() -> void:
	var display := board.duplicate(true)
	for piece in falling:
		display[int(piece["row"])][int(piece["col"])] = str(piece["value"])
	for row in ROWS:
		for col in COLS:
			var button := cells[row * COLS + col]
			button.text = display[row][col]
			button.modulate = Color("ffe172") if selected == Vector2i(col, row) else Color.WHITE
	hud_label.text = "MATHTRIS    SCORE %d    LEVEL %d" % [score, level]
	next_label.text = "Drops: %d   Speed: %dms" % [falling.size(), Rules.mathtris_drop_ms(level, drops_placed, (Time.get_ticks_msec() - started_ms) / 1000)]
	var names := {"sparkle": "Sparkle Burst", "rainbow": "Rainbow Row", "star": "Star Beam", "cloud": "Cloud Float", "dream": "Dream Fix", "mystic": "Mystic Clear"}
	power_button.text = "%s %s" % [names.get(companion_id, "Sparkle Burst"), "READY" if power_ready else "%d/%d" % [clear_charge, SOLVES_FOR_POWER]]
	power_button.disabled = not power_ready


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("090e25")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var root := VBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 6)
	add_child(root)
	hud_label = Label.new()
	hud_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_label.add_theme_font_size_override("font_size", 25)
	hud_label.add_theme_color_override("font_color", Color("66e5ff"))
	root.add_child(hud_label)
	next_label = Label.new()
	next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(next_label)
	var grid := GridContainer.new()
	grid.columns = COLS
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	root.add_child(grid)
	for row in ROWS:
		for col in COLS:
			var cell := Button.new()
			cell.custom_minimum_size = Vector2(50, 33)
			cell.add_theme_font_size_override("font_size", 17)
			cell.pressed.connect(_cell_pressed.bind(row, col))
			grid.add_child(cell)
			cells.append(cell)
	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(controls)
	for label in ["LEFT", "DOWN", "RIGHT"]:
		var button := Button.new()
		button.text = label
		button.custom_minimum_size = Vector2(62, 44)
		var direction := Vector2i.LEFT if label == "LEFT" else (Vector2i.DOWN if label == "DOWN" else Vector2i.RIGHT)
		button.pressed.connect(_nudge.bind(direction))
		controls.add_child(button)
	power_button = Button.new()
	power_button.custom_minimum_size.x = 120
	power_button.pressed.connect(_activate_power)
	controls.add_child(power_button)
	var hint := Button.new()
	hint.text = "Hint"
	hint.custom_minimum_size.x = 48
	hint.pressed.connect(_show_hint)
	controls.add_child(hint)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(message_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(actions)
	action_button = Button.new()
	action_button.pressed.connect(_start_game)
	actions.add_child(action_button)
	var back := Button.new()
	back.text = "Number Games"
	back.pressed.connect(func() -> void:
		AppState.set_shell_destination("category", "Number")
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	actions.add_child(back)
