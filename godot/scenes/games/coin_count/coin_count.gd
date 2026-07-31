extends Control

const COIN_TYPES := [
	{ "v": 1, "label": "1¢", "tex": "res://assets/coins/penny.png" },
	{ "v": 5, "label": "5¢", "tex": "res://assets/coins/nickle.png" },
	{ "v": 10, "label": "10¢", "tex": "res://assets/coins/dime.png" },
	{ "v": 25, "label": "25¢", "tex": "res://assets/coins/quarter.png" },
]

var _target: int = 0
var _current: int = 0
var _target_label: Label
var _current_label: Label
var _progress: ProgressBar
var _hint_label: Label
var _status_label: Label


func _ready() -> void:
	GameSession.reset_for_game()
	GameSession.state_changed.connect(_refresh_hud)
	GameSession.level_completed.connect(_on_level_complete)

	UiFactory.add_background(self)
	var coins: int = int(SaveManager.user_data.get("coins", 0))
	UiFactory.make_header_bar(self, {
		"subscreen": true,
		"title": "Coin Count",
		"coins": coins,
		"on_back": func(): SceneRouter.pop(),
		"on_profile": func(): SceneRouter.go_home(false),
	})

	var body := UiFactory.make_screen_body(self, 88)
	var root := VBoxContainer.new()
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 18)
	root.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(root)

	_target_label = UiFactory.make_subtitle("Target")
	_target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_target_label)

	_current_label = UiFactory.make_title("$0.00", 36)
	_current_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_current_label.add_theme_color_override("font_color", UiFactory.CYAN)
	root.add_child(_current_label)

	_progress = ProgressBar.new()
	_progress.custom_minimum_size = Vector2(300, 18)
	_progress.max_value = 100
	_progress.show_percentage = false
	var pg := UiFactory.stylebox_flat(UiFactory.SLATE_800, 8)
	var fill := UiFactory.stylebox_flat(UiFactory.PINK, 8)
	_progress.add_theme_stylebox_override("background", pg)
	_progress.add_theme_stylebox_override("fill", fill)
	root.add_child(_progress)

	_status_label = UiFactory.make_subtitle("Level 1")
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_status_label)

	_hint_label = Label.new()
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_color_override("font_color", UiFactory.VIOLET)
	root.add_child(_hint_label)

	var coins_row := HBoxContainer.new()
	coins_row.alignment = BoxContainer.ALIGNMENT_CENTER
	coins_row.add_theme_constant_override("separation", 14)
	root.add_child(coins_row)
	for c in COIN_TYPES:
		var value: int = int(c.v)
		var btn := UiFactory.make_coin_button(value, String(c.tex))
		btn.pressed.connect(func(): _add_coin(value))
		coins_row.add_child(btn)

	var hint_btn := UiFactory.make_button("Hint · 5 coins", UiFactory.VIOLET, 48)
	hint_btn.pressed.connect(func(): GameSession.buy_hint())
	root.add_child(hint_btn)

	var last: int = SaveManager.get_game_last_level("coin")
	var start_lvl: int = last if last > 0 else 1
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
	var ok: bool = _current <= _target
	GameSession.register_move(ok)
	if _current == _target:
		GameSession.complete_level()
	elif _current > _target:
		GameSession.fail_level("Too much!")
	_refresh_hud()


func _best_coin() -> Dictionary:
	var remaining := _target - _current
	var sorted: Array = COIN_TYPES.duplicate()
	sorted.sort_custom(func(a, b): return int(a.v) > int(b.v))
	for c in sorted:
		if int(c.v) <= remaining:
			return c
	return {}


func _refresh_hud() -> void:
	_target_label.text = "Make exactly $%.2f" % (_target / 100.0)
	var pct: float = 0.0 if _target == 0 else minf(100.0, (_current / float(_target)) * 100.0)
	_progress.value = pct

	if GameSession.show_hint:
		var coin: Dictionary = _best_coin()
		_hint_label.text = "Hint: tap %s" % coin.get("label", "?")
	else:
		_hint_label.text = ""

	match GameSession.state:
		GameSession.State.PLAYING:
			_current_label.text = "$%.2f" % (_current / 100.0)
			_status_label.text = "Level %d · %.1fs" % [GameSession.level, GameSession.elapsed_seconds()]
		GameSession.State.FAILED:
			_current_label.text = GameSession.fail_message
			get_tree().create_timer(1.0).timeout.connect(
				func(): _launch_level(GameSession.level),
				CONNECT_ONE_SHOT
			)
		GameSession.State.LEVEL_COMPLETE:
			_status_label.text = "Nice!"


func _on_level_complete(level: int, time_sec: float) -> void:
	SaveManager.save_game_progress("coin", level, time_sec)
	_show_victory(level, time_sec)


func _show_victory(level: int, time_sec: float) -> void:
	var layer := ColorRect.new()
	layer.color = Color(0, 0, 0, 0.75)
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.z_index = 100
	add_child(layer)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.add_theme_constant_override("separation", 12)
	layer.add_child(box)

	box.add_child(UiFactory.make_title("Level complete!", 32))
	var info := UiFactory.make_subtitle(
		"Time %.2fs · earned %d coins" % [time_sec, SaveManager.calc_coins(level)]
	)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)

	var next := UiFactory.make_button("Next level", UiFactory.EMERALD, 48)
	next.pressed.connect(func():
		layer.queue_free()
		_launch_level(level + 1)
	)
	box.add_child(next)

	var exit := UiFactory.make_button("Back", UiFactory.SLATE_700, 48)
	exit.pressed.connect(func(): SceneRouter.pop())
	box.add_child(exit)
