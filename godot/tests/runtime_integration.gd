extends Node

const Rules = preload("res://scripts/games/word_game_rules.gd")
const WORD_SCENE = preload("res://scenes/games/word_game.tscn")
const CASH_SCENE = preload("res://scenes/games/cash_counter.tscn")
const COIN_SCENE = preload("res://scenes/games/coin_count.tscn")
const RHYME_SCENE = preload("res://scenes/games/rhyme_rally.tscn")
const MAIN_SCENE = preload("res://scenes/main.tscn")
const MATH_SWIPE_SCENE = preload("res://scenes/games/math_swipe.tscn")
const JUMP_SCENE = preload("res://scenes/games/unicorn_jump.tscn")
const SLIDING_SCENE = preload("res://scenes/games/sliding_window.tscn")
const MATHTRIS_SCENE = preload("res://scenes/games/mathtris.tscn")
const GALAXY_SCENE = preload("res://scenes/games/galaxy_unicorn.tscn")
const MARKET_SCENE = preload("res://scenes/meta/marketplace.tscn")
const ALLEY_SCENE = preload("res://scenes/meta/unicorn_alley.tscn")
const ROOM_SCENE = preload("res://scenes/meta/room_editor.tscn")

const WORD_GAME_IDS := [
	"unicorn_blast", "sentence_sprout", "missing_magic", "sight_spark",
	"prefix_potion", "vowel_vines", "letter_lift", "syllable_stamp",
	"caption_quest", "opposite_orbit", "scramble_spell", "odd_one_out",
	"size_line_up", "chain_link",
]

var failures: Array[String] = []
var check_count := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var original_game := AppState.selected_game_id
	var original_category := AppState.selected_category
	for game_id in WORD_GAME_IDS:
		AppState.selected_game_id = game_id
		var game = WORD_SCENE.instantiate()
		add_child(game)
		await get_tree().process_frame
		_check(_ui_is_accessible(game), "%s meets readable text, contrast, and touch-target minimums" % game_id)
		_check(game.game_id == game_id, "%s selects the requested shared-game mode" % game_id)
		_check(game.active, "%s begins in an active play state" % game_id)
		_check(game.target_rounds > 0, "%s has a positive round target" % game_id)
		_exercise_first_move(game_id, game)
		remove_child(game)
		game.free()
	var cash = CASH_SCENE.instantiate()
	add_child(cash)
	await get_tree().process_frame
	_check(_ui_is_accessible(cash), "Cash Counter meets readable text, contrast, and touch-target minimums")
	_check(cash.active, "Cash Counter begins in an active play state")
	cash.target = 20
	cash.total = 0
	cash.call("_add_bill", 5)
	_check(cash.total == 5 and cash.active, "Cash Counter accepts a non-overshooting bill")
	remove_child(cash)
	cash.free()
	var coin_count = COIN_SCENE.instantiate()
	add_child(coin_count)
	await get_tree().process_frame
	_check(coin_count.target > 0, "Coin Count begins with a positive target")
	_check(_ui_is_accessible(coin_count), "Coin Count meets readable text, contrast, and touch-target minimums")
	_check(coin_count.coin_buttons.size() == 4 and coin_count.coin_buttons.all(func(button: Button) -> bool: return button is CoinChoiceButton), "Coin Count uses four illustrated denomination coins instead of text boxes")
	_check(coin_count.coin_buttons[0].custom_minimum_size.y >= 170.0 and coin_count.coin_buttons[0].tooltip_text.contains("worth"), "illustrated coins retain large accessible tap targets and denomination descriptions")
	remove_child(coin_count)
	coin_count.free()
	var rhyme = RHYME_SCENE.instantiate()
	add_child(rhyme)
	await get_tree().process_frame
	_check(rhyme.target_rounds > 0 and not rhyme.challenge.is_empty(), "Rhyme Rally begins with a playable challenge")
	_check(_ui_is_accessible(rhyme), "Rhyme Rally meets readable text, contrast, and touch-target minimums")
	remove_child(rhyme)
	rhyme.free()
	var math_swipe = MATH_SWIPE_SCENE.instantiate()
	add_child(math_swipe)
	await get_tree().process_frame
	_check(_ui_is_accessible(math_swipe), "Math Swipe meets readable text, contrast, and touch-target minimums")
	_check(math_swipe.active and math_swipe.cards.size() == 2, "Math Swipe launches with two answer cards")
	var correct_card: Button
	for card in math_swipe.cards:
		if bool(card.get_meta("correct")):
			correct_card = card
			break
	math_swipe.call("_submit", correct_card)
	_check(math_swipe.completed == 1, "Math Swipe accepts the correct card")
	remove_child(math_swipe)
	math_swipe.free()
	var jump = JUMP_SCENE.instantiate()
	add_child(jump)
	await get_tree().process_frame
	_check(_ui_is_accessible(jump), "Unicorn Jump meets readable text, contrast, and touch-target minimums")
	_check(jump.active and jump.level_data.size() == 10, "Unicorn Jump launches its level-one ten-node trail")
	_check(jump.node_buttons.size() == 11 and jump.node_buttons.all(func(button: TextureButton) -> bool: return button.texture_normal != null), "Unicorn Jump builds the full trail from authored stepping-stone art")
	_check(jump.find_children("TrailConnector*", "Line2D", true, false).size() == 10, "Unicorn Jump restores the original connected winding path")
	var trail_companion = jump.find_child("ActiveCompanionOnStone", true, false)
	_check(is_instance_valid(trail_companion) and trail_companion.source_model_id == AppState.equipped_companion(), "the equipped 3D companion stands on the current stepping stone")
	_check((jump.node_buttons[0].get_node("JumpValue") as Label).text.is_empty() and jump.jump_label.text.contains(str(absi(jump.level_data[0]))), "jump distance appears in the HUD while all countable landing stones remain unlabeled")
	_check(jump.node_buttons.size() == jump.level_data.size() + 1, "every intermediate wrong landing remains visible between the current stone and later correct destinations")
	var landing: int = jump.level_data[0]
	_check(jump.node_buttons[landing].self_modulate == Color.WHITE, "Unicorn Jump does not reveal the counted landing with a highlight")
	jump.call("_choose_node", landing)
	_check(jump.current_index == landing and jump.active, "Unicorn Jump accepts the exact indexed landing")
	_check(trail_companion.get_parent() == jump.node_buttons[landing], "the active companion moves to the newly reached stone")
	remove_child(jump)
	jump.free()
	var sliding = SLIDING_SCENE.instantiate()
	add_child(sliding)
	await get_tree().process_frame
	_check(_ui_is_accessible(sliding), "Sliding Window meets readable text, contrast, and touch-target minimums")
	_check(sliding.active and sliding.window_size == 3, "Sliding Window launches its level-one race")
	var max_index := 0
	for index in sliding.window_size:
		if sliding.level_data[index] > sliding.level_data[max_index]:
			max_index = index
	sliding.call("_choose", max_index)
	_check(sliding.window_pos == 1 and sliding.active, "Sliding Window advances after selecting the maximum")
	remove_child(sliding)
	sliding.free()
	var mathtris = MATHTRIS_SCENE.instantiate()
	add_child(mathtris)
	await get_tree().process_frame
	_check(_ui_is_accessible(mathtris), "Mathtris meets readable text, contrast, and touch-target minimums")
	_check(mathtris.active and mathtris.board.size() == 14 and mathtris.board[0].size() == 8, "Mathtris launches an 8 by 14 live board")
	_check(not mathtris.falling.is_empty(), "Mathtris launches an initial falling wave")
	remove_child(mathtris)
	mathtris.free()
	var galaxy = GALAXY_SCENE.instantiate()
	add_child(galaxy)
	await get_tree().process_frame
	_check(_ui_is_accessible(galaxy), "Galaxy Unicorn meets readable text, contrast, and touch-target minimums")
	_check(galaxy.active and galaxy.target_kills == 10 and galaxy.lives == 3, "Galaxy Unicorn launches with the React target and lives")
	_check(is_equal_approx(galaxy.player_x, 0.5), "Galaxy Unicorn centers the player for its opening wave")
	galaxy.call("_spawn_enemy", false)
	_check(float(galaxy.enemies[0]["speed"]) <= 0.000125, "Galaxy Unicorn's opening enemies use the gentle level-one speed curve")
	galaxy.enemies.clear()
	galaxy.size = Vector2(720, 1280)
	var galaxy_drag := InputEventScreenDrag.new()
	galaxy_drag.position = Vector2(576, 900)
	galaxy.call("_input", galaxy_drag)
	_check(is_equal_approx(galaxy.player_x, 0.8), "Galaxy Unicorn responds to Android screen dragging")
	galaxy.call("_process", 0.016)
	_check(galaxy.fire_cooldown > 0.0 and galaxy.bolt_flashes.size() > 0, "Galaxy Unicorn auto-fires a visible rainbow bolt")
	_check(galaxy.call("_segment_hits_circle", Vector2(576, 1000), Vector2(576, 300), Vector2(576, 650), 26.0), "Galaxy Unicorn fast bolts use swept collision instead of tunneling through targets")
	remove_child(galaxy)
	galaxy.free()
	var market = MARKET_SCENE.instantiate()
	add_child(market)
	await get_tree().process_frame
	_check(_ui_is_accessible(market), "companion Marketplace meets readable text, contrast, and touch-target minimums")
	_check(market.tab == "companions" and market.content.get_child_count() > 0, "Marketplace launches its companion catalog")
	var companion_previews := market.find_children("CompanionModelPreview", "RoomItemPreview3D", true, false)
	var source_model_ids: Dictionary = {}
	var static_marketplace_models := 0
	var static_marketplace_framing_safe := true
	for live_preview in companion_previews:
		source_model_ids[live_preview.source_model_id] = true
		var preview_animator = live_preview.find_child("IdleAnimator", true, false)
		if not is_instance_valid(preview_animator) and not live_preview.animate_character:
			static_marketplace_models += 1
		var preview_cameras: Array[Node] = live_preview.find_children("*", "Camera3D", true, false)
		var preview_viewports: Array[Node] = live_preview.find_children("*", "SubViewport", true, false)
		var viewport_matches_card: bool = not preview_viewports.is_empty() and live_preview.size.y > 0.0 and absf(
			float(preview_viewports[0].size.x) / float(preview_viewports[0].size.y) - live_preview.size.x / live_preview.size.y
		) <= 0.02
		if preview_cameras.is_empty() or preview_cameras[0].size < 6.8 or not viewport_matches_card:
			static_marketplace_framing_safe = false
	_check(companion_previews.size() == 6 and source_model_ids.size() == 6, "Marketplace companion cards use six distinct authored GLB models")
	_check(static_marketplace_models == 6, "Marketplace companion models remain in a static authored pose")
	_check(static_marketplace_framing_safe, "Marketplace camera preserves horn and hoof clearance without stretching the enlarged unicorns")
	market.call("_show_decor")
	await get_tree().process_frame
	_check(_ui_is_accessible(market), "decor Marketplace meets readable text, contrast, and touch-target minimums")
	_check(market.tab == "decor" and MetaCatalog.filtered_furniture("all", "").size() == 107, "Marketplace keeps the full 107-item decor catalog available")
	_check(market.find_children("CatalogModelPreview", "RoomItemPreview3D", true, false).size() == market.DECOR_PAGE_SIZE, "Marketplace initially creates only one mobile-friendly page of live 3D previews")
	_check(market.find_children("DecorCard_*", "PanelContainer", true, false).size() == market.DECOR_PAGE_SIZE and market.find_child("LoadMoreDecor", true, false) != null, "decor catalog pages its rarity-framed cards without hiding the remaining inventory")
	_check(market.find_child("DecorCategoryChips", true, false) != null and market.find_child("DecorSearch", true, false) != null, "decor catalog restores quick category chips and search")
	market.category_scroll.scroll_horizontal = 80
	var category_scroll_before: int = market.category_scroll.scroll_horizontal
	var category_drag := InputEventScreenDrag.new()
	category_drag.position = market.category_scroll.get_global_rect().get_center()
	category_drag.relative = Vector2(-120, 2)
	market.call("_input", category_drag)
	_check(market.category_scroll.scroll_horizontal > category_scroll_before, "Marketplace category chips respond to horizontal Android dragging even when the gesture starts over a chip")
	var category_release := InputEventScreenTouch.new()
	category_release.pressed = false
	category_release.position = category_drag.position
	market.call("_input", category_release)
	market.call("_set_decor_category", "beds")
	_check(market.category == "all", "a horizontal category swipe does not accidentally activate the chip under the finger")
	market.call("_load_more_decor")
	await get_tree().process_frame
	_check(market.find_children("CatalogModelPreview", "RoomItemPreview3D", true, false).size() == market.DECOR_PAGE_SIZE * 2, "Load More reveals the next modeled decor page")
	market.catalog_scroll.scroll_vertical = 200
	var scroll_before: int = market.catalog_scroll.scroll_vertical
	var market_drag := InputEventScreenDrag.new()
	market_drag.position = market.catalog_scroll.get_global_rect().get_center()
	market_drag.relative = Vector2(2, -120)
	market.call("_input", market_drag)
	_check(market.catalog_scroll.scroll_vertical > scroll_before, "decor Marketplace responds to vertical Android dragging anywhere across a catalog card")
	var signature_nodes := ["bed_race", "pet_fish", "tv_retro", "xmas_sock"]
	var signatures_found := 0
	for item_id in signature_nodes:
		var signature_preview := RoomItemPreview3D.new()
		signature_preview.setup(MetaCatalog.furniture_item(item_id))
		if signature_preview.uses_authored_furniture_model and signature_preview.find_child("AuthoredFurniture_%s" % item_id, true, false) != null and signature_preview.source_furniture_model_id.ends_with(":%s" % item_id):
			signatures_found += 1
		signature_preview.free()
	_check(signatures_found == signature_nodes.size(), "decor previews load item-specific authored models across beds, pets, electronics, and seasonal art")
	remove_child(market)
	market.free()
	var alley = ALLEY_SCENE.instantiate()
	add_child(alley)
	await get_tree().process_frame
	_check(_ui_is_accessible(alley), "Unicorn Alley meets readable text, contrast, and touch-target minimums")
	_check(is_instance_valid(alley.message_label) and alley.house_buttons.size() == 6, "Unicorn Alley launches all six selectable houses")
	_check(alley.map_rect.texture.resource_path.ends_with("unicorn_alley_production_v1.png"), "Unicorn Alley uses the new unified six-door pastel map")
	var door_button: Button = alley.house_buttons.get("sparkle")
	_check(door_button.custom_minimum_size.y > door_button.custom_minimum_size.x, "Alley house targets use tall door-shaped controls")
	_check(door_button.text.is_empty() and door_button.has_node("DoorStateArt"), "Alley doors use environmental light cues without floating label shapes")
	remove_child(alley)
	alley.free()
	AppState.active_room_companion = "sparkle"
	var room = ROOM_SCENE.instantiate()
	add_child(room)
	await get_tree().process_frame
	_check(_ui_is_accessible(room), "room editor meets readable text, contrast, and touch-target minimums")
	_check(room.companion_id == "sparkle" and is_instance_valid(room.room_canvas), "Sparkle's room editor launches")
	_check(room.grid_snap, "room editor starts with eight-percent grid snapping enabled")
	_check(room.call("_item_base_size", "companion_sparkle") == Vector2(252, 180), "room companions use an expanded transparent canvas for horn and hoof clearance")
	var companion_button: Button = room.item_buttons.get("room_companion_sparkle")
	var companion_preview = companion_button.get_node_or_null("RoomItemPreview3D") if is_instance_valid(companion_button) else null
	_check(is_instance_valid(companion_preview) and companion_preview.uses_character_model and companion_preview.source_model_id == "sparkle" and companion_preview.mesh_count >= 1, "rooms automatically present the updated companion-specific GLB")
	var live_unicorn_model = companion_preview.find_child("LiveUnicornModel", true, false) if is_instance_valid(companion_preview) else null
	_check(is_instance_valid(live_unicorn_model) and is_equal_approx(live_unicorn_model.scale.x, 3.84), "room unicorn presentation applies the requested three-times display scale")
	var companion_cameras: Array[Node] = companion_preview.find_children("*", "Camera3D", true, false) if is_instance_valid(companion_preview) else []
	var companion_camera = companion_cameras[0] if not companion_cameras.is_empty() else null
	_check(is_instance_valid(companion_camera) and companion_camera.size >= 6.8 and companion_camera.position.x < -8.0 and absf(companion_camera.position.z) < 2.0, "animated room companions use padded opposite-facing side-view framing")
	var idle_animator = companion_preview.find_child("IdleAnimator", true, false) if is_instance_valid(companion_preview) else null
	var moving_shadow = companion_preview.find_child("MeadowContactShadow", true, false) if is_instance_valid(companion_preview) else null
	_check(is_instance_valid(idle_animator) and is_instance_valid(moving_shadow) and moving_shadow.get_parent() == idle_animator.model, "the companion and its contact shadow share one travel root")
	_check(is_instance_valid(idle_animator) and idle_animator.animation_names() == PackedStringArray(["walk"]), "live unicorn previews expose only the Walk animation")
	_check(is_instance_valid(idle_animator) and is_instance_valid(idle_animator.timer) and not idle_animator.timer.is_stopped() and idle_animator.timer.wait_time >= 10.0 and idle_animator.timer.wait_time <= 30.0, "live unicorn previews schedule Walk at the requested random interval")
	_check(is_instance_valid(idle_animator) and _skeletons_are_in_rest_pose(idle_animator.model), "unicorns use their neutral rig pose while standing instead of freezing a gait-contact frame")
	if is_instance_valid(idle_animator):
		idle_animator.play_random_animation_now()
	_check(is_instance_valid(idle_animator) and idle_animator.last_animation_name == "walk", "Sparkle can immediately exercise its embedded Walk animation")
	if is_instance_valid(idle_animator):
		var walk_home_position: Vector3 = idle_animator.model.position
		var walk_home_rotation: float = idle_animator.model.rotation.y
		_check(idle_animator.play_animation_now("walk"), "authored walk clip can be selected deterministically")
		idle_animator.walk_tween.custom_step(1.5)
		_check(idle_animator.model.position.distance_to(walk_home_position) > 0.1 and not is_equal_approx(idle_animator.model.rotation.y, walk_home_rotation), "walking unicorn travels and pivots instead of walking in place")
		var walk_displacement: Vector3 = idle_animator.model.position - walk_home_position
		var visual_forward: Vector3 = (idle_animator.model.basis * Vector3.BACK).normalized()
		_check(visual_forward.dot(walk_displacement.normalized()) > 0.9, "walking unicorn faces its direction of travel instead of moving backward")
		idle_animator.walk_tween.custom_step(10.0)
		_check(idle_animator.model.position.is_equal_approx(walk_home_position) and is_equal_approx(idle_animator.model.rotation.y, walk_home_rotation), "walking unicorn returns to its exact display position and facing")
		_check(idle_animator.animation_player.assigned_animation == idle_animator.walk_animation and not idle_animator.timer.is_stopped(), "walking route returns to its standing Walk pose and schedules the next route")
	remove_child(room)
	room.free()
	var original_data := AppState.data.duplicate(true)
	AppState.data = SaveService.default_state()
	AppState.data["player"]["name"] = "Runtime Test"
	_check(AppState.buy_companion("rainbow") and AppState.coins() == 500, "companion adoption deducts the exact catalog price")
	_check(AppState.equip_companion("rainbow") and AppState.equipped_companion() == "rainbow", "owned companions can be equipped")
	_check(AppState.buy_furniture("lamp") and AppState.coins() == 350, "decor purchase adds one catalog item")
	var placement := {"instance_id": "test_lamp", "item_id": "lamp", "x": 48.0, "y": 48.0, "rotation": 0, "scale": 1.0, "z_index": 1}
	_check(AppState.place_room_item("rainbow", placement) and AppState.available_count("lamp") == 0, "room placement consumes one available inventory item")
	_check(not AppState.sell_furniture("lamp"), "placed decor cannot be sold")
	AppState.active_room_companion = "rainbow"
	var touch_room = ROOM_SCENE.instantiate()
	add_child(touch_room)
	await get_tree().process_frame
	var lamp_button: Button = touch_room.item_buttons.get("test_lamp")
	var room_press := InputEventScreenTouch.new()
	room_press.pressed = true
	touch_room.call("_item_input", room_press, "test_lamp", lamp_button)
	var lamp_preview = lamp_button.get_node_or_null("RoomItemPreview3D") if is_instance_valid(lamp_button) else null
	_check(lamp_button.text.is_empty() and lamp_button.tooltip_text == "Lava Lamp" and is_instance_valid(lamp_preview) and lamp_preview.mesh_count > 0 and not lamp_preview.uses_character_model, "room decor uses a modeled 3D object instead of an icon glyph")
	_check(is_instance_valid(touch_room.selection_toolbar) and touch_room.selection_toolbar.get_child_count() == 6, "selecting decor opens the original six-action contextual toolbar")
	var room_drag := InputEventScreenDrag.new()
	room_drag.position = touch_room.room_canvas.global_position + Vector2(touch_room.room_canvas.size.x * 0.82, touch_room.room_canvas.size.y * 0.66)
	touch_room.call("_input", room_drag)
	var room_release := InputEventScreenTouch.new()
	room_release.pressed = false
	room_release.position = room_drag.position
	touch_room.call("_input", room_release)
	var moved_items := AppState.room_items("rainbow")
	var moved_lamp := moved_items.filter(func(item: Dictionary) -> bool: return str(item.get("instance_id", "")) == "test_lamp")
	_check(moved_lamp.size() == 1 and is_equal_approx(float(moved_lamp[0]["x"]), 80.0) and is_equal_approx(float(moved_lamp[0]["y"]), 64.0), "room decor follows and commits an Android drag outside its button")
	touch_room.call("_show_bag")
	await get_tree().process_frame
	var empty_bag_message := touch_room.bag_grid.find_child("EmptyBagMessage", true, false) as Label
	_check(is_instance_valid(touch_room.bag_overlay) and touch_room.bag_grid.columns == 1 and is_instance_valid(empty_bag_message) and empty_bag_message.custom_minimum_size.x >= 600.0, "empty furniture bag uses one full-width message instead of a one-character column")
	_check(not touch_room.bag_button.visible and not touch_room.status_label.visible, "open furniture bag hides the underlying floating button and room status")
	_check(_ui_is_accessible(touch_room.bag_overlay), "Furniture Bag meets readable text, contrast, and touch-target minimums")
	touch_room.call("_close_bag")
	remove_child(touch_room)
	touch_room.free()
	_check(AppState.remove_room_item("rainbow", "test_lamp") and AppState.available_count("lamp") == 1, "removed decor returns to the shared bag")
	_check(AppState.sell_furniture("lamp") and AppState.coins() == 425, "unused decor sells for the floored fifty-percent refund")
	AppState.data = original_data
	SaveService.save_state(AppState.data)
	var shell_state := AppState.data.duplicate(true)
	AppState.data["owned_companions"] = ["sparkle", "rainbow", "star", "cloud", "dream", "mystic"]
	AppState.data["player"]["equipped_companion"] = "mystic"
	var shell = MAIN_SCENE.instantiate()
	add_child(shell)
	await get_tree().process_frame
	shell.call("_show_home")
	await get_tree().process_frame
	_check(shell.get_child_count() >= 2, "navigation shell builds its full-screen page")
	_check(_ui_is_accessible(shell), "navigation shell meets readable text, contrast, and touch-target minimums")
	var hero_previews := shell.find_children("*", "RoomItemPreview3D", true, false)
	var hero_preview: Node = null
	var meadow_background_previews: Array[Node] = []
	for candidate in hero_previews:
		if candidate.presentation_context == "hero":
			hero_preview = candidate
		elif candidate.presentation_context == "meadow_background":
			meadow_background_previews.append(candidate)
	var hero_cameras: Array[Node] = hero_preview.find_children("*", "Camera3D", true, false) if is_instance_valid(hero_preview) else []
	var hero_camera = hero_cameras[0] if not hero_cameras.is_empty() else null
	var hero_viewports: Array[Node] = hero_preview.find_children("*", "SubViewport", true, false) if is_instance_valid(hero_preview) else []
	var hero_viewport_matches_rect: bool = is_instance_valid(hero_preview) and not hero_viewports.is_empty() and hero_preview.size.y > 0.0 and absf(
		float(hero_viewports[0].size.x) / float(hero_viewports[0].size.y) - hero_preview.size.x / hero_preview.size.y
	) <= 0.02
	_check(is_instance_valid(hero_preview) and hero_preview.presentation_context == "hero" and is_instance_valid(hero_camera) and hero_camera.size <= 5.81 and hero_camera.position.x < -8.0 and absf(hero_camera.position.z) < 2.0 and hero_viewport_matches_rect, "home companion uses a closer opposite-facing side-view hero camera without viewport stretching (size=%s, position=%s, aspect_match=%s)" % [hero_camera.size if is_instance_valid(hero_camera) else -1.0, hero_camera.position if is_instance_valid(hero_camera) else Vector3.ZERO, hero_viewport_matches_rect])
	var meadow_backgrounds_animate := true
	for background_preview in meadow_background_previews:
		if not is_instance_valid(background_preview.find_child("IdleAnimator", true, false)) or background_preview.anchor_top < 0.30:
			meadow_backgrounds_animate = false
	_check(meadow_background_previews.size() == 5 and meadow_backgrounds_animate, "all other owned companions mill around on the meadow grass")
	var centered_slot := shell.find_child("TrueCenterHeaderSlot", true, false) as Control
	var home_sign := shell.find_child("HomeTitleSign", true, false) as TextureRect
	var alley_sign_button := shell.find_child("UnicornAlleyStreetSignButton", true, false) as Button
	var expected_center: float = shell.global_position.x + shell.size.x * 0.5
	var actual_center: float = centered_slot.global_position.x + centered_slot.size.x * 0.5 if is_instance_valid(centered_slot) else -1.0
	_check(is_instance_valid(centered_slot) and absf(actual_center - expected_center) <= 1.0, "navigation headers center titles on the physical screen independently of side controls (actual %.2f, expected %.2f)" % [actual_center, expected_center])
	_check(is_instance_valid(home_sign) and home_sign.texture.resource_path.ends_with("title_sign_option3_compact_v1.png"), "home meadow uses the approved illustrated Unicorn Arcade sign")
	_check(is_instance_valid(alley_sign_button) and alley_sign_button.has_node("StreetSignArt") and alley_sign_button.text == "UNICORN ALLEY", "home uses an accessible illustrated Unicorn Alley street-sign action")
	shell.call("_show_dashboard")
	await get_tree().process_frame
	_check(shell.find_children("CategoryIcon", "ArcadePictogram", true, false).size() == 4, "all four game-category cards restore polished pictogram icons")
	_check(_ui_is_accessible(shell), "icon category dashboard meets readable text, contrast, and touch-target minimums")
	shell.call("_show_category", "Word")
	await get_tree().process_frame
	var word_icons := shell.find_children("GameIcon", "ArcadePictogram", true, false)
	var word_icon_ids: Dictionary = {}
	for word_icon in word_icons:
		word_icon_ids[word_icon.icon_id] = true
	_check(word_icons.size() == 10 and word_icon_ids.size() == 10, "every Word game card has its own distinct pictogram")
	_check(_ui_is_accessible(shell), "icon game grid meets readable text, contrast, and touch-target minimums")
	remove_child(shell)
	shell.free()
	AppState.data = shell_state
	AppState.selected_game_id = original_game
	AppState.selected_category = original_category
	if failures.is_empty():
		print("GODOT_RUNTIME_INTEGRATION_OK: %d checks passed" % check_count)
		get_tree().quit(0)
	else:
		for failure in failures:
			push_error(failure)
		get_tree().quit(1)


func _exercise_first_move(game_id: String, game: Node) -> void:
	if game_id in ["sentence_sprout", "syllable_stamp", "scramble_spell", "size_line_up"]:
		var expected = game.sequence[0]
		var index: int = game.pool.find(expected)
		game.call("_choose_sequence", {"value": expected, "index": index})
		_check(game.picked.size() == 1, "%s accepts the first ordered item" % game_id)
		return
	if game_id == "letter_lift":
		game.call("_handle_letter_input", game.expected_word.left(1))
		_check(game.picked.size() == 1, "Letter Lift accepts the next exact letter")
		return
	if game_id == "sight_spark":
		game.call("_finish_sight_flash")
		game.call("_on_text_submitted", game.expected_word)
		_check(game.round_index == 1, "Sight Spark accepts the memorized word")
		return
	if game_id == "unicorn_blast":
		_check(not game.blast_words.is_empty(), "Unicorn Blast spawns an initial word")
		var word := str(game.blast_words[0]["text"])
		game.call("_handle_blast_input", word)
		_check(game.round_index == 1, "Unicorn Blast destroys an exactly typed word")
		return
	var answer := ""
	match game_id:
		"vowel_vines":
			for button in game.options.get_children():
				if str(button.text).left(1).to_lower() == str(game.current["vowel"]):
					answer = button.text
					break
		"odd_one_out":
			answer = str(game.current["odd"])
		"chain_link":
			for option in game.current["options"]:
				if Rules.is_chain_link(str(game.current["start"]), str(option)):
					answer = str(option)
					break
		_:
			answer = str(game.current.get("answer", ""))
	_check(not answer.is_empty(), "%s exposes a valid answer" % game_id)
	if game_id in ["caption_quest", "odd_one_out"]:
		var wrong := _find_wrong_choice(game_id, game, answer)
		game.call("_choose", wrong)
		_check(game.lives == 2 and game.active, "%s consumes one life without immediate failure" % game_id)
	game.call("_choose", answer)
	_check(game.round_index == 1, "%s accepts its exact correct choice" % game_id)


func _find_wrong_choice(game_id: String, game: Node, answer: String) -> String:
	if game_id == "caption_quest":
		for option in game.current["options"]:
			if str(option) != answer:
				return str(option)
	else:
		for item in game.current["items"]:
			if str(item["label"]) != answer:
				return str(item["label"])
	return "__wrong__"


func _skeletons_are_in_rest_pose(node: Node) -> bool:
	var skeletons: Array[Node] = node.find_children("*", "Skeleton3D", true, false)
	if node is Skeleton3D:
		skeletons.push_front(node)
	if skeletons.is_empty():
		return false
	for skeleton_node in skeletons:
		var skeleton := skeleton_node as Skeleton3D
		for bone_index in skeleton.get_bone_count():
			if not skeleton.get_bone_pose(bone_index).is_equal_approx(skeleton.get_bone_rest(bone_index)):
				return false
	return true


func _check(condition: bool, message: String) -> void:
	check_count += 1
	if not condition:
		failures.append(message)


func _ui_is_accessible(root: Node) -> bool:
	var issues: Array[String] = []
	_collect_ui_issues(root, issues)
	if not issues.is_empty():
		push_warning("UI accessibility issues: %s" % "; ".join(issues.slice(0, 8)))
	return issues.is_empty()


func _collect_ui_issues(node: Node, issues: Array[String]) -> void:
	if node is Control and (node as Control).is_visible_in_tree():
		var control := node as Control
		if control is Label and not (control as Label).text.strip_edges().is_empty():
			if control.get_theme_font_size("font_size") < 19:
				issues.append("small label %s" % control.name)
			if control.get_theme_constant("outline_size") < 2:
				issues.append("low-contrast label %s" % control.name)
		if control is BaseButton:
			if control.custom_minimum_size.y < 56.0:
				issues.append("short touch target %s" % control.name)
			if control.get_theme_font_size("font_size") < 18:
				issues.append("small button text %s" % control.name)
		if control is LineEdit or control is TextEdit:
			if control.custom_minimum_size.y < 56.0 or control.get_theme_font_size("font_size") < 19:
				issues.append("small text input %s" % control.name)
	for child in node.get_children():
		_collect_ui_issues(child, issues)
