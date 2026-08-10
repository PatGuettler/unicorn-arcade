class_name MarketplaceCatalogController
extends RefCounted

# Marketplace catalog state and actions deliberately live outside the view.
# This controller has no Controls and never changes ScrollContainer offsets;
# the Marketplace scene owns presentation and native scrolling.
const Catalog = preload("res://scripts/meta_catalog.gd")

const DECOR_SLOTS := 8

var tab: String = "companions"
var category: String = "all"
var query: String = ""
var decor_filtered: Array = []
var decor_page: int = 0
var category_tap_guard: ScrollTapGuard = ScrollTapGuard.new(4.0)
var catalog_tap_guard: ScrollTapGuard = ScrollTapGuard.new(4.0)


func show_companions() -> void:
	tab = "companions"


func open_decor_tab() -> void:
	tab = "decor"
	decor_page = 0


func refresh_decor_filter() -> Array:
	decor_filtered = Catalog.filtered_furniture(category, query)
	decor_page = clampi(decor_page, 0, decor_page_count() - 1)
	return decor_filtered


func apply_decor_search(search_text: String) -> Array:
	query = search_text.strip_edges()
	decor_page = 0
	return refresh_decor_filter()


func set_decor_category(category_id: String) -> Array:
	category = category_id
	decor_page = 0
	return refresh_decor_filter()


func guarded_category_action(category_id: String) -> bool:
	if category_tap_guard.is_action_suppressed():
		return false
	set_decor_category(category_id)
	return true


func observe_scroll_gesture(guard: ScrollTapGuard, surface: String, axis: String, event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			guard.begin(surface, axis, touch)
		else:
			guard.finish(touch)
	elif event is InputEventScreenDrag:
		guard.observe_drag(event as InputEventScreenDrag)


func catalog_action_suppressed() -> bool:
	return catalog_tap_guard.is_action_suppressed()


func previous_decor_page() -> bool:
	if catalog_action_suppressed() or decor_page <= 0:
		return false
	decor_page -= 1
	return true


func next_decor_page() -> bool:
	if catalog_action_suppressed() or decor_page >= decor_page_count() - 1:
		return false
	decor_page += 1
	return true


func decor_page_count() -> int:
	return maxi(1, ceili(float(decor_filtered.size()) / float(DECOR_SLOTS)))


func decor_page_items() -> Array:
	var first := decor_page * DECOR_SLOTS
	return decor_filtered.slice(first, mini(first + DECOR_SLOTS, decor_filtered.size()))


func companion_action(definition: Dictionary) -> Dictionary:
	if catalog_action_suppressed():
		return {"handled": false}
	var id := str(definition.get("id", ""))
	var was_owned := id in AppState.owned_companions()
	var result := AppState.equip_companion(id) if was_owned else AppState.buy_companion(id)
	var name := str(definition.get("name", id))
	return {
		"handled": true,
		"result": result,
		"message": "%s equipped." % name if result and was_owned else ("Not enough coins." if not result else "%s adopted!" % name),
	}


func buy_decor(item: Dictionary) -> Dictionary:
	if catalog_action_suppressed() or item.is_empty():
		return {"handled": false}
	var result := AppState.buy_furniture(str(item.get("id", "")))
	return {"handled": true, "result": result, "message": "Purchased." if result else "Not enough coins."}


func sell_decor(item: Dictionary) -> Dictionary:
	if catalog_action_suppressed() or item.is_empty():
		return {"handled": false}
	var result := AppState.sell_furniture(str(item.get("id", "")))
	return {"handled": true, "result": result, "message": "Sold one unused item." if result else "Only unused bag items can be sold."}


func alley_action_allowed() -> bool:
	return not catalog_action_suppressed()
