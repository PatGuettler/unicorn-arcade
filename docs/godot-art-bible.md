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

- Low–mid poly (5k–15k tris target)
- Shared skeleton across 6 skins: sparkle, rainbow, star, cloud, dream, mystic
- Shader: `shaders/toon_magical.gdshader` (toon diffuse + cyan rim)
- Placeholder: colored `BoxMesh` / capsule in alley until rigged GLB lands

## Sparkle vertical slice (Phase 0)

| Asset | Status | Notes |
|-------|--------|-------|
| Sparkle room floor | Placeholder | Indigo plane in `room_editor_3d.tscn` |
| 5 props (lamp, rug, plant, chair, trophy) | Placeholder boxes | Tint violet; map to catalog IDs |
| Unicorn pedestal (home) | Emoji label | Replace with rig + idle anim |
| Alley houses | 1.2m cubes | Pink if owned, slate if locked |

## Furniture tiers (107 items)

- **Tier A (30):** unique meshes — beds, rugs, fountain, moon chair
- **Tier B (77):** kitbash scale/tint variants
- Catalog emoji → `itemId` → mesh or primitive fallback (current)

## External mesh requests (for AI/DCC pipeline)

1. Rigged unicorn base mesh + 6 material variants
2. Modular cozy room kit (walls, floor trim, window) per unicorn theme
3. Hero props: `uni_fountain`, `bed_cloud`, `moon_chair`, `star_lamp`, `record_player`

## UI

- Godot `Control` theme via `scripts/ui_factory.gd`
- Minimum touch target 44px (`DisplayProfile.min_touch_size()`)
