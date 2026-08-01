extends Control

const Catalog = preload("res://scripts/meta_catalog.gd")

const NAVY := Color("07142c")
const PANEL := Color("14214a")
const CYAN := Color("58d6e8")
const PINK := Color("f26fa7")
const YELLOW := Color("ffd166")
const MUTED := Color("aab7e8")
const ALLEY_MAP = preload("res://assets/meta/environments/unicorn_alley_original.jpeg")
const HOUSE_POSITIONS := {
	"sparkle": Vector2(0.60, 0.65),
	"rainbow": Vector2(0.82, 0.80),
	"star": Vector2(0.18, 0.75),
	"cloud": Vector2(0.55, 0.15),
	"dream": Vector2(0.30, 0.50),
	"mystic": Vector2(0.45, 0.80),
}

var message_label: Label
var house_buttons := {}
var map_rect: TextureRect


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
	var stage := Control.new()
	stage.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stage.clip_contents = true
	root.add_child(stage)
	map_rect = TextureRect.new()
	map_rect.texture = ALLEY_MAP
	map_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(map_rect)
	for definition in Catalog.companions():
		var companion_id := str(definition["id"])
		var owned := companion_id in AppState.owned_companions()
		var count := AppState.room_items(companion_id).size()
		var house := Button.new()
		house.text = "%s\n%s" % [str(definition["name"]).to_upper(), "ENTER • %d" % count if owned else "LOCKED"]
		house.custom_minimum_size = Vector2(112, 72)
		house.size = house.custom_minimum_size
		house.add_theme_font_size_override("font_size", 13)
		house.add_theme_stylebox_override("normal", _house_style(Color(str(definition["color"])), owned))
		house.pressed.connect(_house_pressed.bind(companion_id, owned))
		stage.add_child(house)
		house_buttons[companion_id] = house
	stage.resized.connect(_layout_alley.bind(stage))
	_layout_alley.call_deferred(stage)
	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size.y = 50
	message_label.add_theme_color_override("font_color", YELLOW)
	root.add_child(message_label)


func _layout_alley(stage: Control) -> void:
	if not is_instance_valid(map_rect) or stage.size.x < 1.0 or stage.size.y < 1.0:
		return
	var source_size := ALLEY_MAP.get_size()
	var fit_scale := minf(stage.size.x / source_size.x, stage.size.y / source_size.y)
	map_rect.size = source_size * fit_scale
	map_rect.position = (stage.size - map_rect.size) * 0.5
	for companion_id in house_buttons:
		var house := house_buttons[companion_id] as Button
		var normalized: Vector2 = HOUSE_POSITIONS.get(companion_id, Vector2(0.5, 0.5))
		house.position = map_rect.position + map_rect.size * normalized - house.size * 0.5


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
	style.bg_color = Color(color, 0.76) if owned else Color(0.05, 0.07, 0.13, 0.82)
	style.border_color = Color(color, 0.8) if owned else Color("43495d")
	style.set_border_width_all(3)
	style.corner_radius_top_left = 28
	style.corner_radius_top_right = 28
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	return style
