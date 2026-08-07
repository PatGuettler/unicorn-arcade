class_name DoorStateArt
extends Control

var unlocked := false
var accent := Color("ffd166")


func setup(is_unlocked: bool, door_color: Color) -> void:
	unlocked = is_unlocked
	accent = door_color
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	if not unlocked or size.x < 2.0:
		return
	var warm := Color("ffe49a")
	# Light leaking through the door seam and keyhole replaces UI labels.
	draw_colored_polygon(PackedVector2Array([
		Vector2(size.x * 0.46, size.y * 0.78),
		Vector2(size.x * 0.58, size.y * 0.78),
		Vector2(size.x * 0.88, size.y),
		Vector2(size.x * 0.15, size.y),
	]), Color(warm, 0.13))
	draw_line(Vector2(size.x * 0.52, size.y * 0.24), Vector2(size.x * 0.52, size.y * 0.82), Color(warm, 0.18), 14.0, true)
	draw_line(Vector2(size.x * 0.52, size.y * 0.24), Vector2(size.x * 0.52, size.y * 0.82), Color(warm, 0.86), 3.0, true)
	var keyhole := Vector2(size.x * 0.63, size.y * 0.58)
	draw_circle(keyhole, 12.0, Color(warm, 0.12))
	draw_circle(keyhole, 4.0, Color(warm, 0.95))
	for angle in range(0, 360, 45):
		var direction := Vector2.RIGHT.rotated(deg_to_rad(angle))
		draw_line(keyhole + direction * 6.0, keyhole + direction * 15.0, Color(warm, 0.52), 2.0, true)
	# A soft arched edge reads as the room's magic shining around a cracked door.
	draw_arc(Vector2(size.x * 0.5, size.y * 0.34), size.x * 0.38, PI, TAU, 24, Color(accent.lightened(0.35), 0.5), 4.0, true)
	draw_line(Vector2(size.x * 0.12, size.y * 0.34), Vector2(size.x * 0.12, size.y * 0.88), Color(accent.lightened(0.4), 0.34), 3.0, true)
