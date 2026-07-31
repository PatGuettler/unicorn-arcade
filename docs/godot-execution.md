# Godot migration execution

Branch: **`godot/unicorn-arcade-3d`**. Commits allowed; **do not push** until you explicitly approve cutover.

## Model routing

| Work type | Approach |
|-----------|----------|
| Godot / GDScript / architecture | Auto Intelligence or strong coding model in parent chat |
| Repo discovery | `explore` subagent |
| Icons / 2D concepts | GenerateImage or dedicated art pass |
| Pixel sprites | PixelLab MCP |
| 3D meshes | External DCC + Godot import; placeholders in-engine until ready |
| Capacitor CI / layout | Existing Playwright + `ci-investigator` if needed |

## Daily commands

```bash
npm run export:godot-data    # refresh godot/data/*.json from React sources
godot --path godot           # editor (optional)
godot --headless --path godot --import
bash scripts/install-godot-templates.sh
```

## Parity checklist

- Meta: login, home, dashboard, category, shop, profile — **UI parity**
- **Unicorn Alley 3D** (`scenes/meta/alley_3d.tscn`): six houses (Sparkle → Mystic), tap owned → room editor, locked → shop; orbit camera
- **Room editor 3D** (`room_editor_3d.tscn`): textured floor, bag / rotate / remove / snap, save placements to `SaveManager`
- Unicorn companions are procedural low-poly **3D models** with themed toon materials, horn, mane, tail, face, legs, and hooves
- **Home**: 3D pedestal with spinning equipped unicorn model
- Games: all **22** via `playable_game.tscn`; **GameFrame** owns a tappable 3D arena used for answer targets
- Number parity: exact Unicorn Jump destinations, Sliding Window maximum race, 3D coin/cash targets, missing-value Math Swipe, and falling/swap/clear Mathtris equations
- Word parity: MCQ, type-from-memory keyboard, reorder, syllable, scramble, vowel, odd-one-out, chain, cannon projectile, and companion climb mechanics
- **Space Unicorn** is a real-time 3D target shooter with moving invaders, misses, lives, level scaling, and touch/mouse raycasts
- Room editing supports mouse and touch prop dragging, one-finger orbit on empty floor, wheel/pinch zoom, snap, rotate, remove, and persistence
- All 107 furniture IDs resolve to deterministic multi-part 3D models
- 3D helpers: autoload **`World3DHelpers`** (`scripts/world3d/world_3d_helpers.gd`), toon shader `shaders/toon_magical.gdshader`
- Accessibility: generated offline SFX, sound toggle, reduced motion, and 100/115/130% text sizes
- Legacy saves: clipboard JSON import/export in Profile; see [godot-save-migration.md](godot-save-migration.md)
- Save: `user://save.json` mirrors `unicorn_arcade_v1` shape
- Play package: `com.grapegames.wlarcade`, display **Unicorn Arcade**, target SDK **36**

Validation: `godot/tests/runtime_smoke.tscn` loads every game, every meta route,
and every furniture model. Device signoff is tracked in
[godot-qa-matrix.md](godot-qa-matrix.md).

## Cutover (Phase 5)

Replace Capacitor AAB with Godot export; remove `android/` Capacitor tree only after QA signoff. See [android-play-compliance.md](android-play-compliance.md).
