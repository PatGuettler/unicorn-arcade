extends Control

var _spin_root: Node3D


func _ready() -> void:
	UiFactory.add_background(self)
	UiFactory.add_glow(self, UiFactory.CYAN)

	var equipped: String = String(SaveManager.user_data.get("equippedUnicorn", "sparkle"))
	var uni: Dictionary = GameCatalog.get_unicorn(equipped)
	var coins: int = int(SaveManager.user_data.get("coins", 0))

	UiFactory.make_header_bar(self, {
		"player": SaveManager.current_user,
		"coins": coins,
		"on_profile": func(): SceneRouter.go_profile(),
	})

	var body := UiFactory.make_screen_body(self, 88)
	var root := VBoxContainer.new()
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 12)
	body.add_child(root)

	root.add_child(UiFactory.make_subtitle("CURRENT COMPANION"))
	var name := Label.new()
	name.text = String(uni.get("name", "Sparkle"))
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name.add_theme_font_size_override("font_size", 36)
	name.add_theme_color_override("font_color", UiFactory.PINK)
	root.add_child(name)

	var pedestal_host := Control.new()
	pedestal_host.custom_minimum_size = Vector2(0, 260)
	pedestal_host.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(pedestal_host)

	var stack: Dictionary = World3DHelpers.make_viewport_stack(pedestal_host, 0)
	stack.container.set_anchors_preset(Control.PRESET_FULL_RECT)
	stack.container.offset_top = 0
	stack.camera.current = false
	var ped: Dictionary = World3DHelpers.build_pedestal(stack.world, equipped)
	_spin_root = ped.spin_root
	var ped_cam: Camera3D = ped.camera
	ped_cam.current = true

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	root.add_child(grid)

	var profile := UiFactory.make_tile_button("PROFILE", UiFactory.SLATE_400, "🏆")
	profile.pressed.connect(func(): SceneRouter.go_profile())
	grid.add_child(profile)

	var play := UiFactory.make_play_tile()
	play.pressed.connect(func(): SceneRouter.go_dashboard())
	grid.add_child(play)

	var shop := UiFactory.make_tile_button("SHOP", UiFactory.VIOLET, "🛍")
	shop.pressed.connect(func(): SceneRouter.go_shop())
	grid.add_child(shop)

	var alley := UiFactory.make_button("🦄  UNICORN ALLEY — 3D", UiFactory.PINK, 56)
	alley.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alley.pressed.connect(func(): SceneRouter.go_alley())
	root.add_child(alley)


func _process(delta: float) -> void:
	if _spin_root and not bool(SaveManager.get_setting("reduced_motion", false)):
		_spin_root.rotation.y += delta * 0.7
