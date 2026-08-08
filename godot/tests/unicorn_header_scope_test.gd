extends Node

const UnicornHeader = preload("res://scripts/ui/unicorn_header.gd")

var failures: Array[String] = []


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var home_header := UnicornHeader.build("UNICORN ALLEY", "HOME", Callable(self, "_noop"), Callable(self, "_noop"), "SHOP", Callable(self, "_noop"))
	get_tree().root.add_child(home_header)
	await get_tree().process_frame
	_check(home_header.find_child("HeaderLeftSpacer", true, false) != null, "HOME headers retain a left spacer instead of a duplicate back-home button")
	_check(home_header.find_child("HeaderBackButton", true, false) == null, "HOME headers expose only one Home control")
	var home_button := home_header.find_child("HeaderHomeButton", true, false) as Button
	_check(home_button != null and home_button.icon != null and home_button.text.is_empty(), "shared Home controls use the house icon treatment")
	var coin_icon := home_header.find_child("SharedCoinIcon", true, false) as TextureRect
	var coins := home_header.find_child("SharedCoinBalance", true, false) as Label
	var actions := home_header.find_child("HeaderActions", true, false) as HBoxContainer
	_check(coin_icon != null and coin_icon.texture != null, "shared headers display a visible coin icon")
	_check(coins != null and coins.text == str(AppState.coins()) and actions != null and actions.custom_minimum_size.x == 202.0, "shared header uses a compact numeric coin balance while reserving the exact width for a trailing action")
	home_header.queue_free()
	var marketplace_header := UnicornHeader.build("MARKETPLACE", "HOME", Callable(self, "_noop"), Callable(self, "_noop"))
	get_tree().root.add_child(marketplace_header)
	await get_tree().process_frame
	_check(marketplace_header.get_combined_minimum_size().x <= 534.0, "a HOME Marketplace-style header fits inside the 534-pixel phone content width")
	marketplace_header.queue_free()

	var back_header := UnicornHeader.build("NUMBER GAMES", "BACK", Callable(self, "_noop"), Callable(self, "_noop"))
	get_tree().root.add_child(back_header)
	await get_tree().process_frame
	_check(back_header.find_child("HeaderBackButton", true, false) != null, "BACK headers preserve their previous-screen control")
	_check(back_header.find_child("HeaderHomeButton", true, false) != null, "BACK headers retain the Home control")
	back_header.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("UNICORN HEADER SCOPE TESTS PASSED")
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _noop() -> void:
	pass


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
