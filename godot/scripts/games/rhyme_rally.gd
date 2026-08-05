extends Control

const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")

const CHALLENGES := [
	{"prompt": "cat", "answer": "hat", "options": ["hat", "dog", "cup", "pen"]},
	{"prompt": "sun", "answer": "fun", "options": ["fun", "cat", "bed", "log"]},
	{"prompt": "hop", "answer": "top", "options": ["top", "red", "sit", "map"]},
	{"prompt": "bug", "answer": "rug", "options": ["rug", "fan", "kit", "den"]},
	{"prompt": "pig", "answer": "wig", "options": ["wig", "box", "mud", "tub"]},
	{"prompt": "bee", "answer": "tree", "options": ["tree", "sky", "ant", "owl"]},
	{"prompt": "car", "answer": "star", "options": ["star", "moon", "blue", "rain"]},
	{"prompt": "cake", "answer": "lake", "options": ["lake", "milk", "frog", "wind"]},
	{"prompt": "ring", "answer": "king", "options": ["king", "gold", "ball", "song"]},
	{"prompt": "boat", "answer": "coat", "options": ["coat", "ship", "sand", "fish"]},
	{"prompt": "light", "answer": "night", "options": ["night", "cloud", "tree", "grass"]},
	{"prompt": "snail", "answer": "trail", "options": ["trail", "shell", "pond", "leaf"]},
	{"prompt": "sing", "answer": "wing", "options": ["wing", "drum", "note", "horn"]},
	{"prompt": "mouse", "answer": "house", "options": ["house", "cheese", "tail", "barn"]},
	{"prompt": "spoon", "answer": "moon", "options": ["moon", "fork", "plate", "bowl"]},
	{"prompt": "frog", "answer": "log", "options": ["log", "pond", "hop", "lily"]},
	{"prompt": "bright", "answer": "kite", "options": ["kite", "dark", "shade", "cloud"]},
	{"prompt": "snake", "answer": "rake", "options": ["rake", "grass", "hiss", "scale"]},
	{"prompt": "queen", "answer": "green", "options": ["green", "crown", "royal", "throne"]},
	{"prompt": "flower", "answer": "tower", "options": ["tower", "petal", "stem", "vase"]},
	{"prompt": "thunder", "answer": "wonder", "options": ["wonder", "storm", "flash", "rain"]},
	{"prompt": "feather", "answer": "weather", "options": ["weather", "bird", "soft", "fluff"]},
	{"prompt": "dragon", "answer": "wagon", "options": ["wagon", "fire", "scale", "knight"]},
	{"prompt": "balloon", "answer": "cartoon", "options": ["cartoon", "float", "string", "party"]},
]

var level := 1
var round_index := 0
var target_rounds := 0
var challenge: Dictionary = {}
var started_ms := 0
var prompt_label: Label
var progress_label: Label
var message_label: Label
var option_buttons: Array[Button] = []


static func target_for_level(for_level: int) -> int:
	return mini(12, 3 + int(floor(1.2 * for_level)))


func _ready() -> void:
	level = AppState.current_level("rhyme_rally")
	_build_ui()
	_start_level()


func _start_level() -> void:
	round_index = 0
	target_rounds = target_for_level(level)
	started_ms = Time.get_ticks_msec()
	message_label.text = "Pick the word that rhymes. One wrong answer ends the level."
	_show_round()


func _show_round() -> void:
	var ceiling := mini(CHALLENGES.size(), maxi(4, roundi((level + round_index) * 1.5)))
	var floor_index := maxi(0, ceiling - maxi(5, roundi(ceiling * 0.6)))
	challenge = CHALLENGES[randi_range(floor_index, ceiling - 1)].duplicate(true)
	var options: Array = challenge["options"].duplicate()
	options.shuffle()
	prompt_label.text = challenge["prompt"]
	progress_label.text = "%d / %d" % [round_index, target_rounds]
	for index in option_buttons.size():
		option_buttons[index].text = options[index]
		option_buttons[index].disabled = false


func _pick(answer: String) -> void:
	if answer != challenge["answer"]:
		message_label.text = "Pick the word that rhymes! Try this level again."
		_set_enabled(false)
		return
	round_index += 1
	if round_index >= target_rounds:
		var reward := AppState.complete_level("rhyme_rally", level, Time.get_ticks_msec() - started_ms)
		message_label.text = "Rhyme Rally complete! +%d coins" % reward
		level += 1
		_set_enabled(false)
	else:
		_show_round()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("08112f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 36)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 20)
	margin.add_child(layout)
	var title := Label.new()
	title.text = "RHYME RALLY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("f26fa7"))
	layout.add_child(title)
	var instruction := Label.new()
	instruction.text = "What rhymes with"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instruction.add_theme_font_size_override("font_size", 20)
	layout.add_child(instruction)
	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 64)
	prompt_label.add_theme_color_override("font_color", Color("ffd166"))
	layout.add_child(prompt_label)
	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(progress_label)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	layout.add_child(grid)
	for index in 4:
		var button := Button.new()
		button.custom_minimum_size = Vector2(250, 100)
		button.add_theme_font_size_override("font_size", 24)
		button.pressed.connect(func() -> void: _pick(button.text))
		grid.add_child(button)
		option_buttons.append(button)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(message_label)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(actions)
	var retry := Button.new()
	StorybookUI.apply_game_action(retry, 170)
	retry.text = "Retry / Next"
	retry.pressed.connect(_start_level)
	actions.add_child(retry)
	var back := Button.new()
	StorybookUI.apply_game_action(back, 160)
	back.text = "Word Games"
	back.pressed.connect(func() -> void:
		AppState.set_shell_destination("category", "Word")
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	actions.add_child(back)


func _set_enabled(enabled: bool) -> void:
	for button in option_buttons:
		button.disabled = not enabled
