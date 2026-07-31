extends Control

const Catalog = preload("res://scripts/meta_catalog.gd")

const NAVY := Color("07142c")
const PANEL := Color("14214a")
const CYAN := Color("58d6e8")
const PINK := Color("f26fa7")
const YELLOW := Color("ffd166")
const MUTED := Color("aab7e8")

var message_label: Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = NAVY
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	var home := Button.new()
	home.text = "< HOME"
	home.pressed.connect(_go_home)
	header.add_child(home)
	var title := Label.new()
	title.text = "UNICORN ALLEY"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", PINK)
	header.add_child(title)
	var shop := Button.new()
	shop.text = "SHOP"
	shop.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/meta/marketplace.tscn"))
	header.add_child(shop)
	var intro := Label.new()
	intro.text = "Every adopted companion has a house. Make each room their own."
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", MUTED)
	root.add_child(intro)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(grid)
	for definition in Catalog.companions():
		var companion_id := str(definition["id"])
		var owned := companion_id in AppState.owned_companions()
		var count := AppState.room_items(companion_id).size()
		var house := Button.new()
		house.text = "%s'S HOUSE\n%s" % [str(definition["name"]).to_upper(), "%d DECORATIONS\nENTER" % count if owned else "LOCKED\n%d COINS" % int(definition["price"])]
		house.custom_minimum_size = Vector2(190, 180)
		house.add_theme_font_size_override("font_size", 17)
		house.add_theme_stylebox_override("normal", _house_style(Color(str(definition["color"])), owned))
		house.pressed.connect(_house_pressed.bind(companion_id, owned))
		grid.add_child(house)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size.y = 50
	message_label.add_theme_color_override("font_color", YELLOW)
	root.add_child(message_label)


func _house_pressed(companion_id: String, owned: bool) -> void:
	if not owned:
		var definition := Catalog.companion(companion_id)
		message_label.text = "Adopt %s in the Marketplace to unlock this house." % definition.get("name", companion_id)
		return
	AppState.active_room_companion = companion_id
	get_tree().change_scene_to_file("res://scenes/meta/room_editor.tscn")


func _go_home() -> void:
	AppState.shell_view = "home"
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _house_style(color: Color, owned: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, 0.32) if owned else Color("151b2d")
	style.border_color = Color(color, 0.8) if owned else Color("43495d")
	style.set_border_width_all(3)
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style
