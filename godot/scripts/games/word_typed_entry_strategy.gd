class_name WordTypedEntryStrategy
extends WordGameModeStrategy

const Rules = preload("res://scripts/games/word_game_rules.gd")
const RoundCatalog = preload("res://scripts/games/word_round_catalog.gd")
const IDS := ["sight_spark", "letter_lift"]


func family() -> String:
	return "typed_entry"


func supports(game_id: String) -> bool:
	return game_id in IDS


func begin_round(context: Dictionary) -> Dictionary:
	var game_id := str(context.get("game_id", ""))
	if not supports(game_id):
		return super.begin_round(context)
	var level := int(context.get("level", 1))
	var round_index := int(context.get("round_index", 0))
	var words := Rules.words_for_level(level)
	var expected_word := RoundCatalog.word_for_round(words, level, round_index)
	if expected_word.is_empty():
		return _invalid_round()
	if game_id == "sight_spark":
		return {
			"handled": true,
			"ok": true,
			"expected_word": expected_word,
			"phase": "flash",
			"instruction": "Remember this word",
			"prompt": expected_word,
			"placeholder": "",
			"flash_ms": Rules.sight_flash_ms(level),
			"input_visible": false,
		}
	return {
		"handled": true,
		"ok": true,
		"expected_word": expected_word,
		"phase": "letter",
		"instruction": "Type each letter in order",
		"prompt": "_".repeat(expected_word.length()),
		"placeholder": "Type letters…",
		"flash_ms": 0,
		"input_visible": true,
	}


func submit(context: Dictionary, payload) -> Dictionary:
	var game_id := str(context.get("game_id", ""))
	if not supports(game_id):
		return super.submit(context, payload)
	if game_id == "sight_spark":
		return _submit_sight(context, str(payload))
	return _submit_letter(context, str(payload))


func hint(context: Dictionary) -> Dictionary:
	var game_id := str(context.get("game_id", ""))
	if not supports(game_id):
		return super.hint(context)
	var expected_word := str(context.get("expected_word", ""))
	if game_id == "sight_spark":
		if str(context.get("phase", "")) == "type":
			return {"prompt": expected_word, "message": ""}
		return {"message": "Look closely at the prompt."}
	var picked: Array = context.get("picked", [])
	return {"next": expected_word.substr(picked.size(), 1)}


func tick(context: Dictionary, _delta: float) -> Dictionary:
	var game_id := str(context.get("game_id", ""))
	if not supports(game_id) or game_id != "sight_spark" or not bool(context.get("flash_expired", false)):
		return super.tick(context, _delta)
	if str(context.get("phase", "")) != "flash":
		return {"handled": true}
	var expected_word := str(context.get("expected_word", ""))
	return {
		"handled": true,
		"phase": "type",
		"instruction": "Type the word from memory",
		"prompt": expected_word if bool(context.get("hint_visible", false)) else "?",
		"placeholder": "What did you see?",
		"input_visible": true,
	}


func failure_reason(context: Dictionary) -> String:
	var game_id := str(context.get("game_id", ""))
	if not supports(game_id):
		return super.failure_reason(context)
	return {
		"sight_spark": "Spell the spark word from memory!",
		"letter_lift": "Type each letter in order!",
	}.get(game_id, super.failure_reason(context))


func _submit_sight(context: Dictionary, value: String) -> Dictionary:
	if str(context.get("phase", "")) != "type":
		return {"outcome": "ignored"}
	var expected_word := str(context.get("expected_word", ""))
	if value.strip_edges().to_lower() == expected_word:
		return {"outcome": "success", "picked": [], "input": value}
	return {"outcome": "failure", "picked": [], "input": value}


func _submit_letter(context: Dictionary, value: String) -> Dictionary:
	var expected_word := str(context.get("expected_word", ""))
	var picked: Array = context.get("picked", [])
	var typed := "".join(picked)
	if value.length() <= typed.length():
		return {"outcome": "ignored", "picked": picked.duplicate(), "input": typed}
	var character := value.substr(typed.length(), 1).to_lower()
	if character != expected_word.substr(picked.size(), 1):
		return {"outcome": "failure", "picked": picked.duplicate(), "input": typed}
	var next_picked := picked.duplicate()
	next_picked.append(character)
	return {
		"outcome": "success" if next_picked.size() >= expected_word.length() else "continue",
		"picked": next_picked,
		"input": "".join(next_picked),
	}


func _invalid_round() -> Dictionary:
	return {
		"handled": true,
		"ok": false,
		"expected_word": "",
		"phase": "",
		"instruction": "",
		"prompt": "",
		"placeholder": "",
		"flash_ms": 0,
		"input_visible": false,
	}
