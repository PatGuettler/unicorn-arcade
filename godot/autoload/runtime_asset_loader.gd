extends Node

## A small coalescing loader for expensive runtime scenes.  Callers always get
## their callback deferred, including cache hits, which makes UI replacement
## safe while routes are being retired.
signal packed_scene_loaded(path: String, scene: PackedScene)
signal packed_scene_failed(path: String, error_code: Error)

var _cache: Dictionary = {}
var _waiters: Dictionary = {}
var _pending: Dictionary = {}


func _ready() -> void:
	set_process(false)


func load_packed_scene(path: String, callback: Callable = Callable()) -> PackedScene:
	if _cache.has(path):
		var cached := _cache[path] as PackedScene
		if callback.is_valid():
			callback.call_deferred(cached)
		return cached
	if callback.is_valid():
		var callbacks: Array = _waiters.get(path, [])
		callbacks.append(callback)
		_waiters[path] = callbacks
	if not ResourceLoader.exists(path):
		_finish(path, null, ERR_FILE_NOT_FOUND)
		return null
	if not _pending.has(path):
		var result := ResourceLoader.load_threaded_request(path, "PackedScene")
		if result == OK:
			_pending[path] = true
			set_process(true)
		else:
			_finish(path, null, result)
	return null


func cached_packed_scene(path: String) -> PackedScene:
	return _cache.get(path) as PackedScene


func cache_packed_scene(path: String, scene: PackedScene) -> void:
	if not path.is_empty() and scene != null:
		_cache[path] = scene


func is_cached(path: String) -> bool:
	return _cache.has(path)


func _process(_delta: float) -> void:
	for path_variant in _pending.keys():
		var path := str(path_variant)
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			_finish(path, ResourceLoader.load_threaded_get(path) as PackedScene, OK)
		elif status == ResourceLoader.THREAD_LOAD_FAILED:
			_finish(path, null, ERR_CANT_OPEN)
		elif status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_finish(path, null, ERR_INVALID_PARAMETER)


func _finish(path: String, scene: PackedScene, error_code: Error) -> void:
	_pending.erase(path)
	if scene != null:
		_cache[path] = scene
		packed_scene_loaded.emit(path, scene)
	else:
		packed_scene_failed.emit(path, error_code)
	var callbacks: Array = _waiters.get(path, [])
	_waiters.erase(path)
	for callback in callbacks:
		if callback is Callable and (callback as Callable).is_valid():
			(callback as Callable).call_deferred(scene)
	if _pending.is_empty():
		set_process(false)
