extends ArcadeGameController

const Rules = preload("res://scripts/games/word_game_rules.gd")
const RoundCatalog = preload("res://scripts/games/word_round_catalog.gd")
const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const RoomItemPreviewScene = preload("res://scripts/meta/room_item_preview_3d.gd")
const NAVY := Color("08112f")
const PANEL := Color("14214a")
const CYAN := Color("58d6e8")
const PINK := Color("f26fa7")
const YELLOW := Color("ffd166")
const VOWELS := ["a", "e", "i", "o", "u"]

var game_id := ""
var game_info: Dictionary = {}
var level := 1
var round_index := 0
var target_rounds := 0
var lives := 0
var started_ms := 0
var active := false
var hint_visible := false
var current: Dictionary = {}
var sequence: Array = []
var pool: Array = []
var picked: Array = []
var expected_word := ""
var phase := "choice"
var rng := RandomNumberGenerator.new()
var blast_words: Array = []
var spawn_elapsed := 0.0
var suppress_text_event := false

var title_label: Label
var coin_label: Label
var level_label: Label
var timer_label: Label
var progress_label: Label
var lives_label: Label
var instruction_label: Label
var prompt_label: Label
var secondary_label: Label
var message_label: Label
var options: GridContainer
var input_line: LineEdit
var play_area: Control
var hint_button: Button
var retry_button: Button
var flash_timer: Timer
var cannon_preview: Control
var cannon_assembly: PanelContainer
var blast_projectiles: Array[Control] = []
var pending_blast_targets: Array[Button] = []


func _ready() -> void:
	rng.randomize()
	game_id = AppState.selected_game_id
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--game-id="):
			game_id = argument.trim_prefix("--game-id=")
	if game_id.is_empty():
		game_id = "sentence_sprout"
	game_info = GameRegistry.get_game(game_id)
	level = AppState.current_level(game_id)
	_build_ui()
	_start_level()


func _process(delta: float) -> void:
	super(delta)
	if active:
		timer_label.text = "%.1fs" % ((Time.get_ticks_msec() - started_ms) / 1000.0)
	if active and game_id == "unicorn_blast":
		_update_blast(delta * CompanionAbilityService.time_scale())


func _start_level() -> void:
	_clear_blast_words()
	level = AppState.current_level(game_id) if level < 1 else level
	round_index = 0
	target_rounds = Rules.target_for_level(level)
	if game_id == "caption_quest":
		target_rounds = Rules.caption_target(level)
	elif game_id == "odd_one_out":
		target_rounds = Rules.odd_one_out_target(level)
	lives = 3 if game_id in ["caption_quest", "odd_one_out", "unicorn_blast"] else 0
	started_ms = Time.get_ticks_msec()
	active = true
	hint_visible = level == 1
	phase = "choice"
	level_label.text = "LEVEL %d" % level
	retry_button.hide()
	hint_button.disabled = false
	hint_button.text = "FREE HINT" if level == 1 else "HINT  ★5"
	message_label.text = ""
	_load_round()


func _load_round() -> void:
	_clear_options()
	_hide_special_controls()
	picked.clear()
	sequence.clear()
	pool.clear()
	secondary_label.text = ""
	progress_label.text = "%d / %d" % [round_index, target_rounds]
	lives_label.text = "♥ %d" % lives if lives > 0 else ""
	match game_id:
		"sentence_sprout":
			_load_sequence("sentence_build", "words", "Build the sentence in order", "sentence")
		"missing_magic":
			current = Rules.pick_for_level("missing_word", level + round_index, rng)
			instruction_label.text = "Fill the magic blank"
			_render_missing_magic()
		"sight_spark":
			_load_sight_spark()
		"prefix_potion":
			current = Rules.pick_for_level("prefix_mix", level + round_index, rng)
			instruction_label.text = "Brew prefix + root into a real word"
			prompt_label.text = "%s + %s = %s" % [current.get("prefix", ""), current.get("root", ""), current.get("answer", "?") if hint_visible else "?"]
			var choices: Array = [current.get("answer", "")]
			choices.append_array(current.get("wrong", []))
			choices.shuffle()
			_render_choice_buttons(choices)
		"vowel_vines":
			_load_vowel_vines()
		"letter_lift":
			_load_letter_lift()
		"syllable_stamp":
			_load_sequence("syllable_words", "parts", "Stamp syllables in order", "syllable")
		"caption_quest":
			current = Rules.pick_for_level("caption_scenes", level + round_index, rng)
			instruction_label.text = current.get("prompt", "Choose the best caption")
			prompt_label.text = current.get("emoji", "")
			var caption_options: Array = current.get("options", []).duplicate()
			caption_options.shuffle()
			_render_choice_buttons(caption_options)
		"opposite_orbit":
			current = Rules.pick_for_level("opposite_challenges", level + round_index, rng)
			instruction_label.text = "Choose the opposite of"
			prompt_label.text = current.get("word", "")
			var opposite_options: Array = current.get("options", []).duplicate()
			opposite_options.shuffle()
			_render_choice_buttons(opposite_options)
		"scramble_spell":
			_load_scramble()
		"odd_one_out":
			_load_odd_one_out()
		"size_line_up":
			_load_size_line_up()
		"chain_link":
			_load_chain_link()
		"unicorn_blast":
			_load_unicorn_blast()
		_:
			_fail("This game is not configured.")


func _load_sequence(key: String, field: String, instruction: String, mode: String) -> void:
	current = RoundCatalog.pick_rule_round(Rules, key, level, round_index, rng)
	var round := RoundCatalog.sequence_round(current, field)
	sequence = round["sequence"]
	pool = round["pool"]
	phase = mode
	instruction_label.text = instruction
	_render_sequence()


func _load_sight_spark() -> void:
	var words := Rules.words_for_level(level)
	expected_word = RoundCatalog.word_for_round(words, level, round_index)
	phase = "flash"
	instruction_label.text = "Remember this word"
	prompt_label.text = expected_word
	input_line.hide()
	flash_timer.wait_time = Rules.sight_flash_ms(level) / 1000.0
	flash_timer.start()


func _finish_sight_flash() -> void:
	if not active or game_id != "sight_spark":
		return
	phase = "type"
	instruction_label.text = "Type the word from memory"
	prompt_label.text = expected_word if hint_visible else "?"
	_show_text_input("What did you see?")


func _load_vowel_vines() -> void:
	var prepared := RoundCatalog.vowel_round(Rules.data(), VOWELS, level, round_index, rng)
	var vowel: String = prepared["vowel"]
	current = {"vowel": vowel}
	instruction_label.text = "Choose a word beginning with"
	prompt_label.text = vowel.to_upper()
	_render_choice_buttons(prepared["choices"])


func _load_letter_lift() -> void:
	var words := Rules.words_for_level(level)
	expected_word = RoundCatalog.word_for_round(words, level, round_index)
	phase = "letter"
	picked.clear()
	instruction_label.text = "Type each letter in order"
	_render_letter_lift()
	_show_text_input("Type letters…")


func _load_scramble() -> void:
	current = Rules.pick_for_level("scramble_puzzles", level + round_index, rng)
	sequence = Array(current.get("word", "").split(""))
	pool = sequence.duplicate()
	pool.shuffle()
	phase = "scramble"
	instruction_label.text = current.get("hint", "Spell the word")
	_render_sequence()


func _load_odd_one_out() -> void:
	current = Rules.pick_for_level("odd_one_out", level + round_index, rng)
	instruction_label.text = current.get("theme", "Find the odd one out")
	prompt_label.text = "CASE FILE"
	var items: Array = current.get("items", []).duplicate(true)
	items.shuffle()
	for item in items:
		_add_option("%s\n%s" % [item.get("emoji", ""), item.get("label", "")], item.get("label", ""))


func _load_size_line_up() -> void:
	current = Rules.pick_for_level("size_lineups", level + round_index, rng)
	sequence = current.get("order", []).duplicate()
	pool = current.get("words", []).duplicate()
	pool.shuffle()
	phase = "size"
	instruction_label.text = "Tap shortest → longest"
	_render_sequence()


func _load_chain_link() -> void:
	current = Rules.pick_for_level("chain_links", level + round_index, rng)
	instruction_label.text = "Continue with the last letter"
	var start := str(current.get("start", ""))
	prompt_label.text = "%s  →  %s…" % [start, start.right(1).to_upper()]
	var choices: Array = current.get("options", []).duplicate()
	choices.shuffle()
	_render_choice_buttons(choices)


func _load_unicorn_blast() -> void:
	phase = "blast"
	instruction_label.text = "Type each falling word before it reaches the cannon"
	prompt_label.text = "UNICORN CANNON"
	play_area.show()
	_show_text_input("Type a falling word…")
	spawn_elapsed = 0.0
	_spawn_blast_word()


func _render_missing_magic() -> void:
	var pieces: Array = current.get("text", [])
	var rendered: Array[String] = []
	for piece in pieces:
		if piece == null:
			rendered.append(str(current.get("answer", "")) if hint_visible else "___")
		else:
			rendered.append(str(piece))
	prompt_label.text = " ".join(rendered)
	var choices: Array = current.get("options", []).duplicate()
	choices.shuffle()
	_render_choice_buttons(choices)


func _render_choice_buttons(choices: Array) -> void:
	for choice in choices:
		_add_option(str(choice), choice)


func _render_sequence() -> void:
	_clear_options()
	var built: Array[String] = []
	for value in picked:
		built.append(str(value))
	if phase == "sentence":
		prompt_label.text = " ".join(built) if not built.is_empty() else "Build it!"
		secondary_label.text = "Next: %s" % sequence[picked.size()] if hint_visible and picked.size() < sequence.size() else ""
	elif phase == "syllable":
		prompt_label.text = current.get("word", "")
		secondary_label.text = "Stamped: %s" % "-".join(built)
	elif phase == "scramble":
		prompt_label.text = "".join(built).to_upper()
		secondary_label.text = "Next letter: %s" % sequence[picked.size()].to_upper() if hint_visible and picked.size() < sequence.size() else ""
	elif phase == "size":
		prompt_label.text = " → ".join(built) if not built.is_empty() else "Line them up!"
		secondary_label.text = "Next: %s" % sequence[picked.size()] if hint_visible and picked.size() < sequence.size() else ""
	for index in pool.size():
		_add_option(str(pool[index]), {"value": pool[index], "index": index})


func _render_letter_lift() -> void:
	var typed := "".join(picked)
	prompt_label.text = typed.to_upper() + "_".repeat(maxi(0, expected_word.length() - typed.length()))
	# Letter Lift is an ordered typing game, not a memory test. Keep the entire
	# round target visible after every correct letter and on every later round.
	secondary_label.text = "TARGET: %s" % expected_word.to_upper()


func _choose(payload) -> void:
	if not active:
		return
	if payload is Dictionary:
		_choose_sequence(payload)
		return
	var value := str(payload)
	var correct := false
	match game_id:
		"missing_magic", "prefix_potion", "caption_quest", "opposite_orbit":
			correct = value == str(current.get("answer", ""))
		"vowel_vines":
			correct = value.left(1).to_lower() == str(current.get("vowel", ""))
		"odd_one_out":
			correct = value == str(current.get("odd", ""))
		"chain_link":
			correct = Rules.is_chain_link(str(current.get("start", "")), value)
	if correct:
		_successful_round()
	elif game_id in ["caption_quest", "odd_one_out"]:
		_lost_life()
	else:
		_fail(_fail_reason())


func _choose_sequence(payload: Dictionary) -> void:
	var value = payload.get("value")
	var index := int(payload.get("index", -1))
	if picked.size() >= sequence.size() or value != sequence[picked.size()]:
		_fail(_fail_reason())
		return
	picked.append(value)
	if index >= 0 and index < pool.size():
		pool.remove_at(index)
	hint_visible = false
	if picked.size() >= sequence.size():
		_successful_round()
	else:
		_render_sequence()


func _on_text_submitted(value: String) -> void:
	if not active or game_id != "sight_spark" or phase != "type":
		return
	if value.strip_edges().to_lower() == expected_word:
		_successful_round()
	else:
		_fail(_fail_reason())


func _on_text_changed(value: String) -> void:
	if suppress_text_event or not active:
		return
	if game_id == "letter_lift":
		_handle_letter_input(value)
	elif game_id == "unicorn_blast":
		_handle_blast_input(value)


func _handle_letter_input(value: String) -> void:
	var typed := "".join(picked)
	if value.length() <= typed.length():
		_set_input_text(typed)
		return
	var character := value.substr(typed.length(), 1).to_lower()
	if character == expected_word.substr(picked.size(), 1):
		picked.append(character)
		hint_visible = false
		_set_input_text("".join(picked))
		_render_letter_lift()
		if picked.size() >= expected_word.length():
			_successful_round()
	else:
		_fail(_fail_reason())


func _handle_blast_input(value: String) -> void:
	var candidate := value.strip_edges().to_lower()
	for index in blast_words.size():
		if blast_words[index].get("text", "") == candidate:
			_launch_blast_projectile(index)
			_remove_blast_word(index, true)
			_set_input_text("")
			message_label.text = "BLAST!"
			_successful_round(false)
			return


func _successful_round(load_next := true) -> void:
	hint_visible = false
	round_index += 1
	if round_index >= target_rounds:
		_complete_level()
	elif load_next:
		_load_round()
	else:
		progress_label.text = "%d / %d" % [round_index, target_rounds]


func _lost_life() -> void:
	lives -= 1
	lives_label.text = "♥ %d" % maxi(0, lives)
	message_label.text = "Not quite—%d hearts left." % maxi(0, lives)
	if lives <= 0:
		_fail(_fail_reason())


func _complete_level() -> void:
	active = false
	flash_timer.stop()
	var reward := AppState.complete_level(game_id, level, Time.get_ticks_msec() - started_ms)
	message_label.text = "Level complete! +%d coins" % reward
	coin_label.text = "★ %d" % AppState.coins()
	retry_button.text = "NEXT LEVEL"
	retry_button.show()
	hint_button.disabled = true
	input_line.editable = false
	level += 1


func _fail(reason: String) -> void:
	active = false
	flash_timer.stop()
	message_label.text = reason
	retry_button.text = "RETRY"
	retry_button.show()
	hint_button.disabled = true
	input_line.editable = false


func can_show_hint() -> bool:
	return active and not hint_visible


func _show_hint() -> void:
	if not active or hint_visible:
		return
	hint_visible = true
	coin_label.text = "★ %d" % AppState.coins()
	if game_id == "unicorn_blast":
		message_label.text = "Blast: %s" % _urgent_blast_word()
	elif game_id == "letter_lift":
		_render_letter_lift()
	elif phase in ["sentence", "syllable", "scramble", "size"]:
		_render_sequence()
	elif game_id == "missing_magic":
		_render_missing_magic()
	elif game_id == "sight_spark" and phase == "type":
		prompt_label.text = expected_word
	elif game_id == "prefix_potion":
		prompt_label.text = "%s + %s = %s" % [current.get("prefix", ""), current.get("root", ""), current.get("answer", "")]
	else:
		message_label.text = _hint_text()


func _hint_text() -> String:
	match game_id:
		"vowel_vines": return "Pick the word starting with %s." % str(current.get("vowel", "")).to_upper()
		"caption_quest", "missing_magic", "prefix_potion", "opposite_orbit": return "Try: %s" % current.get("answer", "")
		"odd_one_out": return "Investigate: %s" % current.get("odd", "")
		"chain_link": return "Start with %s." % str(current.get("start", "")).right(1).to_upper()
	return "Look closely at the prompt."


func _fail_reason() -> String:
	match game_id:
		"sentence_sprout": return "Tap words in the right order!"
		"missing_magic": return "Fill the magic blank!"
		"sight_spark": return "Spell the spark word from memory!"
		"prefix_potion": return "Brew the real word!"
		"vowel_vines": return "Choose a word beginning with the target vowel!"
		"letter_lift": return "Type each letter in order!"
		"syllable_stamp": return "Stamp syllables in order!"
		"caption_quest": return "Out of hearts—choose the best caption!"
		"opposite_orbit": return "Pick the word that means the opposite!"
		"scramble_spell": return "Tap letters in order to spell the word!"
		"odd_one_out": return "Find the item that does not belong!"
		"size_line_up": return "Tap shortest word first, then longer ones!"
		"chain_link": return "Pick a word beginning with the last letter!"
		"unicorn_blast": return "Words reached your cannon!"
	return "Try this level again."


func _update_blast(delta: float) -> void:
	spawn_elapsed += delta
	if spawn_elapsed * 1000.0 >= Rules.blast_spawn_ms(level):
		spawn_elapsed = 0.0
		_spawn_blast_word()
	var escaped: Array[int] = []
	for index in blast_words.size():
		var entry: Dictionary = blast_words[index]
		entry["y"] = float(entry.get("y", 8.0)) + Rules.blast_speed(level) * delta * 60.0
		_position_blast_word(entry)
		if entry["y"] > 90.0:
			escaped.append(index)
	for position in range(escaped.size() - 1, -1, -1):
		_remove_blast_word(escaped[position])
		_lost_life()
		if not active:
			break
	if hint_visible and active:
		message_label.text = "Blast: %s" % _urgent_blast_word()


func _spawn_blast_word() -> void:
	if not active:
		return
	var words := Rules.words_for_level(level)
	var text := str(words[rng.randi_range(0, words.size() - 1)])
	var button := Button.new()
	button.text = text
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.custom_minimum_size = Vector2(104, 42)
	play_area.add_child(button)
	var entry := {"text": text, "x": rng.randf_range(12.0, 76.0), "y": 8.0, "button": button}
	blast_words.append(entry)
	_position_blast_word(entry)


func _position_blast_word(entry: Dictionary) -> void:
	var button: Button = entry["button"]
	var width := maxf(play_area.size.x, 430.0)
	var height := maxf(play_area.size.y, 330.0)
	button.position = Vector2(width * float(entry["x"]) / 100.0 - 52.0, height * float(entry["y"]) / 100.0)
	_position_cannon()


func _position_cannon() -> void:
	if is_instance_valid(cannon_assembly):
		cannon_assembly.position = Vector2(maxf(0.0, play_area.size.x * 0.5 - cannon_assembly.size.x * 0.5), maxf(0.0, play_area.size.y - cannon_assembly.size.y - 8.0))


func _launch_blast_projectile(index: int) -> void:
	if index < 0 or index >= blast_words.size() or not is_instance_valid(cannon_preview):
		return
	var target: Button = blast_words[index].get("button")
	if not is_instance_valid(target):
		return
	target.disabled = true
	target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pending_blast_targets.append(target)
	var projectile := RoomItemPreviewScene.new()
	projectile.name = "UnicornBlastProjectile"
	projectile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	projectile.size = Vector2(64, 52)
	projectile.position = _cannon_muzzle_position() - projectile.size * 0.5
	projectile.setup({"id": "companion_%s" % AppState.equipped_companion(), "category": "companions", "animate": true, "presentation": "marketplace"})
	play_area.add_child(projectile)
	blast_projectiles.append(projectile)
	var target_position := target.position + target.size * 0.5 - projectile.size * 0.5
	var duration := 0.10 if AppState.setting("reduced_motion", false) else 0.32
	var tween := create_tween()
	tween.tween_property(projectile, "position", target_position, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(projectile, "modulate:a", 0.0, 0.08)
	tween.finished.connect(func() -> void:
		blast_projectiles.erase(projectile)
		if is_instance_valid(projectile):
			projectile.queue_free()
		pending_blast_targets.erase(target)
		if is_instance_valid(target):
			target.queue_free()
	)


func _cannon_muzzle_position() -> Vector2:
	if is_instance_valid(cannon_assembly):
		return cannon_assembly.position + Vector2(cannon_assembly.size.x - 18.0, cannon_assembly.size.y * 0.38)
	return play_area.size * Vector2(0.5, 0.9)


func _remove_blast_word(index: int, preserve_visual := false) -> void:
	if index < 0 or index >= blast_words.size():
		return
	var button: Button = blast_words[index].get("button")
	if is_instance_valid(button) and not preserve_visual:
		button.queue_free()
	blast_words.remove_at(index)


func _clear_blast_words() -> void:
	for entry in blast_words:
		var button: Button = entry.get("button")
		if is_instance_valid(button):
			button.queue_free()
	blast_words.clear()
	for projectile in blast_projectiles:
		if is_instance_valid(projectile):
			projectile.queue_free()
	blast_projectiles.clear()
	for target in pending_blast_targets:
		if is_instance_valid(target):
			target.queue_free()
	pending_blast_targets.clear()


func _urgent_blast_word() -> String:
	var urgent := ""
	var highest := -1.0
	for entry in blast_words:
		if float(entry.get("y", 0.0)) > highest:
			highest = float(entry["y"])
			urgent = str(entry["text"])
	return urgent


func _hide_special_controls() -> void:
	input_line.hide()
	input_line.editable = true
	_set_input_text("")
	play_area.hide()


func _show_text_input(placeholder: String) -> void:
	input_line.placeholder_text = placeholder
	input_line.editable = true
	input_line.show()
	input_line.grab_focus()


func _set_input_text(value: String) -> void:
	suppress_text_event = true
	input_line.text = value
	input_line.caret_column = value.length()
	suppress_text_event = false


func _clear_options() -> void:
	for child in options.get_children():
		options.remove_child(child)
		child.queue_free()


func _add_option(text: String, payload) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 72)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 19)
	button.pressed.connect(_choose.bind(payload))
	options.add_child(button)


func _go_back() -> void:
	AppState.set_shell_destination("category", str(game_info.get("category", "Word")))
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = NAVY
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	var back := Button.new()
	StorybookUI.apply_game_action(back, 120)
	back.text = "‹ BACK"
	back.pressed.connect(_go_back)
	header.add_child(back)
	title_label = Label.new()
	title_label.text = str(game_info.get("title", "WORD GAME")).to_upper()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 25)
	title_label.add_theme_color_override("font_color", PINK if game_info.get("category") == "Word" else CYAN)
	header.add_child(title_label)
	coin_label = Label.new()
	coin_label.text = "★ %d" % AppState.coins()
	coin_label.add_theme_color_override("font_color", YELLOW)
	coin_label.add_theme_color_override("font_outline_color", StorybookUI.PLUM)
	coin_label.add_theme_constant_override("outline_size", 3)
	coin_label.add_theme_font_size_override("font_size", 24)
	header.add_child(coin_label)
	layout.add_child(header)
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 18)
	level_label = Label.new()
	stats.add_child(level_label)
	progress_label = Label.new()
	stats.add_child(progress_label)
	lives_label = Label.new()
	lives_label.add_theme_color_override("font_color", PINK)
	stats.add_child(lives_label)
	timer_label = Label.new()
	stats.add_child(timer_label)
	layout.add_child(stats)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	layout.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	scroll.add_child(content)
	instruction_label = Label.new()
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	StorybookUI.apply_story_label(instruction_label, Color("c8d2ff"), 18, true)
	content.add_child(instruction_label)
	var prompt_plaque := PanelContainer.new()
	prompt_plaque.name = "WordPromptPlaque"
	StorybookUI.apply_prompt_plaque(prompt_plaque, Color("fff3d6"))
	content.add_child(prompt_plaque)
	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	prompt_label.custom_minimum_size = Vector2(0, 78)
	StorybookUI.apply_story_label(prompt_label, Color("9c356d"), 36, false)
	prompt_plaque.add_child(prompt_label)
	secondary_label = Label.new()
	secondary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	secondary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	StorybookUI.apply_story_label(secondary_label, Color("62e6a7"), 20, true)
	content.add_child(secondary_label)
	var play_frame := PanelContainer.new()
	play_frame.name = "WordPlayFrame"
	play_frame.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("14214a"), Color("e1ae4f"), 18))
	content.add_child(play_frame)
	play_area = Control.new()
	play_area.custom_minimum_size = Vector2(0, 430)
	play_area.clip_contents = true
	var play_bg := ColorRect.new()
	play_bg.color = Color("0d1738")
	play_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	play_area.add_child(play_bg)
	cannon_assembly = PanelContainer.new()
	cannon_assembly.name = "UnicornBlastCannon"
	cannon_assembly.custom_minimum_size = Vector2(172, 106)
	cannon_assembly.size = Vector2(172, 106)
	cannon_assembly.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cannon_assembly.add_theme_stylebox_override("panel", StorybookUI.plaque_style(Color("26366d"), Color("ffe172"), 18))
	play_area.add_child(cannon_assembly)
	# PanelContainer owns exactly one layout child. The inner canvas is a plain
	# Control so the barrel, muzzle, and equipped-unicorn art retain their
	# authored positions rather than being reflowed by the panel container.
	var cannon_canvas := Control.new()
	cannon_canvas.name = "CannonCanvas"
	cannon_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cannon_assembly.add_child(cannon_canvas)
	var barrel := ColorRect.new()
	barrel.name = "CannonRainbowBarrel"
	barrel.color = Color("58d6e8")
	barrel.position = Vector2(92, 25)
	barrel.size = Vector2(76, 26)
	barrel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cannon_canvas.add_child(barrel)
	var muzzle := ColorRect.new()
	muzzle.name = "CannonMuzzle"
	muzzle.color = Color("ffe172")
	muzzle.position = Vector2(152, 20)
	muzzle.size = Vector2(20, 36)
	muzzle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cannon_canvas.add_child(muzzle)
	cannon_preview = RoomItemPreviewScene.new()
	cannon_preview.name = "CannonEquippedUnicornAmmo"
	cannon_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cannon_preview.size = Vector2(98, 82)
	cannon_preview.position = Vector2(4, 12)
	cannon_preview.setup({"id": "companion_%s" % AppState.equipped_companion(), "category": "companions", "animate": true, "presentation": "marketplace"})
	cannon_canvas.add_child(cannon_preview)
	play_area.resized.connect(_position_cannon)
	play_frame.add_child(play_area)
	input_line = LineEdit.new()
	input_line.custom_minimum_size = Vector2(0, 58)
	input_line.add_theme_font_size_override("font_size", 22)
	input_line.text_changed.connect(_on_text_changed)
	input_line.text_submitted.connect(_on_text_submitted)
	content.add_child(input_line)
	options = GridContainer.new()
	options.columns = 2
	options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options.add_theme_constant_override("h_separation", 10)
	options.add_theme_constant_override("v_separation", 10)
	content.add_child(options)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(0, 48)
	message_label.add_theme_font_size_override("font_size", 17)
	content.add_child(message_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	layout.add_child(actions)
	hint_button = Button.new()
	StorybookUI.apply_game_action(hint_button, 140)
	hint_button.pressed.connect(_show_hint)
	actions.add_child(hint_button)
	retry_button = Button.new()
	StorybookUI.apply_game_action(retry_button, 160)
	retry_button.pressed.connect(_start_level)
	actions.add_child(retry_button)
	flash_timer = Timer.new()
	flash_timer.one_shot = true
	flash_timer.timeout.connect(_finish_sight_flash)
	add_child(flash_timer)
