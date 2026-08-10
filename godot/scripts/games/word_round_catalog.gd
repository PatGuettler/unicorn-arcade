class_name WordRoundCatalog
extends RefCounted

static func word_for_round(words: Array, level: int, round_index: int) -> String:
	if words.is_empty():
		return ""
	return str(words[(round_index + level) % words.size()])

static func pick_rule_round(rules: Object, key: String, level: int, round_index: int, rng: RandomNumberGenerator) -> Dictionary:
	return rules.pick_for_level(key, level + round_index, rng)

static func vowel_for_round(vowels: Array, level: int, round_index: int) -> String:
	if vowels.is_empty():
		return ""
	return str(vowels[(round_index + level) % vowels.size()])

static func sequence_round(current: Dictionary, field: String) -> Dictionary:
	var values = current.get(field, [])
	if not values is Array:
		return {"current": current, "sequence": [], "pool": []}
	var sequence: Array = values.duplicate()
	var pool := sequence.duplicate()
	pool.shuffle()
	return {"current": current, "sequence": sequence, "pool": pool}

static func vowel_round(data: Dictionary, vowels: Array, level: int, round_index: int, rng: RandomNumberGenerator) -> Dictionary:
	var vowel := vowel_for_round(vowels, level, round_index)
	if vowel.is_empty():
		return {}
	var all_vowels: Dictionary = data.get("vowel_words", {})
	var good: Array = all_vowels.get(vowel, [])
	if good.is_empty():
		return {}
	var choices: Array = [good[rng.randi_range(0, good.size() - 1)]]
	var wrong_pool: Array = []
	for other in vowels:
		if other != vowel:
			wrong_pool.append_array(all_vowels.get(other, []))
	wrong_pool.shuffle()
	for word in wrong_pool:
		if not choices.has(word):
			choices.append(word)
		if choices.size() == 4:
			break
	choices.shuffle()
	return {"vowel": vowel, "choices": choices}
