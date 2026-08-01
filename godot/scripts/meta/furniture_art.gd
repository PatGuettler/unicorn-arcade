class_name FurnitureArt
extends Control

var item_id := ""
var category := "cozy"
var accent := Color("7ed7e8")
var dark := Color("26335d")
var light := Color("f7e9c8")


func setup(definition: Dictionary) -> void:
	item_id = str(definition.get("id", definition.get("item_id", "decor")))
	category = str(definition.get("category", "cozy"))
	var hue := float(abs(item_id.hash()) % 360) / 360.0
	accent = Color.from_hsv(hue, 0.48, 0.9)
	dark = accent.darkened(0.55)
	light = accent.lightened(0.42)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if size.x < 2.0 or size.y < 2.0:
		return
	var scale_factor := minf(size.x, size.y) / 100.0
	var origin := (size - Vector2(100, 100) * scale_factor) * 0.5
	draw_set_transform(origin, 0.0, Vector2.ONE * scale_factor)
	_draw_shadow()
	if item_id == "lamp":
		_draw_lava_lamp()
	elif item_id == "rug" or category == "rugs":
		_draw_rug()
	elif item_id == "plant" or category == "nature":
		_draw_plant()
	elif category == "beds":
		_draw_bed()
	elif category == "tables":
		_draw_table()
	elif category == "lighting":
		_draw_light()
	elif category == "pets":
		_draw_pet()
	elif category == "toys":
		_draw_toy()
	elif category == "electronics":
		_draw_electronics()
	elif category == "seasonal":
		_draw_seasonal()
	elif category == "kitchen":
		_draw_kitchen()
	elif category == "wall":
		_draw_wall_art()
	elif category == "luxury":
		_draw_luxury()
	elif category == "unicorn":
		_draw_unicorn_decor()
	elif category == "companions":
		_draw_companion()
	else:
		_draw_cozy()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_shadow() -> void:
	var points: Array = []
	for index in 24:
		var angle := TAU * float(index) / 24.0
		points.append(Vector2(50.0 + cos(angle) * 31.0, 83.0 + sin(angle) * 8.0))
	_poly(points, Color("4208172f"))


func _draw_lava_lamp() -> void:
	_poly([Vector2(35, 75), Vector2(65, 75), Vector2(60, 83), Vector2(40, 83)], dark)
	_poly([Vector2(39, 70), Vector2(61, 70), Vector2(66, 76), Vector2(34, 76)], accent.darkened(0.28))
	_poly([Vector2(42, 20), Vector2(58, 20), Vector2(64, 69), Vector2(36, 69)], Color("c579e9f6"))
	_poly([Vector2(42, 20), Vector2(58, 20), Vector2(55, 13), Vector2(45, 13)], dark)
	draw_circle(Vector2(47, 51), 7, Color("ffe66d"))
	draw_circle(Vector2(55, 35), 5, PINKISH)
	draw_circle(Vector2(51, 62), 4, accent.lightened(0.2))
	_stroke([Vector2(42, 20), Vector2(58, 20), Vector2(64, 69), Vector2(36, 69), Vector2(42, 20)])


const PINKISH := Color("ff77aa")


func _draw_rug() -> void:
	var points := [Vector2(15, 63), Vector2(30, 44), Vector2(70, 44), Vector2(85, 63), Vector2(70, 80), Vector2(30, 80)]
	_poly(points, accent)
	_stroke(points + [points[0]])
	_poly([Vector2(25, 63), Vector2(35, 51), Vector2(65, 51), Vector2(75, 63), Vector2(65, 74), Vector2(35, 74)], light)
	for x in [25, 33, 67, 75]:
		draw_line(Vector2(x, 77), Vector2(x - 3, 84), dark, 2.4, true)


func _draw_plant() -> void:
	_poly([Vector2(34, 57), Vector2(66, 57), Vector2(61, 82), Vector2(39, 82)], accent.darkened(0.18))
	draw_rect(Rect2(31, 53, 38, 8), light, true)
	_stroke([Vector2(34, 57), Vector2(66, 57), Vector2(61, 82), Vector2(39, 82), Vector2(34, 57)])
	for leaf in [[Vector2(49, 55), Vector2(30, 24), Vector2(47, 35)], [Vector2(50, 55), Vector2(69, 18), Vector2(57, 42)], [Vector2(50, 55), Vector2(45, 10), Vector2(38, 35)], [Vector2(52, 55), Vector2(80, 37), Vector2(59, 49)], [Vector2(47, 56), Vector2(20, 40), Vector2(40, 50)]]:
		_poly(leaf, Color("57b979"))
		_stroke(leaf + [leaf[0]], Color("24563c"), 2.0)


func _draw_bed() -> void:
	if "coffin" in item_id:
		_poly([Vector2(35, 15), Vector2(65, 15), Vector2(76, 35), Vector2(67, 84), Vector2(33, 84), Vector2(24, 35)], Color("5c244f"))
		_stroke([Vector2(35, 15), Vector2(65, 15), Vector2(76, 35), Vector2(67, 84), Vector2(33, 84), Vector2(24, 35), Vector2(35, 15)], Color("e2a7d3"), 3)
		return
	if "bunk" in item_id:
		for y in [27, 59]:
			draw_rect(Rect2(20, y, 59, 20), accent, true)
			draw_rect(Rect2(25, y + 3, 20, 9), light, true)
		for x in [18, 78]:
			draw_rect(Rect2(x, 18, 5, 68), dark, true)
		return
	var frame := Color("805c43") if "cloud" not in item_id else Color("dfefff")
	draw_rect(Rect2(17, 49, 67, 29), frame, true)
	draw_rect(Rect2(23, 42, 58, 27), accent.lightened(0.16), true)
	draw_rect(Rect2(25, 44, 23, 11), light, true)
	_poly([Vector2(48, 55), Vector2(81, 49), Vector2(81, 68), Vector2(48, 69)], accent)
	for x in [19, 78]:
		draw_rect(Rect2(x, 75, 6, 11), dark, true)
	_stroke([Vector2(17, 49), Vector2(84, 49), Vector2(84, 78), Vector2(17, 78), Vector2(17, 49)])


func _draw_table() -> void:
	var top_color := Color("a7744d") if "pool" not in item_id else Color("3e9f77")
	_poly([Vector2(18, 42), Vector2(74, 34), Vector2(87, 47), Vector2(29, 57)], top_color)
	_stroke([Vector2(18, 42), Vector2(74, 34), Vector2(87, 47), Vector2(29, 57), Vector2(18, 42)])
	for leg in [[Vector2(29, 55), Vector2(37, 54), Vector2(34, 84), Vector2(28, 84)], [Vector2(76, 49), Vector2(83, 47), Vector2(80, 77), Vector2(74, 79)]]:
		_poly(leg, dark)
	if "desk" in item_id:
		draw_rect(Rect2(41, 58, 29, 18), accent.darkened(0.2), true)


func _draw_light() -> void:
	if "chandelier" in item_id or "disco" in item_id:
		draw_line(Vector2(50, 9), Vector2(50, 31), dark, 4, true)
		draw_circle(Vector2(50, 48), 19, light)
		for angle in range(0, 360, 45):
			var direction := Vector2.RIGHT.rotated(deg_to_rad(angle))
			draw_line(Vector2(50, 48) + direction * 20, Vector2(50, 48) + direction * 29, accent, 3, true)
		return
	if "candle" in item_id:
		draw_rect(Rect2(42, 40, 17, 40), light, true)
		_poly([Vector2(50, 37), Vector2(43, 27), Vector2(51, 14), Vector2(58, 28)], Color("ffd166"))
		return
	if "flashlight" in item_id:
		_poly([Vector2(25, 47), Vector2(57, 39), Vector2(64, 56), Vector2(31, 65)], dark)
		_poly([Vector2(58, 38), Vector2(82, 32), Vector2(87, 56), Vector2(64, 58)], accent)
		return
	# Floor lamp / lantern silhouette.
	draw_rect(Rect2(47, 43, 6, 37), dark, true)
	_poly([Vector2(31, 45), Vector2(40, 22), Vector2(61, 22), Vector2(70, 45)], accent)
	draw_rect(Rect2(35, 78, 31, 7), dark, true)
	_stroke([Vector2(31, 45), Vector2(40, 22), Vector2(61, 22), Vector2(70, 45), Vector2(31, 45)])


func _draw_pet() -> void:
	if "fish" in item_id or "turtle" in item_id:
		draw_circle(Vector2(48, 54), 22, Color("73cce3"))
		_poly([Vector2(29, 54), Vector2(14, 42), Vector2(14, 66)], accent)
		draw_circle(Vector2(56, 48), 3, dark)
		return
	var body_color := accent.lightened(0.12)
	draw_circle(Vector2(49, 55), 22, body_color)
	draw_circle(Vector2(48, 34), 18, body_color)
	if "cat" in item_id:
		_poly([Vector2(34, 24), Vector2(28, 9), Vector2(43, 19)], body_color)
		_poly([Vector2(54, 19), Vector2(69, 9), Vector2(63, 27)], body_color)
	else:
		draw_circle(Vector2(29, 36), 10, body_color.darkened(0.08))
		draw_circle(Vector2(68, 36), 10, body_color.darkened(0.08))
	for eye_x in [42, 55]:
		draw_circle(Vector2(eye_x, 33), 2.6, dark)
	draw_circle(Vector2(49, 40), 3, PINKISH)
	for x in [38, 57]:
		draw_circle(Vector2(x, 77), 7, body_color)


func _draw_toy() -> void:
	if "robot" in item_id:
		draw_rect(Rect2(31, 27, 39, 31), accent, true)
		draw_rect(Rect2(26, 58, 49, 26), dark, true)
		for x in [42, 58]: draw_circle(Vector2(x, 41), 4, light)
		draw_line(Vector2(50, 27), Vector2(50, 15), dark, 4, true)
		draw_circle(Vector2(50, 12), 4, PINKISH)
		return
	if "ball" in item_id:
		draw_circle(Vector2(50, 55), 29, light)
		draw_circle(Vector2(50, 55), 9, dark)
		return
	if "blocks" in item_id:
		for block in [[22, 53, 25, 25], [48, 53, 27, 25], [35, 27, 27, 25]]:
			draw_rect(Rect2(block[0], block[1], block[2], block[3]), Color.from_hsv(float(block[0]) / 100.0, 0.55, 0.95), true)
		return
	# Plush/doll silhouette.
	draw_circle(Vector2(35, 32), 11, accent)
	draw_circle(Vector2(65, 32), 11, accent)
	draw_circle(Vector2(50, 41), 20, accent.lightened(0.1))
	draw_circle(Vector2(50, 67), 23, accent)
	for x in [43, 57]: draw_circle(Vector2(x, 39), 2.5, dark)


func _draw_electronics() -> void:
	if "phone" in item_id or "camera" in item_id or "radio" in item_id:
		draw_rect(Rect2(23, 36, 57, 39), accent, true)
		draw_circle(Vector2(52, 55), 13, dark)
		draw_circle(Vector2(52, 55), 7, Color("86e1f0"))
		draw_rect(Rect2(29, 28, 20, 9), dark, true)
		return
	if "console" in item_id:
		_poly([Vector2(22, 53), Vector2(37, 37), Vector2(63, 37), Vector2(79, 53), Vector2(71, 72), Vector2(29, 72)], accent)
		draw_circle(Vector2(65, 54), 4, PINKISH)
		draw_line(Vector2(37, 48), Vector2(37, 61), dark, 4, true)
		draw_line(Vector2(31, 54), Vector2(43, 54), dark, 4, true)
		return
	# TV, PC, or arcade cabinet.
	draw_rect(Rect2(20, 22, 60, 49), dark, true)
	draw_rect(Rect2(26, 28, 48, 34), Color("70d7e7"), true)
	draw_line(Vector2(50, 71), Vector2(50, 82), dark, 5, true)
	draw_rect(Rect2(34, 80, 32, 6), dark, true)


func _draw_seasonal() -> void:
	if "pump" in item_id:
		for x in [38, 50, 62]: draw_circle(Vector2(x, 57), 18, Color("f28c28"))
		draw_rect(Rect2(47, 27, 7, 13), Color("4f7d42"), true)
		return
	if "tree" in item_id:
		for y in [27, 43, 60]:
			_poly([Vector2(50, y - 20), Vector2(22, y + 24), Vector2(78, y + 24)], Color("3f9b66").darkened(float(y) / 300.0))
		draw_rect(Rect2(46, 77, 8, 11), dark, true)
		return
	if "gift" in item_id:
		draw_rect(Rect2(22, 38, 57, 43), accent, true)
		draw_rect(Rect2(46, 36, 9, 47), PINKISH, true)
		draw_rect(Rect2(19, 34, 64, 11), light, true)
		return
	# Snow/ghost/ornament character shape.
	draw_circle(Vector2(50, 39), 20, light)
	draw_circle(Vector2(50, 69), 25, accent.lightened(0.25))
	for x in [43, 57]: draw_circle(Vector2(x, 37), 3, dark)


func _draw_kitchen() -> void:
	if "tea" in item_id or "espresso" in item_id:
		draw_circle(Vector2(48, 57), 22, accent)
		draw_arc(Vector2(69, 57), 12, -1.3, 1.3, 18, dark, 5, true)
		_poly([Vector2(29, 45), Vector2(44, 25), Vector2(63, 45)], light)
		return
	if "oven" in item_id:
		draw_rect(Rect2(23, 26, 55, 58), Color("a24d3b"), true)
		draw_arc(Vector2(50, 71), 21, PI, TAU, 24, dark, 7, true)
		return
	# Counter / basket / appliance.
	draw_rect(Rect2(18, 45, 67, 36), accent, true)
	draw_rect(Rect2(14, 37, 75, 12), light, true)
	draw_rect(Rect2(28, 56, 20, 25), dark, true)
	draw_circle(Vector2(66, 63), 10, accent.lightened(0.3))


func _draw_wall_art() -> void:
	draw_rect(Rect2(20, 18, 60, 62), dark, true)
	draw_rect(Rect2(26, 24, 48, 50), light, true)
	_poly([Vector2(28, 65), Vector2(44, 44), Vector2(55, 57), Vector2(65, 37), Vector2(73, 67)], accent)
	draw_circle(Vector2(39, 35), 6, Color("ffd166"))


func _draw_luxury() -> void:
	if "trophy" in item_id or "crown" in item_id:
		_poly([Vector2(27, 25), Vector2(39, 43), Vector2(50, 23), Vector2(61, 43), Vector2(75, 25), Vector2(69, 58), Vector2(32, 58)], Color("ffd166"))
		draw_rect(Rect2(45, 57, 10, 20), dark, true)
		draw_rect(Rect2(32, 75, 36, 9), Color("ffd166"), true)
		return
	if "moon" in item_id:
		draw_circle(Vector2(48, 49), 30, Color("ffe7a3"))
		draw_circle(Vector2(61, 39), 28, Color("00000000"))
		return
	# Crystal / ornate object.
	_poly([Vector2(50, 10), Vector2(72, 40), Vector2(62, 78), Vector2(50, 89), Vector2(38, 78), Vector2(28, 40)], accent.lightened(0.22))
	_poly([Vector2(50, 10), Vector2(50, 89), Vector2(38, 78), Vector2(28, 40)], accent)
	_stroke([Vector2(50, 10), Vector2(72, 40), Vector2(62, 78), Vector2(50, 89), Vector2(38, 78), Vector2(28, 40), Vector2(50, 10)])


func _draw_unicorn_decor() -> void:
	if "rug" in item_id:
		_draw_rug()
		return
	if "lamp" in item_id:
		_draw_light()
		return
	if "shelf" in item_id:
		for y in [34, 55, 76]:
			draw_rect(Rect2(20, y, 60, 6), dark, true)
			for x in range(26, 76, 10): draw_rect(Rect2(x, y - 13, 7, 13), Color.from_hsv(float(x) / 85.0, 0.45, 0.95), true)
		return
	# Fountain / horn planter.
	draw_arc(Vector2(50, 58), 22, 0, TAU, 28, accent, 8, true)
	_poly([Vector2(50, 17), Vector2(60, 56), Vector2(42, 52)], light)
	draw_circle(Vector2(50, 70), 20, Color("65d6e8"))


func _draw_companion() -> void:
	# A compact painted side-view unicorn, used for the movable house companion.
	var coat := light
	var mane := PINKISH if "sparkle" in item_id else accent
	_poly([Vector2(25, 68), Vector2(20, 51), Vector2(31, 42), Vector2(59, 41), Vector2(70, 51), Vector2(64, 68)], coat)
	_poly([Vector2(58, 45), Vector2(61, 25), Vector2(72, 18), Vector2(81, 28), Vector2(73, 52)], coat)
	_poly([Vector2(72, 19), Vector2(70, 7), Vector2(78, 18)], Color("ffd166"))
	_poly([Vector2(63, 31), Vector2(54, 18), Vector2(68, 24)], mane)
	_poly([Vector2(30, 43), Vector2(18, 30), Vector2(22, 51)], mane)
	_poly([Vector2(24, 54), Vector2(9, 46), Vector2(19, 65)], mane.lightened(0.12))
	for x in [31, 54]:
		_poly([Vector2(x, 65), Vector2(x + 9, 65), Vector2(x + 7, 86), Vector2(x, 86)], coat.darkened(0.08))
		draw_rect(Rect2(x - 1, 82, 10, 6), dark, true)
	draw_circle(Vector2(74, 27), 2.4, dark)
	_stroke([Vector2(25, 68), Vector2(20, 51), Vector2(31, 42), Vector2(59, 41), Vector2(61, 25), Vector2(72, 18), Vector2(81, 28), Vector2(73, 52), Vector2(64, 68)], dark, 2.2)


func _draw_cozy() -> void:
	if "book" in item_id:
		for book in [[25, 60, 48, 11], [31, 48, 45, 11], [24, 36, 43, 11]]:
			draw_rect(Rect2(book[0], book[1], book[2], book[3]), Color.from_hsv(float(book[1]) / 100.0, 0.45, 0.9), true)
		return
	if "hammock" in item_id:
		draw_arc(Vector2(50, 35), 34, 0.2, PI - 0.2, 28, accent, 9, true)
		draw_line(Vector2(18, 36), Vector2(15, 82), dark, 5, true)
		draw_line(Vector2(82, 36), Vector2(85, 82), dark, 5, true)
		return
	# Armchair / general cozy furniture.
	draw_rect(Rect2(29, 42, 43, 38), accent, true)
	draw_rect(Rect2(22, 54, 16, 28), accent.darkened(0.12), true)
	draw_rect(Rect2(64, 54, 16, 28), accent.darkened(0.12), true)
	draw_rect(Rect2(36, 52, 29, 22), light, true)
	for x in [29, 66]: draw_rect(Rect2(x, 78, 7, 10), dark, true)


func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)


func _stroke(points: Array, color: Color = Color("5b315f"), width: float = 2.5) -> void:
	draw_polyline(PackedVector2Array(points), color, width, true)
