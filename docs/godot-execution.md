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

- Meta: login, home, dashboard, category, shop, profile, alley 3D, room editor — **scaffold shipped**
- Games: **Coin Count** reference; others route to stub until ported
- Save: `user://save.json` mirrors `unicorn_arcade_v1` shape
- Play package: `com.grapegames.wlarcade`, display **Unicorn Arcade**, target SDK **36**

## Cutover (Phase 5)

Replace Capacitor AAB with Godot export; remove `android/` Capacitor tree only after QA signoff. See [android-play-compliance.md](android-play-compliance.md).
