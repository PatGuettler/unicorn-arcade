extends Node

## Bottom banner via Poing AdMob (Android). Config: res://config/admob.json (see admob.example.json).

const CONFIG_PATH := "res://config/admob.json"
const EXAMPLE_PATH := "res://config/admob.example.json"
const DISCLOSURE_HEIGHT := 14.0

var _config: Dictionary = {}
var _ad_view: AdView
var _disclosure: Label
var _host: Control
var _sdk_initialized := false
var _banner_logical_height := 60.0


func _ready() -> void:
	_reload_config()
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
	return _banner_logical_height + DISCLOSURE_HEIGHT + _bottom_inset()


func should_show_for_player_logged_in(player_name: String) -> bool:
	if player_name.strip_edges().is_empty():
		return bool(_config.get("show_on_login", false))
	return true


func attach_to(host: Control, player_name: String = "") -> void:
	_host = host
	if host == null or not should_show_for_player_logged_in(player_name):
		detach()
		return
	if not _should_show_ads():
		detach()
		return
	_ensure_disclosure(host)
	if _sdk_initialized:
		_show_banner()
	else:
		_initialize_mobile_ads(_show_banner)


func detach() -> void:
	_destroy_banner()
	if is_instance_valid(_disclosure):
		_disclosure.queue_free()
	_disclosure = null
	_host = null


func _should_show_ads() -> bool:
	return ads_enabled() and _platform_supports_ads()


func _platform_supports_ads() -> bool:
	var os_name := OS.get_name()
	return os_name == "Android" or os_name == "iOS"


func _banner_unit_id() -> String:
	return str(_config.get("android_banner_unit_id", "")).strip_edges()


func _initialize_mobile_ads(on_ready: Callable = Callable()) -> void:
	if _sdk_initialized:
		if on_ready.is_valid():
			on_ready.call()
		return

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
		_sdk_initialized = true
		if on_ready.is_valid():
			on_ready.call()

	MobileAds.initialize(listener)


func _show_banner() -> void:
	var unit_id := _banner_unit_id()
	if unit_id.is_empty():
		push_warning("AdBarService: android_banner_unit_id is missing in admob config")
		return

	_destroy_banner()

	var ad_size := AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)
	_ad_view = AdView.new(unit_id, ad_size, AdPosition.BOTTOM)

	var ad_listener := AdListener.new()
	ad_listener.on_ad_loaded = _on_banner_loaded
	ad_listener.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		push_warning("AdBarService: banner failed: %s" % error.message)

	_ad_view.ad_listener = ad_listener
	_ad_view.load_ad(AdRequest.new())


func _on_banner_loaded() -> void:
	if _ad_view == null:
		return
	var px := float(_ad_view.get_height_in_pixels())
	if px > 0.0:
		_banner_logical_height = _pixels_to_viewport_y(px)


func _destroy_banner() -> void:
	if _ad_view != null:
		_ad_view.destroy()
	_ad_view = null


func _ensure_disclosure(host: Control) -> void:
	if is_instance_valid(_disclosure) and _disclosure.get_parent() == host:
		return
	if is_instance_valid(_disclosure):
		_disclosure.queue_free()
	_disclosure = Label.new()
	_disclosure.name = "AdDisclosure"
	_disclosure.text = "Ad"
	_disclosure.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_disclosure.add_theme_font_size_override("font_size", 10)
	_disclosure.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	host.add_child(_disclosure)
	_disclosure.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_disclosure.offset_top = -DISCLOSURE_HEIGHT - _bottom_inset()
	_disclosure.offset_bottom = -_bottom_inset()


func _pixels_to_viewport_y(pixels: float) -> float:
	var window_h := float(DisplayServer.window_get_size().y)
	if window_h <= 0.0:
		return pixels
	var viewport_h := float(get_viewport().get_visible_rect().size.y)
	return pixels * (viewport_h / window_h)


func _bottom_inset() -> float:
	var safe := DisplayServer.get_display_safe_area()
	var window_h := DisplayServer.window_get_size().y
	if window_h <= 0:
		return 0.0
	return maxf(0.0, float(window_h - safe.end.y))
