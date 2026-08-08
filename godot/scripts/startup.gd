extends Control

const MAIN_SCENE := "res://scenes/main.tscn"
const VIDEO_START_TIMEOUT_SECONDS := 1.5
const VIDEO_FINISH_GRACE_SECONDS := 0.35
const VIDEO_END_EARLY_SECONDS := 0.12
const VIDEO_STALL_SECONDS := 1.25

@onready var poster: TextureRect = $Poster
@onready var video: VideoStreamPlayer = $Video
@onready var playback_guard: Timer = $PlaybackGuard
@onready var loading_cover: Control = $LoadingCover
@onready var skip_button: Button = $SkipButton

var _is_finishing := false
var _playback_started := false
var _fallback_started := false
var _threaded_load_attempted := false
var _threaded_load_requested := false
var _last_stream_position := 0.0
var _last_progress_msec := 0


func _ready() -> void:
	video.finished.connect(_finish_intro)
	playback_guard.timeout.connect(_finish_intro)
	skip_button.button_down.connect(_finish_intro)
	playback_guard.start(VIDEO_START_TIMEOUT_SECONDS)
	# Autoplay starts Android's decoder as early as possible. This deferred call
	# only covers renderers that did not honour the scene setting.
	_ensure_video_playing.call_deferred()


func _ensure_video_playing() -> void:
	if not video.is_playing() and not _is_finishing:
		video.play()


func _process(_delta: float) -> void:
	if _is_finishing:
		_poll_main_scene_load()
		return
	# Keep the exact boot frame visible until the decoder has advanced. This
	# prevents a black flash between Godot's static splash and video frame one.
	var position := video.stream_position
	var length := video.get_stream_length()
	if not _playback_started and video.is_playing() and position > 0.0:
		_playback_started = true
		_last_stream_position = position
		_last_progress_msec = Time.get_ticks_msec()
		poster.hide()
		# Do not stream the main scene while the Theora decoder is active. The
		# scene contains several GLBs and texture-heavy screens; loading it in
		# parallel starves lower-end Android devices and makes the intro stutter.
		# The loading cover handles the short scene load after the visual ends.
		# Once decoding starts, replace the startup timeout with a playback
		# failsafe based on the real stream length.
		playback_guard.start(maxf(length * 2.0 + VIDEO_FINISH_GRACE_SECONDS, 0.5))
	if _playback_started:
		if position > _last_stream_position + 0.01:
			_last_stream_position = position
			_last_progress_msec = Time.get_ticks_msec()
		elif Time.get_ticks_msec() - _last_progress_msec >= int(VIDEO_STALL_SECONDS * 1000.0):
			_finish_intro()
			return
	if _is_playback_complete(position, length, video.is_playing(), _playback_started):
		_finish_intro()


func _is_playback_complete(
	position: float,
	length: float,
	is_playing: bool,
	has_started: bool
) -> bool:
	if not has_started:
		return false
	if not is_playing:
		return true
	return length > 0.0 and position >= maxf(0.0, length - VIDEO_END_EARLY_SECONDS)


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
	video.hide()
	poster.hide()
	loading_cover.show()
	skip_button.disabled = true
	skip_button.hide()
	set_process_input(false)
	_begin_main_scene_load()
	_poll_main_scene_load()


func _begin_main_scene_load() -> void:
	if _threaded_load_attempted or "--startup-test" in OS.get_cmdline_user_args():
		return
	_threaded_load_attempted = true
	_threaded_load_requested = ResourceLoader.load_threaded_request(MAIN_SCENE, "PackedScene", true) == OK


func _poll_main_scene_load() -> void:
	if not _threaded_load_requested:
		_start_fallback_transition()
		return
	var progress: Array = []
	var status := ResourceLoader.load_threaded_get_status(MAIN_SCENE, progress)
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed := ResourceLoader.load_threaded_get(MAIN_SCENE) as PackedScene
		if packed != null:
			set_process(false)
			get_tree().change_scene_to_packed(packed)
			return
	if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_start_fallback_transition()


func _start_fallback_transition() -> void:
	if _fallback_started:
		return
	_fallback_started = true
	_fallback_transition.call_deferred()


func _fallback_transition() -> void:
	await get_tree().process_frame
	set_process(false)
	get_tree().change_scene_to_file(MAIN_SCENE)
