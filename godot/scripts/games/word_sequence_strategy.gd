class_name WordSequenceStrategy
extends WordGameModeStrategy

const Rules = preload("res://scripts/games/word_game_rules.gd")
const RoundCatalog = preload("res://scripts/games/word_round_catalog.gd")
const IDS := ["sentence_sprout", "syllable_stamp", "scramble_spell", "size_line_up"]


func family() -> String:
	return "sequence"


func supports(game_id: String) -> bool:
	return game_id in IDS


func begin_round(context: Dictionary) -> Dictionary:
	var game_id := str(context.get("game_id", ""))
	if not supports(game_id):
		return super.begin_round(context)
	var level := int(context.get("level", 1))
	var round_index := int(context.get("round_index", 0))
	var rng := context.get("rng") as RandomNumberGenerator
	if rng == null:
		return _invalid_round()
	match game_id:
		"sentence_sprout":
			return _begin_catalog_round("sentence_build", "words", level, round_index, rng, "sentence", "Build the sentence in order")
		"syllable_stamp":
			return _begin_catalog_round("syllable_words", "parts", level, round_index, rng, "syllable", "Stamp syllables in order")
		"scramble_spell":
			return _begin_scramble_round(level, round_index, rng)
		"size_line_up":
			return _begin_size_round(level, round_index, rng)
	return _invalid_round()


func submit(context: Dictionary, payload) -> Dictionary:
	var game_id := str(context.get("game_id", ""))
	if not supports(game_id):
		return super.submit(context, payload)
	var sequence: Array = context.get("sequence", [])
	var pool: Array = context.get("pool", [])
	var picked: Array = context.get("picked", [])
	var payload_data: Dictionary = payload if payload is Dictionary else {}
	var value = payload_data.get("value")
	var index := int(payload_data.get("index", -1))
	if picked.size() >= sequence.size() or value != sequence[picked.size()]:
		return {"outcome": "failure", "picked": picked.duplicate(), "pool": pool.duplicate()}
	var next_picked := picked.duplicate()
	var next_pool := pool.duplicate()
	next_picked.append(value)
	if index >= 0 and index < next_pool.size():
		next_pool.remove_at(index)
	return {
		"outcome": "success" if next_picked.size() >= sequence.size() else "continue",
		"picked": next_picked,
		"pool": next_pool,
	}


func hint(context: Dictionary) -> Dictionary:
	var game_id := str(context.get("game_id", ""))
	if not supports(game_id):
		return super.hint(context)
	var sequence: Array = context.get("sequence", [])
	var picked: Array = context.get("picked", [])
	if picked.size() >= sequence.size():
		return {"next": ""}
	return {"next": str(sequence[picked.size()])}


func failure_reason(context: Dictionary) -> String:
	var game_id := str(context.get("game_id", ""))
	if not supports(game_id):
		return super.failure_reason(context)
	return {
		"sentence_sprout": "Tap words in the right order!",
		"syllable_stamp": "Stamp syllables in order!",
		"scramble_spell": "Tap letters in order to spell the word!",
		"size_line_up": "Tap shortest word first, then longer ones!",
	}.get(game_id, super.failure_reason(context))


func _begin_catalog_round(key: String, field: String, level: int, round_index: int, rng: RandomNumberGenerator, phase: String, instruction: String) -> Dictionary:
	var current := RoundCatalog.pick_rule_round(Rules, key, level, round_index, rng)
	var prepared := RoundCatalog.sequence_round(current, field)
	return _round(current, prepared.get("sequence", []), prepared.get("pool", []), phase, instruction)


func _begin_scramble_round(level: int, round_index: int, rng: RandomNumberGenerator) -> Dictionary:
	var current := RoundCatalog.pick_rule_round(Rules, "scramble_puzzles", level, round_index, rng)
	var sequence: Array = Array(str(current.get("word", "")).split(""))
	var pool := sequence.duplicate()
	pool.shuffle()
	return _round(current, sequence, pool, "scramble", str(current.get("hint", "Spell the word")))


func _begin_size_round(level: int, round_index: int, rng: RandomNumberGenerator) -> Dictionary:
	var current := RoundCatalog.pick_rule_round(Rules, "size_lineups", level, round_index, rng)
	var sequence: Array = current.get("order", []).duplicate()
	var pool: Array = current.get("words", []).duplicate()
	pool.shuffle()
	return _round(current, sequence, pool, "size", "Tap shortest → longest")


func _round(current: Dictionary, sequence: Array, pool: Array, phase: String, instruction: String) -> Dictionary:
	if current.is_empty() or sequence.is_empty() or pool.is_empty():
		return _invalid_round()
	return {
		"handled": true,
		"ok": true,
		"current": current,
		"sequence": sequence,
		"pool": pool,
		"phase": phase,
		"instruction": instruction,
	}


func _invalid_round() -> Dictionary:
	return {
		"handled": true,
		"ok": false,
		"current": {},
		"sequence": [],
		"pool": [],
		"phase": "",
		"instruction": "",
	}
