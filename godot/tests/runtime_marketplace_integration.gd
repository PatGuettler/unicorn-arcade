extends Node

const MARKET_SCENE = preload("res://scenes/meta/marketplace.tscn")

var failures: Array[String] = []
var check_count := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var pre_test_data := AppState.data.duplicate(true)
	var test_session_started := SaveService.begin_test_session()
	var test_profile := SaveService.create_profile("Marketplace Integration")
	if not test_session_started or test_profile.is_empty() or not SaveService.has_active_profile():
		push_error("marketplace integration could not create its isolated active save profile")
		SaveService.end_test_session()
		get_tree().quit(1)
		return
	AppState.data = test_profile
	var market = MARKET_SCENE.instantiate()
	add_child(market)
	await market.catalog_build_complete
	_check(_ui_is_accessible(market), "companion Marketplace meets readable text, contrast, and touch-target minimums")
	_check(market.tab == "companions" and market.content.get_child_count() > 0, "Marketplace launches its companion catalog")
	var companion_portraits := market.find_children("CompanionPortrait", "TextureRect", true, false)
	var source_model_ids: Dictionary = {}
	var portrait_paths: Dictionary = {}
	var portrait_metadata_safe := true
	for portrait in companion_portraits:
		source_model_ids[str(portrait.get_meta("source_model_id", ""))] = true
		if portrait.texture != null:
			portrait_paths[portrait.texture.resource_path] = true
		if portrait.tooltip_text.is_empty() or not portrait.has_meta("source_model_id"):
			portrait_metadata_safe = false
	_check(companion_portraits.size() == 6 and source_model_ids.size() == 6, "Marketplace companion cards use six distinct authored portrait source IDs")
	_check(portrait_paths.size() == 6 and portrait_paths.keys().all(func(path: String) -> bool: return path.begins_with("res://assets/characters/unicorns/thumbnails/")), "Marketplace companion cards use six distinct authored portrait textures")
	_check(portrait_metadata_safe and market.find_children("*", "SubViewport", true, false).is_empty(), "Marketplace portraits expose source metadata and do not create live 3D SubViewports")
	market.call("_show_decor")
	await market.catalog_build_complete
	await get_tree().process_frame
	_check(_ui_is_accessible(market), "decor Marketplace meets readable text, contrast, and touch-target minimums")
	_check(market.tab == "decor" and MetaCatalog.filtered_furniture("all", "").size() == 107, "Marketplace keeps the full 107-item decor catalog available")
	var first_list := market.find_child("DecorItemList", true, false) as ItemList
	_check(is_instance_valid(first_list) and first_list.item_count <= 24 and market.find_children("DecorSelectedDetail", "VBoxContainer", true, false).size() == 1, "Marketplace bounds first page to one 24-item native list and one selected-item detail panel")
	_check(market.find_child("DecorCategoryChips", true, false) != null and market.find_child("DecorSearch", true, false) != null and market.find_child("PreviousDecorPage", true, false) != null and market.find_child("NextDecorPage", true, false) != null and market.find_child("DecorPageIndicator", true, false) != null, "decor catalog exposes search, categories, and accessible page navigation")
	var decor_source_ids: Dictionary = {}
	var signature_nodes := ["bed_race", "pet_fish", "tv_retro", "xmas_sock"]
	var signature_paths: Dictionary = {}
	var page_count := ceili(float(MetaCatalog.filtered_furniture("all", "").size()) / 24.0)
	for page in range(page_count):
		if page > 0:
			market.call("_next_decor_page")
			await market.catalog_build_complete
		var page_list := market.find_child("DecorItemList", true, false) as ItemList
		var page_indicator := market.find_child("DecorPageIndicator", true, false) as Label
		_check(is_instance_valid(page_list) and page_list.item_count <= 24 and is_instance_valid(page_indicator) and page_indicator.text == "PAGE %d OF %d" % [page + 1, page_count], "Marketplace page %d stays bounded and reports its position" % (page + 1))
		for item_index in page_list.item_count if is_instance_valid(page_list) else 0:
			var metadata: Dictionary = page_list.get_item_metadata(item_index)
			var item_id := str(metadata.get("source_model_id", ""))
			decor_source_ids[item_id] = true
			var icon := page_list.get_item_icon(item_index)
			if item_id in signature_nodes and icon != null and icon.resource_path == "res://assets/store/decor_thumbnails/%s.png" % item_id:
				signature_paths[item_id] = true
	_check(decor_source_ids.size() == 107, "Marketplace pagination exposes all 107 unique decor source IDs across pages")
	_check(signature_paths.size() == signature_nodes.size(), "decor pages retain item-specific authored thumbnail assets across beds, pets, electronics, and seasonal art")
	while market.decor_page > 0:
		market.call("_previous_decor_page")
		await market.catalog_build_complete
	await get_tree().process_frame
	var first_list_node := market.find_child("DecorItemList", true, false)
	var first_list: ItemList = first_list_node as ItemList
	var category_bar: HScrollBar = market.category_scroll.get_h_scroll_bar()
	var catalog_bar: VScrollBar = market.catalog_scroll.get_v_scroll_bar()
	var list_bar: VScrollBar = null
	if is_instance_valid(first_list):
		list_bar = first_list.get_v_scroll_bar()
	_check(is_instance_valid(first_list), "Marketplace exposes its native decor item list after returning to page one")
	_check(first_list.max_columns == 3, "Marketplace decor keeps a stable three-column portrait grid")
	_check(first_list.has_auto_height(), "Marketplace decor ItemList auto-sizes to its page instead of owning vertical scrolling")
	_check(is_instance_valid(list_bar) and list_bar.max_value <= list_bar.page, "Marketplace decor ItemList has no inner vertical scroll range")
	_check(is_instance_valid(category_bar) and category_bar.max_value > category_bar.page, "Marketplace category ScrollContainer has a horizontal scroll range")
	_check(is_instance_valid(catalog_bar) and catalog_bar.max_value > catalog_bar.page, "Marketplace catalog ScrollContainer has a vertical scroll range")
	var category_press := InputEventScreenTouch.new()
	category_press.index = 4
	category_press.pressed = true
	market.call("_on_category_scroll_gui_input", category_press)
	var category_drag := InputEventScreenDrag.new()
	category_drag.index = 4
	category_drag.relative = Vector2(-96, 2)
	market.call("_on_category_scroll_gui_input", category_drag)
	_check(market.category_dragging, "Marketplace category drag is tracked locally after its touch deadzone")
	var category_release := InputEventScreenTouch.new()
	category_release.index = 4
	category_release.pressed = false
	market.call("_on_category_scroll_gui_input", category_release)
	_check(not market.category_dragging and market.get("_scroll_touch_index") == -1, "Marketplace category release resets local touch state")
	market.call("_set_decor_category", "beds")
	_check(market.category == "all", "a horizontal category swipe does not accidentally activate the chip under the finger")
	var catalog_press := InputEventScreenTouch.new()
	catalog_press.index = 8
	catalog_press.pressed = true
	market.call("_on_catalog_scroll_gui_input", catalog_press)
	var catalog_drag := InputEventScreenDrag.new()
	catalog_drag.index = 8
	catalog_drag.relative = Vector2(2, -96)
	market.call("_on_catalog_scroll_gui_input", catalog_drag)
	_check(market.catalog_dragging, "Marketplace catalog drag is tracked locally after its touch deadzone")
	var catalog_release := InputEventScreenTouch.new()
	catalog_release.index = 8
	catalog_release.pressed = false
	market.call("_on_catalog_scroll_gui_input", catalog_release)
	_check(not market.catalog_dragging and market.get("_scroll_touch_index") == -1, "Marketplace catalog release resets local touch state")
	_check(not market.has_method("_apply_category_scroll_drag"), "Marketplace no longer exposes custom category scroll mutation")
	_check(not market.has_method("_apply_catalog_scroll_drag"), "Marketplace no longer exposes custom catalog scroll mutation")
	_check(not market.has_method("_mark_root_input_handled"), "Marketplace no longer handles scrolling through the root viewport")
	await _release_marketplace(market)
	AppState.data = pre_test_data
	SaveService.end_test_session()
	if failures.is_empty():
		print("GODOT_RUNTIME_MARKETPLACE_INTEGRATION_OK: %d checks passed" % check_count)
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _release_marketplace(market: Node) -> void:
	if not is_instance_valid(market):
		return
	var ready: Variant = market.call("prepare_for_scene_change")
	if ready is Signal:
		await ready
	market.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame


func _check(condition: bool, message: String) -> void:
	check_count += 1
	if not condition:
		failures.append(message)


func _ui_is_accessible(root: Node) -> bool:
	var issues: Array[String] = []
	_collect_ui_issues(root, issues)
	if not issues.is_empty():
		push_warning("UI accessibility issues: %s" % "; ".join(issues.slice(0, 8)))
	return issues.is_empty()


func _collect_ui_issues(node: Node, issues: Array[String]) -> void:
	if node is Control and (node as Control).is_visible_in_tree():
		var control := node as Control
		if control is Label and not (control as Label).text.strip_edges().is_empty():
			if control.get_theme_font_size("font_size") < 19:
				issues.append("small label %s" % control.name)
			if control.get_theme_constant("outline_size") < 2:
				issues.append("low-contrast label %s" % control.name)
		if control is BaseButton:
			var required_touch_height := 56.0
			if control.custom_minimum_size.y < required_touch_height:
				issues.append("short touch target %s" % control.name)
			if control.get_theme_font_size("font_size") < 18:
				issues.append("small button text %s" % control.name)
		if control is LineEdit or control is TextEdit:
			if control.custom_minimum_size.y < 56.0 or control.get_theme_font_size("font_size") < 19:
				issues.append("small text input %s" % control.name)
	for child in node.get_children():
		_collect_ui_issues(child, issues)
