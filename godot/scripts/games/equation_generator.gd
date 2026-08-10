class_name EquationGenerator
extends RefCounted


static func math_swipe_core(for_level: int, rng: RandomNumberGenerator) -> Dictionary:
	var operation := "+"
	var left := 0
	var right := 0
	if for_level <= 3:
		left = rng.randi_range(1, 8)
		right = rng.randi_range(1, 8)
	elif for_level <= 6:
		operation = "-"
		var answer := rng.randi_range(1, 8)
		right = rng.randi_range(1, answer)
		left = answer + right
	elif for_level <= 10:
		operation = "+" if rng.randf() > 0.5 else "-"
		if operation == "+":
			left = rng.randi_range(5, 19)
			right = rng.randi_range(5, 19)
		else:
			var answer := rng.randi_range(5, 19)
			right = rng.randi_range(1, answer)
			left = answer + right
	else:
		var choice := rng.randf()
		if choice < 0.4:
			operation = "×"
			left = rng.randi_range(2, 11)
			right = rng.randi_range(2, 11)
		elif choice < 0.7:
			left = rng.randi_range(10, 29)
			right = rng.randi_range(10, 29)
		else:
			operation = "-"
			var answer := rng.randi_range(10, 29)
			right = rng.randi_range(1, answer)
			left = answer + right
	return _core(left, right, operation)


static func comet_math_rescue_core(for_level: int, rng: RandomNumberGenerator) -> Dictionary:
	var operation := "+"
	if for_level >= 10:
		operation = ["+", "-", "x", "/"][rng.randi_range(0, 3)]
	elif for_level >= 7:
		operation = "x"
	elif for_level >= 4:
		operation = "-"
	var left := 0
	var right := 0
	match operation:
		"+":
			left = rng.randi_range(1, 4 + mini(8, for_level))
			right = rng.randi_range(1, 4 + mini(8, for_level))
		"-":
			right = rng.randi_range(1, 3 + mini(7, for_level))
			left = right + rng.randi_range(0, 4 + mini(8, for_level))
		"x":
			left = rng.randi_range(2, 3 + mini(6, for_level / 2))
			right = rng.randi_range(2, 3 + mini(5, for_level / 2))
		"/":
			right = rng.randi_range(2, 3 + mini(6, for_level / 2))
			var answer := rng.randi_range(2, 3 + mini(7, for_level / 2))
			left = right * answer
	return _core(left, right, operation)


static func _core(left: int, right: int, operation: String) -> Dictionary:
	var answer := 0
	match operation:
		"+": answer = left + right
		"-": answer = left - right
		"x", "×": answer = left * right
		"/":
			if right == 0 or left % right != 0:
				return {}
			answer = left / right
		_: return {}
	return {"left": left, "right": right, "operation": operation, "answer": answer}
