extends Node

## Bottom banner via Poing AdMob (Android). Config: res://config/admob.json (see admob.example.json).
## Games render into a persistent content viewport that sits above a separate ad slot.

const CONFIG_PATH := "res://config/admob.json"
const EXAMPLE_PATH := "res://config/admob.example.json"
var _config: Dictionary = {}
var _ad_view: AdView
var _sdk_initialized := false
var _sdk_initializing := false
var _banner_logical_height := 60.0
var _banner_requested := false
var _reservation_active := false
var _app_layout: VBoxContainer
var _game_render_area: SubViewportContainer
var _app_content_viewport: SubViewport
var _ad_bar_area: Control
var _hosted_scene: Node
var _layout_sync_queued := false


func _ready() -> void:
	_reload_config()
	_connect_scene_tracking()
	call_deferred("_ensure_app_layout")
	call_deferred("_host_current_scene")
	if _platform_supports_ads() and ads_enabled():
		_initialize_mobile_ads()


func _exit_tree() -> void:
	detach()


func _reload_config() -> void:
	if FileAccess.file_exists(CONFIG_PATH):
		_config = _parse_json_file(CONFIG_PATH)
	elif FileAccess.file_exists(EXAMPLE_PATH):
		_config = _parse_json_file(EXAMPLE_PATH)
	else:
		_config = {}
	_banner_logical_height = float(_config.get("banner_height_dp", 60.0))


func _parse_json_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func config() -> Dictionary:
	return _config


func ads_enabled() -> bool:
	return bool(_config.get("ads_enabled", false))


func banner_height() -> float:
	if not _should_show_ads():
		return 0.0
	# The native anchored banner owns Android's navigation/safe-area placement.
	# Reserving that inset here as well leaves an extra blank strip above it.
	return _banner_logical_height


func should_show_for_player_logged_in(player_name: String) -> bool:
	if player_name.strip_edges().is_empty():
		return bool(_config.get("show_on_login", false))
	return true


## Prefer this from any scene. `host` is optional (kept for call-site compatibility).
func attach_to(_host: Control = null, player_name: String = "") -> void:
	sync_for_player(player_name)


func sync_for_player(player_name: String = "") -> void:
	if not should_show_for_player_logged_in(player_name) or not _should_show_ads():
		detach()
		return

	_set_reservation_active(true)
	if _banner_requested and _ad_view != null:
		_ad_view.show()
		return
	if _sdk_initialized:
		_show_banner()
	else:
		_initialize_mobile_ads()


func detach() -> void:
	_banner_requested = false
	_destroy_banner()
	_set_reservation_active(false)


func _should_show_ads() -> bool:
	return ads_enabled() and _platform_supports_ads()


func _platform_supports_ads() -> bool:
	var os_name := OS.get_name()
	return os_name == "Android" or os_name == "iOS"


func _banner_unit_id() -> String:
	return str(_config.get("android_banner_unit_id", "")).strip_edges()


func _initialize_mobile_ads() -> void:
	if _sdk_initialized:
		_show_banner_if_attached()
		return
	if _sdk_initializing:
		return
	_sdk_initializing = true

	if not Engine.has_singleton("PoingGodotAdMob"):
		# Native plugin missing from APK/AAB (common when android/bin AARs were not exported).
		push_warning(
			"AdBarService: PoingGodotAdMob singleton missing — AdMob Android binaries were not packaged"
		)

	var request_config := RequestConfiguration.new()
	if bool(_config.get("child_directed", true)):
		request_config.tag_for_child_directed_treatment = (
			RequestConfiguration.TagForChildDirectedTreatment.TRUE
		)
	if bool(_config.get("tag_for_under_age_of_consent", true)):
		request_config.tag_for_under_age_of_consent = (
			RequestConfiguration.TagForUnderAgeOfConsent.TRUE
		)
	var rating := str(_config.get("max_ad_content_rating", "G"))
	match rating:
		"PG":
			request_config.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_PG
		"T":
			request_config.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_T
		"MA":
			request_config.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_MA
		_:
			request_config.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_G

	MobileAds.set_request_configuration(request_config)

	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_sdk_initializing = false
		_sdk_initialized = true
		print("AdBarService: MobileAds initialized")
		_show_banner_if_attached()

	MobileAds.initialize(listener)


func _show_banner() -> void:
	if _ad_view != null:
		_set_reservation_active(true)
		_ad_view.show()
		return
	var unit_id := _banner_unit_id()
	if unit_id.is_empty():
		push_warning("AdBarService: android_banner_unit_id is missing in admob config")
		detach()
		return

	if not Engine.has_singleton("PoingGodotAdMobAdView"):
		detach()
		push_warning(
			"AdBarService: PoingGodotAdMobAdView missing — cannot show banner on this build"
		)
		return

	_destroy_banner()
	_banner_requested = true
	_set_reservation_active(true)

	var ad_size := AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	_ad_view = AdView.new(unit_id, ad_size, AdPosition.BOTTOM)

	var ad_listener := AdListener.new()
	ad_listener.on_ad_loaded = _on_banner_loaded
	ad_listener.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		push_warning("AdBarService: banner failed: %s" % error.message)
		detach()

	_ad_view.ad_listener = ad_listener
	print("AdBarService: loading banner unit %s" % unit_id)
	_ad_view.load_ad(AdRequest.new())


func _on_banner_loaded() -> void:
	if _ad_view == null:
		return
	# Loading creates the native view, but visibility is plugin/platform state.
	# Explicitly show it so a prior hidden or background-created banner cannot
	# remain invisible on Android.
	_ad_view.show()
	var px := float(_ad_view.get_height_in_pixels())
	if px > 0.0:
		_banner_logical_height = _pixels_to_viewport_y(px)
	_update_app_layout()
	print("AdBarService: banner loaded (height_px=%.0f)" % px)


func _show_banner_if_attached() -> void:
	if (
		should_show_for_player_logged_in(AppState.player_name())
		and _should_show_ads()
	):
		_show_banner()


func _destroy_banner() -> void:
	if _ad_view != null:
		_ad_view.destroy()
	_ad_view = null


func _connect_scene_tracking() -> void:
	var tree := get_tree()
	if tree != null and not tree.scene_changed.is_connected(_on_scene_changed):
		tree.scene_changed.connect(_on_scene_changed)
	var viewport := get_viewport()
	if viewport != null and not viewport.size_changed.is_connected(_on_viewport_size_changed):
		viewport.size_changed.connect(_on_viewport_size_changed)


func _on_scene_changed() -> void:
	call_deferred("_host_current_scene")


func _on_viewport_size_changed() -> void:
	_update_app_layout()


func _set_reservation_active(value: bool) -> void:
	_reservation_active = value
	_update_app_layout()


func _reservation_height() -> float:
	# The sibling slot reserves only the measured adaptive-banner height.  Native
	# AdMob handles any device bottom inset inside its own placement.
	return _banner_logical_height if _reservation_active else 0.0


func _ensure_app_layout() -> void:
	if is_instance_valid(_app_layout) and not _app_layout.is_queued_for_deletion():
		return
	_app_layout = null
	_game_render_area = null
	_app_content_viewport = null
	_ad_bar_area = null
	_hosted_scene = null
	var tree := get_tree()
	if tree == null or tree.root == null:
		return
	_app_layout = VBoxContainer.new()
	_app_layout.name = "AppViewportLayout"
	_app_layout.add_theme_constant_override("separation", 0)
	tree.root.add_child(_app_layout)
	# Anchors only resolve against an owning viewport after this node is parented.
	_app_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_game_render_area = SubViewportContainer.new()
	_game_render_area.name = "GameRenderArea"
	_game_render_area.stretch = true
	_game_render_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_game_render_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_game_render_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_app_layout.add_child(_game_render_area)
	_app_content_viewport = SubViewport.new()
	_app_content_viewport.name = "AppContentViewport"
	_app_content_viewport.transparent_bg = false
	_app_content_viewport.handle_input_locally = false
	_game_render_area.add_child(_app_content_viewport)
	_ad_bar_area = Control.new()
	_ad_bar_area.name = "AdBarArea"
	_ad_bar_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Keep this as a full-width sibling of GameRenderArea.  It is intentionally
	# not part of the content SubViewport, so app UI cannot render behind AdMob.
	_ad_bar_area.mouse_filter = Control.MOUSE_FILTER_STOP
	_app_layout.add_child(_ad_bar_area)
	_app_layout.minimum_size_changed.connect(_schedule_layout_sync)
	_app_layout.resized.connect(_schedule_layout_sync)
	_game_render_area.resized.connect(_schedule_layout_sync)
	_update_app_layout()


func _update_app_layout() -> void:
	_ensure_app_layout()
	if not is_instance_valid(_ad_bar_area):
		return
	_ad_bar_area.custom_minimum_size.y = _reservation_height()
	# Keep this transparent layout child visible so VBoxContainer immediately
	# reallocates it to zero height when inactive instead of retaining its old rect.
	_ad_bar_area.visible = true
	_schedule_layout_sync()


func _schedule_layout_sync() -> void:
	if _layout_sync_queued:
		return
	_layout_sync_queued = true
	call_deferred("_enforce_app_layout_bounds")


func _enforce_app_layout_bounds() -> void:
	_layout_sync_queued = false
	if not is_instance_valid(_app_layout) or not is_instance_valid(_game_render_area):
		return
	var tree := get_tree()
	if tree == null or tree.root == null:
		return
	var root_size := tree.root.get_visible_rect().size
	if root_size.x < 1.0 or root_size.y < 1.0:
		return
	_app_layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_app_layout.offset_left = 0.0
	_app_layout.offset_top = 0.0
	_app_layout.offset_right = 0.0
	_app_layout.offset_bottom = 0.0
	_app_layout.size = root_size
	_game_render_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_game_render_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_app_layout.queue_sort()


func _host_current_scene() -> void:
	_ensure_app_layout()
	if not is_instance_valid(_app_content_viewport):
		return
	var tree := get_tree()
	var scene := tree.current_scene if tree != null else null
	if not is_instance_valid(scene) or scene == _app_layout:
		return
	if scene.get_parent() == _app_content_viewport:
		_hosted_scene = scene
		return
	scene.reparent(_app_content_viewport)
	_hosted_scene = scene
	# SceneTree only accepts a direct root child as current_scene. The persistent
	# wrapper keeps that contract while content_scene() exposes the actual route.
	tree.current_scene = _app_layout
	if scene is Control:
		(scene as Control).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func content_scene() -> Node:
	return _hosted_scene if is_instance_valid(_hosted_scene) else null


func _pixels_to_viewport_y(pixels: float) -> float:
	var window_h := float(DisplayServer.window_get_size().y)
	if window_h <= 0.0:
		return pixels
	var viewport_h := float(get_viewport().get_visible_rect().size.y)
	return pixels * (viewport_h / window_h)
