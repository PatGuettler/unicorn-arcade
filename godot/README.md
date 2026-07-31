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

## Run

```powershell
Godot_v4.7.1-stable_win64.exe --path "E:\AI Projects\games\guettler\unicorn\godot"
```

## Validate

First let the editor import assets, then run the headless checks:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --editor --path "E:\AI Projects\games\guettler\unicorn\godot" --quit-after 180
Godot_v4.7.1-stable_win64_console.exe --headless --path "E:\AI Projects\games\guettler\unicorn\godot" --script res://tests/run_tests.gd
```

Expected result: `GODOT_PARITY_TESTS_OK: 12 checks passed`.

## Export the Android prototype

The checked-in `Android Prototype` preset produces a debug-signed, arm64-only APK:

```powershell
Godot_v4.7.1-stable_win64_console.exe --headless --path "E:\AI Projects\games\guettler\unicorn\godot" --export-debug "Android Prototype" "build/android/UnicornArcade-0.1.0-prototype-arm64.apk"
```

This checkpoint exposes the complete 22-game registry, with Coin Count and Rhyme Rally playable. The other game ports remain upcoming work.
