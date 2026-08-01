class_name GameplayRules
extends RefCounted


static func math_swipe_target(level: int) -> int:
	return 3 + level / 2


static func jump_path_length(level: int) -> int:
	return 5 + level * 5


static func jump_max(level: int) -> int:
	return 6 if level > 5 else (4 if level > 2 else 3)


static func jump_negative_max(level: int) -> int:
	return 5 if level >= 25 else (2 if level >= 15 else 0)


static func sliding_length(level: int) -> int:
	return 20 if level > 5 else 15


static func sliding_bounds(level: int) -> Vector2i:
	return Vector2i(-100 if level > 5 else 0, 100 if level > 2 else 20)


static func sliding_window(level: int) -> int:
	return mini(5, 3 + level / 3)


static func rival_move_ms(level: int) -> int:
	return maxi(1000, 2500 - (level - 1) * 150)


static func galaxy_target(level: int) -> int:
	return 8 + int(floor(level * 2.5))


static func galaxy_fire_ms(level: int) -> int:
	return maxi(120, 280 - level * 15)


static func galaxy_spawn_ms(level: int) -> int:
	return maxi(600, 2200 - level * 150)


static func galaxy_enemy_speed_scale(level: int) -> float:
	return minf(1.35, 0.25 + float(maxi(1, level) - 1) * 0.075)


static func mathtris_drop_ms(level: int, drops: int = 0, elapsed_seconds: int = 0) -> int:
	var value: int
	if level <= 10:
		value = 950 - (level - 1) * 70
	elif level <= 20:
		value = 280 - (level - 11) * 7
	else:
		value = 200 - (level - 21) * 4
	value -= mini(240, drops * 5)
	value -= mini(200, elapsed_seconds * 4)
	return maxi(90, value)


static func mathtris_concurrent(elapsed_seconds: int, level: int) -> int:
	var count := 1
	if elapsed_seconds >= 35:
		count = 2
	if elapsed_seconds >= 70:
		count = 3
	if elapsed_seconds >= 110:
		count = 4
	if elapsed_seconds >= 150:
		count = 5
	if level >= 12:
		count += 1
	return mini(5, count)


static func mathtris_allowed(level: int) -> Array[String]:
	if level <= 10:
		return ["1", "2", "+", "="]
	if level <= 20:
		var middle: Array[String] = ["1", "2", "3", "+", "="]
		if level >= 13:
			middle.insert(3, "4")
		if level >= 16:
			middle.insert(4, "5")
		return middle
	var maximum := mini(9, 5 + (level - 21) / 3)
	var result: Array[String] = []
	for digit in range(1, maximum + 1):
		result.append(str(digit))
	result.append("+")
	result.append("=")
	if level >= 24:
		result.append("-")
	return result


static func equation_valid(tokens: Array[String]) -> bool:
	if tokens.size() != 5:
		return false
	if tokens[1] in ["+", "-"] and tokens[3] == "=":
		return _calculate(tokens[0], tokens[1], tokens[2]) == int(tokens[4])
	if tokens[1] == "=" and tokens[3] in ["+", "-"]:
		return int(tokens[0]) == _calculate(tokens[2], tokens[3], tokens[4])
	return false


static func _calculate(a: String, operation: String, b: String) -> int:
	return int(a) + int(b) if operation == "+" else int(a) - int(b)
