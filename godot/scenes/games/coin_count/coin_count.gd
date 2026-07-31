extends Control

const COIN_TYPES := [
	{ "id": "p", "v": 1, "label": "1¢" },
	{ "id": "n", "v": 5, "label": "5¢" },
	{ "id": "d", "v": 10, "label": "10¢" },
	{ "id": "q", "v": 25, "label": "25¢" },
]

var _target: int = 0
var _current: int = 0
var _target_label: Label
var _current_label: Label
var _progress: ProgressBar
var _hint_label: Label


func _ready() -> void:
	GameSession.reset_for_game()
	GameSession.state_changed.connect(_refresh_hud)
	GameSession.level_completed.connect(_on_level_complete)

	UiFactory.make_panel(self)
	UiFactory.make_header(self, "Coin Count", func(): SceneRouter.pop(), int(SaveManager.user_data.coins))

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_top = 72
	root.add_theme_constant_override("separation", 16)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(root)

	_target_label = Label.new()
	_target_label.add_theme_font_size_override("font_size", 22)
	root.add_child(_target_label)

	_current_label = Label.new()
	_current_label.add_theme_font_size_override("font_size", 32)
	_current_label.add_theme_color_override("font_color", UiFactory.CYAN)
	root.add_child(_current_label)

	_progress = ProgressBar.new()
	_progress.custom_minimum_size = Vector2(260, 24)
	_progress.max_value = 100
	root.add_child(_progress)

	_hint_label = Label.new()
	_hint_label.add_theme_color_override("font_color", UiFactory.PINK)
	root.add_child(_hint_label)

	var coins_row := HBoxContainer.new()
	coins_row.add_theme_constant_override("separation", 12)
	root.add_child(coins_row)
	for c in COIN_TYPES:
		var btn := UiFactory.make_button(c.label)
		var value: int = c.v
		btn.pressed.connect(func(): _add_coin(value))
		coins_row.add_child(btn)

	var hint_btn := UiFactory.make_button("Hint (5🪙)")
	hint_btn.pressed.connect(func(): GameSession.buy_hint())
	root.add_child(hint_btn)

	var last := SaveManager.get_game_last_level("coin")
	var start_lvl := last if last > 0 else 1
	_launch_level(start_lvl)


func _launch_level(lvl: int) -> void:
	var tgt: int
	if lvl <= 3:
		tgt = (randi() % 9 + 1) * 5
	elif lvl <= 8:
		tgt = randi() % 100 + 25
	else:
		tgt = randi() % 400 + 100
	_target = tgt
	_current = 0
	GameSession.start_level(lvl)
	_refresh_hud()


func _add_coin(value: int) -> void:
	if GameSession.state != GameSession.State.PLAYING:
		return
	_current += value
	var ok := _current <= _target
	GameSession.register_move(ok)
	if _current == _target:
		GameSession.complete_level()
	elif _current > _target:
		GameSession.fail_level("Overshot target!")
	_refresh_hud()


func _best_coin() -> Dictionary:
	var remaining := _target - _current
	var sorted := COIN_TYPES.duplicate()
	sorted.sort_custom(func(a, b): return a.v > b.v)
	for c in sorted:
		if c.v <= remaining:
			return c
	return {}


func _refresh_hud() -> void:
	_target_label.text = "Target: $%.2f" % (_target / 100.0)
	_current_label.text = "Current: $%.2f" % (_current / 100.0)
	var pct := 0.0 if _target == 0 else minf(100.0, (_current / float(_target)) * 100.0)
	_progress.value = pct

	if GameSession.show_hint:
		var coin := _best_coin()
		_hint_label.text = "Hint: try %s" % coin.get("label", "?")
	else:
		_hint_label.text = ""

	if GameSession.state == GameSession.State.FAILED:
		_current_label.text = GameSession.fail_message if GameSession.fail_message else "Try again!"
		get_tree().create_timer(1.2).timeout.connect(func(): _launch_level(GameSession.level), CONNECT_ONE_SHOT)
		return

	if GameSession.state == GameSession.State.PLAYING:
			_current_label.text = "Current: $%.2f  (Lv %d · %.1fs)" % [
				_current / 100.0,
				GameSession.level,
				GameSession.elapsed_seconds(),
			]


func _on_level_complete(level: int, time_sec: float) -> void:
	SaveManager.save_game_progress("coin", level, time_sec)
	var overlay := _build_victory(level, time_sec)
	add_child(overlay)


func _build_victory(level: int, time_sec: float) -> Control:
	var layer := ColorRect.new()
	layer.color = Color(0, 0, 0, 0.65)
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	layer.add_child(box)

	var title := UiFactory.make_title("Level Complete!")
	box.add_child(title)

	var info := Label.new()
	info.text = "Time: %.2fs · +%d coins" % [time_sec, SaveManager.calc_coins(level)]
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)

	var next := UiFactory.make_button("Next Level", UiFactory.PINK)
	next.pressed.connect(func():
		layer.queue_free()
		_launch_level(level + 1)
	)
	box.add_child(next)

	var exit := UiFactory.make_button("Back to games")
	exit.pressed.connect(func(): SceneRouter.pop())
	box.add_child(exit)

	return layer
