extends Node

const PROJECT_ROOT := "res://"
const EXCLUDED_DIRECTORIES := [".godot", "addons", "android", "build"]

var failures: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var script_paths: Array[String] = []
	_collect_scripts(PROJECT_ROOT, script_paths)
	script_paths.sort()
	for script_path in script_paths:
		# Use the normal cache so autoload dependencies retain their project-aware
		# singleton bindings, then verify instantiability without reloading scripts
		# that are already live as autoloads (or this runner itself). A non-null
		# ResourceLoader result alone can retain a script with compilation errors.
		var script := ResourceLoader.load(script_path, "GDScript") as GDScript
		if script == null:
			failures.append("%s (load failed)" % script_path)
			continue
		if not script.can_instantiate():
			failures.append("%s (script cannot instantiate after compilation)" % script_path)
	if failures.is_empty():
		print("GODOT_PARSE_SMOKE_OK: loaded %d app-owned GDScripts" % script_paths.size())
		get_tree().quit(0)
	else:
		for script_path in failures:
			push_error("Could not load or parse %s" % script_path)
		get_tree().quit(1)


func _collect_scripts(directory_path: String, script_paths: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		failures.append("Could not open %s" % directory_path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var entry_path := directory_path.path_join(entry)
		if directory.current_is_dir():
			if not entry.begins_with(".") and not EXCLUDED_DIRECTORIES.has(entry):
				_collect_scripts(entry_path, script_paths)
		elif entry.ends_with(".gd"):
			script_paths.append(entry_path)
		entry = directory.get_next()
	directory.list_dir_end()
