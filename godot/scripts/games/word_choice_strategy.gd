class_name WordChoiceStrategy
extends WordGameModeStrategy

const Rules = preload("res://scripts/games/word_game_rules.gd")
const RoundCatalog = preload("res://scripts/games/word_round_catalog.gd")
const VOWELS := ["a", "e", "i", "o", "u"]
const IDS := [
	"missing_magic",
	"prefix_potion",
	"vowel_vines",
	"caption_quest",
	"opposite_orbit",
	"odd_one_out",
	"chain_link",
]


func family() -> String:
	return "choice"


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
	if game_id == "vowel_vines":
		return _begin_vowel_round(level, round_index, rng)
	return _begin_rule_round(game_id, level, round_index, rng, bool(context.get("hint_visible", false)))


func submit(context: Dictionary, payload) -> Dictionary:
	var game_id := str(context.get("game_id", ""))
	if not supports(game_id):
		return super.submit(context, payload)
	var current: Dictionary = context.get("current", {})
	if current.is_empty():
		return {"outcome": "failure"}
	var value := str(payload)
	var correct := false
	match game_id:
		"missing_magic", "prefix_potion", "caption_quest", "opposite_orbit":
			correct = value == str(current.get("answer", ""))
		"vowel_vines":
			correct = not value.is_empty() and value.left(1).to_lower() == str(current.get("vowel", ""))
		"odd_one_out":
			correct = value == str(current.get("odd", ""))
		"chain_link":
			correct = Rules.is_chain_link(str(current.get("start", "")), value)
	if correct:
		return {"outcome": "success"}
	if game_id in ["caption_quest", "odd_one_out"]:
		return {"outcome": "lost_life"}
	return {"outcome": "failure"}


func hint(context: Dictionary) -> Dictionary:
	var game_id := str(context.get("game_id", ""))
	if not supports(game_id):
		return super.hint(context)
	var current: Dictionary = context.get("current", {})
	match game_id:
		"missing_magic":
			return {"prompt": _missing_prompt(current, true), "message": ""}
		"prefix_potion":
			return {
				"prompt": "%s + %s = %s" % [current.get("prefix", ""), current.get("root", ""), current.get("answer", "")],
				"message": "",
			}
		"vowel_vines":
			return {"message": "Pick the word starting with %s." % str(current.get("vowel", "")).to_upper()}
		"caption_quest", "opposite_orbit":
			return {"message": "Try: %s" % current.get("answer", "")}
		"odd_one_out":
			return {"message": "Investigate: %s" % current.get("odd", "")}
		"chain_link":
			return {"message": "Start with %s." % str(current.get("start", "")).right(1).to_upper()}
	return {}


func failure_reason(context: Dictionary) -> String:
	var game_id := str(context.get("game_id", ""))
	if not supports(game_id):
		return super.failure_reason(context)
	return {
		"missing_magic": "Fill the magic blank!",
		"prefix_potion": "Brew the real word!",
		"vowel_vines": "Choose a word beginning with the target vowel!",
		"caption_quest": "Out of hearts—choose the best caption!",
		"opposite_orbit": "Pick the word that means the opposite!",
		"odd_one_out": "Find the item that does not belong!",
		"chain_link": "Pick a word beginning with the last letter!",
	}.get(game_id, super.failure_reason(context))


func _begin_vowel_round(level: int, round_index: int, rng: RandomNumberGenerator) -> Dictionary:
	var prepared := RoundCatalog.vowel_round(Rules.data(), VOWELS, level, round_index, rng)
	var choices: Array = prepared.get("choices", [])
	if prepared.is_empty() or choices.is_empty():
		return _invalid_round()
	var current := {"vowel": prepared.get("vowel", "")}
	if str(current["vowel"]).is_empty():
		return _invalid_round()
	var options: Array = []
	for choice in choices:
		options.append({"text": str(choice), "payload": choice})
	return _round(current, "Choose a word beginning with", str(current["vowel"]).to_upper(), options)


func _begin_rule_round(game_id: String, level: int, round_index: int, rng: RandomNumberGenerator, hint_visible: bool) -> Dictionary:
	var key: String = str({
		"missing_magic": "missing_word",
		"prefix_potion": "prefix_mix",
		"caption_quest": "caption_scenes",
		"opposite_orbit": "opposite_challenges",
		"odd_one_out": "odd_one_out",
		"chain_link": "chain_links",
	}.get(game_id, ""))
	var current := RoundCatalog.pick_rule_round(Rules, key, level, round_index, rng)
	if current.is_empty():
		return _invalid_round()
	var options: Array = []
	match game_id:
		"missing_magic":
			var missing_choices: Array = current.get("options", []).duplicate()
			missing_choices.shuffle()
			for choice in missing_choices:
				options.append({"text": str(choice), "payload": choice})
			return _round(current, "Fill the magic blank", _missing_prompt(current, hint_visible), options)
		"prefix_potion":
			var prefix_choices: Array = [current.get("answer", "")]
			prefix_choices.append_array(current.get("wrong", []))
			prefix_choices.shuffle()
			for choice in prefix_choices:
				options.append({"text": str(choice), "payload": choice})
			var answer: String = str(current.get("answer", "?")) if hint_visible else "?"
			return _round(current, "Brew prefix + root into a real word", "%s + %s = %s" % [current.get("prefix", ""), current.get("root", ""), answer], options)
		"caption_quest":
			var caption_choices: Array = current.get("options", []).duplicate()
			caption_choices.shuffle()
			for choice in caption_choices:
				options.append({"text": str(choice), "payload": choice})
			return _round(current, str(current.get("prompt", "Choose the best caption")), str(current.get("emoji", "")), options)
		"opposite_orbit":
			var opposite_choices: Array = current.get("options", []).duplicate()
			opposite_choices.shuffle()
			for choice in opposite_choices:
				options.append({"text": str(choice), "payload": choice})
			return _round(current, "Choose the opposite of", str(current.get("word", "")), options)
		"odd_one_out":
			var items: Array = current.get("items", []).duplicate(true)
			items.shuffle()
			for item in items:
				options.append({"text": "%s\n%s" % [item.get("emoji", ""), item.get("label", "")], "payload": item.get("label", "")})
			return _round(current, str(current.get("theme", "Find the odd one out")), "CASE FILE", options)
		"chain_link":
			var chain_choices: Array = current.get("options", []).duplicate()
			chain_choices.shuffle()
			for choice in chain_choices:
				options.append({"text": str(choice), "payload": choice})
			var start := str(current.get("start", ""))
			return _round(current, "Continue with the last letter", "%s  →  %s…" % [start, start.right(1).to_upper()], options)
	return _invalid_round()


func _round(current: Dictionary, instruction: String, prompt: String, options: Array) -> Dictionary:
	if options.is_empty():
		return _invalid_round()
	return {
		"handled": true,
		"ok": true,
		"current": current,
		"instruction": instruction,
		"prompt": prompt,
		"options": options,
	}


func _invalid_round() -> Dictionary:
	return {
		"handled": true,
		"ok": false,
		"current": {},
		"instruction": "",
		"prompt": "",
		"options": [],
	}


func _missing_prompt(current: Dictionary, reveal: bool) -> String:
	var rendered: Array[String] = []
	for piece in current.get("text", []):
		if piece == null:
			rendered.append(str(current.get("answer", "")) if reveal else "___")
		else:
			rendered.append(str(piece))
	return " ".join(rendered)
