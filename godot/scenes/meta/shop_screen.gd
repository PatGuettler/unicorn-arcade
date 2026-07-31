extends Control

const TABS := ["Unicorns", "Decor"]


func _ready() -> void:
	UiFactory.make_panel(self)
	UiFactory.make_header(self, "Shop", func(): SceneRouter.pop(), int(SaveManager.user_data.coins))

	var tabs := TabContainer.new()
	tabs.set_anchors_preset(Control.PRESET_FULL_RECT)
	tabs.offset_top = 72
	add_child(tabs)

	var uni_scroll := ScrollContainer.new()
	uni_scroll.name = "Unicorns"
	tabs.add_child(uni_scroll)
	var uni_list := VBoxContainer.new()
	uni_list.add_theme_constant_override("separation", 8)
	uni_scroll.add_child(uni_list)

	for u in GameCatalog.unicorns:
		var owned := u.id in SaveManager.user_data.ownedUnicorns
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = "🦄 %s — %d coins" % [u.name, u.price]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		var btn := UiFactory.make_button("Owned" if owned else "Buy", UiFactory.PINK)
		btn.disabled = owned
		var uid: String = u.id
		var price: int = u.price
		btn.pressed.connect(func(): _buy_unicorn(uid, price))
		row.add_child(btn)
		uni_list.add_child(row)

	var decor_scroll := ScrollContainer.new()
	decor_scroll.name = "Decor"
	tabs.add_child(decor_scroll)
	var decor_list := VBoxContainer.new()
	decor_scroll.add_child(decor_list)
	for item in GameCatalog.furniture.slice(0, 40):
		var row2 := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "%s %s — %d" % [item.icon, item.name, item.price]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row2.add_child(lbl)
		var buy := UiFactory.make_button("Buy")
		var iid: String = item.id
		var ip: int = item.price
		buy.pressed.connect(func(): _buy_item(iid, ip))
		row2.add_child(buy)
		decor_list.add_child(row2)


func _buy_unicorn(id: String, price: int) -> void:
	if SaveManager.buy_unicorn(id, price):
		get_tree().reload_current_scene()


func _buy_item(id: String, price: int) -> void:
	if SaveManager.buy_furniture(id, price):
		get_tree().reload_current_scene()
