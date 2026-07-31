extends Node

## Lightweight offline SFX. Generated tones avoid shipping external audio licenses.

var _enabled := true


func _ready() -> void:
	sync_settings()


func sync_settings() -> void:
	_enabled = bool(SaveManager.get_setting("sound_enabled", true))


func play_ui() -> void:
	_play_tone(520.0, 0.045, -20.0)


func play_success() -> void:
	_play_tone(740.0, 0.09, -14.0)
	await get_tree().create_timer(0.07).timeout
	_play_tone(980.0, 0.13, -14.0)


func play_fail() -> void:
	_play_tone(210.0, 0.16, -15.0)


func play_place() -> void:
	_play_tone(620.0, 0.07, -18.0)


func _play_tone(frequency: float, duration: float, volume_db: float) -> void:
	if not _enabled:
		return
	var sample_rate := 22050
	var sample_count := int(duration * sample_rate)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for i in sample_count:
		var envelope := 1.0 - float(i) / float(sample_count)
		var wave := sin(TAU * frequency * float(i) / float(sample_rate))
		var sample := int(clampf(wave * envelope, -1.0, 1.0) * 16000.0)
		bytes.encode_s16(i * 2, sample)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
