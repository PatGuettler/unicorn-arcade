extends RefCounted
class_name UiFactory

const BG := Color("#020617")
const PINK := Color("#f472b6")
const VIOLET := Color("#a78bfa")
const CYAN := Color("#22d3ee")


static func make_panel(parent: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = BG
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


static func make_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


static func make_button(text: String, accent: Color = CYAN) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(DisplayProfile.min_touch_size() * 3, DisplayProfile.min_touch_size())
	var normal := StyleBoxFlat.new()
	normal.bg_color = accent.darkened(0.35)
	normal.set_corner_radius_all(12)
	btn.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = accent.darkened(0.2)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_color_override("font_color", Color.WHITE)
	return btn


static func make_header(parent: Control, title: String, on_back: Callable, coins: int = -1) -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 12
	bar.offset_right = -12
	bar.offset_top = DisplayProfile.content_margin()
	bar.add_theme_constant_override("separation", 8)
	parent.add_child(bar)

	if on_back.is_valid():
		var back := make_button("←", VIOLET)
		back.pressed.connect(on_back)
		bar.add_child(back)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 20)
	t.add_theme_color_override("font_color", Color.WHITE)
	bar.add_child(t)

	spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(spacer)

	if coins >= 0:
		var coin_l := Label.new()
		coin_l.text = "🪙 %d" % coins
		coin_l.add_theme_color_override("font_color", PINK)
		bar.add_child(coin_l)
