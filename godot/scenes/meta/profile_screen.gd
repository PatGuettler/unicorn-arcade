extends Control


func _ready() -> void:
	UiFactory.add_background(self)
	var coins: int = int(SaveManager.user_data.get("coins", 0))
	UiFactory.make_header_bar(self, {
		"subscreen": true,
		"title": "Profile",
		"coins": coins,
		"on_back": func(): SceneRouter.pop(),
		"on_profile": func(): SceneRouter.go_home(false),
	})

	var body := UiFactory.make_screen_body(self, 88)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	content.add_child(UiFactory.make_title("Player: %s" % SaveManager.current_user, 22))
	content.add_child(UiFactory.make_subtitle("ACCESSIBILITY & SAVE"))

	var sound_enabled := bool(SaveManager.get_setting("sound_enabled", true))
	var sound_btn := UiFactory.make_button(
		"Sound: %s" % ("On" if sound_enabled else "Off"),
		UiFactory.CYAN,
		44
	)
	sound_btn.pressed.connect(func():
		SaveManager.set_setting("sound_enabled", not sound_enabled)
		AudioManager.sync_settings()
		SceneRouter.refresh_current()
	)
	content.add_child(sound_btn)

	var reduced_motion := bool(SaveManager.get_setting("reduced_motion", false))
	var motion_btn := UiFactory.make_button(
		"Reduced motion: %s" % ("On" if reduced_motion else "Off"),
		UiFactory.VIOLET,
		44
	)
	motion_btn.pressed.connect(func():
		SaveManager.set_setting("reduced_motion", not reduced_motion)
		SceneRouter.refresh_current()
	)
	content.add_child(motion_btn)

	var text_scale := float(SaveManager.get_setting("text_scale", 1.0))
	var text_btn := UiFactory.make_button("Text size: %d%%" % roundi(text_scale * 100), UiFactory.PINK, 44)
	text_btn.pressed.connect(func():
		var next_scale := 1.15 if text_scale < 1.1 else (1.3 if text_scale < 1.25 else 1.0)
		SaveManager.set_setting("text_scale", next_scale)
		SceneRouter.refresh_current()
	)
	content.add_child(text_btn)

	var transfer_status := UiFactory.make_subtitle(
		"Copy your save before replacing the Capacitor app."
	)
	transfer_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(transfer_status)

	var export_btn := UiFactory.make_button("Copy save JSON", UiFactory.EMERALD, 44)
	export_btn.pressed.connect(func():
		DisplayServer.clipboard_set(SaveManager.export_json())
		transfer_status.text = "Save copied to clipboard."
	)
	content.add_child(export_btn)

	var import_btn := UiFactory.make_button("Import save JSON from clipboard", UiFactory.SLATE_700, 44)
	import_btn.pressed.connect(func():
		if SaveManager.import_json(DisplayServer.clipboard_get()):
			AudioManager.sync_settings()
			SceneRouter.go_home(false)
		else:
			transfer_status.text = "Clipboard does not contain valid save JSON."
	)
	content.add_child(import_btn)

	for cat_variant in GameCatalog.categories:
		var cat: Dictionary = cat_variant
		var cat_id: String = String(cat.get("id", ""))
		var games: Array = GameCatalog.games.get(cat_id, [])
		if games.is_empty():
			continue
		content.add_child(UiFactory.make_subtitle(String(cat.get("title", "")).to_upper()))
		for g_variant in games:
			var g: Dictionary = g_variant
			var gid: String = String(g.get("id", ""))
			var block: Dictionary = SaveManager.user_data.get(gid, {})
			var line := Label.new()
			line.text = "  %s — level %d" % [g.get("title", ""), int(block.get("maxLevel", 0))]
			line.add_theme_color_override("font_color", Color.WHITE)
			content.add_child(line)
