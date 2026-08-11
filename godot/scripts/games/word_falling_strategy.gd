class_name WordFallingStrategy
extends WordGameModeStrategy

const Rules = preload("res://scripts/games/word_game_rules.gd")
const IDS := ["unicorn_blast"]


func family() -> String:
	return "falling"


func supports(game_id: String) -> bool:
	return game_id in IDS


func begin_round(context: Dictionary) -> Dictionary:
	if not supports(str(context.get("game_id", ""))):
		return super.begin_round(context)
	return {"handled": true, "ok": true, "phase": "blast", "instruction": "Type each falling word before it reaches the cannon", "prompt": "UNICORN CANNON", "placeholder": "Type a falling word…"}


func spawn(context: Dictionary) -> Dictionary:
	if not supports(str(context.get("game_id", ""))):
		return {"handled": false}
	var words := Rules.words_for_level(int(context.get("level", 1)))
	if words.is_empty():
		return {"handled": true, "spawned": false, "source_empty": true}
	var rng := context.get("rng") as RandomNumberGenerator
	if rng == null:
		return {"handled": true, "spawned": false, "source_empty": true}
	return {"handled": true, "spawned": true, "entry": {"text": str(words[rng.randi_range(0, words.size() - 1)]), "x": rng.randf_range(12.0, 76.0), "y": 8.0}}


func submit(context: Dictionary, payload) -> Dictionary:
	if not supports(str(context.get("game_id", ""))):
		return super.submit(context, payload)
	var candidate := str(payload).strip_edges().to_lower()
	var entries: Array = context.get("blast_models", [])
	for index in entries.size():
		if str(entries[index].get("text", "")) == candidate:
			return {"outcome": "success", "match_index": index}
	return {"outcome": "ignored"}


func tick(context: Dictionary, delta: float) -> Dictionary:
	if not supports(str(context.get("game_id", ""))):
		return super.tick(context, delta)
	var spawn_elapsed := float(context.get("spawn_elapsed", 0.0)) + delta
	var entries: Array = []
	for source_entry in context.get("blast_models", []):
		entries.append((source_entry as Dictionary).duplicate(true))
	var spawn_due := not bool(context.get("blast_source_exhausted", false)) and spawn_elapsed * 1000.0 >= Rules.blast_spawn_ms(int(context.get("level", 1)))
	var spawned := false
	var source_empty := false
	if spawn_due:
		spawn_elapsed = 0.0
		var spawn_result := spawn(context)
		spawned = bool(spawn_result.get("spawned", false))
		source_empty = bool(spawn_result.get("source_empty", false))
		if spawned:
			entries.append((spawn_result.get("entry", {}) as Dictionary).duplicate(true))
	var escaped: Array[int] = []
	for index in entries.size():
		var entry: Dictionary = entries[index]
		entry["y"] = float(entry.get("y", 8.0)) + Rules.blast_speed(int(context.get("level", 1))) * delta * 60.0
		if float(entry["y"]) > 78.0:
			escaped.append(index)
	return {"handled": true, "spawn_elapsed": spawn_elapsed, "spawn_due": spawn_due, "spawned": spawned, "source_empty": source_empty, "entries": entries, "escaped": escaped}


func hint(context: Dictionary) -> Dictionary:
	if not supports(str(context.get("game_id", ""))):
		return super.hint(context)
	var urgent := ""
	var highest := -1.0
	for entry in context.get("blast_models", []):
		if float(entry.get("y", 0.0)) > highest:
			highest = float(entry.get("y", 0.0))
			urgent = str(entry.get("text", ""))
	return {"word": urgent, "message": "Blast: %s" % urgent}


func failure_reason(context: Dictionary) -> String:
	if not supports(str(context.get("game_id", ""))):
		return super.failure_reason(context)
	return "Words reached your cannon!"
