extends Node


func _ready() -> void:
	_run.call_deferred()


func _source(path: String, issues: Array[String]) -> String:
	if not FileAccess.file_exists(path):
		issues.append("required audit source is missing: %s" % path)
		return ""
	return FileAccess.get_file_as_string(path)


func _check(condition: bool, message: String, issues: Array[String]) -> void:
	if not condition:
		issues.append(message)


func _run() -> void:
	var issues: Array[String] = []
	var main := _source("res://scripts/main.gd", issues)
	var marketplace := _source("res://scripts/meta/marketplace.gd", issues)
	var jump := _source("res://scripts/games/unicorn_jump.gd", issues)
	var coin := _source("res://scripts/games/coin_count.gd", issues)
	var cash := _source("res://scripts/games/cash_counter.gd", issues)
	var word := _source("res://scripts/games/word_game.gd", issues)
	var galaxy := _source("res://scripts/games/galaxy_unicorn.gd", issues)
	var mathtris := _source("res://scripts/games/mathtris.gd", issues)
	var capture := _source("res://tests/capture_alpha.gd", issues)
	var app_state := _source("res://autoload/app_state.gd", issues)
	var previews := _source("res://autoload/decor_preview_cache.gd", issues)
	var loader := _source("res://autoload/runtime_asset_loader.gd", issues)
	var abilities := _source("res://autoload/companion_ability_service.gd", issues)

	_check(not FileAccess.file_exists("res://scripts/meta/furniture_art.gd") and not FileAccess.file_exists("res://scripts/meta/furniture_art.gd.uid"), "FurnitureArt source and UID are removed", issues)
	_check(not main.contains("func _show_home_status("), "dead main._show_home_status is removed", issues)
	_check(not marketplace.contains("signal scene_change_ready"), "unused Marketplace scene_change_ready signal is removed", issues)
	_check(not jump.contains("func _signed("), "dead Unicorn Jump _signed helper is removed", issues)
	_check(not coin.contains("static func target_bounds("), "unused Coin Count target_bounds helper is removed", issues)
	_check(not word.contains("const PANEL :="), "unused Word Game PANEL constant is removed", issues)
	_check(not galaxy.contains("LegacyGalaxyHUD") and not galaxy.contains("var hud_label:") and not galaxy.contains("func _update_hud("), "hidden legacy Galaxy HUD is removed", issues)

	_check(main.contains("signal scene_change_ready") and main.contains("return scene_change_ready") and main.contains("scene_change_ready.emit()"), "Main scene_change_ready remains a used public transition signal", issues)
	_check(cash.contains("static func target_bounds(") and cash.contains("var bounds := target_bounds(level)"), "Cash Counter retains its used target_bounds helper", issues)
	_check(mathtris.contains("var hud_label:") and mathtris.contains("hud_label.text =") and mathtris.contains("root.add_child(hud_label)"), "Mathtris retains its visible HUD", issues)
	_check(capture.count("room_selected") >= 4, "room_selected remains a supported capture presentation", issues)
	_check(app_state.contains("signal state_changed") and app_state.count("state_changed.emit()") >= 3, "AppState.state_changed remains declared and emitted", issues)
	_check(previews.contains("signal preview_ready") and previews.contains("preview_ready.emit("), "decor preview_ready remains declared and emitted", issues)
	_check(loader.contains("signal packed_scene_loaded") and loader.contains("packed_scene_loaded.emit(") and loader.contains("signal packed_scene_failed") and loader.contains("packed_scene_failed.emit("), "runtime loader result signals remain declared and emitted", issues)
	_check(abilities.contains("signal ability_changed") and abilities.contains("ability_changed.emit()") and abilities.contains("signal ability_activated") and abilities.contains("ability_activated.emit("), "companion ability signals remain declared and emitted", issues)
	_check(word.contains("var title_label: Label") and word.contains("title_label = Label.new()") and word.contains("header.add_child(title_label)"), "Word Game title_label remains live and visible", issues)

	if issues.is_empty():
		print("DEAD_CODE_AUDIT_PR31_OK")
		get_tree().quit(0)
	else:
		push_error("PR31 dead-code audit failed: %s" % "; ".join(issues))
		get_tree().quit(1)
