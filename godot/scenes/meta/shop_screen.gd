extends Control


func _ready() -> void:
	UiFactory.add_background(self)
	var coins: int = int(SaveManager.user_data.get("coins", 0))
	UiFactory.make_header_bar(self, {
		"subscreen": true,
		"title": "Shop",
		"coins": coins,
		"on_back": func(): SceneRouter.pop(),
		"on_profile": func(): SceneRouter.go_home(false),
	})

	var body := UiFactory.make_screen_body(self, 88)
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(tabs)

	var uni_scroll := ScrollContainer.new()
	uni_scroll.name = "Unicorns"
	tabs.add_child(uni_scroll)
	var uni_list := VBoxContainer.new()
	uni_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	uni_list.add_theme_constant_override("separation", 10)
	uni_scroll.add_child(uni_list)

	for u_variant in GameCatalog.unicorns:
		var u: Dictionary = u_variant
		var uid: String = String(u.get("id", ""))
		var owned: bool = uid in SaveManager.user_data.ownedUnicorns
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UiFactory.stylebox_flat(UiFactory.SLATE_900, 12))
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		row.add_child(h)
		h.add_child(UiFactory.make_texture_rect(UiFactory.unicorn_texture_path(uid), Vector2(56, 56)))
		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var nm := Label.new()
		nm.text = String(u.get("name", ""))
		nm.add_theme_font_size_override("font_size", 18)
		info.add_child(nm)
		info.add_child(UiFactory.make_subtitle("%d coins" % int(u.get("price", 0))))
		h.add_child(info)
		var btn := UiFactory.make_button("Owned" if owned else "Buy", UiFactory.PINK)
		btn.disabled = owned
		var price: int = int(u.get("price", 0))
		btn.pressed.connect(func(): _buy_unicorn(uid, price))
		h.add_child(btn)
		uni_list.add_child(row)

	var decor_scroll := ScrollContainer.new()
	decor_scroll.name = "Decor"
	tabs.add_child(decor_scroll)
	var decor_list := VBoxContainer.new()
	decor_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	decor_scroll.add_child(decor_list)

	for item_variant in GameCatalog.furniture.slice(0, 50):
		var item: Dictionary = item_variant
		var iid: String = String(item.get("id", ""))
		var row2 := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "%s  %s" % [item.get("icon", ""), item.get("name", "")]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(lbl)
		var buy := UiFactory.make_button("%d 🪙" % int(item.get("price", 0)))
		var ip: int = int(item.get("price", 0))
		buy.pressed.connect(func(): _buy_item(iid, ip))
		row2.add_child(buy)
		decor_list.add_child(row2)


func _buy_unicorn(id: String, price: int) -> void:
	if SaveManager.buy_unicorn(id, price):
		SceneRouter.refresh_current()


func _buy_item(id: String, price: int) -> void:
	if SaveManager.buy_furniture(id, price):
		SceneRouter.refresh_current()
