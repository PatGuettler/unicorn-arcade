extends Node

signal ability_changed
signal ability_activated(companion_id: String, game_id: String)

const ABILITIES := {
	"sparkle": {"name": "Second Sparkle", "description": "Gives you one free retry.", "active": false},
	"rainbow": {"name": "Lucky Rainbow", "description": "Gives a chance at bonus coins.", "active": false},
	"star": {"name": "Guiding Star", "description": "Gives you a free hint.", "active": false},
	"cloud": {"name": "Cloud Time", "description": "Makes fast parts move slower.", "active": false},
	"dream": {"name": "Dreamy Nudge", "description": "Makes a helpful move glow if you get stuck.", "active": false},
	"mystic": {"name": "Mystic Move", "description": "Tap to make one helpful move.", "active": true},
}

var game_id := ""
var level := 0
var used := false
var assist_hint_armed := false


func begin_level(next_game_id: String, next_level: int) -> void:
	if game_id == next_game_id and level == next_level:
		return
	game_id = next_game_id
	level = next_level
	used = false
	assist_hint_armed = false
	ability_changed.emit()


func companion_id() -> String:
	var app_state := get_node_or_null("/root/AppState")
	return str(app_state.call("equipped_companion")) if app_state != null else "sparkle"


func definition() -> Dictionary:
	return ABILITIES.get(companion_id(), ABILITIES["sparkle"]).duplicate(true)


func is_available() -> bool:
	return not used


func consume_checkpoint_retry() -> bool:
	if companion_id() != "sparkle" or used:
		return false
	_use()
	return true


func consume_free_hint() -> bool:
	if assist_hint_armed:
		assist_hint_armed = false
		return true
	if companion_id() != "star" or used:
		return false
	_use()
	return true


func arm_assist_hint() -> void:
	assist_hint_armed = true


func time_scale() -> float:
	return 0.75 if companion_id() == "cloud" else 1.0


func consume_dream_nudge() -> bool:
	if companion_id() != "dream" or used:
		return false
	_use()
	return true


func consume_mystic_move() -> bool:
	if companion_id() != "mystic" or used:
		return false
	_use()
	return true


func reward_bonus(base_reward: int) -> int:
	if companion_id() != "rainbow" or used:
		return 0
	# A saved completion can never be rerolled by reopening a result screen.
	var app_state := get_node_or_null("/root/AppState")
	var progress: Dictionary = app_state.call("progress_for_game", game_id) if app_state != null else {}
	var run_count: int = progress.get("completed", []).size()
	var roll := absi(hash("%s:%d:%d" % [game_id, level, run_count])) % 100
	used = true
	ability_changed.emit()
	if roll < 20:
		ability_activated.emit(companion_id(), game_id)
		return ceili(base_reward * 0.5)
	return 0


func _use() -> void:
	used = true
	ability_changed.emit()
	ability_activated.emit(companion_id(), game_id)
