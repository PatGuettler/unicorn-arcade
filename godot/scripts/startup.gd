extends Control

const MAIN_SCENE := "res://scenes/main.tscn"
const VIDEO_START_TIMEOUT_SECONDS := 7.0

@onready var poster: TextureRect = $Poster
@onready var video: VideoStreamPlayer = $Video
@onready var playback_guard: Timer = $PlaybackGuard

var _is_finishing := false


func _ready() -> void:
	video.finished.connect(_finish_intro)
	playback_guard.timeout.connect(_finish_intro)
	playback_guard.start(VIDEO_START_TIMEOUT_SECONDS)
	video.play()


func _process(_delta: float) -> void:
	# Keep the exact boot frame visible until the decoder has advanced. This
	# prevents a black flash between Godot's static splash and video frame one.
	if poster.visible and video.is_playing() and video.stream_position > 0.0:
		poster.hide()


func _input(event: InputEvent) -> void:
	if _is_skip_event(event):
		get_viewport().set_input_as_handled()
		_finish_intro()


func _is_skip_event(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return event.pressed
	if event is InputEventMouseButton:
		return event.pressed
	if event is InputEventKey:
		return event.pressed and not event.echo
	if event is InputEventJoypadButton:
		return event.pressed
	return false


func _finish_intro() -> void:
	if _is_finishing:
		return
	_is_finishing = true
	playback_guard.stop()
	video.stop()
	set_process(false)
	set_process_input(false)
	get_tree().change_scene_to_file(MAIN_SCENE)
