class_name CoinChoiceButton
extends Button

const COPPER_DARK := Color("7d3f24")
const COPPER := Color("c8794e")
const COPPER_LIGHT := Color("f0b17d")
const SILVER_DARK := Color("677082")
const SILVER := Color("b8c1cf")
const SILVER_LIGHT := Color("eef3fa")
const NAVY := Color("17254d")
const CREAM := Color("fff3d6")

var denomination := "Penny"
var cents := 1
var size_ratio := 0.82


func setup(coin_name: String, coin_cents: int, ratio: float) -> void:
	denomination = coin_name
	cents = coin_cents
	size_ratio = ratio
	name = "%sCoinButton" % coin_name
	text = coin_name
	tooltip_text = "%s, worth %d cents" % [coin_name, coin_cents]
	custom_minimum_size = Vector2(220, 174)
	focus_mode = Control.FOCUS_ALL
	flat = true
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	add_theme_color_override("font_color", Color.TRANSPARENT)
	add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	add_theme_color_override("font_focus_color", Color.TRANSPARENT)
	add_theme_color_override("font_disabled_color", Color.TRANSPARENT)
	add_theme_font_size_override("font_size", 20)
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, 68.0)
	var radius := 55.0 * size_ratio
	var is_copper := denomination == "Penny"
	var dark := COPPER_DARK if is_copper else SILVER_DARK
	var mid := COPPER if is_copper else SILVER
	var light := COPPER_LIGHT if is_copper else SILVER_LIGHT
	var dim := Color(0.52, 0.56, 0.66, 0.48) if disabled else Color.WHITE
	dark *= dim
	mid *= dim
	light *= dim

	draw_circle(center + Vector2(0, 6), radius + 5, Color(0.02, 0.04, 0.12, 0.46))
	draw_circle(center, radius + 5, dark)
	draw_circle(center, radius + 1, light)
	draw_circle(center, radius - 4, mid)
	draw_arc(center, radius - 8, -2.7, -0.15, 30, light, 3.0, true)
	draw_arc(center, radius - 10, 0.45, 2.35, 30, dark, 2.5, true)
	_draw_coin_face(center, radius, dark, light)

	var font := ThemeDB.fallback_font
	var label_color := Color(CREAM, 0.48) if disabled else CREAM
	var value_color := Color(light, 0.62) if disabled else light
	draw_string(font, Vector2(0, 140), denomination.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, label_color)
	draw_string(font, Vector2(0, 165), _value_label(), HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, value_color)
	if has_focus():
		draw_arc(center, radius + 11, 0.0, TAU, 48, Color("58d6e8"), 4.0, true)


func _draw_coin_face(center: Vector2, radius: float, dark: Color, light: Color) -> void:
	var font := ThemeDB.fallback_font
	match denomination:
		"Penny":
			draw_string(font, center + Vector2(-radius, 8), "1", HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 31, light)
			for y in [-19.0, -13.0, 18.0, 24.0]:
				draw_line(center + Vector2(-radius * 0.44, y), center + Vector2(radius * 0.44, y), dark, 2.0, true)
		"Nickel":
			draw_string(font, center + Vector2(-radius, 8), "5", HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 31, dark)
			for x in [-20.0, -10.0, 0.0, 10.0, 20.0]:
				draw_line(center + Vector2(x, 20), center + Vector2(x, 29), dark, 2.0, true)
		"Dime":
			draw_string(font, center + Vector2(-radius, 8), "10", HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 27, dark)
			for angle in 10:
				var p := center + Vector2.RIGHT.rotated(TAU * angle / 10.0) * (radius - 12)
				draw_circle(p, 1.8, light)
		"Quarter":
			draw_string(font, center + Vector2(-radius, 8), "25", HORIZONTAL_ALIGNMENT_CENTER, radius * 2.0, 30, dark)
			for angle in 13:
				var p := center + Vector2.RIGHT.rotated(TAU * angle / 13.0) * (radius - 10)
				draw_circle(p, 1.8, dark)


func _value_label() -> String:
	return "%d¢" % cents

