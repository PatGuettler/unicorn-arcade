extends Control


func _ready() -> void:
	UiFactory.make_panel(self)
	var equipped := SaveManager.user_data.get("equippedUnicorn", "sparkle")
	var uni := GameCatalog.get_unicorn(equipped)

	UiFactory.make_header(self, "Home", Callable(), int(SaveManager.user_data.coins))

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_top = 80
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)

	var companion := Label.new()
	companion.text = "🦄 %s" % uni.get("name", "Sparkle")
	companion.add_theme_font_size_override("font_size", 32)
	companion.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(companion)

	var desc := Label.new()
	desc.text = uni.get("desc", "")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.add_theme_color_override("font_color", Color("#cbd5e1"))
	vbox.add_child(desc)

	_add_nav_button(vbox, "Play Games", SceneRouter.go_dashboard)
	_add_nav_button(vbox, "Unicorn Alley", SceneRouter.go_alley)
	_add_nav_button(vbox, "Shop", SceneRouter.go_shop)
	_add_nav_button(vbox, "Profile", SceneRouter.go_profile)


func _add_nav_button(parent: VBoxContainer, label: String, handler: Callable) -> void:
	var btn := UiFactory.make_button(label)
	btn.pressed.connect(func(): handler.call(true))
	parent.add_child(btn)
