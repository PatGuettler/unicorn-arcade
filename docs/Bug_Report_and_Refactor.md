---

name: Godot bug and refactor plan
overview: "A prioritized bug-fix and refactor plan for the Godot codebase: one shipping-blocker parse error, root causes for the three user-reported bugs (decor rotation, shop scroll, profile scroll), a set of correctness bugs including double coin rewards and save-migration data loss, and a decomposition plan to remove duplication from the 1000-line god classes."
todos:

- id: p0-galaxy-parse
content: Restore `var gameplay_paused` and `func set_gameplay_paused()` in godot/scripts/games/galaxy_unicorn.gd, restore the `_input` pause guard, and decide intentionally on the `opening_timer` value. Confirm the Galaxy scene loads and runtime_integration.gd lines 217-220 pass.
status: pending
- id: p0-stray-print
content: Delete the unreachable `print("PROFILE_PHASE settings")` at godot/scripts/main.gd line 910.
status: pending
- id: p0-ci-tests
content: Add a godot-tests CI job that runs the headless test scenes and run_tests.gd before the Android export and fails the build on non-zero exit. Add a parse-only smoke gate.
status: pending
- id: p1-rotation
content: "Fix decor rotation: re-arm the SubViewport render target in set_display_yaw(), make preview retirement await a completed frame instead of a synchronous get_image(), stop treating the upright PNG fallback as a rotated result, and apply scale changes to the live preview. Add a test asserting captured pixels differ between two yaws."
status: pending
- id: p1-shop-scroll
content: "Fix shop scrolling: remove the manual scroll_horizontal/scroll_vertical writes and set_input_as_handled() from marketplace.gd _input, keep only tap suppression, switch the vertical scrollbar off SHOW_ALWAYS, extract a shared ScrollTapGuard, and update runtime_marketplace_integration.gd which currently asserts the broken hybrid."
status: pending
- id: p1-profile-scroll
content: "Fix profile scrolling: set follow_focus=false and a scroll_deadzone in _make_vertical_scroll, set MOUSE_FILTER_PASS on chips/toggles/banner/logout, cache the ArcadePictogram StyleBoxFlat, refresh the grid in place on filter change instead of rebuilding the page, and stop growing content height mid-drag. Also fix the VISIT UNICORN ALLEY wiring and the status_label reassignment."
status: pending
- id: p2-reward-and-save
content: "Fix the data-integrity bugs: coin_count double coin reward (add active guard), legacy React import not refreshing AppState.data, unhandled save_failed with skipped pause saves, and free hints in word_game."
status: pending
- id: p2-crashes-and-races
content: "Fix crashes and races: empty-array randi_range in word_round_catalog.gd and word_game.gd, stacked outcome overlays in game_experience.gd, AdMob _sdk_initializing wedge, reentrant _update_path await in unicorn_jump.gd, and missing `active` on rhyme_rally/coin_count."
status: pending
- id: p3-run-lifecycle
content: Extract a shared LevelRunController plus HintHighlight, CategoryBackButton, and ProgressionActionButton helpers, and remove the duplicated retry/next/back/payout/hint blocks from all ten minigames. Make CompanionAbilityService.begin_level consistent across every game.
status: pending
- id: p3-split-god-classes
content: Split main.gd, room_item_preview_3d.gd, game_experience.gd, room_editor.gd, marketplace.gd, and word_game.gd into single-responsibility classes, one extraction per commit with tests green in between.
status: pending
- id: p3-dedupe-ui-and-domain
content: Consolidate the three header implementations, coin displays, and four palette copies onto UnicornHeader/StorybookUI. Merge cash_counter with coin_count, extract MathProblemGenerator, point rhyme_rally at WordGameRules.selection_window, and switch global RNG calls to seeded RNG.
status: pending
- id: p3-perf-and-dead-code
content: Retain the evidence-backed PR30 performance passes and remove only the PR31 candidates proven dead by the project-aware audit; preserve emitted public signals and live presentation paths.
status: completed
isProject: false

---

even

# Godot bug and refactor plan

Audit of 72 GDScript files / ~16k lines in `godot/`. Findings are ordered so each phase is independently shippable and verifiable. Phase 0 must land before anything else, because the game does not currently run.

## PR31 implementation status (2026-08-10)

The dead-code portion of Phase 3.6 is complete using a fresh repository-wide source/scene/string-call audit. Only candidates with no live reference or behavior were removed:

- **Confirmed and fixed:** deleted `furniture_art.gd` and its UID; removed `main._show_home_status`, Marketplace's never-emitted `scene_change_ready`, Unicorn Jump's `_signed`, Coin Count's unused `target_bounds`, Word Game's unused `PANEL`, and Galaxy's hidden `LegacyGalaxyHUD` field, builder, update helper, and calls.
- **Confirmed distinction:** Cash Counter's `target_bounds` remains because `_start_round_with_lifecycle` calls it. The refactor integration assertion now checks both halves of this contract.
- **Rejected removals:** retained the live Mathtris HUD; Main's declared/returned/emitted `scene_change_ready`; the `room_selected` capture presentation; AppState's emitted `state_changed`; emitted preview, loader, and companion-ability signals; and Word Game's constructed, configured, and mounted `title_label`. The earlier claim that `title_label` was absent/dead was stale.
- **Deferred:** Android build/device-pipeline validation belongs to PR32 and remains pending. PR31 changes no Android plugin, export, or packaging behavior.

`dead_code_audit_pr31.tscn` is a project-aware regression gate for every removed and retained candidate and is explicitly wired into `scripts/ci/godot-tests.sh`. The parser, audit, affected runtime suites, parity, and complete bounded manifest all pass through the project-local Godot 4.7.1 wrapper with no surviving task process.

Rendered evidence used exact-HEAD source restoration for the baseline (`galaxy_unicorn.gd` `a12c7b6…`, `word_game.gd` `08c0b4b…`, `unicorn_jump.gd` `b5db41c…`). Opposite Orbit is byte-identical before/after at 450x1280 (`53228102…ECB6D`) and 720x1280 (`A75DDE0C…61BE2`). Galaxy renders at both sizes were inspected and are behaviorally/layout-clean; independent-process hashes differ because its visible star field directly uses `Time.get_ticks_msec()`, so no false byte-identity claim is made. The removed Jump helper is non-visual; the existing seeded capture harness cannot restart Jump because its `_start_level` requires a level argument, so `runtime_number_suite` plus `unicorn_jump_layout_test` are the authoritative checks rather than an unsupported capture claim.

## Phase 0: Blockers, the build is broken right now



### 0.1 `galaxy_unicorn.gd` does not parse

[godot/scripts/games/galaxy_unicorn.gd](godot/scripts/games/galaxy_unicorn.gd) line 50 reads `gameplay_paused`, which is declared nowhere in the repo:

```
func _process(delta: float) -> void:
	super(delta)
	if not active or gameplay_paused or size.x < 1.0 or size.y < 1.0:
```

`var gameplay_paused := false` and `func set_gameplay_paused()` were both deleted in commit `1675c56`, but the usage came back through a merge. In GDScript 2 an undeclared identifier is a hard parse error, so the Galaxy Unicorn scene fails to load entirely.

Two related breakages follow from the same missing method:

- [godot/autoload/game_experience.gd](godot/autoload/game_experience.gd) lines 845-850 guard on `has_method("set_gameplay_paused")`, so tutorial pause silently never happens.
- [godot/tests/runtime_integration.gd](godot/tests/runtime_integration.gd) lines 217-220 call `set_gameplay_paused` directly, so the integration suite fails.

Fix: restore both members on the game script.

```gdscript
var gameplay_paused := false

func set_gameplay_paused(paused: bool) -> void:
	gameplay_paused = paused
```

Also restore the `_input` guard (`if not active or gameplay_paused:`) so paused tutorials do not accept fire input, and decide intentionally whether `opening_timer` returns to `1500.0` (it was lowered to `0.0` in `1675c56`, which removes the delay that let the first tutorial overlay mount before the wave moves).

### 0.2 Debug statement left in the shell

[godot/scripts/main.gd](godot/scripts/main.gd) line 910 is `print("PROFILE_PHASE settings")`, tab-indented after `return container`, so it is unreachable code trailing `_build_companion_preview`. Delete it.

### 0.3 Nothing runs the Godot test suite

There are 16 test scripts and 14 test scenes in `godot/tests/`, and CI never executes any of them. [.github/workflows/deploy-android.yml](.github/workflows/deploy-android.yml) only ever calls `godot --import` and `godot --export-*`. That gap is precisely why 0.1 reached `main`.

Add a `godot-tests` job that runs before the Android export and fails the build on a non-zero exit, invoking the existing headless entry points, which already `quit(0)` / `quit(1)` and print markers such as `GODOT_PARITY_TESTS_OK`:

- `godot --headless --path godot res://tests/runtime_integration.tscn`
- the same for `runtime_main_shell_integration`, `runtime_marketplace_integration`, `runtime_profile_integration`, `runtime_refactor_integration`, `ad_layout_integration`, `sliding_window_scope_test`, `unicorn_header_scope_test`, `unicorn_jump_layout_test`
- `run_tests.gd` for the parity checks

A parse-only smoke gate is worth adding too, since it would have caught 0.1 in seconds.

## Phase 1: The three reported bugs



### 1.1 Decor rotation in Unicorn Alley

Root cause is render-target lifetime, not rotation math or persistence. In [godot/scripts/meta/room_item_preview_3d.gd](godot/scripts/meta/room_item_preview_3d.gd) line 65, furniture previews are created with `UPDATE_ONCE`:

```gdscript
viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if animate_character else SubViewport.UPDATE_ONCE
```

`set_display_yaw()` at lines 81-84 rotates `display_rotation_root` but never re-arms the viewport, so the `SubViewportContainer` keeps displaying the first frame. The 3D scene rotates and the pixels do not.

The second half of the bug is capture timing. [godot/scripts/meta/room_editor.gd](godot/scripts/meta/room_editor.gd) line 498 snapshots synchronously:

```gdscript
frozen = DecorPreviewCache.cache_visible_image(definition, float(item.get("rotation", 0.0)), viewport.get_texture().get_image())
```

There is no wait for `frame_post_draw`, unlike [godot/autoload/decor_preview_cache.gd](godot/autoload/decor_preview_cache.gd) lines 112-118 which waits up to 12 frames. So deselecting freezes a stale or blank image, and on a transparent readback the editor keeps the previous texture, which can show the wrong angle while the saved data is correct.

Fixes:

- Re-arm the render target inside `set_display_yaw()` (set `UPDATE_ONCE` again, or hold `UPDATE_ALWAYS` while an item is selected and drop back on deselect).
- Make retirement await a completed frame, or drop the direct readback and let `DecorPreviewCache.request()` bake at the saved yaw.
- Do not treat the upright PNG fallback ([room_editor.gd](godot/scripts/meta/room_editor.gd) line 841) as a rotated result; it is the reason rugs and wall art look like rotation is ignored.
- `SMALLER` / `LARGER` at lines 613-614 resize the button but never the live 3D preview. Add a scale path, and consider including scale in `cache_key` ([decor_preview_cache.gd](godot/autoload/decor_preview_cache.gd) lines 36-37), which currently keys on id plus 45-degree yaw only.

Persistence is fine: `rotation` round-trips correctly through `RoomRules.normalized`, `AppState.place_room_item`, and `SaveService`. Tests pass today because they assert `DisplayRotationRoot.rotation_degrees.y` rather than rendered pixels, so add a test that asserts the captured image actually changes between two yaws.

### 1.2 Shop scrolling is buggy and laggy

[godot/scripts/meta/marketplace.gd](godot/scripts/meta/marketplace.gd) lines 428-470 reimplement scrolling that `ScrollContainer` already performs, so two systems move the same list on the same touches:

```gdscript
category_scroll.scroll_horizontal = clampi(_category_scroll_start - int(round(delta.x)), 0, maximum)
get_viewport().set_input_as_handled()
```

Before the deadzone flips `catalog_dragging` true the container also scrolls, and afterwards the manual assignment fights whatever the container applied. That is the jitter.

The correct pattern already exists in this repo. [room_editor.gd](godot/scripts/meta/room_editor.gd) lines 147-148 observe the gesture only, to suppress an accidental tap, and let the container own movement:

```
# ScrollContainer owns physical movement. This only identifies a completed
# swipe so the touched chip or bag item cannot immediately activate.
```

Fixes:

- Delete the manual `scroll_horizontal` / `scroll_vertical` writes and the `set_input_as_handled()` calls; keep only the suppression flags (`_catalog_suppress_until_ms`, `_category_suppress_until_ms`).
- Update [godot/tests/runtime_marketplace_integration.gd](godot/tests/runtime_marketplace_integration.gd) lines 62-73 and 97-108, which currently call `_input` directly and therefore lock in the broken hybrid.
- Change `SCROLL_MODE_SHOW_ALWAYS` (line 101) to auto to stop per-frame scrollbar layout.
- Extract the suppression logic into one shared `ScrollTapGuard` used by both the shop and the furniture bag.

Worth noting for expectation-setting: the shop has zero 3D SubViewports. Companion and decor art are static PNGs, so the lag is input and layout, not GPU.

### 1.3 Profile scrolling is buggy and laggy

Several compounding causes, all in [main.gd](godot/scripts/main.gd):

- `_make_vertical_scroll` (lines 656-670) sets neither `follow_focus = false` nor `scroll_deadzone`. Focus changes yank the list. The shop sets both.
- Interactive controls inside the scroll keep the `BaseButton` default `MOUSE_FILTER_STOP`: filter chips (lines 535-548), settings toggles (619-626), banner (481-483), logout (416-421). A drag starting on any of them is swallowed instead of scrolling. Set `MOUSE_FILTER_PASS`.
- Every visible game tile hosts an `ArcadePictogram`, and [godot/scripts/ui/arcade_pictogram.gd](godot/scripts/ui/arcade_pictogram.gd) lines 30-38 allocate a fresh `StyleBoxFlat` on every `_draw()`, with `NOTIFICATION_RESIZED` triggering redraws during scroll. With the All filter that is 22 tiles. Cache the stylebox.
- Tapping a filter chip calls `_show_profile()`, which runs the full `_reset_page()` teardown and rebuild (lines 61-122, 376-378). Refresh the grid in place instead.
- `_populate_profile` (lines 394-428) adds sections across frames via `call_deferred` and `await`, so content height grows underneath an in-progress drag.

Two unrelated bugs in the same view: "VISIT UNICORN ALLEY" at lines 481-482 is wired to `_show_dashboard()`, and `_build_profile_settings` reassigns the shared `status_label` at lines 641-644.

## Phase 2: Correctness bugs

Highest impact first.

- **Double coin rewards.** [coin_count.gd](godot/scripts/games/coin_count.gd) lines 53-60 has no `active` guard, so two fast taps that both hit the target each call `AppState.complete_level`. [cash_counter.gd](godot/scripts/games/cash_counter.gd) line 67 sets `active = false` first; copy that.
- **Save migration data loss.** [godot/autoload/legacy_react_import.gd](godot/autoload/legacy_react_import.gd) lines 57-58 call `SaveService.select_profile()`, which updates the envelope on disk but never refreshes `AppState.data`, already loaded in `_ready()` from the pre-import state. A migrating Android user can hold a default in-memory profile over a valid save. Emit a signal and have `AppState` reload.
- **Silent save failure.** [app_state.gd](godot/autoload/app_state.gd) lines 275-280 emit `save_failed`, which has no listeners anywhere, and still emit success signals so the UI looks persisted. Also `has_active_profile()` gating means pause and focus-out saves are skipped when `_active_key` and `last_user` diverge.
- **Crash on empty word data.** `randi_range(0, size - 1)` with an empty array crashes: [word_round_catalog.gd](godot/scripts/games/word_round_catalog.gd) line 23 and [word_game.gd](godot/scripts/games/word_game.gd) lines 506-507. Guard both.
- **Hints are free.** [word_game.gd](godot/scripts/games/word_game.gd) line 709 shows `"HINT  ★5"` but never calls `AppState.spend_hint(level)`, unlike `math_swipe.gd` line 235.
- **Stacked outcome overlays.** [game_experience.gd](godot/autoload/game_experience.gd) handles run-end in both `_process` (66-70) and `_on_run_activity_changed` (154-159), each deferring without a shared guard, and the two paths disagree on retry conditions.
- **AdMob init can wedge.** [ad_bar_service.gd](godot/autoload/ad_bar_service.gd) sets `_sdk_initializing = true` at line 146 and only clears it in the completion listener (177-178). If the native plugin is missing, banner recovery is dead for the session. Add a timeout.
- **Reentrant await.** [unicorn_jump.gd](godot/scripts/games/unicorn_jump.gd) lines 245-282 make `_update_path()` async while three call sites can overlap it, racing camera focus against a running `_animate_jump`.
- **Missing run state.** `rhyme_rally.gd` and `coin_count.gd` declare no `active`, so `ArcadeGameController.runtime_snapshot()` falls back to `active: true` ([arcade_game_controller.gd](godot/scripts/games/arcade_game_controller.gd) line 28) and the shell believes a finished run is live.
- **Smaller items:** `mathtris.gd` `_seed_bottom_pile` (126-135) can exit after 60 attempts with matches already on the board; `comet_math_rescue.gd` (115-116) resolves a timeout as a wrong answer using the default lane; `unicorn_jump.gd` line 121 shows a 0-based stone number in kid-facing text while tooltips are 1-based; `accessible_ui.gd` and `safe_area.gd` never prune their `applied` maps.



## Phase 3: Refactor for single responsibility

Do this only after Phases 0-2 are green, and land each extraction as its own commit with tests passing in between.

### 3.1 Shared minigame run lifecycle

All ten games extend `ArcadeGameController`, but it only publishes snapshots; every game reimplements the run flow. Verbatim-duplicated blocks:

- `can_retry_failure` / `retry_failure` gating on `action_button.text == "Retry"` is copy-pasted in `sliding_window.gd` (141-147), `unicorn_jump.gd` (147-153), `comet_math_rescue.gd` (245-251), and more.
- The next-or-retry lambda `_start_level(level + 1 if action_button.text == "Next Level" else level)` appears in at least five games.
- The back-to-category block (`AppState.set_shell_destination` then `change_scene_to_file("res://scenes/main.tscn")`) appears in eight or more games.
- The win payout block calling `AppState.complete_level` plus message and coin label appears in nine games.
- Gold `modulate` hint highlighting appears in four games.
- `CompanionAbilityService.begin_level` is called by five games and missing from `math_swipe`, `cash_counter`, `coin_count`, `rhyme_rally`, and `word_game`, which is a real behavior inconsistency, not just duplication.

Promote into the base class or small helpers: a `LevelRunController` owning `active` / `started_ms` / end state / `finish_level()` / retry and next-level wiring / `begin_level`, plus `HintHighlight`, `CategoryBackButton`, and `ProgressionActionButton`.

### 3.2 Split the god classes

Every one of these mixes construction, domain logic, and input handling:

- [main.gd](godot/scripts/main.gd), 910 lines: split into `MainShellRouter` (routing, `_reset_page`, scene change), `ProfileViewBuilder`, `GameCatalogUI` (`_make_game_card`, `_make_category_card`), and `MainLoginView`. Long methods: `_show_login` (160-244), `_add_header` (685-759), `_show_home` (245-311), `_reset_page` (61-122).
- [room_item_preview_3d.gd](godot/scripts/meta/room_item_preview_3d.gd), 1046 lines: split into `DecorPreviewViewport` (render-target lifetime, which is where the 1.1 fix belongs), `ProceduralFurnitureBuilder`, `AuthoredFurnitureLoader`, and `CompanionPreviewBuilder`, leaving a thin facade. `_build_seasonal` is 85 lines, `_build_pet` 75.
- [game_experience.gd](godot/autoload/game_experience.gd), 1027 lines: an autoload that also builds chrome, tutorials, profile overlays, and outcome modals. Extract the presentation layers so the singleton only orchestrates.
- [room_editor.gd](godot/scripts/meta/room_editor.gd), 1003 lines: `_show_bag` alone is 120 lines (660-780). Extract a `FurnitureBagOverlay` class.
- [marketplace.gd](godot/scripts/meta/marketplace.gd): split view construction from `MarketplaceCatalogController`.
- `word_game.gd` (718 lines) drives 15 game IDs from one script, with `_build_ui` spanning 594-718. Split per mode behind a common interface.



### 3.3 Deduplicate shared UI

`_anchor_rect` and the compact-header-button helper exist in both [marketplace.gd](godot/scripts/meta/marketplace.gd) (553-577) and [godot/scripts/ui/unicorn_header.gd](godot/scripts/ui/unicorn_header.gd) (137-159). Three separate header implementations exist (`marketplace._build_header`, `UnicornHeader.build`, `main._add_header`), along with three coin displays and four copies of the color palette constants across `main.gd`, `marketplace.gd`, `unicorn_alley.gd`, and `room_editor.gd`. Consolidate on `UnicornHeader` plus a shared palette in `StorybookUI`.

### 3.4 Merge duplicated domain logic

- `cash_counter.gd` and `coin_count.gd` are the same game over different denominations; `coin_count.gd` even defines an unused `target_bounds()` (19-25) while inlining the ranges at 36-41.
- Three separate math problem generators: `comet_math_rescue.gd` (45-92), `math_swipe.gd` (37-91), `gameplay_rules.gd` (121-132). Extract `MathProblemGenerator`.
- `rhyme_rally.gd` (64-66) reimplements `WordGameRules.selection_window`; call the existing helper.
- `rhyme_rally.gd` and `galaxy_unicorn.gd` use global `randf()` / `randi_range()` instead of the seeded RNG the other games use, which makes bug reports unreproducible.



### 3.5 Performance passes

- `mathtris.gd` `_refresh` (612-627) allocates a new `StyleBoxFlat` per cell per call; reuse them.
- `galaxy_unicorn.gd` allocates via `bullets.filter` / `enemies.filter` every frame (153-156, 186, 208) and redraws 48 stars plus all entities.
- `word_game.gd` (67-68) formats a timer string every frame; `comet_math_rescue.gd` re-lays out lane buttons every frame.
- `game_experience.gd` `_process` runs for the whole app lifetime including the main menu, and its `_has_property` helper walks `get_property_list()` on a hot path (401-405).
- `accessible_ui.gd` and `safe_area.gd` both hook `get_tree().node_added` globally, so every node added during a page rebuild pays a deferred callback.



### 3.6 Dead code removal

Confirmed unreferenced across `godot/` including scenes and string-based calls: `FurnitureArt` entirely ([furniture_art.gd](godot/scripts/meta/furniture_art.gd), 349 lines, only a `class_name`); `main._show_home_status` (312-314); `marketplace.scene_change_ready` (never emitted); the `preview_ready`, `packed_scene_loaded`, `packed_scene_failed`, `ability_changed`, `ability_activated`, and `state_changed` signals (emitted, never connected); `unicorn_jump._signed` (504-506); `coin_count.target_bounds` (19-25); `word_game.PANEL` and `title_label`; the hidden `LegacyGalaxyHUD` label (365-369); and the `presentation: "room_selected"` value that `room_item_preview_3d.gd` never reads.

## Verification

For each phase: run the headless suites from 0.3 locally, then confirm the same job passes in CI. Phase 1 needs manual device checks that automated tests cannot cover: rotate a decor item through all eight angles and confirm the visual matches after deselect and after leaving and re-entering the room; drag-scroll the shop catalog and the category chip strip; drag-scroll the profile starting the gesture on a filter chip and on a settings toggle.

## Note on provenance

The Phase 0.1 breakage was introduced by my own conflict resolution earlier in this session. When merging `codex/godot-performance-maintainability` into `main` I kept that branch's `super(delta)` and `gameplay_paused` guard, without noticing `main` had deleted the declaration in `1675c56`. Fix it first.

## PR32 Android delivery verification (2026-08-10)

The Android build-template cache now requires an exact `4.7.1.stable` marker: a missing or stale marker forces a fresh template extract rather than reusing a structurally valid but incompatible cache. CI has no fallback cache key for that directory. Local PR32 evidence is recorded in `docs/android-build-evidence-pr32.md`: signed release AAB and debug APK built at version 32 / 1.32, and the debug package was installed in place on the authorized Pixel 9 Pro without clearing data.
