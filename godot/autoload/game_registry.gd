extends Node

const GAMES := [
	{"id": "unicorn_jump", "title": "Unicorn Jump", "category": "Number", "scene": ""},
	{"id": "sliding_window", "title": "Sliding Window", "category": "Number", "scene": ""},
	{"id": "coin_count", "title": "Coin Count", "category": "Number", "scene": "res://scenes/games/coin_count.tscn"},
	{"id": "cash_counter", "title": "Cash Counter", "category": "Number", "scene": ""},
	{"id": "math_swipe", "title": "Math Swipe", "category": "Number", "scene": ""},
	{"id": "mathtris", "title": "Mathtris", "category": "Number", "scene": ""},
	{"id": "unicorn_blast", "title": "Unicorn Blast", "category": "Word", "scene": ""},
	{"id": "rhyme_rally", "title": "Rhyme Rally", "category": "Word", "scene": "res://scenes/games/rhyme_rally.tscn"},
	{"id": "sentence_sprout", "title": "Sentence Sprout", "category": "Word", "scene": ""},
	{"id": "missing_magic", "title": "Missing Magic", "category": "Word", "scene": ""},
	{"id": "sight_spark", "title": "Sight Spark", "category": "Word", "scene": ""},
	{"id": "prefix_potion", "title": "Prefix Potion", "category": "Word", "scene": ""},
	{"id": "vowel_vines", "title": "Vowel Vines", "category": "Word", "scene": ""},
	{"id": "letter_lift", "title": "Letter Lift", "category": "Word", "scene": ""},
	{"id": "syllable_stamp", "title": "Syllable Stamp", "category": "Word", "scene": ""},
	{"id": "caption_quest", "title": "Caption Quest", "category": "Word", "scene": ""},
	{"id": "opposite_orbit", "title": "Opposite Orbit", "category": "Mystery", "scene": ""},
	{"id": "scramble_spell", "title": "Scramble Spell", "category": "Mystery", "scene": ""},
	{"id": "odd_one_out", "title": "Odd One Out", "category": "Mystery", "scene": ""},
	{"id": "size_line_up", "title": "Size Line-Up", "category": "Mystery", "scene": ""},
	{"id": "chain_link", "title": "Chain Link", "category": "Mystery", "scene": ""},
	{"id": "galaxy_unicorn", "title": "Galaxy Unicorn", "category": "Arcade", "scene": ""},
]


func all_games() -> Array:
	return GAMES.duplicate(true)


func get_game(game_id: String) -> Dictionary:
	for game in GAMES:
		if game["id"] == game_id:
			return game.duplicate(true)
	return {}


func games_in_category(category: String) -> Array:
	return GAMES.filter(func(game: Dictionary) -> bool: return game["category"] == category)
