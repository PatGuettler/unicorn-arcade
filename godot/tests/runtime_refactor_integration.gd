extends Node

const RoomEditor = preload("res://scripts/meta/room_editor.gd")
const FurnitureBagOverlay = preload("res://scripts/meta/furniture_bag_overlay.gd")
const RoomItemPreview3D = preload("res://scripts/meta/room_item_preview_3d.gd")
const RoomPreviewViewport = preload("res://scripts/meta/room_preview_viewport.gd")
const RoomAuthoredFurnitureLoader = preload("res://scripts/meta/room_authored_furniture_loader.gd")
const RoomProceduralFurnitureBuilder = preload("res://scripts/meta/room_procedural_furniture_builder.gd")
const GameExperienceChromePresenter = preload("res://scripts/ui/game_experience_chrome_presenter.gd")
const GameExperienceTutorialPresenter = preload("res://scripts/ui/game_experience_tutorial_presenter.gd")

class TutorialPauseProbe extends Control:
	var level := 1
	var pause_calls: Array[bool] = []

	func set_gameplay_paused(value: bool) -> void:
		pause_calls.append(value)

var failures: Array[String] = []

func _ready() -> void:
	_run.call_deferred()

func _check(value: bool, message: String) -> void:
	if not value: failures.append(message)


func _has_visible_pixels(texture: Texture2D) -> bool:
	if texture == null:
		return false
	var image := texture.get_image()
	return image != null and not image.is_empty() and image.get_used_rect().has_area()


func _room_item(items: Array, instance_id: String) -> Dictionary:
	for item in items:
		if str(item.get("instance_id", "")) == instance_id:
			return item
	return {}


func _run() -> void:
	var tutorial_presenter := GameExperienceTutorialPresenter.new()
	var tutorial_source: String = FileAccess.get_file_as_string("res://scripts/ui/game_experience_tutorial_presenter.gd")
	_check(tutorial_presenter is RefCounted and not tutorial_source.contains("\nvar ") and not tutorial_source.contains("AppState") and not tutorial_source.contains("GameExperience.") and not tutorial_source.contains("TutorialCatalog") and not tutorial_source.contains("attached_scene") and not tutorial_source.contains("CompanionAbilityService"), "tutorial presenter is a stateless RefCounted that does not own game, tutorial catalog, or gameplay state")
	var tutorial_overlay := Control.new()
	tutorial_overlay.set_meta("lessons", ["FIRST STEP", "SECOND STEP", "THIRD STEP"])
	tutorial_overlay.set_meta("step", 0)
	tutorial_overlay.set_meta("tutorial_level", 2)
	var tutorial_card := PanelContainer.new()
	tutorial_overlay.add_child(tutorial_card)
	tutorial_presenter.build(tutorial_card, tutorial_overlay, 2, ["FIRST STEP", "SECOND STEP", "THIRD STEP"], func(_overlay: Control) -> void: pass)
	var tutorial_heading := tutorial_overlay.find_child("TutorialHeading", true, false) as Label
	var tutorial_lesson := tutorial_overlay.find_child("TutorialLesson", true, false) as Label
	var tutorial_next := tutorial_overlay.find_child("TutorialNext", true, false) as Button
	_check(is_instance_valid(tutorial_heading) and tutorial_heading.text == "GUIDED LEVEL 2  •  STEP 1 OF 3" and is_instance_valid(tutorial_lesson) and tutorial_lesson.text == "FIRST STEP" and is_instance_valid(tutorial_next) and tutorial_next.text == "SHOW ME THE NEXT STEP", "tutorial presenter builds the exact heading, lesson, and next-button contract")
	var first_advance_complete := tutorial_presenter.advance(tutorial_overlay)
	_check(not first_advance_complete and int(tutorial_overlay.get_meta("step")) == 1 and tutorial_heading.text == "GUIDED LEVEL 2  •  STEP 2 OF 3" and tutorial_lesson.text == "SECOND STEP" and tutorial_next.text == "SHOW ME THE NEXT STEP", "tutorial presenter advances the step copy without consuming the overlay")
	var second_advance_complete := tutorial_presenter.advance(tutorial_overlay)
	_check(not second_advance_complete and int(tutorial_overlay.get_meta("step")) == 2 and tutorial_heading.text == "GUIDED LEVEL 2  •  STEP 3 OF 3" and tutorial_lesson.text == "THIRD STEP" and tutorial_next.text == "LET ME PLAY", "tutorial presenter preserves the final-step button transition")
	_check(tutorial_presenter.advance(tutorial_overlay), "tutorial presenter returns completion only after all tutorial steps are consumed")
	tutorial_overlay.free()
	var saved_tutorial_scene := GameExperience.attached_scene
	var saved_tutorial_controller := GameExperience.attached_controller
	var saved_tutorial_game_id := GameExperience.attached_game_id
	var saved_tutorials: Dictionary = AppState.data.get("tutorials", {}).duplicate(true)
	var tutorial_host := Control.new()
	add_child(tutorial_host)
	GameExperience.attached_scene = tutorial_host
	GameExperience.attached_controller = null
	GameExperience.attached_game_id = "coin_count"
	GameExperience._maybe_show_tutorial(true)
	var host_tutorial := tutorial_host.get_node_or_null("GuidedTutorialOverlay") as Control
	_check(is_instance_valid(host_tutorial) and str(host_tutorial.get_meta("game_id")) == "coin_count" and int(host_tutorial.get_meta("tutorial_level")) == 1 and host_tutorial.find_child("TutorialHeading", true, false) != null and host_tutorial.find_child("TutorialLesson", true, false) != null and host_tutorial.find_child("TutorialNext", true, false) != null, "GameExperience tutorial wrapper retains overlay metadata and presenter node contracts")
	GameExperience._advance_tutorial(host_tutorial)
	_check(int(host_tutorial.get_meta("step")) == 1 and (host_tutorial.find_child("TutorialHeading", true, false) as Label).text == "GUIDED LEVEL 1  •  STEP 2 OF 3", "GameExperience tutorial advance wrapper delegates presentation while retaining host metadata")
	var galaxy_probe := TutorialPauseProbe.new()
	add_child(galaxy_probe)
	GameExperience.attached_scene = galaxy_probe
	GameExperience.attached_game_id = "galaxy_unicorn"
	GameExperience._maybe_show_tutorial(true)
	var galaxy_tutorial := galaxy_probe.get_node_or_null("GuidedTutorialOverlay") as Control
	_check(is_instance_valid(galaxy_tutorial) and galaxy_probe.pause_calls == [true], "GameExperience pauses Galaxy gameplay when mounting its tutorial overlay")
	galaxy_tutorial.queue_free()
	await get_tree().process_frame
	_check(galaxy_probe.pause_calls == [true, false], "GameExperience unpauses Galaxy gameplay when its tutorial overlay exits")
	GameExperience.attached_scene = saved_tutorial_scene
	GameExperience.attached_controller = saved_tutorial_controller
	GameExperience.attached_game_id = saved_tutorial_game_id
	AppState.data["tutorials"] = saved_tutorials
	tutorial_host.free()
	galaxy_probe.free()
	var chrome_presenter := GameExperienceChromePresenter.new()
	var presenter_source: String = FileAccess.get_file_as_string("res://scripts/ui/game_experience_chrome_presenter.gd")
	_check(chrome_presenter is RefCounted and not presenter_source.contains("\nvar ") and not presenter_source.contains("AppState") and not presenter_source.contains("CompanionAbilityService"), "chrome presenter is a stateless RefCounted that receives presentation inputs instead of owning game state")
	var chrome_host := Control.new()
	add_child(chrome_host)
	chrome_presenter.apply_storybook_atmosphere(chrome_host)
	chrome_presenter.apply_storybook_atmosphere(chrome_host)
	_check(chrome_host.find_children("StorybookAtmosphere", "Control", true, false).size() == 1, "chrome presenter adds its storybook atmosphere idempotently")
	var presenter_header := chrome_presenter.build_header("Coin Count", 75, func() -> void: pass, func() -> void: pass, func() -> void: pass)
	var presenter_header_panel := presenter_header.get("panel") as PanelContainer
	var presenter_coin_button := presenter_header.get("coin_button") as Button
	_check(is_instance_valid(presenter_header_panel) and presenter_header_panel.name == "StandardGameHeader" and is_instance_valid(presenter_coin_button) and presenter_coin_button.name == "GameHeaderCoins" and presenter_coin_button.get_parent().get_parent() == presenter_header_panel and presenter_coin_button.text == " 75", "chrome presenter returns the exact header panel and coin button contract")
	var presenter_objective := chrome_presenter.build_objective_plaque("sparkle", func() -> void: pass, func() -> void: pass, func() -> void: pass)
	var presenter_objective_panel := presenter_objective.get("panel") as PanelContainer
	var presenter_primary := presenter_objective.get("objective_primary") as Label
	var presenter_detail := presenter_objective.get("objective_detail") as Label
	var presenter_ability := presenter_objective.get("ability_button") as Button
	var presenter_hint := presenter_objective.get("hint_button") as Button
	_check(is_instance_valid(presenter_objective_panel) and presenter_objective_panel.name == "GameObjectivePlaque" and is_instance_valid(presenter_primary) and presenter_primary.name == "ObjectivePrimary" and is_instance_valid(presenter_detail) and presenter_detail.name == "ObjectiveDetail" and is_instance_valid(presenter_ability) and presenter_ability.name == "CompanionAbility" and is_instance_valid(presenter_hint) and presenter_hint.name == "OrdinaryHint", "chrome presenter returns the exact objective labels and action button contract")
	var comet_scene := Control.new()
	var comet_equation := Label.new()
	comet_equation.name = "CometEquationBanner"
	comet_scene.add_child(comet_equation)
	var comet_meter := Label.new()
	comet_meter.name = "CometRescueMeter"
	comet_scene.add_child(comet_meter)
	chrome_presenter.configure_comet_chrome(comet_scene, "comet_math_rescue")
	_check(not comet_equation.visible and not comet_meter.visible, "chrome presenter hides duplicate Comet chrome only for the Comet game")
	var saved_attached_game_id := GameExperience.attached_game_id
	var saved_objective_primary := GameExperience.objective_primary
	var saved_objective_detail := GameExperience.objective_detail
	var saved_coin_button := GameExperience.coin_button
	var saved_ability_button := GameExperience.ability_button
	var saved_hint_button := GameExperience.hint_button
	var wrapper_header := GameExperience._build_header("Coin Count")
	var wrapper_objective := GameExperience._build_objective_plaque()
	chrome_host.add_child(wrapper_header)
	chrome_host.add_child(wrapper_objective)
	GameExperience.attached_game_id = "comet_math_rescue"
	GameExperience._configure_comet_chrome(comet_scene)
	_check(GameExperience.coin_button == wrapper_header.find_child("GameHeaderCoins", true, false) and GameExperience.objective_primary == wrapper_objective.find_child("ObjectivePrimary", true, false) and GameExperience.objective_detail == wrapper_objective.find_child("ObjectiveDetail", true, false) and GameExperience.ability_button == wrapper_objective.find_child("CompanionAbility", true, false) and GameExperience.hint_button == wrapper_objective.find_child("OrdinaryHint", true, false) and not comet_equation.visible and not comet_meter.visible, "GameExperience compatibility wrappers preserve public chrome fields and delegate Comet hiding")
	GameExperience.attached_game_id = saved_attached_game_id
	GameExperience.objective_primary = saved_objective_primary
	GameExperience.objective_detail = saved_objective_detail
	GameExperience.coin_button = saved_coin_button
	GameExperience.ability_button = saved_ability_button
	GameExperience.hint_button = saved_hint_button
	chrome_host.free()
	comet_scene.free()
	var procedural_rug_parent := Node3D.new()
	RoomProceduralFurnitureBuilder.new().build(procedural_rug_parent, "missing_procedural_rug", "rugs")
	var rug_mesh_count := 0
	for child in procedural_rug_parent.get_children():
		if child is MeshInstance3D and child.get_parent() == procedural_rug_parent:
			rug_mesh_count += 1
	_check(procedural_rug_parent.get_node_or_null("Rug") != null and rug_mesh_count == 4, "procedural builder creates the generic rug plus three direct inlay meshes")
	procedural_rug_parent.free()
	var procedural_chair_parent := Node3D.new()
	RoomProceduralFurnitureBuilder.new().build(procedural_chair_parent, "missing_procedural_chair", "unknown")
	var chair_mesh_count := 0
	for child in procedural_chair_parent.get_children():
		if child is MeshInstance3D and child.get_parent() == procedural_chair_parent:
			chair_mesh_count += 1
	_check(procedural_chair_parent.get_node_or_null("Seat") != null and procedural_chair_parent.get_node_or_null("Back") != null and chair_mesh_count == 6, "procedural builder falls back to a chair with direct Seat, Back, and four leg meshes")
	procedural_chair_parent.free()
	var authored_parent := Node3D.new()
	var authored_lamp := RoomAuthoredFurnitureLoader.build("lamp", authored_parent)
	var authored_missing := RoomAuthoredFurnitureLoader.build("missing_loader_id", authored_parent)
	_check(bool(authored_lamp.get("built", false)) and authored_lamp.get("source_model_id", "") == "store1:lamp" and authored_parent.get_node_or_null("AuthoredFurniture_lamp") != null and not bool(authored_missing.get("built", true)) and authored_parent.get_child_count() == 1, "authored furniture loader builds lamp and safely rejects missing ids")
	authored_parent.free()
	var received: Array = []
	var path := "res://scenes/games/coin_count.tscn"
	RuntimeAssetLoader.load_packed_scene(path, func(scene: PackedScene) -> void: received.append(scene))
	RuntimeAssetLoader.load_packed_scene(path, func(scene: PackedScene) -> void: received.append(scene))
	for frame in 120:
		await get_tree().process_frame
	_check(received.size() == 2 and received[0] != null and received[0] == received[1], "loader coalesces duplicate successful requests")
	var missing: Array = []
	RuntimeAssetLoader.load_packed_scene("res://missing/refactor-test.tscn", func(scene: PackedScene) -> void: missing.append(scene))
	for frame in 3:
		await get_tree().process_frame
	_check(missing.size() == 1 and missing[0] == null and not RuntimeAssetLoader.is_processing(), "loader reports a missing path and idles")
	var definition := {"id":"rug", "category":"rugs"}
	var yaw := 45.0
	var rotation_preview := RoomItemPreview3D.new()
	rotation_preview.setup(definition.merged({"animate": false, "presentation": "cache"}, true))
	rotation_preview.set_display_yaw(0.0)
	var rotation_root := rotation_preview.display_rotation_root
	var rotation_owner = rotation_preview.preview_viewport
	var rotation_viewport := rotation_preview.get_node_or_null("SubViewport") as SubViewport
	var rotation_stage := rotation_viewport.get_node_or_null("PreviewStage") as Node3D if is_instance_valid(rotation_viewport) else null
	var zero_yaw_is_upright := is_instance_valid(rotation_root) and is_zero_approx(rotation_root.rotation_degrees.x) and is_zero_approx(rotation_root.rotation_degrees.y) and is_zero_approx(rotation_root.rotation_degrees.z)
	rotation_preview.set_display_yaw(yaw)
	_check(rotation_owner is RoomPreviewViewport and is_instance_valid(rotation_viewport) and rotation_viewport.size == Vector2i(192, 192) and rotation_viewport.own_world_3d and rotation_viewport.transparent_bg and rotation_viewport.render_target_update_mode == SubViewport.UPDATE_ONCE and rotation_preview.find_children("*", "SubViewport", true, false).size() == 1 and rotation_preview.find_children("PreviewStage", "Node3D", true, false).size() == 1 and rotation_preview.find_children("DisplayRotationRoot", "Node3D", true, false).size() == 1 and rotation_owner.viewport == rotation_viewport and rotation_owner.stage == rotation_stage and rotation_owner.display_rotation_root == rotation_root and rotation_stage.get_parent() == rotation_viewport and rotation_root.get_parent() == rotation_stage and zero_yaw_is_upright and is_equal_approx(rotation_root.rotation_degrees.y, yaw) and is_zero_approx(rotation_root.rotation_degrees.x) and is_zero_approx(rotation_root.rotation_degrees.z), "RoomPreviewViewport owns the exact furniture viewport/stage/rotation-root chain")
	rotation_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	rotation_preview.set_display_yaw(90.0)
	_check(rotation_viewport.render_target_update_mode == SubViewport.UPDATE_ONCE, "static furniture yaw requests one redraw after a disabled viewport")
	var static_companion := RoomItemPreview3D.new()
	static_companion.setup({"id": "companion_sparkle", "category": "companions", "animate": false, "presentation": "game_hud"})
	var companion_viewport := static_companion.get_node_or_null("SubViewport") as SubViewport
	var companion_stage := static_companion.preview_viewport.stage as Node3D
	var companion_cameras := companion_stage.find_children("*", "Camera3D", false, false) if is_instance_valid(companion_stage) else []
	var companion_camera := companion_cameras[0] as Camera3D if companion_cameras.size() == 1 else null
	_check(static_companion.companion_builder != null and static_companion.source_model_id == "sparkle" and static_companion.preview_viewport is RoomPreviewViewport and is_instance_valid(companion_viewport) and companion_viewport.size == Vector2i(448, 320) and companion_viewport.render_target_update_mode == SubViewport.UPDATE_ONCE and companion_cameras.size() == 1 and is_instance_valid(companion_camera) and companion_camera.projection == Camera3D.PROJECTION_ORTHOGONAL and is_equal_approx(companion_camera.size, 8.80) and companion_camera.position.is_equal_approx(Vector3(-8.40, 4.28, 0.90)) and companion_camera.current and companion_stage.find_child("CompanionTravelRoot", true, false) != null and companion_stage.find_child("MeadowContactShadow", true, false) != null, "static companion builder owns the source, travel root, shadow, and HUD camera contract")
	static_companion.preview_viewport.shutdown()
	_check(companion_viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "RoomPreviewViewport shutdown disables its render target")
	for _frame in 120:
		if static_companion.find_child("LiveUnicornModel", true, false) != null and not RuntimeAssetLoader.is_processing():
			break
		await get_tree().process_frame
	_check(static_companion.find_child("LiveUnicornModel", true, false) != null and static_companion.mesh_count > 0, "static companion async model instantiation updates facade mesh_count")
	var animated_companion := RoomItemPreview3D.new()
	animated_companion.setup({"id": "companion_sparkle", "category": "companions", "animate": true, "presentation": "room"})
	for _frame in 120:
		if animated_companion.find_child("LiveUnicornModel", true, false) != null:
			break
		await get_tree().process_frame
	var animated_idle := animated_companion.get_node_or_null("IdleAnimator")
	animated_companion.set_motion_state(true)
	_check(animated_companion.companion_builder != null and animated_companion.find_child("LiveUnicornModel", true, false) != null and animated_companion.mesh_count > 0 and is_instance_valid(animated_idle) and animated_idle.get_parent() == animated_companion and String(animated_idle.get("active_action")) != "", "animated companion builder mounts the host-owned animator and facade motion reaches its walk action")
	animated_companion.free()
	await get_tree().process_frame
	static_companion.free()
	rotation_preview.free()
	_check(DecorPreviewCache.cache_key(definition, 0.0) != DecorPreviewCache.cache_key(definition, yaw), "decor cache keeps 0 and 45 degree renders in distinct yaw keys")
	var transparent_readback := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	_check(not bool(DecorPreviewCache.call("_has_visible_pixels", transparent_readback)), "decor cache rejects a fully transparent viewport readback")
	var textures: Array = []
	DecorPreviewCache.request(definition, yaw, func(texture: Texture2D) -> void: textures.append(texture))
	DecorPreviewCache.request(definition, yaw, func(texture: Texture2D) -> void: textures.append(texture))
	_check(DecorPreviewCache.active_viewport_count() <= 1, "decor cache has at most one transient viewport")
	for frame in 40:
		await get_tree().process_frame
	for frame in 3:
		await get_tree().process_frame
	_check(textures.size() == 2 and textures[0] is ImageTexture and _has_visible_pixels(textures[0]) and textures[0] == textures[1] and DecorPreviewCache.is_thumbnail_fallback(definition, yaw), "Fluffy Rug cache coalesces active duplicates into a visible thumbnail fallback ImageTexture")
	var bag_preview := FurnitureBagOverlay.new()
	var placeholder := bag_preview.call("_decor_thumbnail", "rug") as Texture2D
	_check(_has_visible_pixels(placeholder), "furniture bag assigns the Fluffy Rug thumbnail while its 3D preview is pending")
	var preview_parent := Button.new()
	preview_parent.size = Vector2(100, 100)
	preview_parent.rotation_degrees = 0.0
	var preview := TextureRect.new()
	preview.name = "CachedDecorPreview"
	preview.size = preview_parent.size
	preview_parent.add_child(preview)
	bag_preview.call("_refresh_cached_decor_preview", preview_parent, definition, yaw)
	_check(preview.texture == textures[0] and is_zero_approx(preview.rotation_degrees) and is_zero_approx(preview_parent.rotation_degrees), "furniture bag keeps both the fallback Fluffy Rug texture and its button upright")
	preview_parent.free()
	bag_preview.free()
	var saved_bag_inventory: Dictionary = AppState.data.get("inventory", {}).duplicate(true)
	AppState.data["inventory"]["lamp"] = 1
	AppState.data["inventory"]["rug"] = 1
	var bag_overlay := FurnitureBagOverlay.new()
	bag_overlay.setup("sparkle")
	add_child(bag_overlay)
	await get_tree().process_frame
	var bag_sheet := bag_overlay.get_node_or_null("FurnitureBagSheet") as PanelContainer
	var bag_category_chips: Array[Node] = bag_overlay.category_scroll.find_children("*", "Button", true, false)
	var bag_category_chip := bag_category_chips[0] as Button if not bag_category_chips.is_empty() else null
	var bag_item := bag_overlay.grid.get_child(0) as Button if bag_overlay.grid.get_child_count() > 0 else null
	_check(bag_overlay.name == "FurnitureBagOverlay" and is_instance_valid(bag_sheet) and is_equal_approx(bag_sheet.anchor_top, 0.34) and is_equal_approx(bag_sheet.anchor_bottom, 1.0) and bag_overlay.grid.name == "BagGrid" and bag_overlay.grid.columns == 3, "FurnitureBagOverlay owns the named bottom-sheet layout and three-column catalog grid")
	_check(bag_overlay.category_scroll.name == "FurnitureBagCategoryScroll" and bag_overlay.catalog_scroll.name == "FurnitureBagScroll" and bag_overlay.category_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO and bag_overlay.category_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED and bag_overlay.catalog_scroll.horizontal_scroll_mode == ScrollContainer.SCROLL_MODE_DISABLED and bag_overlay.catalog_scroll.vertical_scroll_mode == ScrollContainer.SCROLL_MODE_AUTO and is_instance_valid(bag_overlay.category_scroll.get_h_scroll_bar()) and is_instance_valid(bag_overlay.catalog_scroll.get_v_scroll_bar()), "FurnitureBagOverlay delegates category and catalog movement to native horizontal and vertical ScrollContainers")
	_check(is_equal_approx(bag_overlay.category_scroll.scroll_deadzone, 12.0) and is_equal_approx(bag_overlay.catalog_scroll.scroll_deadzone, 12.0) and is_equal_approx(bag_overlay.category_tap_guard.deadzone, 12.0) and is_equal_approx(bag_overlay.catalog_tap_guard.deadzone, 12.0) and not bag_overlay.catalog_scroll.follow_focus and bag_overlay.grid.mouse_filter == Control.MOUSE_FILTER_PASS and is_instance_valid(bag_category_chip) and bag_category_chip.mouse_filter == Control.MOUSE_FILTER_PASS and is_instance_valid(bag_item) and bag_item.mouse_filter == Control.MOUSE_FILTER_PASS, "FurnitureBagOverlay keeps deadzones, focus behavior, and pass-through mouse filters on its native scrolling surfaces")
	var selected_bag_items: Array[String] = []
	var closed_bag_events: Array = []
	bag_overlay.item_selected.connect(func(item_id: String) -> void: selected_bag_items.append(item_id))
	bag_overlay.closed.connect(func() -> void: closed_bag_events.append(true))
	bag_overlay.call("_select_item", "lamp")
	var category_press := InputEventScreenTouch.new()
	category_press.index = 21
	category_press.pressed = true
	bag_overlay.call("_on_bag_category_scroll_gui_input", category_press)
	var category_drag := InputEventScreenDrag.new()
	category_drag.index = 21
	category_drag.relative = Vector2(-32, 1)
	bag_overlay.call("_on_bag_category_scroll_gui_input", category_drag)
	var category_release := InputEventScreenTouch.new()
	category_release.index = 21
	category_release.pressed = false
	bag_overlay.call("_on_bag_category_scroll_gui_input", category_release)
	bag_overlay.call("_set_bag_category", "beds")
	var catalog_press := InputEventScreenTouch.new()
	catalog_press.index = 22
	catalog_press.pressed = true
	bag_overlay.call("_on_bag_catalog_scroll_gui_input", catalog_press)
	var catalog_drag := InputEventScreenDrag.new()
	catalog_drag.index = 22
	catalog_drag.relative = Vector2(1, -32)
	bag_overlay.call("_on_bag_catalog_scroll_gui_input", catalog_drag)
	var catalog_release := InputEventScreenTouch.new()
	catalog_release.index = 22
	catalog_release.pressed = false
	bag_overlay.call("_on_bag_catalog_scroll_gui_input", catalog_release)
	bag_overlay.call("_select_item", "rug")
	_check(selected_bag_items == ["lamp"] and bag_overlay.category == "all" and bag_overlay.category_tap_guard.is_action_suppressed() and bag_overlay.catalog_tap_guard.is_action_suppressed(), "FurnitureBagOverlay suppresses immediate category and item actions after real touch drags")
	bag_overlay.category_tap_guard.clear_suppression()
	bag_overlay.catalog_tap_guard.clear_suppression()
	bag_overlay.call("_set_bag_category", "lighting")
	await get_tree().process_frame
	_check(bag_overlay.category == "lighting" and is_instance_valid(bag_overlay.grid) and bag_overlay.grid.get_parent() == bag_overlay.catalog_scroll and bag_overlay.find_children("FurnitureBagCategoryScroll", "ScrollContainer", true, false).size() == 1 and bag_overlay.find_children("FurnitureBagScroll", "ScrollContainer", true, false).size() == 1, "FurnitureBagOverlay rebuilds a coherent single-scroll category view after changing categories")
	bag_overlay.close()
	bag_overlay.close()
	await get_tree().process_frame
	_check(closed_bag_events.size() == 1 and not is_instance_valid(bag_overlay), "FurnitureBagOverlay emits its closed signal exactly once and releases itself")
	AppState.data["inventory"] = saved_bag_inventory
	var lifecycle_host := Control.new()
	add_child(lifecycle_host)
	var lifecycle_editor := RoomEditor.new()
	lifecycle_editor.room_canvas = lifecycle_host
	var first_item := {"instance_id": "live_rug_a", "item_id": "rug", "rotation": 0.0, "scale": 1.0, "z_index": 1}
	var second_item := {"instance_id": "live_rug_b", "item_id": "rug", "rotation": 45.0, "scale": 1.1, "z_index": 2}
	# The hidden companion home anchor sits behind placed decor in saved data, but
	# it must never affect visible decor ordering controls.
	var hidden_companion_anchor := {"instance_id": "room_companion_sparkle", "item_id": "companion_sparkle", "rotation": 0.0, "scale": 1.0, "z_index": 0}
	lifecycle_editor.local_items = [hidden_companion_anchor, first_item, second_item]
	lifecycle_editor.call("_create_item_button", first_item)
	lifecycle_editor.call("_create_item_button", second_item)
	for _frame in 4:
		await get_tree().process_frame
	var first_button := lifecycle_editor.item_buttons.get("live_rug_a") as Button
	var second_button := lifecycle_editor.item_buttons.get("live_rug_b") as Button
	var first_cached := first_button.get_node_or_null("CachedDecorPreview") as TextureRect
	var first_live := first_button.get_node_or_null("RoomItemPreview3D") as RoomItemPreview3D
	var first_root := first_live.display_rotation_root if is_instance_valid(first_live) else null
	var first_authored_rug := first_live.find_child("AuthoredFurniture_rug", true, false) if is_instance_valid(first_live) else null
	var second_live := second_button.get_node_or_null("RoomItemPreview3D") as RoomItemPreview3D
	var first_viewport := first_live.get_node_or_null("SubViewport") as SubViewport if is_instance_valid(first_live) else null
	_check(is_instance_valid(first_live) and is_instance_valid(second_live) and first_cached == null and first_live.animate_character == false and first_live.uses_authored_furniture_model and first_live.source_furniture_model_id == "store1:rug" and is_instance_valid(first_authored_rug) and is_instance_valid(first_viewport) and first_viewport.render_target_update_mode == SubViewport.UPDATE_ONCE, "visible room decor uses static authored 3D previews without CachedDecorPreview snapshots")
	first_live.set_display_yaw(45.0)
	_check(is_equal_approx(first_root.rotation_degrees.y, 45.0) and is_zero_approx(first_root.rotation_degrees.x) and is_zero_approx(first_root.rotation_degrees.z) and first_viewport.render_target_update_mode == SubViewport.UPDATE_ONCE and is_zero_approx(first_button.rotation_degrees), "static room decor redraws once after a yaw update while its button remains upright")
	var original_live := first_live
	first_button.custom_minimum_size = Vector2(140, 140)
	first_button.size = first_button.custom_minimum_size
	_check(first_button.get_node_or_null("RoomItemPreview3D") == original_live and is_zero_approx(first_live.anchor_left) and is_zero_approx(first_live.anchor_top) and is_equal_approx(first_live.anchor_right, 1.0) and is_equal_approx(first_live.anchor_bottom, 1.0), "room scale changes keep the same full-rect live preview node")
	lifecycle_editor.selected_id = "live_rug_a"
	lifecycle_editor.call("_show_selection_toolbar")
	var backmost_toolbar := lifecycle_editor.selection_toolbar as HBoxContainer
	var backmost_back := backmost_toolbar.get_child(4) as Button
	var backmost_front := backmost_toolbar.get_child(5) as Button
	lifecycle_editor.selected_id = "live_rug_b"
	lifecycle_editor.call("_show_selection_toolbar")
	var frontmost_toolbar := lifecycle_editor.selection_toolbar as HBoxContainer
	var frontmost_back := frontmost_toolbar.get_child(4) as Button
	var frontmost_front := frontmost_toolbar.get_child(5) as Button
	_check(backmost_back.disabled and not backmost_front.disabled and not frontmost_back.disabled and frontmost_front.disabled, "layer controls stop at the visible decor boundaries and ignore the hidden companion anchor")
	# Exercise the actual action path against a controlled room state, then put
	# AppState back exactly as it was so this regression never changes a profile.
	var saved_rooms: Dictionary = AppState.data.get("rooms", {}).duplicate(true)
	var saved_save_envelope: Dictionary = SaveService._envelope.duplicate(true)
	var saved_active_key: String = SaveService._active_key
	var saved_test_in_memory: bool = SaveService._test_in_memory
	var test_profile_key := "runtime_refactor"
	SaveService._test_in_memory = true
	SaveService._envelope = SaveService.default_state()
	SaveService._envelope["last_user"] = test_profile_key
	SaveService._envelope["users"][test_profile_key] = {"display_name": test_profile_key, "profile": AppState.data.duplicate(true)}
	SaveService._active_key = test_profile_key
	var action_rooms := saved_rooms.duplicate(true)
	action_rooms[lifecycle_editor.companion_id] = [hidden_companion_anchor.duplicate(true), first_item.duplicate(true), second_item.duplicate(true)]
	AppState.data["rooms"] = action_rooms
	lifecycle_editor.local_items = AppState.room_items(lifecycle_editor.companion_id)
	lifecycle_editor.selected_id = "live_rug_a"
	lifecycle_editor.call("_refresh_room_items")
	for step in 8:
		lifecycle_editor.call("_selection_action", "LARGER")
	await get_tree().process_frame
	var enlarged_local := _room_item(lifecycle_editor.local_items, "live_rug_a")
	var enlarged_saved := _room_item(AppState.room_items(lifecycle_editor.companion_id), "live_rug_a")
	var base_size: Vector2 = lifecycle_editor.call("_item_base_size", "rug")
	var larger_toolbar := lifecycle_editor.selection_toolbar as HBoxContainer
	var larger_button := larger_toolbar.get_child(3) as Button
	_check(is_equal_approx(float(enlarged_local.get("scale", 0.0)), 1.8) and is_equal_approx(float(enlarged_saved.get("scale", 0.0)), 1.8) and first_button.get_node_or_null("RoomItemPreview3D") == original_live and first_button.size.is_equal_approx(base_size * 1.8) and first_live.size.is_equal_approx(first_button.size) and larger_button.disabled, "LARGER updates AppState and the existing full-rect live preview while disabling at the maximum scale")
	for step in 13:
		lifecycle_editor.call("_selection_action", "SMALLER")
	await get_tree().process_frame
	var reduced_local := _room_item(lifecycle_editor.local_items, "live_rug_a")
	var reduced_saved := _room_item(AppState.room_items(lifecycle_editor.companion_id), "live_rug_a")
	var smaller_toolbar := lifecycle_editor.selection_toolbar as HBoxContainer
	var smaller_button := smaller_toolbar.get_child(2) as Button
	_check(is_equal_approx(float(reduced_local.get("scale", 0.0)), 0.5) and is_equal_approx(float(reduced_saved.get("scale", 0.0)), 0.5) and first_button.get_node_or_null("RoomItemPreview3D") == original_live and first_button.size.is_equal_approx(base_size * 0.5) and first_live.size.is_equal_approx(first_button.size) and smaller_button.disabled, "SMALLER updates AppState and the existing full-rect live preview while disabling at the minimum scale")
	for step in 5:
		lifecycle_editor.call("_selection_action", "LARGER")
	lifecycle_editor.call("_selection_action", "FRONT")
	var front_local := _room_item(lifecycle_editor.local_items, "live_rug_a")
	var front_neighbor := _room_item(lifecycle_editor.local_items, "live_rug_b")
	var front_saved := _room_item(AppState.room_items(lifecycle_editor.companion_id), "live_rug_a")
	var front_toolbar := lifecycle_editor.selection_toolbar as HBoxContainer
	_check(int(front_local.get("z_index", 0)) == 2 and int(front_neighbor.get("z_index", 0)) == 1 and int(front_saved.get("z_index", 0)) == 2 and first_button.z_index == 2 and second_button.z_index == 1 and first_button.get_node_or_null("RoomItemPreview3D") == original_live and (front_toolbar.get_child(5) as Button).disabled, "FRONT swaps only visible decor z-order through AppState and refreshes the front boundary")
	lifecycle_editor.call("_selection_action", "BACK")
	var restored_local := _room_item(lifecycle_editor.local_items, "live_rug_a")
	var restored_neighbor := _room_item(lifecycle_editor.local_items, "live_rug_b")
	var restored_saved := _room_item(AppState.room_items(lifecycle_editor.companion_id), "live_rug_a")
	var restored_toolbar := lifecycle_editor.selection_toolbar as HBoxContainer
	_check(int(restored_local.get("z_index", 0)) == 1 and int(restored_neighbor.get("z_index", 0)) == 2 and int(restored_saved.get("z_index", 0)) == 1 and first_button.z_index == 1 and second_button.z_index == 2 and first_button.get_node_or_null("RoomItemPreview3D") == original_live and (restored_toolbar.get_child(4) as Button).disabled, "BACK restores visible decor z-order through AppState and refreshes the back boundary")
	AppState.data["rooms"] = saved_rooms
	SaveService._envelope = saved_save_envelope
	SaveService._active_key = saved_active_key
	SaveService._test_in_memory = saved_test_in_memory
	lifecycle_host.queue_free()
	lifecycle_editor.free()
	if failures.is_empty():
		print("RUNTIME_REFACTOR_INTEGRATION_OK")
		get_tree().quit(0)
	else:
		for failure in failures: push_error(failure)
		get_tree().quit(1)
