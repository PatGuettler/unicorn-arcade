extends RefCounted
class_name LevelUtilsJump


static func generate_level_data(lvl: int) -> Array:
	var len_arr := 5 + lvl * 5
	var arr: Array = []
	arr.resize(len_arr)
	for i in len_arr:
		arr[i] = null
	var curr := 0
	var last := 0
	var max_j := 3
	if lvl > 5:
		max_j = 6
	elif lvl > 2:
		max_j = 4
	var allow_negative := lvl >= 15
	var big_negative := lvl >= 25
	var min_neg := 1
	var max_neg := 2 if not big_negative else 5

	while curr < len_arr:
		var do_trick := allow_negative and randf() < 0.2 and len_arr - curr > 6
		if do_trick:
			var b := randi() % (max_neg - min_neg + 1) + min_neg
			var net_progress := randi() % 3 + 1
			var f := b + net_progress
			if curr + f < len_arr and arr[curr + f] == null:
				arr[curr] = f
				arr[curr + f] = -b
				curr += f - b
				last = -999
				continue
		var j := 1
		var attempts := 0
		while attempts < 10:
			j = randi() % max_j + 1
			if not (j == last and len_arr - curr > j):
				if curr + j >= len_arr or arr[curr + j] == null:
					break
			attempts += 1
		if curr + j > len_arr:
			j = len_arr - curr
		arr[curr] = j
		curr += j
		last = j

	for i in len_arr:
		if arr[i] == null:
			if allow_negative and randf() < 0.3:
				arr[i] = -(randi() % (max_neg - min_neg + 1) + min_neg)
			else:
				arr[i] = randi() % max_j + 1
	return arr
