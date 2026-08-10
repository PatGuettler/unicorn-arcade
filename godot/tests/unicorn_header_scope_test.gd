extends Node

const UnicornHeader = preload("res://scripts/ui/unicorn_header.gd")

var failures: Array[String] = []
var back_taps := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var host := Control.new()
	add_child(host)
	var home_header := UnicornHeader.build("UNICORN ALLEY", "HOME", Callable(self, "_noop"), Callable(self, "_noop"), "SHOP", Callable(self, "_noop"))
	host.add_child(home_header)
	await get_tree().process_frame
	host.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	host.size = Vector2(534, 120)
	home_header.position = Vector2(16, 14)
	home_header.size = Vector2(502, 64)
	await get_tree().process_frame
	_check(home_header.find_children("*", "PanelContainer", true, false).is_empty() and home_header.find_children("*", "HBoxContainer", true, false).is_empty() and home_header.find_children("*", "GridContainer", true, false).is_empty(), "shared header uses an explicit plaque and fixed slots, not dynamic Container layout")
	_check(home_header.find_child("HeaderLeftSpacer", true, false) != null and home_header.find_child("HeaderBackButton", true, false) == null, "HOME headers retain a spacer and never duplicate Home")
	var home_button := home_header.find_child("HeaderHomeButton", true, false) as Button
	var trailing_button := home_header.find_child("HeaderTrailingAction", true, false) as Button
	var coin_icon := home_header.find_child("SharedCoinIcon", true, false) as Label
	var coins := home_header.find_child("SharedCoinBalance", true, false) as Label
	_check(home_button != null and home_button.text.is_empty() and home_button.find_child("HeaderHomeGlyph", true, false) is TextureRect, "shared Home control uses the house icon")
	_check(home_button != null and home_button.has_meta("compact_header_control") and trailing_button != null and trailing_button.has_meta("compact_header_control"), "shared header actions declare compact-header accessibility metadata")
	_check(coin_icon != null and coin_icon.text == "★" and coin_icon.tooltip_text == "Coins" and coin_icon.get_theme_color("font_color") == Color("ffd166"), "shared header uses the correct accessible gold-star currency glyph")
	_check(coins != null and coins.text == str(AppState.coins()) and home_header.find_child("HeaderTrailingAction", true, false) != null, "shared header keeps numeric balance and optional compact trailing action")
	var home_title := home_header.find_child("HeaderTitle", true, false) as Label
	_check(_header_fits(home_header, 502.0) and home_title != null and home_title.size.x >= home_title.get_combined_minimum_size().x, "shared HOME trailing header fits its full title and every child inside the 534px plaque")
	host.size = Vector2(704, 120)
	home_header.size = Vector2(672, 64)
	await get_tree().process_frame
	_check(_header_fits(home_header, 672.0) and home_title.size.x >= home_title.get_combined_minimum_size().x, "shared HOME trailing header remains clean and untruncated inside the native 704px plaque")
	home_header.queue_free()

	var long_header := UnicornHeader.build("GAME CATEGORIES", "HOME", Callable(self, "_noop"), Callable(self, "_noop"))
	host.add_child(long_header)
	long_header.position = Vector2(16, 14)
	long_header.size = Vector2(502, 64)
	await get_tree().process_frame
	var long_title := long_header.find_child("HeaderTitle", true, false) as Label
	_check(long_title != null and long_title.size.x >= long_title.get_combined_minimum_size().x and _header_fits(long_header, 502.0), "centered long GAME CATEGORIES title has a real untruncated lane at 534px")
	long_header.size = Vector2(672, 64)
	await get_tree().process_frame
	_check(long_title.size.x >= long_title.get_combined_minimum_size().x and _header_fits(long_header, 672.0), "centered long GAME CATEGORIES title remains untruncated at 704px")
	long_header.queue_free()

	var back_header := UnicornHeader.build("NUMBER GAMES", "BACK", Callable(self, "_record_back"), Callable(self, "_noop"))
	host.add_child(back_header)
	back_header.position = Vector2(16, 14)
	back_header.size = Vector2(502, 64)
	await get_tree().process_frame
	var back_button := back_header.find_child("HeaderBackButton", true, false) as Button
	var back_home := back_header.find_child("HeaderHomeButton", true, false) as Button
	var back_actions := back_header.find_child("HeaderActions", true, false) as Control
	_check(back_button != null and back_button.has_meta("compact_header_control") and back_home != null and back_home.has_meta("compact_header_control"), "BACK header actions declare compact-header accessibility metadata")
	_check(back_button != null and back_home != null and back_button.text == "‹ BACK" and back_button.size.x >= back_button.get_combined_minimum_size().x and back_button.position.y == 8.0 and back_button.size.y == 48.0 and back_home.position.y == 8.0 and back_home.size.y == 48.0 and _header_fits(back_header, 502.0), "BACK remains readable and untruncated while Back and Home use matching centered 48px controls")
	_check(back_actions != null and back_actions.mouse_filter == Control.MOUSE_FILTER_IGNORE and back_actions.get_rect().has_point(back_button.get_rect().get_center()), "the full-rect action host covers Back but is pointer-transparent")
	back_button.pressed.emit()
	_check(back_taps == 1, "Back's normal pressed signal reaches the registered callback exactly once")
	back_header.size = Vector2(672, 64)
	await get_tree().process_frame
	_check(back_button.size.x >= back_button.get_combined_minimum_size().x and back_button.position.y == 8.0 and back_button.size.y == 48.0 and back_home.position.y == 8.0 and back_home.size.y == 48.0 and _header_fits(back_header, 672.0), "BACK remains untruncated while Back and Home stay centered and shadow-contained at native width")
	back_header.queue_free()
	host.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("UNICORN HEADER SCOPE TESTS PASSED")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _header_fits(header: Panel, width: float) -> bool:
	var parts: Array[Control] = []
	for name in ["HeaderLeftSpacer", "HeaderBackButton", "HeaderTitle", "HeaderHomeButton", "SharedCoinIcon", "SharedCoinBalance", "HeaderTrailingAction"]:
		var part := header.find_child(name, true, false) as Control
		if part != null:
			parts.append(part)
	for part in parts:
		if part.position.x < 0.0 or part.get_rect().end.x > width or part.position.y < 0.0 or part.get_rect().end.y > header.size.y:
			return false
	for first_index in parts.size():
		for second_index in range(first_index + 1, parts.size()):
			if parts[first_index].get_rect().intersects(parts[second_index].get_rect()):
				return false
	return true


func _noop() -> void:
	pass


func _record_back() -> void:
	back_taps += 1


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
