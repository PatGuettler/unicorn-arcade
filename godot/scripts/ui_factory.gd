extends RefCounted
class_name UiFactory

const BG := Color("#020617")
const SLATE_900 := Color("#0f172a")
const SLATE_800 := Color("#1e293b")
const SLATE_700 := Color("#334155")
const SLATE_400 := Color("#94a3b8")
const PINK := Color("#f472b6")
const VIOLET := Color("#a78bfa")
const CYAN := Color("#22d3ee")
const EMERALD := Color("#10b981")
const EMERALD_DARK := Color("#047857")


static func unicorn_texture_path(unicorn_id: String) -> String:
	match unicorn_id:
		"dream":
			return "res://assets/unicorns/dreamer.png"
		_:
			return "res://assets/unicorns/%s.png" % unicorn_id


static func touch_min() -> int:
	return 44


static func font_size(base_size: int) -> int:
	var scale := 1.0
	if not SaveManager.user_data.is_empty():
		scale = float(SaveManager.get_setting("text_scale", 1.0))
	return maxi(10, roundi(base_size * scale))


static func add_background(parent: Control) -> void:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.color = BG
	parent.add_child(bg)
	parent.move_child(bg, 0)


static func add_glow(parent: Control, color: Color, size: Vector2 = Vector2(420, 420)) -> void:
	var glow := ColorRect.new()
	glow.custom_minimum_size = size
	glow.size = size
	glow.color = Color(color.r, color.g, color.b, 0.12)
	glow.set_anchors_preset(Control.PRESET_CENTER)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(glow)


static func stylebox_flat(color: Color, radius: int = 16, border_color: Color = Color.TRANSPARENT, border_w: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	if border_w > 0:
		sb.border_width_bottom = border_w
		sb.border_color = border_color
	return sb


static func make_title(text: String, size: int = 28) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size(size))
	label.add_theme_color_override("font_color", Color.WHITE)
	return label


static func make_subtitle(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size(14))
	label.add_theme_color_override("font_color", SLATE_400)
	return label


static func make_button(text: String, accent: Color = CYAN, min_h: int = 0) -> Button:
	var btn := Button.new()
	btn.text = text
	var h := min_h if min_h > 0 else touch_min()
	btn.custom_minimum_size = Vector2(0, h)
	btn.add_theme_font_size_override("font_size", font_size(16))
	var normal := stylebox_flat(accent.darkened(0.35), 14)
	var hover := stylebox_flat(accent.darkened(0.15), 14)
	var pressed := stylebox_flat(accent.darkened(0.5), 14)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.pressed.connect(AudioManager.play_ui)
	return btn


static func make_tile_button(label_text: String, accent: Color, icon_text: String = "") -> Button:
	var btn := Button.new()
	btn.text = "%s\n%s" % [icon_text, label_text] if icon_text else label_text
	btn.custom_minimum_size = Vector2(100, 100)
	btn.add_theme_font_size_override("font_size", font_size(13))
	var normal := stylebox_flat(SLATE_800, 24, SLATE_900, 4)
	var hover := stylebox_flat(SLATE_700, 24, SLATE_900, 4)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", stylebox_flat(SLATE_700, 24, SLATE_900, 0))
	btn.add_theme_color_override("font_color", accent)
	btn.pressed.connect(AudioManager.play_ui)
	return btn


static func make_play_tile() -> Button:
	var btn := Button.new()
	btn.text = "▶\nPLAY"
	btn.custom_minimum_size = Vector2(100, 100)
	btn.add_theme_font_size_override("font_size", font_size(15))
	var normal := stylebox_flat(EMERALD, 24, EMERALD_DARK, 4)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", stylebox_flat(EMERALD.lightened(0.08), 24, EMERALD_DARK, 4))
	btn.add_theme_stylebox_override("pressed", stylebox_flat(EMERALD.darkened(0.1), 24, EMERALD_DARK, 0))
	btn.add_theme_color_override("font_color", Color("#022c22"))
	btn.pressed.connect(AudioManager.play_ui)
	return btn


static func make_line_edit(placeholder: String = "") -> LineEdit:
	var field := LineEdit.new()
	field.placeholder_text = placeholder
	field.custom_minimum_size = Vector2(280, touch_min())
	field.add_theme_font_size_override("font_size", font_size(16))
	var sb := stylebox_flat(SLATE_900, 14, SLATE_700, 1)
	field.add_theme_stylebox_override("normal", sb)
	field.add_theme_stylebox_override("focus", stylebox_flat(SLATE_900, 14, CYAN, 2))
	field.add_theme_color_override("font_color", Color.WHITE)
	field.add_theme_color_override("placeholder_color", SLATE_700)
	field.clear_button_enabled = true
	return field


static func make_screen_body(parent: Control, top_inset: int = 76) -> MarginContainer:
	var body := MarginContainer.new()
	body.set_anchors_preset(Control.PRESET_FULL_RECT)
	body.offset_top = top_inset
	body.add_theme_constant_override("margin_left", 16)
	body.add_theme_constant_override("margin_right", 16)
	body.add_theme_constant_override("margin_bottom", 24)
	parent.add_child(body)
	return body


static func make_header_bar(parent: Control, opts: Dictionary) -> Control:
	var is_sub: bool = opts.get("subscreen", false)
	var title: String = opts.get("title", "")
	var coins: int = int(opts.get("coins", -1))
	var on_back: Callable = opts.get("on_back", Callable())
	var on_profile: Callable = opts.get("on_profile", Callable())
	var player: String = opts.get("player", "")

	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.offset_left = 0
	bar.offset_right = 0
	bar.offset_top = 0
	bar.custom_minimum_size.y = touch_min() + 20
	bar.add_theme_stylebox_override("panel", stylebox_flat(Color(15.0 / 255.0, 23.0 / 255.0, 42.0 / 255.0, 0.92), 0))
	parent.add_child(bar)

	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12
	row.offset_right = -12
	row.offset_top = DisplayProfile.content_margin()
	row.add_theme_constant_override("separation", 10)
	bar.add_child(row)

	if is_sub and on_back.is_valid():
		var back := Button.new()
		back.text = "←"
		back.custom_minimum_size = Vector2(touch_min(), touch_min())
		back.add_theme_stylebox_override("normal", stylebox_flat(SLATE_800, 22))
		back.pressed.connect(on_back)
		row.add_child(back)
		if not title.is_empty():
			row.add_child(make_title(title, 20))
	elif on_profile.is_valid() and not player.is_empty():
		var profile := Button.new()
		profile.text = "👤  %s" % player
		profile.custom_minimum_size = Vector2(0, touch_min())
		profile.add_theme_stylebox_override("normal", stylebox_flat(SLATE_800, 16))
		profile.pressed.connect(on_profile)
		row.add_child(profile)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	if on_profile.is_valid() and is_sub:
		var home_btn := make_button("Home", VIOLET)
		home_btn.custom_minimum_size = Vector2(72, touch_min())
		home_btn.pressed.connect(on_profile)
		row.add_child(home_btn)

	if coins >= 0:
		var coin := Label.new()
		coin.text = "🪙 %d" % coins
		coin.add_theme_font_size_override("font_size", font_size(18))
		coin.add_theme_color_override("font_color", PINK)
		row.add_child(coin)

	return bar


static func make_card_panel() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", stylebox_flat(SLATE_900, 20, SLATE_800, 1))
	return card


static func make_texture_rect(path: String, size: Vector2) -> TextureRect:
	var tex_rect := TextureRect.new()
	tex_rect.custom_minimum_size = size
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(path):
		tex_rect.texture = load(path)
	return tex_rect


static func make_coin_button(cents: int, texture_path: String) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(72, 72)
	if ResourceLoader.exists(texture_path):
		btn.icon = load(texture_path)
		btn.expand_icon = true
		btn.text = ""
	else:
		btn.text = "%d¢" % cents
	btn.add_theme_stylebox_override("normal", stylebox_flat(SLATE_800, 36))
	btn.add_theme_stylebox_override("hover", stylebox_flat(SLATE_700, 36))
	btn.pressed.connect(AudioManager.play_ui)
	return btn
