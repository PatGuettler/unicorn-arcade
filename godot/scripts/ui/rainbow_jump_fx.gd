class_name RainbowJumpFX
extends Control

const COLORS := [Color("ff5f8f"), Color("ffab4c"), Color("ffe263"), Color("64e39d"), Color("62caff"), Color("b884ff")]

var trail: Array[Vector2] = []
var burst_center := Vector2.ZERO
var burst_amount := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_flight_point(point: Vector2) -> void:
	trail.append(point)
	if trail.size() > 28:
		trail.pop_front()
	queue_redraw()


func clear_flight() -> void:
	trail.clear()
	queue_redraw()


func landing_burst(point: Vector2) -> void:
	burst_center = point
	burst_amount = 0.0
	var tween := create_tween()
	tween.tween_property(self, "burst_amount", 1.0, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.42)
	tween.tween_property(self, "burst_amount", 0.0, 0.38)
	tween.tween_callback(queue_redraw)


func _process(_delta: float) -> void:
	if burst_amount > 0.0:
		queue_redraw()


func _draw() -> void:
	if trail.size() >= 2:
		for color_index in COLORS.size():
			var points := PackedVector2Array()
			var perpendicular := Vector2(0, float(color_index - 2) * 2.8)
			for point in trail:
				points.append(point + perpendicular)
			draw_polyline(points, Color(COLORS[color_index], 0.86), 4.5, true)
	if burst_amount <= 0.0:
		return
	var radius := 13.0 + burst_amount * 31.0
	# A curled rainbow puff comes from the tail on every landing.
	for color_index in COLORS.size():
		var offset := Vector2(float(color_index - 2) * 2.8, 0)
		draw_arc(burst_center + offset, radius - color_index * 1.8, PI * 0.18, PI * 1.82, 36, Color(COLORS[color_index], 1.0 - burst_amount * 0.18), 5.0, true)
	for index in 8:
		var angle := TAU * float(index) / 8.0
		var point := burst_center + Vector2.RIGHT.rotated(angle) * (radius + 13.0)
		draw_circle(point, 2.0 + burst_amount * 2.0, COLORS[index % COLORS.size()])
