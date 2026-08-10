extends Node

const MARKET_SCENE = preload("res://scenes/meta/marketplace.tscn")
const MarketplaceCatalogController = preload("res://scripts/meta/marketplace_catalog_controller.gd")

var failures: Array[String] = []
var check_count := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var previous_data := AppState.data.duplicate(true)
	var session_started := SaveService.begin_test_session()
	var profile := SaveService.create_profile("Marketplace Integration")
	if not session_started or profile.is_empty():
		push_error("could not create Marketplace test profile")
		get_tree().quit(1)
		return
	AppState.data = profile
	AppState.data["player"]["coins"] = 5000
	var host := Control.new()
	add_child(host)
	var market = MARKET_SCENE.instantiate()
	host.add_child(market)
	await get_tree().process_frame
	host.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	host.size = Vector2(534, 1000)
	await get_tree().process_frame
	_check(market.catalog_controller is MarketplaceCatalogController and market.catalog_controller is RefCounted, "Marketplace owns catalog state in a non-Control controller")
	market.tab = "decor"
	market.category = "beds"
	market.query = "race"
	market._decor_page = 3
	_check(market.catalog_controller.tab == "decor" and market.catalog_controller.category == "beds" and market.catalog_controller.query == "race" and market.catalog_controller.decor_page == 3 and market._decor_filtered == market.catalog_controller.decor_filtered and market.category_tap_guard == market.catalog_controller.category_tap_guard and market.catalog_tap_guard == market.catalog_controller.catalog_tap_guard, "Marketplace test-facing catalog state forwards to its controller")
	market.call("_show_companions")
	var controller := market.catalog_controller as MarketplaceCatalogController
	controller.open_decor_tab()
	controller.decor_page = 999
	controller.refresh_decor_filter()
	_check(controller.decor_filtered.size() > 0 and controller.decor_page == controller.decor_page_count() - 1 and controller.decor_page_count() >= 1, "Controller owns Decor filtering and clamps page transitions")
	controller.apply_decor_search("race")
	_check(controller.query == "race" and controller.decor_page == 0 and controller.decor_filtered.all(func(item: Dictionary) -> bool: return "race" in (str(item["name"]) + " " + str(item["desc"])).to_lower()), "Controller search resets paging and filters catalog entries")
	controller.set_decor_category("all")
	controller.apply_decor_search("")
	market.call("_show_companions")
	_check(market.catalog_ready and market.tab == "companions", "Marketplace reports a synchronous ready state without a deferred catalog build")
	_check(not market._search.visible and not market._search_button.visible and not market.category_scroll.visible, "Companion catalog hides every Decor filter control")
	_check(market.find_children("*", "GridContainer", true, false).is_empty() and market.find_children("*", "VBoxContainer", true, false).is_empty() and market.find_children("*", "HBoxContainer", true, false).is_empty(), "Marketplace uses only explicit fixed controls, never dynamic layout containers")
	_check(market.find_children("*", "SubViewport", true, false).is_empty() and market.find_children("*", "ItemList", true, false).is_empty(), "Marketplace has no live 3D preview or nested list")
	_check(market._companion_cards.size() == 6 and market._decor_cards.size() == 8, "Marketplace preallocates exactly six companion cards and eight Decor slots")
	var child_count := _descendant_count(market)
	_check(_catalog_fills_viewport(market, 450.0), "Marketplace catalog content fills the narrow native vertical-scroll viewport instead of collapsing left")
	var companion_ids: Array[String] = []
	for card_data in market._companion_cards:
		var portrait := card_data["portrait"] as TextureRect
		companion_ids.append(str(portrait.get_meta("source_model_id", "")))
	_check(companion_ids == ["sparkle", "rainbow", "star", "cloud", "dream", "mystic"], "Marketplace preserves six authored companion thumbnails in display order")
	_check(market.catalog_scroll.get_v_scroll_bar().max_value > market.catalog_scroll.get_v_scroll_bar().page, "Companion cards use the single native vertical catalog scroll")
	_check(market.catalog_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO and market.catalog_scroll.mouse_filter == Control.MOUSE_FILTER_PASS, "Marketplace catalog leaves vertical movement and touch dispatch to its native ScrollContainer")
	var header := market.find_child("MarketplaceHeader", true, false) as Panel
	var header_parts := [
		header.find_child("MarketplaceTitle", true, false) as Control,
		header.find_child("MarketplaceHome", true, false) as Control,
		header.find_child("MarketplaceCoinIcon", true, false) as Control,
		header.find_child("MarketplaceCoinBalance", true, false) as Control,
	]
	var market_title := header.find_child("MarketplaceTitle", true, false) as Label
	var market_home := header.find_child("MarketplaceHome", true, false) as Button
	var market_star := header.find_child("MarketplaceCoinIcon", true, false) as Label
	_check(header != null and is_equal_approx(header.size.x, 502.0) and _header_parts_fit(header_parts, header.size.x) and is_equal_approx(market_title.get_rect().get_center().x, header.size.x * 0.5) and market_home != null and market_star != null and market_star.text == "★" and market_star.get_theme_color("font_color") == Color("e1ae4f") and header.find_child("EquippedCompanionIcon", true, false) == null, "Marketplace has one centered-title plaque with only Home, gold star, and balance in the right cluster")
	_check(_marketplace_home_is_centered(header, market_home), "Marketplace Home is compact, glyph-backed, and vertically centered inside the 58px plaque at narrow width")
	_check(is_equal_approx(market.message_label.position.x, 14.0) and is_equal_approx(market.message_label.get_rect().end.x, 520.0), "Marketplace status feedback follows the narrow 14px margins")
	var narrow_right_companion := market._companion_cards[1]["card"] as Control
	_check(narrow_right_companion.get_rect().end.x >= market.content.size.x - 5.0, "Companion grid reaches the narrow catalog right margin")
	_check(_companion_card_usable(market._companion_cards[0]) and _companion_card_usable(market._companion_cards[1]), "Companion cards retain wide readable text and action regions at narrow width")
	var companion_scroll_before: int = market.catalog_scroll.scroll_vertical
	var companion_press := InputEventScreenTouch.new()
	companion_press.index = 7
	companion_press.pressed = true
	market.call("_on_catalog_scroll_gui_input", companion_press)
	var companion_drag := InputEventScreenDrag.new()
	companion_drag.index = 7
	companion_drag.relative = Vector2(0, -180)
	market.call("_on_catalog_scroll_gui_input", companion_drag)
	_check(market.catalog_tap_guard.is_dragging() and market.catalog_scroll.scroll_vertical == companion_scroll_before, "catalog gesture observation identifies a vertical swipe without mutating the native ScrollContainer offset")
	market.catalog_scroll.set_deferred("scroll_vertical", mini(120, int(market.catalog_scroll.get_v_scroll_bar().max_value - market.catalog_scroll.get_v_scroll_bar().page)))
	await get_tree().process_frame
	_check(market.catalog_scroll.scroll_vertical > companion_scroll_before, "catalog native ScrollContainer advances independently of the observer")
	var companion_release := InputEventScreenTouch.new()
	companion_release.index = 7
	companion_release.pressed = false
	market.call("_on_catalog_scroll_gui_input", companion_release)
	_check(market.catalog_tap_guard.touch_index == -1 and market.catalog_tap_guard.is_action_suppressed(), "catalog release clears the observed touch and suppresses its immediate action")
	var companion_coins_before := AppState.coins()
	market.call("_companion_action", 1)
	_check("rainbow" not in AppState.owned_companions() and AppState.coins() == companion_coins_before, "Immediate companion action after catalog swipe is suppressed")
	market.catalog_tap_guard.clear_suppression()
	market.call("_companion_action", 1)
	_check("rainbow" in AppState.owned_companions() and market.message_label.text == "Rainbow adopted!", "Later companion tap remains available after catalog swipe suppression with the original message")

	market.call("_open_decor_tab")
	await get_tree().process_frame
	_check(market.tab == "decor" and market._decor_filtered.size() == 107, "Decor opens all 107 persisted catalog entries")
	_check(market._search.visible and market._search_button.visible and market.category_scroll.visible, "Decor reveals its complete search and category filter controls")
	_check(_decor_chrome_ordered(market), "Decor search, category strip, and catalog have touch-safe vertical gaps at narrow width")
	_check(market.category_scroll.get_h_scroll_bar().max_value > market.category_scroll.get_h_scroll_bar().page and market.catalog_scroll.get_v_scroll_bar().max_value > market.catalog_scroll.get_v_scroll_bar().page, "Decor has independent native horizontal category and vertical catalog scroll ranges")
	_check(market.category_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO and market.category_scroll.mouse_filter == Control.MOUSE_FILTER_PASS and market._category_chips.all(func(chip: Button) -> bool: return chip.mouse_filter == Control.MOUSE_FILTER_PASS), "Decor drag surfaces and category controls remain native-scroll friendly")
	var lifecycle_press := InputEventScreenTouch.new()
	lifecycle_press.index = 6
	lifecycle_press.pressed = true
	market.catalog_tap_guard.begin("catalog", "vertical", lifecycle_press)
	var lifecycle_drag := InputEventScreenDrag.new()
	lifecycle_drag.index = 6
	lifecycle_drag.relative = Vector2(0, -1)
	market.catalog_tap_guard.observe_drag(lifecycle_drag)
	market.catalog_tap_guard.on_scroll_started()
	var lifecycle_release := InputEventScreenTouch.new()
	lifecycle_release.index = 6
	lifecycle_release.pressed = false
	market.catalog_tap_guard.finish(lifecycle_release)
	_check(market.catalog_tap_guard.is_action_suppressed(), "native scroll lifecycle suppresses an action even before observer motion reaches its deadzone")
	market.catalog_tap_guard.clear_suppression()
	_check(_descendant_count(market) == child_count, "Opening Decor changes only fixed slot data, not the Control tree")
	var alley := market.find_child("MarketplaceAlley", true, false) as Button
	_check(alley != null and alley.position.y + alley.size.y <= market._decor_panel.custom_minimum_size.y and alley.position.y + alley.size.y <= market.content.custom_minimum_size.y, "The fixed Decor canvas reserves room for Unicorn Alley plus bottom padding")
	var narrow_decor_card := market._decor_cards[0]["card"] as Control
	_check(narrow_decor_card.get_rect().end.x >= market.content.size.x - 3.0 and alley.get_rect().end.x >= market.content.size.x - 3.0, "Decor cards and Unicorn Alley reach the narrow catalog right margin")
	_check(_decor_card_usable(market._decor_cards[0]), "Decor card text and buy/sell actions remain non-overlapping and touch-sized at narrow width")
	_check(_decor_rarity_field_usable(market._decor_cards[0]), "Decor rarity reserves 144px with an eight-pixel name gap and fully renders UNCOMMON and LEGENDARY at narrow width")
	var decor_scroll_before: int = market.catalog_scroll.scroll_vertical
	var decor_press := InputEventScreenTouch.new()
	decor_press.index = 8
	decor_press.pressed = true
	market.call("_on_catalog_scroll_gui_input", decor_press)
	var decor_drag := InputEventScreenDrag.new()
	decor_drag.index = 8
	decor_drag.relative = Vector2(0, -220)
	market.call("_on_catalog_scroll_gui_input", decor_drag)
	_check(market.catalog_tap_guard.is_dragging() and market.catalog_scroll.scroll_vertical == decor_scroll_before, "decor catalog observer does not assign scroll offsets during a drag")
	market.catalog_scroll.set_deferred("scroll_vertical", mini(decor_scroll_before + 120, int(market.catalog_scroll.get_v_scroll_bar().max_value - market.catalog_scroll.get_v_scroll_bar().page)))
	await get_tree().process_frame
	var decor_release := InputEventScreenTouch.new()
	decor_release.index = 8
	decor_release.pressed = false
	market.call("_on_catalog_scroll_gui_input", decor_release)
	_check(market.catalog_scroll.scroll_vertical > decor_scroll_before and market.catalog_tap_guard.is_action_suppressed(), "decor catalog native movement and release suppression remain independent")
	var swipe_item: Dictionary = market._decor_cards[0]["item"]
	var swipe_item_id := str(swipe_item["id"])
	market.call("_buy_decor", 0)
	_check(int(AppState.data["inventory"].get(swipe_item_id, 0)) == 0, "Immediate Decor buy after catalog swipe is suppressed")
	market.catalog_tap_guard.clear_suppression()
	market.call("_next_decor_page")
	_check(market._decor_page == 1, "Later Decor pager action remains available after catalog swipe suppression")
	market._decor_page = 0
	market.call("_refresh_decor_cards")
	var category_before: String = market.category
	var scroll_before: int = market.category_scroll.scroll_horizontal
	var category_press := InputEventScreenTouch.new()
	category_press.index = 9
	category_press.pressed = true
	market.call("_on_category_scroll_gui_input", category_press)
	var category_drag := InputEventScreenDrag.new()
	category_drag.index = 9
	category_drag.relative = Vector2(-180, 0)
	market.call("_on_category_scroll_gui_input", category_drag)
	_check(market.category_tap_guard.is_dragging() and market.category_scroll.scroll_horizontal == scroll_before, "category observer recognizes a horizontal swipe without moving the native strip")
	market.category_scroll.set_deferred("scroll_horizontal", mini(120, int(market.category_scroll.get_h_scroll_bar().max_value - market.category_scroll.get_h_scroll_bar().page)))
	await get_tree().process_frame
	var category_release := InputEventScreenTouch.new()
	category_release.index = 9
	category_release.pressed = false
	market.call("_on_category_scroll_gui_input", category_release)
	_check(market.category_scroll.scroll_horizontal > scroll_before and market.category_tap_guard.is_action_suppressed(), "category native strip movement stays separate from observer-only action suppression")
	market.call("_guarded_category_action", "beds")
	_check(market.category == category_before, "Category action immediately after a swipe is suppressed")
	await get_tree().create_timer(0.25).timeout
	market.category_tap_guard.clear_suppression()
	market.call("_guarded_category_action", "beds")
	_check(market.category == "beds", "Category action remains available after swipe suppression expires")
	market.call("_set_decor_category", "all")
	host.size = Vector2(704, 1200)
	await get_tree().process_frame
	_check(is_equal_approx(header.size.x, 672.0) and _header_parts_fit(header_parts, header.size.x) and is_equal_approx(market_title.get_rect().get_center().x, header.size.x * 0.5) and market_home.get_rect().position.x < market_star.get_rect().position.x and market_star.get_rect().end.x < (header.find_child("MarketplaceCoinBalance", true, false) as Control).position.x, "Marketplace top bar stays centered and ordered Home-star-balance at native phone width")
	_check(_marketplace_home_is_centered(header, market_home), "Marketplace Home remains compact, contained, and vertically centered at native phone width")
	_check(is_equal_approx(market.message_label.position.x, 14.0) and is_equal_approx(market.message_label.get_rect().end.x, 690.0), "Marketplace status feedback follows the wide 14px margins")
	_check(market._companions_tab.get_rect().end.x <= market._decor_tab.position.x and is_equal_approx(market._decor_tab.get_rect().end.x, 688.0), "Marketplace tabs split the full wide phone width without clipping")
	_check((market._companion_cards[1]["card"] as Control).get_rect().end.x >= market.content.size.x - 5.0 and (market._decor_cards[0]["card"] as Control).get_rect().end.x >= market.content.size.x - 3.0 and alley.get_rect().end.x >= market.content.size.x - 3.0, "Fixed card pools expand to the wide native catalog right margin")
	_check(_catalog_fills_viewport(market, 500.0) and _companion_card_usable(market._companion_cards[1]) and _decor_card_usable(market._decor_cards[0]), "Wide Marketplace content, cards, text, and actions fill the real viewport")
	_check(_decor_rarity_field_usable(market._decor_cards[0]), "Decor rarity remains fully rendered in its fixed right-aligned field at native phone width")
	_check(_decor_chrome_ordered(market), "Decor search, category strip, and catalog retain touch-safe vertical gaps at native width")
	_check(_descendant_count(market) == child_count, "Responsive width changes preserve the immutable Marketplace Control tree")
	var reached: Dictionary = {}
	for page in market._decor_page_count():
		market._decor_page = page
		market.call("_refresh_decor_cards")
		for slot in market._decor_cards:
			var item: Dictionary = slot["item"]
			if not item.is_empty():
				reached[str(item["id"])] = true
	_check(reached.size() == 107 and reached.has("bed_race") and reached.has("lamp"), "Pagination reaches all 107 Decor IDs using the bounded fixed card pool")
	market.call("_set_decor_category", "beds")
	_check(market._decor_page == 0 and market._decor_filtered.all(func(item: Dictionary) -> bool: return str(item["category"]) == "beds"), "Category selection resets to page one and filters synchronously")
	market._search.text = "race"
	market.call("_apply_decor_search")
	_check(market._decor_filtered.size() > 0 and market._decor_filtered.all(func(item: Dictionary) -> bool: return "race" in (str(item["name"]) + " " + str(item["desc"])).to_lower()), "Search applies only on its explicit action and updates fixed slots")
	market.category = "all"; market.query = ""; market._decor_page = 0; market.call("_refresh_decor_filter")
	var first_slot: Dictionary = market._decor_cards[0]
	var item_id := str(first_slot["item"]["id"])
	var coins_before := AppState.coins()
	market.call("_buy_decor", 0)
	_check(int(AppState.data["inventory"].get(item_id, 0)) == 1 and AppState.coins() < coins_before and market.message_label.text == "Purchased.", "Buy uses AppState persistence exactly once and keeps its original message")
	market.call("_sell_decor", 0)
	_check(int(AppState.data["inventory"].get(item_id, 0)) == 0 and AppState.coins() > coins_before - int(first_slot["item"]["price"]) and market.message_label.text == "Sold one unused item.", "Sell uses the unused-item AppState API exactly once and keeps its original message")
	_check(_descendant_count(market) == child_count, "Filter, page, buy, and sell never create or destroy catalog controls")
	_check(not market.has_method("_drain_content") and not market.has_method("_append_decor_batch") and not market.has_method("_maybe_load_more"), "Marketplace removes deferred, lazy, and scroll-driven rebuild paths")
	market.prepare_for_scene_change()
	market.queue_free()
	host.queue_free()
	await get_tree().process_frame
	AppState.data = previous_data
	SaveService.end_test_session()
	if failures.is_empty():
		print("GODOT_RUNTIME_MARKETPLACE_INTEGRATION_OK: %d checks passed" % check_count)
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _descendant_count(root: Node) -> int:
	return root.find_children("*", "", true, false).size()


func _header_parts_fit(parts: Array, width: float) -> bool:
	var header := parts[0].get_parent() as Control if not parts.is_empty() and parts[0] != null else null
	if header == null or not parts.all(func(part: Control) -> bool: return part != null and part.position.x >= 0.0 and part.get_rect().end.x <= width and part.position.y >= 0.0 and part.get_rect().end.y <= header.size.y):
		return false
	for first_index in parts.size():
		for second_index in range(first_index + 1, parts.size()):
			var first := parts[first_index] as Control
			var second := parts[second_index] as Control
			if first.get_rect().intersects(second.get_rect()):
				return false
	return true


func _marketplace_home_is_centered(header: Panel, home: Button) -> bool:
	if header == null or home == null:
		return false
	var glyph := home.find_child("MarketplaceHomeGlyph", true, false) as TextureRect
	return home.has_meta("compact_header_control") and home.has_meta("standard_game_chrome") and home.custom_minimum_size == Vector2(48, 48) and is_equal_approx(home.size.x, 48.0) and is_equal_approx(home.size.y, 48.0) and is_equal_approx(home.position.y, 5.0) and is_equal_approx(home.get_rect().get_center().y, header.size.y * 0.5) and home.position.y >= 0.0 and home.get_rect().end.y <= header.size.y and glyph != null and glyph.texture != null and glyph.mouse_filter == Control.MOUSE_FILTER_IGNORE


func _decor_chrome_ordered(market: Control) -> bool:
	var search_rect: Rect2 = market._search.get_rect()
	var search_button_rect: Rect2 = market._search_button.get_rect()
	var category_rect: Rect2 = market.category_scroll.get_rect()
	var catalog_rect: Rect2 = market.catalog_scroll.get_rect()
	return not search_rect.intersects(search_button_rect) and maxf(search_rect.end.y, search_button_rect.end.y) + 8.0 <= category_rect.position.y and category_rect.end.y + 8.0 <= catalog_rect.position.y


func _catalog_fills_viewport(market: Control, minimum_width: float) -> bool:
	var scroll_width: float = market.catalog_scroll.size.x
	var scrollbar_width: float = market.catalog_scroll.get_v_scroll_bar().size.x
	var expected: float = scroll_width - scrollbar_width
	return market.content.size.x > minimum_width and absf(market.content.size.x - expected) <= 4.0


func _companion_card_usable(card_data: Dictionary) -> bool:
	var card := card_data["card"] as Control
	var name := card_data["name"] as Control
	var description := card_data["description"] as Control
	var action := card_data["action"] as Control
	return card.size.x >= 220.0 and name.size.x >= 180.0 and description.size.x >= 180.0 and action.size.x >= 180.0 and not name.get_rect().intersects(description.get_rect()) and not description.get_rect().intersects(action.get_rect())


func _decor_card_usable(card_data: Dictionary) -> bool:
	var card := card_data["card"] as Control
	var name := card_data["name"] as Control
	var rarity := card_data["rarity"] as Control
	var description := card_data["description"] as Control
	var counts := card_data["counts"] as Control
	var buy := card_data["buy"] as Control
	var sell := card_data["sell"] as Control
	return card.size.x >= 440.0 and name.size.x >= 180.0 and description.size.x >= 220.0 and buy.size.x >= 100.0 and sell.size.x >= 100.0 and not name.get_rect().intersects(rarity.get_rect()) and not description.get_rect().intersects(counts.get_rect()) and not counts.get_rect().intersects(buy.get_rect()) and not buy.get_rect().intersects(sell.get_rect())


func _decor_rarity_field_usable(card_data: Dictionary) -> bool:
	var name := card_data["name"] as Label
	var rarity := card_data["rarity"] as Label
	if name == null or rarity == null:
		return false
	var original := rarity.text
	var fits_long_values := true
	for value in ["UNCOMMON", "LEGENDARY"]:
		rarity.text = value
		fits_long_values = fits_long_values and rarity.get_combined_minimum_size().x <= rarity.size.x
	rarity.text = original
	return is_equal_approx(rarity.size.x, 144.0) and is_equal_approx(rarity.position.x - name.get_rect().end.x, 8.0) and rarity.horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT and rarity.get_theme_font_size("font_size") == 14 and not rarity.clip_text and fits_long_values


func _check(condition: bool, message: String) -> void:
	check_count += 1
	if not condition:
		failures.append(message)
