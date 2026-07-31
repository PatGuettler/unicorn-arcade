extends GameFrame

## Unified gameplay for all 22 mini-games (parity with React app).

var _r_idx: int = 0
var _target_round: int = 5
var _puzzle: Dictionary = {}
var _pool: Array = []
var _built: Array = []
var _picked: Array = []
var _active_mode: String = ""
var _active_cfg: Dictionary = {}
var _lives: int = 3
var _arena_answer := ""
var _arena_mode := ""

# Number games
var _amount_target: int = 0
var _amount_current: int = 0
var _jump_data: Array = []
var _jump_index: int = 0
var _window_data: Array = []
var _window_pos: int = 0
var _window_size: int = 3
var _opponent_pos: int = 0
var _opponent_clock := 0.0
var _math_cards: Array = []
var _math_done: int = 0
var _math_need: int = 5
var _mathtris_board: Array = []
var _mathtris_falling := Vector2i(-1, -1)
var _mathtris_value := ""
var _mathtris_selected := Vector2i(-1, -1)
var _mathtris_clock := 0.0
var _mathtris_score := 0
var _mathtris_drops := 0
var _type_word: String = ""
var _type_index: int = 0
var _type_buffer: String = ""

# Space shooter
var _space_kills: int = 0
var _space_need: int = 12
var _space_lives: int = 3


const WORD_MODES := {
	"missingMagic": {"list": "MISSING_WORD", "mode": "blank"},
	"rhymeRally": {"list": "RHYME_CHALLENGES", "mode": "mcq", "key": "word"},
	"oppositeOrbit": {"list": "OPPOSITE_CHALLENGES", "mode": "mcq", "key": "word"},
	"prefixPotion": {"list": "PREFIX_MIX", "mode": "prefix"},
	"captionQuest": {"list": "CAPTION_SCENES", "mode": "caption"},
	"sentenceSprout": {"list": "SENTENCE_BUILD", "mode": "sequence", "field": "words"},
	"syllableStamp": {"list": "SYLLABLE_WORDS", "mode": "syllable"},
	"oddOneOut": {"list": "ODD_ONE_OUT", "mode": "odd"},
	"scrambleSpell": {"list": "SCRAMBLE_PUZZLES", "mode": "scramble"},
	"sizeLineUp": {"list": "SIZE_LINEUPS", "mode": "size_order"},
	"chainLink": {"list": "CHAIN_LINKS", "mode": "chain"},
	"letterLift": {"mode": "type"},
	"sightSpark": {"mode": "type"},
	"unicornBlast": {"mode": "type"},
	"vowelVines": {"mode": "vowel"},
}

const MATHTRIS_COLS := 8
const MATHTRIS_ROWS := 14


func _ready() -> void:
	var gid := SceneRouter.get_game_id()
	var entry := GameCatalog.get_game_entry(SceneRouter.get_category_id(), gid)
	mount(gid, String(entry.get("title", gid)))
	game_arena().choice_picked.connect(_on_arena_choice)
	game_arena().enemy_destroyed.connect(_on_arena_enemy_destroyed)
	game_arena().player_hit.connect(_on_arena_player_hit)


func _round_index() -> int:
	return _r_idx


func _round_target_index() -> int:
	return _target_round


func on_level_started(lvl: int) -> void:
	_r_idx = 0
	_arena_answer = ""
	_arena_mode = ""
	game_arena().clear_action()
	clear_play_children()

	match game_id:
		"coin":
			_start_coin(lvl)
		"cash":
			_start_cash(lvl)
		"mathSwipe":
			_start_math_swipe(lvl)
		"unicorn":
			_start_unicorn_jump(lvl)
		"sliding":
			_start_sliding(lvl)
		"mathtris":
			_start_mathtris(lvl)
		"spaceUnicorn":
			_start_space(lvl)
		_:
			if WORD_MODES.has(game_id):
				_target_round = WordData.target_for_level(lvl)
				if game_id == "oddOneOut":
					_target_round = mini(6, _target_round)
				_lives = 3
				_load_word_round(lvl)
			else:
				_show_message("Unknown game: %s" % game_id)


func _show_message(text: String) -> void:
	var lbl := UiFactory.make_subtitle(text)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_play_area.add_child(lbl)


# --- Coin / Cash ---

func _start_coin(lvl: int) -> void:
	_amount_target = _coin_target(lvl)
	_amount_current = 0
	_build_amount_ui("Make exact change", true)
	_refresh_amount_labels()


func _start_cash(lvl: int) -> void:
	if lvl <= 3:
		_amount_target = randi() % 20 + 1
	elif lvl <= 8:
		_amount_target = randi() % 80 + 20
	else:
		_amount_target = randi() % 900 + 100
	_amount_current = 0
	_build_amount_ui("Count the cash", false)
	_refresh_amount_labels()


func _coin_target(lvl: int) -> int:
	if lvl <= 3:
		return (randi() % 9 + 1) * 5
	if lvl <= 8:
		return randi() % 100 + 25
	return randi() % 400 + 100


func _build_amount_ui(title: String, coins: bool) -> void:
	var t := UiFactory.make_title(title, 22)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_play_area.add_child(t)
	var cur := Label.new()
	cur.name = "amount_label"
	cur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cur.add_theme_font_size_override("font_size", 32)
	cur.add_theme_color_override("font_color", UiFactory.CYAN)
	_play_area.add_child(cur)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	_play_area.add_child(row)
	if coins:
		var values: Array[int] = [1, 5, 10, 25]
		game_arena().present_currency(values, true)
		for value in values:
			var btn := UiFactory.make_coin_button(value, _coin_tex(value))
			btn.pressed.connect(func(): _add_amount(value))
			row.add_child(btn)
	else:
		var values: Array[int] = [1, 5, 10, 20, 50, 100]
		game_arena().present_currency(values, false)
		for value in values:
			var btn := UiFactory.make_button("$%d" % value, UiFactory.VIOLET, 48)
			btn.pressed.connect(func(): _add_amount(value))
			row.add_child(btn)


func _coin_tex(cents: int) -> String:
	match cents:
		1: return "res://assets/coins/penny.png"
		5: return "res://assets/coins/nickle.png"
		10: return "res://assets/coins/dime.png"
		_: return "res://assets/coins/quarter.png"


func _add_amount(v: int) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	_amount_current += v
	if _amount_current == _amount_target:
		GameSession.register_move(true)
		win_level()
	elif _amount_current > _amount_target:
		fail_level("Too much!")
	else:
		GameSession.register_move(true)
	_refresh_amount_labels()


func _refresh_amount_labels() -> void:
	var lbl: Label = _play_area.get_node_or_null("amount_label")
	if lbl:
		if game_id == "coin":
			lbl.text = "$%.2f / $%.2f" % [_amount_current / 100.0, _amount_target / 100.0]
		else:
			lbl.text = "$%d / $%d" % [_amount_current, _amount_target]


# --- Math swipe ---

func _start_math_swipe(lvl: int) -> void:
	_math_done = 0
	_math_need = mini(8, 3 + lvl / 2)
	_next_math_problem(lvl)


func _next_math_problem(lvl: int) -> void:
	clear_play_children()
	var prob := _gen_math(lvl)
	_puzzle = prob
	var q := UiFactory.make_title(prob.question, 28)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_play_area.add_child(q)
	_arena_answer = str(prob.answer)
	game_arena().present_choices(prob.answers)
	for ans in prob.answers:
		var btn := UiFactory.make_button(str(ans), UiFactory.CYAN, 52)
		var a := int(ans)
		btn.pressed.connect(func(): _pick_math_answer(a))
		_play_area.add_child(btn)


func _gen_math(lvl: int) -> Dictionary:
	var operation := "+"
	var a := randi_range(1, 8)
	var b := randi_range(1, 8)
	var answer := a + b
	if lvl <= 3:
		pass
	elif lvl <= 6:
		operation = "-"
		answer = randi_range(1, 8)
		b = randi_range(1, answer)
		a = answer + b
	elif lvl <= 10:
		operation = "+" if randf() > 0.5 else "-"
		if operation == "+":
			a = randi_range(5, 19)
			b = randi_range(5, 19)
			answer = a + b
		else:
			answer = randi_range(5, 19)
			b = randi_range(1, answer)
			a = answer + b
	else:
		var choice := randf()
		if choice < 0.4:
			operation = "×"
			a = randi_range(2, 11)
			b = randi_range(2, 11)
			answer = a * b
		elif choice < 0.7:
			operation = "+"
			a = randi_range(10, 29)
			b = randi_range(10, 29)
			answer = a + b
		else:
			operation = "-"
			answer = randi_range(10, 29)
			b = randi_range(1, answer)
			a = answer + b

	var missing := randi_range(0, 2)
	var correct := answer
	var question := "%d %s %d = %d" % [a, operation, b, answer]
	if missing == 0:
		correct = a
		question = "? %s %d = %d" % [operation, b, answer]
	elif missing == 1:
		correct = b
		question = "%d %s ? = %d" % [a, operation, answer]
	else:
		question = "%d %s %d = ?" % [a, operation, b]

	var wrong := correct
	while wrong == correct or wrong < 0:
		var offset := randi_range(-3, 3)
		wrong = correct + (1 if offset == 0 else offset)
	return {
		"question": question,
		"answer": correct,
		"answers": WordData.shuffle_array([correct, wrong]),
	}


func _math_mcq(question: String, answer: int) -> Dictionary:
	var answers: Array = [answer]
	while answers.size() < 4:
		var w := answer + randi() % 7 - 3
		if w > 0 and w not in answers:
			answers.append(w)
	return {"question": question, "answer": answer, "answers": WordData.shuffle_array(answers)}


func _pick_math_answer(a: int) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	if a == int(_puzzle.answer):
		GameSession.register_move(true)
		_math_done += 1
		if _math_done >= _math_need:
			win_level()
		else:
			_next_math_problem(GameSession.level)
	else:
		fail_level("Try again!")


# --- Unicorn jump ---

func _start_unicorn_jump(lvl: int) -> void:
	_jump_data = LevelUtilsJump.generate_level_data(lvl)
	_jump_index = 0
	_render_jump_path()


func _render_jump_path() -> void:
	clear_play_children()
	var power: int = int(_jump_data[_jump_index])
	_show_message("You are on %d · Jump %+d spaces" % [_jump_index, power])
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	_play_area.add_child(grid)
	var first := maxi(0, _jump_index - absi(power) - 3)
	var last := mini(_jump_data.size(), _jump_index + absi(power) + 5)
	var expected_index := _jump_index + power
	var arena_indices: Array = [expected_index]
	for candidate in range(first, last + 1):
		if candidate != _jump_index and candidate != expected_index and arena_indices.size() < 6:
			arena_indices.append(candidate)
	game_arena().present_choices(WordData.shuffle_array(arena_indices))
	for i in range(first, last + 1):
		var is_finish := i == _jump_data.size()
		var label := "FINISH" if is_finish else str(i)
		var expected := i == _jump_index + power
		var accent := UiFactory.PINK if expected and GameSession.show_hint else UiFactory.SLATE_800
		if i == _jump_index:
			accent = UiFactory.CYAN
			label = "%d\nYOU" % i
		var btn := UiFactory.make_button(label, accent, 52)
		btn.disabled = i == _jump_index
		var idx := i
		btn.pressed.connect(func(): _jump_to(idx))
		grid.add_child(btn)


func _jump_to(idx: int) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	var expected := _jump_index + int(_jump_data[_jump_index])
	if idx != expected:
		fail_level("Wrong jump!")
		return
	GameSession.register_move(true)
	_jump_index = idx
	if _jump_index == _jump_data.size():
		win_level()
	else:
		_render_jump_path()


# --- Sliding window ---

func _start_sliding(lvl: int) -> void:
	_window_size = mini(5, 3 + lvl / 4)
	_window_data = []
	var length := 15 + (5 if lvl > 5 else 0)
	var minimum := -100 if lvl > 5 else 0
	var maximum := 100 if lvl > 2 else 20
	for i in length:
		_window_data.append(randi_range(minimum, maximum))
	_window_pos = 0
	_opponent_pos = 0
	_opponent_clock = 1.8
	set_process(true)
	_render_window()


func _render_window() -> void:
	clear_play_children()
	var slice: Array = []
	for i in _window_size:
		if _window_pos + i < _window_data.size():
			slice.append(_window_data[_window_pos + i])
	var line := Label.new()
	line.text = "Pick the maximum · Rival %d/%d" % [_opponent_pos, _window_data.size() - _window_size + 1]
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_play_area.add_child(line)
	game_arena().present_choices(slice)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	_play_area.add_child(row)
	for i in slice.size():
		var value := int(slice[i])
		var absolute_index := _window_pos + i
		var btn := UiFactory.make_button(str(value), UiFactory.VIOLET, 58)
		btn.pressed.connect(func(): _collect_window_pick(absolute_index))
		row.add_child(btn)


func _collect_window_pick(index: int) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	var max_value := -INF
	for i in _window_size:
		max_value = maxf(max_value, float(_window_data[_window_pos + i]))
	if int(_window_data[index]) != int(max_value):
		set_process(false)
		fail_level("Not the maximum!")
		return
	GameSession.register_move(true)
	_window_pos += 1
	if _window_pos + _window_size >= _window_data.size():
		set_process(false)
		win_level()
	else:
		_render_window()


func _collect_window_value(value: int) -> void:
	for i in _window_size:
		var index := _window_pos + i
		if int(_window_data[index]) == value:
			_collect_window_pick(index)
			return


# --- Mathtris ---

func _start_mathtris(lvl: int) -> void:
	game_arena().clear_action()
	_mathtris_board.clear()
	for row in MATHTRIS_ROWS:
		var cells: Array = []
		cells.resize(MATHTRIS_COLS)
		cells.fill("")
		_mathtris_board.append(cells)
	_mathtris_score = 0
	_mathtris_drops = 0
	_mathtris_selected = Vector2i(-1, -1)
	_mathtris_falling = Vector2i(-1, -1)
	_seed_mathtris(lvl)
	_spawn_mathtris_piece(lvl)
	_mathtris_clock = 0.8
	set_process(true)
	_render_mathtris()


func _mathtris_tokens(lvl: int) -> Array:
	if lvl <= 10:
		return ["1", "1", "1", "2", "2", "+", "="]
	if lvl <= 20:
		return ["1", "2", "2", "3", "3", "4", "5", "+", "="]
	return ["1", "2", "3", "4", "5", "6", "7", "8", "9", "+", "-", "="]


func _seed_mathtris(lvl: int) -> void:
	var tokens := _mathtris_tokens(lvl)
	for row in range(MATHTRIS_ROWS - 4, MATHTRIS_ROWS):
		for col in MATHTRIS_COLS:
			_mathtris_board[row][col] = str(tokens.pick_random())


func _spawn_mathtris_piece(lvl: int) -> void:
	var open: Array[int] = []
	for col in MATHTRIS_COLS:
		if str(_mathtris_board[0][col]).is_empty():
			open.append(col)
	if open.is_empty():
		set_process(false)
		fail_level("Blocks reached the top!")
		return
	var tokens := _mathtris_tokens(lvl)
	_mathtris_falling = Vector2i(int(open.pick_random()), 0)
	_mathtris_value = str(tokens.pick_random())


func _step_mathtris() -> void:
	if _mathtris_falling.x < 0:
		_spawn_mathtris_piece(GameSession.level)
		return
	var next_row := _mathtris_falling.y + 1
	if next_row >= MATHTRIS_ROWS or not str(_mathtris_board[next_row][_mathtris_falling.x]).is_empty():
		_mathtris_board[_mathtris_falling.y][_mathtris_falling.x] = _mathtris_value
		_mathtris_falling = Vector2i(-1, -1)
		_mathtris_drops += 1
		_clear_mathtris_equations()
		if GameSession.state == GameSession.State.PLAYING:
			_spawn_mathtris_piece(GameSession.level)
	else:
		_mathtris_falling.y = next_row
	_render_mathtris()


func _render_mathtris() -> void:
	clear_play_children()
	_show_message("Score %d/700 · Make equations across or down" % _mathtris_score)
	var grid := GridContainer.new()
	grid.columns = MATHTRIS_COLS
	grid.add_theme_constant_override("h_separation", 2)
	grid.add_theme_constant_override("v_separation", 2)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_play_area.add_child(grid)
	for row in MATHTRIS_ROWS:
		for col in MATHTRIS_COLS:
			var value := str(_mathtris_board[row][col])
			var is_falling := _mathtris_falling == Vector2i(col, row)
			if is_falling:
				value = _mathtris_value
			var cell := Button.new()
			cell.text = value
			cell.custom_minimum_size = Vector2(34, 28)
			cell.add_theme_font_size_override("font_size", UiFactory.font_size(14))
			var selected := _mathtris_selected == Vector2i(col, row)
			var color := UiFactory.PINK if is_falling else (Color("#fde68a") if selected else UiFactory.SLATE_700)
			cell.add_theme_stylebox_override("normal", UiFactory.stylebox_flat(color.darkened(0.25), 5))
			cell.disabled = value.is_empty() or is_falling
			var cell_pos := Vector2i(col, row)
			cell.pressed.connect(func(): _mathtris_cell_pick(cell_pos))
			grid.add_child(cell)

	var controls := HBoxContainer.new()
	controls.alignment = BoxContainer.ALIGNMENT_CENTER
	for spec in [
		["←", -1],
		["↓", 0],
		["→", 1],
	]:
		var btn := UiFactory.make_button(str(spec[0]), UiFactory.VIOLET, 42)
		var direction := int(spec[1])
		btn.pressed.connect(func(): _move_mathtris_piece(direction))
		controls.add_child(btn)
	_play_area.add_child(controls)


func _move_mathtris_piece(direction: int) -> void:
	if _mathtris_falling.x < 0 or GameSession.state != GameSession.State.PLAYING:
		return
	if direction == 0:
		_step_mathtris()
		return
	var next_col := _mathtris_falling.x + direction
	if next_col < 0 or next_col >= MATHTRIS_COLS:
		return
	if not str(_mathtris_board[_mathtris_falling.y][next_col]).is_empty():
		return
	_mathtris_falling.x = next_col
	_render_mathtris()


func _mathtris_cell_pick(cell_pos: Vector2i) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	if _mathtris_selected.x < 0:
		_mathtris_selected = cell_pos
		_render_mathtris()
		return
	var delta := cell_pos - _mathtris_selected
	if absi(delta.x) + absi(delta.y) != 1:
		_mathtris_selected = cell_pos
		_render_mathtris()
		return
	var first := str(_mathtris_board[_mathtris_selected.y][_mathtris_selected.x])
	_mathtris_board[_mathtris_selected.y][_mathtris_selected.x] = _mathtris_board[cell_pos.y][cell_pos.x]
	_mathtris_board[cell_pos.y][cell_pos.x] = first
	_mathtris_selected = Vector2i(-1, -1)
	GameSession.register_move(true)
	_clear_mathtris_equations()
	_render_mathtris()


func _clear_mathtris_equations() -> void:
	var hits: Dictionary = {}
	for row in MATHTRIS_ROWS:
		for col in range(MATHTRIS_COLS - 4):
			var segment: Array = []
			for offset in 5:
				segment.append(str(_mathtris_board[row][col + offset]))
			if _valid_mathtris_equation(segment):
				for offset in 5:
					hits[Vector2i(col + offset, row)] = true
	for col in MATHTRIS_COLS:
		for row in range(MATHTRIS_ROWS - 4):
			var segment: Array = []
			for offset in 5:
				segment.append(str(_mathtris_board[row + offset][col]))
			if _valid_mathtris_equation(segment):
				for offset in 5:
					hits[Vector2i(col, row + offset)] = true
	if hits.is_empty():
		return
	for pos_variant in hits.keys():
		var pos: Vector2i = pos_variant
		_mathtris_board[pos.y][pos.x] = ""
	_mathtris_apply_gravity()
	_mathtris_score += hits.size() * 100
	AudioManager.play_success()
	if _mathtris_score >= 700:
		set_process(false)
		win_level()


func _valid_mathtris_equation(segment: Array) -> bool:
	if segment.any(func(value): return str(value).is_empty()):
		return false
	var a := str(segment[0])
	var b := str(segment[1])
	var c := str(segment[2])
	var d := str(segment[3])
	var e := str(segment[4])
	if a.is_valid_int() and (b == "+" or b == "-") and c.is_valid_int() and d == "=" and e.is_valid_int():
		var result := int(a) + int(c) if b == "+" else int(a) - int(c)
		return result == int(e) and result >= 0 and result <= 9
	if a.is_valid_int() and b == "=" and c.is_valid_int() and (d == "+" or d == "-") and e.is_valid_int():
		var result := int(c) + int(e) if d == "+" else int(c) - int(e)
		return result == int(a) and result >= 0 and result <= 9
	return false


func _mathtris_apply_gravity() -> void:
	for col in MATHTRIS_COLS:
		var stack: Array = []
		for row in MATHTRIS_ROWS:
			var value := str(_mathtris_board[row][col])
			if not value.is_empty():
				stack.append(value)
		for row in MATHTRIS_ROWS:
			_mathtris_board[row][col] = ""
		for i in stack.size():
			_mathtris_board[MATHTRIS_ROWS - stack.size() + i][col] = stack[i]


# --- Word games ---

func _load_word_round(lvl: int) -> void:
	var cfg: Dictionary = WORD_MODES[game_id]
	var mode: String = cfg.mode
	match mode:
		"type":
			_start_type_word(lvl)
		"vowel":
			_start_vowel(lvl)
		_:
			var arr: Array = WordData.list(String(cfg.list))
			_puzzle = WordData.pick_for_level(arr, lvl + _r_idx)
			if typeof(_puzzle) != TYPE_DICTIONARY:
				_show_message("No word data")
				return
			_built.clear()
			_picked.clear()
			_pool.clear()
			_active_mode = mode
			_active_cfg = cfg
			_render_word_mode(mode, cfg)


func _render_word_mode(mode: String, cfg: Dictionary) -> void:
	clear_play_children()

	match mode:
		"blank":
			var parts: Array = _puzzle.get("text", [])
			var line := ""
			for p in parts:
				if p == null:
					line += " ___ "
				else:
					line += " %s " % str(p)
			_play_area.add_child(UiFactory.make_title(line, 20))
			_add_option_buttons(_puzzle.get("options", []), _puzzle.get("answer", ""))
		"mcq", "caption", "prefix":
			var key: String = cfg.get("key", "prompt")
			if mode == "caption":
				_play_area.add_child(UiFactory.make_title(String(_puzzle.get("emoji", "")), 32))
				key = "prompt"
			if mode == "prefix":
				_play_area.add_child(UiFactory.make_title("%s + %s" % [_puzzle.get("prefix", ""), _puzzle.get("root", "")], 22))
				var choices: Array = WordData.shuffle_array([_puzzle.get("answer", "")] + _puzzle.get("wrong", []))
				_add_option_buttons(choices, _puzzle.get("answer", ""))
				return
			_play_area.add_child(UiFactory.make_title(String(_puzzle.get(key, "?")), 24))
			var opts: Array = WordData.shuffle_array(_puzzle.get("options", []))
			_add_option_buttons(opts, _puzzle.get("answer", ""))
		"odd":
			_play_area.add_child(UiFactory.make_subtitle(String(_puzzle.get("theme", ""))))
			var grid := GridContainer.new()
			grid.columns = 2
			var odd_labels: Array = []
			for item_variant in WordData.shuffle_array(_puzzle.get("items", [])):
				var item: Dictionary = item_variant
				odd_labels.append(String(item.get("label", "")))
				var btn := UiFactory.make_button("%s\n%s" % [item.get("emoji", ""), item.get("label", "")], UiFactory.VIOLET, 72)
				var label := String(item.get("label", ""))
				btn.pressed.connect(func(): _pick_odd(label))
				grid.add_child(btn)
			_play_area.add_child(grid)
			_arena_mode = "odd"
			game_arena().present_choices(odd_labels)
		"scramble":
			_play_area.add_child(UiFactory.make_title(String(_puzzle.get("hint", "")), 18))
			_picked.clear()
			var word: String = String(_puzzle.get("word", ""))
			_pool = WordData.shuffle_array(word.split(""))
			_add_scramble_pool()
		"size_order":
			var order_arr: Array = _puzzle.get("order", [])
			if _built.is_empty():
				_pool = WordData.shuffle_array(_puzzle.get("words", []).duplicate())
			_play_area.add_child(UiFactory.make_subtitle("Shortest → longest"))
			_add_pool_buttons_for_order(order_arr)
		"sequence":
			var words: Array = _puzzle.get("words", [])
			if _built.is_empty():
				_pool = WordData.shuffle_array(words.duplicate())
			_play_area.add_child(UiFactory.make_subtitle("Build the sentence"))
			_add_pool_buttons_for_order(words)
		"syllable":
			var parts: Array = _puzzle.get("parts", [])
			if _built.is_empty():
				_pool = WordData.shuffle_array(parts.duplicate())
			_play_area.add_child(UiFactory.make_subtitle("Stamp syllables in order"))
			_add_pool_buttons_for_order(parts)
		"chain":
			_play_area.add_child(UiFactory.make_title("Chain: %s" % _puzzle.get("start", ""), 22))
			var opts: Array = WordData.shuffle_array(_puzzle.get("options", []))
			_add_chain_buttons(opts)


func _add_option_buttons(options: Array, answer: String) -> void:
	_arena_answer = answer
	_arena_mode = "mcq"
	game_arena().present_choices(options)
	for o in options:
		var btn := UiFactory.make_button(String(o), UiFactory.CYAN, 48)
		var pick := String(o)
		btn.pressed.connect(func(): _word_mcq_pick(pick, answer))
		_play_area.add_child(btn)


func _word_mcq_pick(pick: String, answer: String) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	if pick == str(answer):
		_advance_word_round()
	else:
		fail_level("Oops!")


func _pick_odd(label: String) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	if label == str(_puzzle.get("odd", "")):
		_advance_word_round()
	else:
		_lives -= 1
		if _lives <= 0:
			fail_level("Wrong item!")


func _add_scramble_pool() -> void:
	_arena_mode = "scramble"
	game_arena().present_choices(_pool.slice(0, 6))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_play_area.add_child(row)
	var word: String = String(_puzzle.get("word", ""))
	var next_i := _picked.size()
	for i in _pool.size():
		var ch: String = str(_pool[i])
		var btn := UiFactory.make_button(ch, UiFactory.PINK, 44)
		var idx := i
		btn.pressed.connect(func(): _scramble_pick(ch, idx, word, next_i))
		row.add_child(btn)


func _scramble_pick(ch: String, idx: int, word: String, expected_i: int) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	if ch != word[expected_i]:
		fail_level("Wrong letter!")
		return
	GameSession.register_move(true)
	_picked.append(ch)
	_pool.remove_at(idx)
	if _picked.size() >= word.length():
		_advance_word_round()
	else:
		clear_play_children()
		_play_area.add_child(UiFactory.make_title(String(_puzzle.get("hint", "")), 18))
		_add_scramble_pool()


func _add_pool_buttons_for_order(order: Array) -> void:
	var next_w: String = str(order[_built.size()]) if _built.size() < order.size() else ""
	_arena_mode = "order"
	game_arena().present_choices(_pool.slice(0, 6))
	if not _built.is_empty():
		var built_words := PackedStringArray()
		for built_word in _built:
			built_words.append(str(built_word))
		var built_label := UiFactory.make_subtitle("Built: %s" % " ".join(built_words))
		built_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_play_area.add_child(built_label)
	for i in _pool.size():
		var w: String = str(_pool[i])
		var btn := UiFactory.make_button(w, UiFactory.CYAN, 44)
		var idx := i
		btn.pressed.connect(func(): _sequence_pick(w, idx, next_w, order))
		_play_area.add_child(btn)


func _sequence_pick(w: String, idx: int, expected: String, order: Array) -> void:
	if GameSession.state != GameSession.State.PLAYING or expected.is_empty():
		return
	if w != expected:
		fail_level("Wrong order!")
		return
	GameSession.register_move(true)
	_built.append(w)
	_pool.remove_at(idx)
	if _built.size() >= order.size():
		_advance_word_round()
	else:
		_render_word_mode(_active_mode, _active_cfg)


func _add_pool_buttons(_field: String) -> void:
	var order: Array = _puzzle.get(_field, [])
	_add_pool_buttons_for_order(order)


func _add_chain_buttons(options: Array) -> void:
	var req := String(_puzzle.get("start", "")).substr(-1).to_lower()
	_arena_mode = "chain"
	game_arena().present_choices(options)
	for o in options:
		var btn := UiFactory.make_button(String(o), UiFactory.VIOLET, 44)
		var pick := String(o)
		btn.pressed.connect(func(): _chain_pick(pick, req))
		_play_area.add_child(btn)


func _chain_pick(word: String, req: String) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	if word.length() > 0 and word[0].to_lower() == req:
		_advance_word_round()
	else:
		fail_level("Breaks the chain!")


func _advance_word_round() -> void:
	GameSession.register_move(true)
	_r_idx += 1
	if _r_idx >= _target_round:
		win_level()
	else:
		_load_word_round(GameSession.level)


func _start_type_word(lvl: int) -> void:
	var words := WordData.words_for_level(lvl)
	if words.is_empty():
		words = ["cat", "dog", "sun", "play", "unicorn"]
	_type_word = str(words[(_r_idx + lvl) % words.size()])
	_type_index = 0
	_type_buffer = ""
	game_arena().set_companion_progress(0.0)
	clear_play_children()
	var show_word := game_id != "sightSpark" or GameSession.show_hint
	var prompt := UiFactory.make_title(_type_word if show_word else "Memorize…", 28)
	prompt.name = "type_prompt"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_play_area.add_child(prompt)
	var progress := UiFactory.make_subtitle("_ ".repeat(_type_word.length()))
	progress.name = "type_progress"
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_play_area.add_child(progress)
	var keyboard := GridContainer.new()
	keyboard.name = "type_keyboard"
	keyboard.columns = 7
	keyboard.add_theme_constant_override("h_separation", 4)
	keyboard.add_theme_constant_override("v_separation", 4)
	_play_area.add_child(keyboard)
	var letters: Array = []
	for code in range(97, 123):
		letters.append(String.chr(code))
	letters = WordData.shuffle_array(letters)
	for letter_variant in letters:
		var c := str(letter_variant)
		var btn := UiFactory.make_button(c.to_upper(), UiFactory.SLATE_800, 40)
		btn.pressed.connect(func(): _type_char(c))
		keyboard.add_child(btn)
	if game_id == "sightSpark" and not GameSession.show_hint:
		prompt.text = _type_word.to_upper()
		get_tree().create_timer(1.5).timeout.connect(func():
			if is_instance_valid(prompt) and _type_index == 0:
				prompt.text = "Type it from memory!"
		)


func _type_char(ch: String) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	if _type_index >= _type_word.length():
		return
	if ch == _type_word[_type_index]:
		GameSession.register_move(true)
		_type_index += 1
		_type_buffer += ch
		if game_id == "unicornBlast":
			game_arena().fire_magic()
		elif game_id == "letterLift":
			game_arena().set_companion_progress(float(_type_index) / float(_type_word.length()))
		var progress: Label = _play_area.get_node_or_null("type_progress")
		if progress:
			var remaining := "_ ".repeat(_type_word.length() - _type_index)
			progress.text = "%s%s" % [_type_buffer.to_upper(), remaining]
		if _type_index >= _type_word.length():
			_advance_word_round()
	else:
		fail_level("Wrong letter!")


func _start_vowel(lvl: int) -> void:
	var vowels := ["a", "e", "i", "o", "u"]
	var v: String = vowels[(_r_idx + lvl) % vowels.size()]
	var words: Array = WordData.vowel_word_list(v)
	if words.is_empty():
		words = ["cat", "hat", "bat"]
	var good: Array = words.filter(func(word): return str(word).to_lower().begins_with(v))
	if good.is_empty():
		good = words
	_puzzle = {"vowel": v, "answer": WordData.pick_for_level(good, lvl + _r_idx)}
	var wrong: Array = []
	var wrong_pool: Array = []
	for other_vowel in vowels:
		if other_vowel == v:
			continue
		for word in WordData.vowel_word_list(other_vowel):
			if not str(word).to_lower().begins_with(v):
				wrong_pool.append(word)
	for w in WordData.shuffle_array(wrong_pool):
		if str(w) != str(_puzzle.answer) and str(w) not in wrong and wrong.size() < 3:
			wrong.append(w)
	clear_play_children()
	_play_area.add_child(UiFactory.make_title("Pick a word with '%s'" % v, 22))
	_add_option_buttons(WordData.shuffle_array([_puzzle.answer] + wrong), _puzzle.answer)


# --- Space unicorn (arcade) ---

func _start_space(lvl: int) -> void:
	_space_kills = 0
	_space_need = 10 + lvl
	_space_lives = 3
	set_process(true)
	clear_play_children()
	_show_message("Tap the invaders in the 3D arena — destroy %d!" % _space_need)
	game_arena().start_space(lvl)


func _on_arena_choice(value: String) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	if game_id == "mathSwipe":
		if value.is_valid_int():
			_pick_math_answer(int(value))
	elif game_id == "coin" or game_id == "cash":
		if value.is_valid_int():
			_add_amount(int(value))
	elif game_id == "unicorn":
		if value.is_valid_int():
			_jump_to(int(value))
	elif game_id == "sliding":
		if value.is_valid_int():
			_collect_window_value(int(value))
	elif _arena_mode == "odd":
		_pick_odd(value)
	elif _arena_mode == "scramble":
		var index := _pool.find(value)
		var word := String(_puzzle.get("word", ""))
		if index >= 0 and _picked.size() < word.length():
			_scramble_pick(value, index, word, _picked.size())
	elif _arena_mode == "order":
		var index := _pool.find(value)
		if index >= 0:
			var order: Array = []
			match _active_mode:
				"sequence", "syllable":
					order = _puzzle.get("words" if _active_mode == "sequence" else "parts", [])
				"size_order":
					order = _puzzle.get("order", [])
			var expected := str(order[_built.size()]) if _built.size() < order.size() else ""
			_sequence_pick(value, index, expected, order)
	elif _arena_mode == "chain":
		var req := String(_puzzle.get("start", "")).substr(-1).to_lower()
		_chain_pick(value, req)
	elif _arena_mode == "mcq" and not _arena_answer.is_empty():
		_word_mcq_pick(value, _arena_answer)


func _on_arena_enemy_destroyed() -> void:
	if game_id != "spaceUnicorn" or GameSession.state != GameSession.State.PLAYING:
		return
	_space_kills += 1
	GameSession.register_move(true)
	if _space_kills >= _space_need:
		game_arena().stop_space()
		set_process(false)
		win_level()


func _on_arena_player_hit() -> void:
	if game_id != "spaceUnicorn" or GameSession.state != GameSession.State.PLAYING:
		return
	_space_lives -= 1
	if _space_lives <= 0:
		game_arena().stop_space()
		set_process(false)
		fail_level("Ship lost!")


func _process(delta: float) -> void:
	if game_id == "spaceUnicorn":
		_status.text = "Level %d · Invaders %d/%d · Hearts %d" % [
			GameSession.level,
			_space_kills,
			_space_need,
			_space_lives,
		]
	elif game_id == "sliding" and GameSession.state == GameSession.State.PLAYING:
		_opponent_clock -= delta
		if _opponent_clock <= 0.0:
			_opponent_pos += 1
			_opponent_clock = maxf(0.45, 1.8 - GameSession.level * 0.06)
			if _opponent_pos + _window_size >= _window_data.size():
				set_process(false)
				fail_level("The rival beat you!")
			else:
				_render_window()
	elif game_id == "mathtris" and GameSession.state == GameSession.State.PLAYING:
		_mathtris_clock -= delta
		if _mathtris_clock <= 0.0:
			_mathtris_clock = maxf(
				0.12,
				0.95 - GameSession.level * 0.055 - minf(0.3, _mathtris_drops * 0.008)
			)
			_step_mathtris()
