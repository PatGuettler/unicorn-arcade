extends Control

const NAVY := Color("08112f")
const PANEL := Color("14214a")
const CYAN := Color("58d6e8")
const PINK := Color("f26fa7")
const YELLOW := Color("ffd166")
const TEXT := Color("f7f1ff")

var coin_label: Label
var status_label: Label


func _ready() -> void:
	_build_ui()
	AppState.coins_changed.connect(_on_coins_changed)


func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = NAVY
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 24)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 16)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	var title := Label.new()
	title.text = "UNICORN\nARCADE"
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", PINK)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	coin_label = Label.new()
	coin_label.text = "★ %d" % AppState.coins()
	coin_label.add_theme_font_size_override("font_size", 26)
	coin_label.add_theme_color_override("font_color", YELLOW)
	header.add_child(coin_label)
	layout.add_child(header)

	var welcome := Label.new()
	welcome.text = "Learn, play, and make Sparkle's world your own."
	welcome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	welcome.add_theme_font_size_override("font_size", 18)
	welcome.add_theme_color_override("font_color", Color("c8d2ff"))
	layout.add_child(welcome)

	status_label = Label.new()
	status_label.text = "Godot parity foundation • 2 playable ports • 22 registered games"
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", CYAN)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(status_label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	var categories := VBoxContainer.new()
	categories.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	categories.add_theme_constant_override("separation", 20)
	scroll.add_child(categories)

	for category in ["Number", "Word", "Mystery", "Arcade"]:
		var heading := Label.new()
		heading.text = category
		heading.add_theme_font_size_override("font_size", 24)
		heading.add_theme_color_override("font_color", CYAN if category == "Number" else PINK)
		categories.add_child(heading)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		categories.add_child(grid)
		for game in GameRegistry.games_in_category(category):
			var button := Button.new()
			button.text = game["title"] + ("\nPLAY" if game["scene"] != "" else "\nCOMING IN PORT")
			button.custom_minimum_size = Vector2(0, 94)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.add_theme_font_size_override("font_size", 17)
			button.add_theme_color_override("font_color", TEXT)
			button.add_theme_stylebox_override("normal", _panel_style(PANEL))
			button.add_theme_stylebox_override("hover", _panel_style(Color("24366b")))
			button.pressed.connect(_open_game.bind(game))
			grid.add_child(button)


func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.35, 0.84, 0.91, 0.35)
	return style


func _open_game(game: Dictionary) -> void:
	if game["scene"] == "":
		status_label.text = "%s is registered for parity, but not ported in this checkpoint." % game["title"]
		return
	get_tree().change_scene_to_file(game["scene"])


func _on_coins_changed(value: int) -> void:
	coin_label.text = "★ %d" % value
