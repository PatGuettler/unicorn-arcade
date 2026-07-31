extends Control

const Rules = preload("res://scripts/games/gameplay_rules.gd")

var level := 1
var target := 0
var completed := 0
var active := false
var started_ms := 0
var problem: Dictionary = {}
var cards: Array[Button] = []
var press_start := {}
var problem_label: Label
var progress_label: Label
var message_label: Label
var action_button: Button


func _ready() -> void:
	level = AppState.current_level("math_swipe")
	_build_ui()
	_start_level(level)


func _start_level(for_level: int) -> void:
	level = for_level
	target = Rules.math_swipe_target(level)
	completed = 0
	started_ms = Time.get_ticks_msec()
	active = true
	action_button.hide()
	message_label.text = "Swipe in any direction, or tap, to choose."
	_new_problem()


func generate_problem(for_level: int, rng: RandomNumberGenerator = null) -> Dictionary:
	if rng == null:
		rng = RandomNumberGenerator.new()
		rng.randomize()
	var operation := "+"
	var num1 := 0
	var num2 := 0
	var answer := 0
	if for_level <= 3:
		num1 = rng.randi_range(1, 8)
		num2 = rng.randi_range(1, 8)
		answer = num1 + num2
	elif for_level <= 6:
		operation = "-"
		answer = rng.randi_range(1, 8)
		num2 = rng.randi_range(1, answer)
		num1 = answer + num2
	elif for_level <= 10:
		operation = "+" if rng.randf() > 0.5 else "-"
		if operation == "+":
			num1 = rng.randi_range(5, 19)
			num2 = rng.randi_range(5, 19)
			answer = num1 + num2
		else:
			answer = rng.randi_range(5, 19)
			num2 = rng.randi_range(1, answer)
			num1 = answer + num2
	else:
		var choice := rng.randf()
		if choice < 0.4:
			operation = "x"
			num1 = rng.randi_range(2, 11)
			num2 = rng.randi_range(2, 11)
			answer = num1 * num2
		elif choice < 0.7:
			num1 = rng.randi_range(10, 29)
			num2 = rng.randi_range(10, 29)
			answer = num1 + num2
		else:
			operation = "-"
			answer = rng.randi_range(10, 29)
			num2 = rng.randi_range(1, answer)
			num1 = answer + num2
	var missing := rng.randi_range(0, 2)
	var correct: int = [num1, num2, answer][missing]
	var display := "? %s %d = %d" % [operation, num2, answer]
	if missing == 1:
		display = "%d %s ? = %d" % [num1, operation, answer]
	elif missing == 2:
		display = "%d %s %d = ?" % [num1, operation, num2]
	var wrong: int = correct
	while wrong == correct or wrong < 0:
		var offset := rng.randi_range(-3, 3)
		wrong = correct + (1 if offset == 0 else offset)
	return {"display": display, "correct": correct, "wrong": wrong, "operation": operation}


func _new_problem() -> void:
	problem = generate_problem(level)
	problem_label.text = problem["display"]
	progress_label.text = "LEVEL %d     %d / %d" % [level, completed, target]
	var correct_left := randf() > 0.5
	for index in cards.size():
		var is_correct := (index == 0) == correct_left
		cards[index].text = str(problem["correct"] if is_correct else problem["wrong"])
		cards[index].set_meta("correct", is_correct)
		cards[index].disabled = false
		cards[index].modulate = Color.WHITE


func _submit(card: Button) -> void:
	if not active:
		return
	if bool(card.get_meta("correct")):
		completed += 1
		if completed >= target:
			active = false
			var reward := AppState.complete_level("math_swipe", level, Time.get_ticks_msec() - started_ms)
			message_label.text = "Level complete! +%d coins" % reward
			action_button.text = "Next Level"
			action_button.show()
			_set_cards_enabled(false)
		else:
			message_label.text = "Correct!"
			_new_problem.call_deferred()
	else:
		active = false
		message_label.text = "Wrong answer! Try this level again."
		action_button.text = "Retry"
		action_button.show()
		_set_cards_enabled(false)


func _card_input(event: InputEvent, card: Button) -> void:
	if not active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			press_start[card] = event.position
		else:
			var distance: float = event.position.distance_to(press_start.get(card, event.position))
			if distance < 5.0 or distance > 80.0:
				_submit(card)
			press_start.erase(card)
	elif event is InputEventScreenTouch:
		if event.pressed:
			press_start[card] = event.position
		else:
			var distance: float = event.position.distance_to(press_start.get(card, event.position))
			if distance < 5.0 or distance > 80.0:
				_submit(card)
			press_start.erase(card)


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("100b2b")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_bottom", 26)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var root := VBoxContainer.new()
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_theme_constant_override("separation", 18)
	margin.add_child(root)
	var title := Label.new()
	title.text = "MATH SWIPE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("61e7ff"))
	root.add_child(title)
	progress_label = Label.new()
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.add_theme_font_size_override("font_size", 18)
	root.add_child(progress_label)
	var prompt := Label.new()
	prompt.text = "SOLVE THE EQUATION"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_color", Color("99a6c8"))
	root.add_child(prompt)
	problem_label = Label.new()
	problem_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	problem_label.add_theme_font_size_override("font_size", 48)
	problem_label.custom_minimum_size.y = 90
	root.add_child(problem_label)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	root.add_child(row)
	for index in 2:
		var card := Button.new()
		card.custom_minimum_size = Vector2(220, 260)
		card.add_theme_font_size_override("font_size", 72)
		card.gui_input.connect(_card_input.bind(card))
		row.add_child(card)
		cards.append(card)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 18)
	root.add_child(message_label)
	action_button = Button.new()
	action_button.pressed.connect(func() -> void: _start_level(level + 1 if action_button.text == "Next Level" else level))
	root.add_child(action_button)
	var back := Button.new()
	back.text = "Number Games"
	back.pressed.connect(func() -> void:
		AppState.set_shell_destination("category", "Number")
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)
	root.add_child(back)


func _set_cards_enabled(enabled: bool) -> void:
	for card in cards:
		card.disabled = not enabled
