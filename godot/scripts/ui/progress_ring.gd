class_name ProgressRing
extends Control

var progress := 0.0
var accent := Color("58d6e8")
var track := Color(0.12, 0.16, 0.32, 0.92)
var center_fill := Color("17254d")
var caption := ""
var value_text := ""


func setup(amount: float, label: String, detail: String, color: Color) -> void:
	progress = clampf(amount, 0.0, 1.0)
	caption = label
	value_text = detail
	accent = color
	custom_minimum_size = Vector2(118, 148)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var side := minf(size.x, size.y - 40.0)
	var center := Vector2(size.x * 0.5, side * 0.5 + 2.0)
	var radius := side * 0.40
	draw_circle(center, radius + 8.0, Color(accent, 0.18))
	draw_arc(center, radius, 0.0, TAU, 48, track, 10.0, true)
	if progress > 0.001:
		var sweep := TAU * progress
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + sweep, 48, accent, 10.0, true)
	draw_circle(center, radius - 12.0, center_fill)
	var percent := "%d%%" % int(round(progress * 100.0))
	var font := ThemeDB.fallback_font
	var percent_size := 20
	var percent_width := font.get_string_size(percent, HORIZONTAL_ALIGNMENT_LEFT, -1, percent_size).x
	draw_string(font, center + Vector2(-percent_width * 0.5, 7), percent, HORIZONTAL_ALIGNMENT_LEFT, -1, percent_size, Color("fff3d6"))
	var caption_size := 14
	var caption_width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, caption_size).x
	draw_string(font, Vector2(size.x * 0.5 - caption_width * 0.5, size.y - 28.0), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, caption_size, accent)
	if not value_text.is_empty():
		var detail_size := 12
		var detail_width := font.get_string_size(value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, detail_size).x
		draw_string(font, Vector2(size.x * 0.5 - detail_width * 0.5, size.y - 10.0), value_text, HORIZONTAL_ALIGNMENT_LEFT, -1, detail_size, Color("c9d3ef"))
