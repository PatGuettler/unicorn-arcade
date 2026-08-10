extends ArcadeGameController

const COINS := {"Penny": 1, "Nickel": 5, "Dime": 10, "Quarter": 25}
const COIN_SIZES := {"Penny": 0.86, "Nickel": 0.96, "Dime": 0.76, "Quarter": 1.0}
const CoinChoiceButtonScene = preload("res://scripts/games/coin_choice_button.gd")
const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")

var level := 1
var target := 0
var total := 0
var started_ms := 0
var failed := false
var active := false
var target_label: Label
var total_label: Label
var message_label: Label
var coin_buttons: Array[Button] = []


static func target_bounds(for_level: int) -> Vector2i:
	if for_level <= 3:
		return Vector2i(5, 45)
	if for_level <= 8:
		return Vector2i(25, 124)
	return Vector2i(100, 499)


func _ready() -> void:
	level = AppState.current_level("coin_count")
	_build_ui()
	_start_round()


func _start_round() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if level <= 3:
		target = rng.randi_range(1, 9) * 5
	elif level <= 8:
		target = rng.randi_range(25, 124)
	else:
		target = rng.randi_range(100, 499)
	total = 0
	failed = false
	active = true
	started_ms = Time.get_ticks_msec()
	target_label.text = "Make %s" % _money(target)
	total_label.text = _money(total)
	message_label.text = "Tap coins. Exact wins; overshoot ends the round."
	for button in coin_buttons:
		button.modulate = Color.WHITE
	_set_buttons_enabled(true)


func _add_coin(value: int) -> void:
	if not active:
		return
	total += value
	total_label.text = _money(total)
	if total == target:
		active = false
		_set_buttons_enabled(false)
		var reward := AppState.complete_level("coin_count", level, Time.get_ticks_msec() - started_ms)
		message_label.text = "Perfect! +%d coins" % reward
		level += 1
	elif total > target:
		active = false
		failed = true
		message_label.text = "Too much—try this level again."
		_set_buttons_enabled(false)


func can_retry_failure() -> bool:
	return failed


func retry_failure() -> void:
	if failed:
		_start_round()


func _show_hint() -> void:
	if not active or total >= target:
		return
	var remaining := target - total
	var best := 1
	for value in COINS.values():
		if int(value) <= remaining and int(value) > best:
			best = int(value)
	for button in coin_buttons:
		button.modulate = Color("ffe172") if int(button.get_meta("coin_value", 0)) == best else Color.WHITE
	message_label.text = "%s is the biggest coin that still fits." % _money(best)

func can_show_hint() -> bool:
	return active and not failed and total < target


func _request_hint() -> void:
	if not can_show_hint():
		return
	if AppState.spend_hint(level):
		_show_hint()


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("08112f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 44)
	margin.add_theme_constant_override("margin_bottom", 32)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 22)
	margin.add_child(layout)
	var title := Label.new()
	title.text = "COIN COUNT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	StorybookUI.apply_story_label(title, Color("58d6e8"), 38, true)
	layout.add_child(title)
	var target_plaque := PanelContainer.new()
	StorybookUI.apply_prompt_plaque(target_plaque, Color("fff3d6"))
	layout.add_child(target_plaque)
	var target_stack := VBoxContainer.new()
	target_plaque.add_child(target_stack)
	target_label = Label.new()
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	StorybookUI.apply_story_label(target_label, Color("9c356d"), 30, false)
	target_stack.add_child(target_label)
	total_label = Label.new()
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	StorybookUI.apply_story_label(total_label, Color("172143"), 72, false)
	target_stack.add_child(total_label)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 18)
	layout.add_child(message_label)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	layout.add_child(grid)
	for coin_name in COINS:
		var button := CoinChoiceButtonScene.new()
		button.setup(coin_name, COINS[coin_name], COIN_SIZES[coin_name])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_add_coin.bind(COINS[coin_name]))
		button.set_meta("coin_value", COINS[coin_name])
		grid.add_child(button)
		coin_buttons.append(button)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(actions)
	var retry := Button.new()
	retry.text = "Retry / Next"
	retry.custom_minimum_size = Vector2(210, 58)
	StorybookUI.apply_game_action(retry, 210)
	retry.pressed.connect(_start_round)
	actions.add_child(retry)
	var hint := Button.new()
	StorybookUI.apply_game_action(hint, 120)
	hint.text = "Hint"
	hint.pressed.connect(_request_hint)
	actions.add_child(hint)
	var back := Button.new()
	back.text = "Number Games"
	back.custom_minimum_size = Vector2(210, 58)
	StorybookUI.apply_game_action(back, 210)
	back.pressed.connect(func() -> void:
		AppState.set_shell_destination("category", "Number")
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	actions.add_child(back)


func _set_buttons_enabled(enabled: bool) -> void:
	for button in coin_buttons:
		button.disabled = not enabled


func _money(cents: int) -> String:
	return "$%d.%02d" % [cents / 100, cents % 100]
