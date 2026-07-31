# Godot QA matrix — Unicorn Arcade

## Automated gates

Run before every Android artifact:

```bash
npm run export:godot-data
godot --headless --editor --path godot --quit
godot --headless --path godot res://tests/runtime_smoke.tscn
godot --headless --path godot --export-release Android build/godot/unicorn-arcade.aab
```

`runtime_smoke.tscn` opens every one of the 22 games and every meta route. Any
missing or unparsable screen fails the run.

## Device matrix

| Class | Resolution / API | Orientation | Required checks |
|---|---|---|---|
| Small Android phone | 360×800, API 24 | Portrait | Login, all buttons ≥44 px, game board scrolling |
| Current Pixel | 412×915, API 36 | Portrait | Touch raycasts, safe area, audio, clipboard save transfer |
| Samsung phone | 384×854, API 35+ | Portrait | Back gesture, Vulkan Mobile renderer, lifecycle resume |
| 8-inch tablet | 800×1280, API 30+ | Portrait + landscape | Wider grids, room orbit/drag, furniture bag |
| 10–12-inch tablet | 1200×1920, API 36 | Portrait + landscape | Alley camera, 3D model LOD/performance |

## Functional passes

- Login creates and resumes local profiles.
- Home routes independently to Play, Profile, Shop, and Unicorn Alley.
- Every category opens all configured games.
- Every game can fail, restart, complete a level, award coins, and persist its
  maximum level and completion time.
- Hint behavior: level 1 free; later levels cost five coins.
- Shop purchase decrements coins and updates owned unicorns/inventory.
- Alley opens owned rooms and sends locked houses to the shop.
- Room editor supports select, touch/mouse drag, rotate, scale, snap,
  bring-to-front, remove, inventory return, and save/reload.
- Profile sound, reduced-motion, text-size, save copy, and save import work.
- Android back never exits from a nested screen; it returns through the stack.

## Performance targets

- 60 FPS target on current phones and tablets; 30 FPS minimum on API 24 class.
- No script errors during a complete navigation pass.
- No more than six active Space Unicorn enemies.
- Only one directional shadow light per 3D viewport.
- Android release artifact contains arm64-v8a and targets API 36.

## Cutover gate

Do not remove the Capacitor Android project or publish the Godot AAB until:

1. The automated gates pass.
2. At least one Pixel/Samsung phone and one tablet pass this matrix.
3. Clipboard save export/import is verified with a real legacy save.
4. The production keystore signs the AAB and Play Console accepts an internal
   test upload under `com.grapegames.wlarcade`.
