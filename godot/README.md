# Unicorn Arcade Godot port

This folder is the Godot 4 parity implementation. The React/Capacitor source remains in the repository as the executable behavior reference until all 22 games and metagame systems pass parity.

## Checkpoint 01

- Portrait-first responsive shell with the original dark arcade palette and pastel cyan/pink/yellow accents.
- Versioned JSON persistence with a v1 migration path.
- Exact shared economy rules: new player starts with 1,000 coins, Sparkle owned, reward `10 + level*5`, level 1 hints free, other hints cost 5.
- Registry for all 22 games.
- Playable Coin Count port with exact target bands, denominations, exact-win, and overshoot-fail behavior.
- Playable Rhyme Rally port with the original 24 challenge records, level target formula, difficulty-window selection, and one-wrong-answer failure.
- Imported `sparkle_v1.glb` with named body/head/horn/tail/leg pivots.

The Sparkle asset has passed the directional graybox gate, not the final production gate. Rigging, production UVs, final textures, and idle/celebrate animations remain open.

## Checkpoint 02

- Persistent login, home, category dashboard, game lists, and profile/settings navigation.
- Progress summaries for every registered game and a live Sparkle GLB companion viewport on the home screen.
- Playable Cash Counter with the original bill set, target bands, hint rule, exact-win behavior, and overshoot failure.
- All ten word games and all five word-mystery games are now playable. Their source datasets are mechanically extracted from the React implementation into `data/word_games.json`.
- Shared implementations preserve the original difficulty window, round target formula, Caption Quest/Odd One Out caps and lives, Sight Spark timing, Chain Link validation, ordered-tap failures, keyboard rules, and Unicorn Blast speed/spawn formulas.
- Seventeen of the 22 registered games are playable. Unicorn Jump, Sliding Window, Math Swipe, Mathtris, and Galaxy Unicorn remain.

## Checkpoint 03

- All 22 registered games are playable in Godot.
- Unicorn Jump preserves exact indexed jumps, level-scaled path generation, late negative trick jumps, scrolling, and zoom controls.
- Sliding Window preserves value bands, window growth, maximum selection, rival timing, and immediate failure rules.
- Math Swipe preserves all four difficulty bands, random missing positions, two-card answers, tap/swipe acceptance, and one-error failure.
- Galaxy Unicorn is a live drag-and-auto-fire game with the original kill targets, spawn/fire curves, enemy health/speeds, fifth-level bosses, lives, pickups, and escape/collision penalties.
- Mathtris is a live 8x14 falling-block board with the original token unlocks, time/level/drop speed ramp, concurrent waves, fixed-block swaps, five-cell equation detection, gravity, score/level rules, top-out, and all six companion power behaviors.
- The five new portrait layouts have rendered review captures under `previews/alpha_v0_3/`.

## Run

```powershell
Godot_v4.7.1-stable_win64.exe --path "E:\AI Projects\games\guettler\unicorn\godot"
```

## Validate

First let the editor import assets, then run the headless checks:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --editor --path "E:\AI Projects\games\guettler\unicorn\godot" --quit-after 180
Godot_v4.7.1-stable_win64_console.exe --headless --path "E:\AI Projects\games\guettler\unicorn\godot" --script res://tests/run_tests.gd
Godot_v4.7.1-stable_win64_console.exe --headless --path "E:\AI Projects\games\guettler\unicorn\godot" res://tests/runtime_integration.tscn --quit-after 120
```

Expected results: `GODOT_PARITY_TESTS_OK: 66 checks passed` and `GODOT_RUNTIME_INTEGRATION_OK: 79 checks passed`.

## Export the Android prototype

The checked-in `Android Alpha` preset produces a debug-signed, arm64-only APK:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path "E:\AI Projects\games\guettler\unicorn\godot" --export-debug "Android Alpha" "build/android/UnicornArcade-0.3.0-alpha-arm64.apk"
```

This checkpoint exposes the complete 22-game registry with all 22 playable ports. The companion/decor marketplace, Unicorn Alley, room editor, production audio, wider device QA, and final character/environment art remain upcoming work.
