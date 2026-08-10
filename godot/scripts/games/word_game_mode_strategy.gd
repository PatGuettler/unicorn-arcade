class_name WordGameModeStrategy
extends RefCounted


func family() -> String:
	return ""


func supports(_game_id: String) -> bool:
	return false


func begin_round(_context: Dictionary) -> Dictionary:
	return {"handled": false}


func submit(_context: Dictionary, _payload) -> Dictionary:
	return {"outcome": "ignored"}


func hint(_context: Dictionary) -> Dictionary:
	return {}


func tick(_context: Dictionary, _delta: float) -> Dictionary:
	return {}


func failure_reason(_context: Dictionary) -> String:
	return "Try this level again."
