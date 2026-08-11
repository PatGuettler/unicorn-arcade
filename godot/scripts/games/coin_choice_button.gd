class_name CoinChoiceButton
extends Button

const StorybookUI = preload("res://scripts/ui/storybook_ui.gd")
const SILVER_LIGHT := Color("eef3fa")
const PORTRAIT_TOP_Y := 2.0
const PORTRAIT_BOTTOM_Y := 116.0
const DENOMINATION_BASELINE_Y := 140.0
const COIN_TEXTURES := {
	"Penny": "res://assets/games/currency/penny.png",
	"Nickel": "res://assets/games/currency/nickel.png",
	"Dime": "res://assets/games/currency/dime.png",
	"Quarter": "res://assets/games/currency/quarter.png",
}

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
	set_meta("currency_art", true)
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
	var portrait := TextureRect.new()
	portrait.name = "OfficialCoinPortrait"
	portrait.texture = load(COIN_TEXTURES[coin_name])
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.anchor_left = 0.5
	portrait.anchor_right = 0.5
	portrait.offset_left = -66.0 * size_ratio
	portrait.offset_right = 66.0 * size_ratio
	# A bounded image lane prevents tall source art from entering either text line.
	# Width remains ratio-based so the denominations keep their relative coin sizes.
	portrait.offset_top = PORTRAIT_TOP_Y
	portrait.offset_bottom = PORTRAIT_BOTTOM_Y
	add_child(portrait)
	portrait.position.x -= 0.0
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var label_color := Color(StorybookUI.CREAM, 0.48) if disabled else StorybookUI.CREAM
	var value_color := Color(SILVER_LIGHT, 0.62) if disabled else SILVER_LIGHT
	draw_string(font, Vector2(0, DENOMINATION_BASELINE_Y), denomination.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x, 20, label_color)
	draw_string(font, Vector2(0, 165), _value_label(), HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, value_color)
	if has_focus():
		# Outline the entire accessible portrait region rather than drawing a
		# second, procedural coin below the official denomination art.
		draw_rect(Rect2(8, 2, maxf(0.0, size.x - 16.0), 138), StorybookUI.CYAN, false, 4.0, true)


func _value_label() -> String:
	return "%d¢" % cents
