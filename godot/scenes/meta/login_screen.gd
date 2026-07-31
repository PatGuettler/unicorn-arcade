extends Control

var _name_field: LineEdit


func _ready() -> void:
	UiFactory.add_background(self)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(340, 0)
	column.add_theme_constant_override("separation", 0)
	center.add_child(column)

	var hero_frame := PanelContainer.new()
	hero_frame.add_theme_stylebox_override("panel", UiFactory.stylebox_flat(Color.BLACK, 20))
	var hero_tex := UiFactory.make_texture_rect(
		"res://assets/branding/login_hero.png",
		Vector2(340, 190)
	)
	hero_frame.add_child(hero_tex)
	column.add_child(hero_frame)

	var card := UiFactory.make_card_panel()
	var card_body := VBoxContainer.new()
	card_body.add_theme_constant_override("separation", 14)
	card.add_child(card_body)
	column.add_child(card)

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", 24)
	pad.add_theme_constant_override("margin_right", 24)
	pad.add_theme_constant_override("margin_top", 20)
	pad.add_theme_constant_override("margin_bottom", 24)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 10)
	pad.add_child(inner)
	card_body.add_child(pad)

	var title := Label.new()
	title.text = "UNICORN ARCADE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color.WHITE)
	inner.add_child(title)

	inner.add_child(UiFactory.make_subtitle("Train your brain with magical mini-games."))

	var name_label := Label.new()
	name_label.text = "USERNAME"
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", UiFactory.SLATE_400)
	inner.add_child(name_label)

	_name_field = UiFactory.make_line_edit("Enter player name…")
	_name_field.text_submitted.connect(func(_t): _on_play())
	inner.add_child(_name_field)

	var play := UiFactory.make_button("Start Playing", UiFactory.CYAN, 52)
	play.pressed.connect(_on_play)
	inner.add_child(play)


func _on_play() -> void:
	var player_name := _name_field.text.strip_edges()
	if player_name.is_empty():
		_name_field.modulate = Color(1, 0.6, 0.6)
		return
	SaveManager.login(player_name)
	SceneRouter.go_home(false)
