extends Control
class_name GameFrame

const GameArena3DScript = preload("res://scenes/games/shared/game_arena_3d.gd")

var game_id: String = ""
var game_title: String = ""
var _play_area: VBoxContainer
var _status: Label
var _hint_btn: Button
var _overlay: Control
var _arena


func mount(game_id_in: String, title: String) -> void:
	game_id = game_id_in
	game_title = title
	GameSession.reset_for_game()
	GameSession.state_changed.connect(_on_session_changed)
	GameSession.level_completed.connect(_on_level_completed)

	UiFactory.add_background(self)
	var equipped: String = String(SaveManager.user_data.get("equippedUnicorn", "sparkle"))

	UiFactory.make_header_bar(self, {
		"subscreen": true,
		"title": title,
		"coins": int(SaveManager.user_data.get("coins", 0)),
		"on_back": func(): SceneRouter.pop(),
		"on_profile": func(): SceneRouter.go_home(false),
	})

	var body := UiFactory.make_screen_body(self, 88)

	_arena = GameArena3DScript.new()
	_arena.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_arena)
	_arena.configure(equipped)

	_play_area = VBoxContainer.new()
	_play_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_play_area.add_theme_constant_override("separation", 12)
	_play_area.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(_play_area)

	_status = UiFactory.make_subtitle("Level 1")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_play_area.add_child(_status)

	_hint_btn = UiFactory.make_button("Hint · 5 coins", UiFactory.VIOLET, 44)
	_hint_btn.pressed.connect(func(): GameSession.buy_hint())
	_play_area.add_child(_hint_btn)

	var start_lvl := SaveManager.get_game_last_level(game_id)
	if start_lvl <= 0:
		start_lvl = 1
	begin_level(start_lvl)


func play_area() -> VBoxContainer:
	return _play_area


func game_arena() -> Node:
	return _arena


func clear_play_children() -> void:
	for c in _play_area.get_children():
		if c != _status and c != _hint_btn:
			_play_area.remove_child(c)
			c.queue_free()


func begin_level(lvl: int) -> void:
	GameSession.start_level(lvl)
	_update_status()
	on_level_started(lvl)


func on_level_started(_lvl: int) -> void:
	pass


func win_level() -> void:
	GameSession.complete_level()


func fail_level(msg: String = "") -> void:
	GameSession.fail_level(msg)


func _round_index() -> int:
	return 0


func _round_target_index() -> int:
	return 0


func _update_status() -> void:
	_status.text = "Level %d · %.1fs · Round %d/%d" % [
		GameSession.level,
		GameSession.elapsed_seconds(),
		_round_index(),
		_round_target_index(),
	]


func _on_session_changed() -> void:
	_update_status()
	if GameSession.state == GameSession.State.FAILED:
		get_tree().create_timer(1.0).timeout.connect(
			func(): begin_level(GameSession.level),
			CONNECT_ONE_SHOT
		)


func _on_level_completed(level: int, time_sec: float) -> void:
	SaveManager.save_game_progress(game_id, level, time_sec)
	_show_victory(level, time_sec)


func _show_victory(level: int, time_sec: float) -> void:
	if _overlay:
		_overlay.queue_free()
	_overlay = ColorRect.new()
	_overlay.color = Color(0, 0, 0, 0.8)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.z_index = 50
	add_child(_overlay)
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_CENTER)
	box.add_theme_constant_override("separation", 10)
	_overlay.add_child(box)
	box.add_child(UiFactory.make_title("Level complete!", 28))
	var info := UiFactory.make_subtitle(
		"%.2fs · +%d coins" % [time_sec, SaveManager.calc_coins(level)]
	)
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)
	var next := UiFactory.make_button("Next level", UiFactory.EMERALD, 48)
	next.pressed.connect(func():
		_overlay.queue_free()
		_overlay = null
		begin_level(level + 1)
	)
	box.add_child(next)
	var back := UiFactory.make_button("Back", UiFactory.SLATE_700, 44)
	back.pressed.connect(func(): SceneRouter.pop())
	box.add_child(back)
