# Godot art bible — Unicorn Arcade 3D

## Palette (from web app)

| Token | Hex | Use |
|-------|-----|-----|
| Night base | `#020617` | UI background, sky fill |
| Indigo room | `#1e1b4b` | Floors, alley ground |
| Pink accent | `#f472b6` | Sparkle theme, CTAs |
| Violet | `#a78bfa` | Secondary buttons, props |
| Cyan | `#22d3ee` | HUD highlights, rim light |
| Gold | `#fde68a` | Stars, rewards |

## Character (unicorns)

- Runtime low-poly procedural model shared by 6 themed variants: sparkle, rainbow, star, cloud, dream, mystic
- Model parts: capsule body, chest, neck, head, muzzle, ears, eyes, horn, four articulated-looking legs, hooves, mane, and tail
- Shader: `shaders/toon_magical.gdshader` (toon diffuse + cyan rim)
- Used consistently on the home pedestal, game arena, rooms, and Unicorn Alley
- Optional production upgrade: replace the procedural model with one shared-skeleton GLB while preserving `build_unicorn_model()` as low-tier fallback

## Sparkle vertical slice (Phase 0)

| Asset | Status | Notes |
|-------|--------|-------|
| Sparkle room floor | Complete | Sparkle texture + modular 3D walls |
| 5 props (lamp, rug, plant, chair, trophy) | Complete | Procedural category meshes mapped to catalog IDs |
| Unicorn pedestal (home) | Complete | Spinning themed 3D unicorn model |
| Alley houses | Complete | Six themed houses, 3D unicorn previews, labels, locks, and raycast triggers |

## Furniture tiers (107 items)

- **Tier A families:** multi-part beds, tables, lamps, electronics, plants, kitchen cabinets, wall art, pets/toys, luxury/unicorn pedestals
- **Tier B variants:** deterministic scale and palette variants generated from each catalog ID
- All catalog IDs resolve to a multi-part 3D prop; emoji is retained only in shop/bag UI
- External GLBs can replace individual IDs later without changing save data

## External mesh requests (for AI/DCC pipeline)

1. Rigged unicorn base mesh + 6 material variants
2. Modular cozy room kit (walls, floor trim, window) per unicorn theme
3. Hero props: `uni_fountain`, `bed_cloud`, `moon_chair`, `star_lamp`, `record_player`

## UI

- Godot `Control` theme via `scripts/ui_factory.gd`
- Minimum touch target 44px (`DisplayProfile.min_touch_size()`)
