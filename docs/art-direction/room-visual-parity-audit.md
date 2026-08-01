# Room and Alley visual parity audit

Date: 2026-07-31

## Verdict

The Godot metagame currently has functional data and interactions, but it does
not preserve the visual experience of the React original. The Alley and room
editor are graybox UI, not presentation-complete ports.

## Direct comparison

| Area | React original | Current Godot port | Material gap |
| --- | --- | --- | --- |
| Unicorn Alley | `unicornAlleyMap.jpeg`: an 800x1200 illustrated street with six spatial house hotspots | A two-column grid of six large text buttons on a navy field | The location, house fantasy, map exploration, and visual ownership cues are absent |
| Room backdrop | A companion-specific illustrated interior for every unicorn | Two flat rectangles representing wall and floor | All room identity, perspective, windows, architectural detail, material, and atmosphere are absent |
| Sparkle room | 480x519 isometric floral room shell with wood floor and windows | Flat maroon wall over a blue floor | Isometric dollhouse feel is absent |
| Rainbow room | 1536x1024 cloud-and-rainbow bedroom with windows and rainbow curtains | Same generic flat room with only a color change | Companion theme is absent |
| Star room | 1024x1024 galaxy bedroom with illuminated canopy and nebula rug | Same generic flat room | Lighting and celestial theme are absent |
| Cloud room | 1024x1024 pastel cloud-and-star room with arched window and cloud rug | Same generic flat room | Soft airborne/cloud identity is absent |
| Dreamer room | 1024x1024 midnight celestial library with gold trim | Same generic flat room | Library, night lighting, and dream theme are absent |
| Mystic room | 1536x1024 crystal observatory with stained glass and luminous floor sigil | Same generic flat room | Crystal architecture and magical illumination are absent |
| Furniture | Recognizable emoji/object art at the placement point with drop shadow | Rounded buttons containing truncated names such as `LAVA`, `FLUFFY`, and `MAGIC` | Objects do not look like furniture or belong in the room perspective |
| Selection tools | Compact contextual toolbar floats above the selected object | Six permanent text controls live below the canvas | Editing is spatially disconnected from the selected item and consumes phone height |
| Furniture bag | Floating circular briefcase opens a 65%-height bottom drawer with icon grid and categories | Full-width text button replaces the room with a list | The original toy-box interaction and visual inventory are absent |
| Companion gift | Unicorn avatar appears as a placeable visual object | Generic labeled rectangle | Character ownership is not visible in the room |

## Source evidence

- Alley: `src/components/unicornAlley/unicornAlleyMap.jpeg`
- Room backgrounds: `src/components/assets/*Room.png`
- Original layout and overlays: `src/components/unicornAlley/unicornAlleyView.jsx` and `roomView.jsx`
- Current implementation: `godot/scripts/meta/unicorn_alley.gd` and `room_editor.gd`
- Current captures: `previews/hotfix_v0_4_2/alley_tall.png` and `previews/hotfix_v0_4_1/room_tall.png`

## Required visual-parity work

1. Replace the button grid with a newly illustrated portrait Alley map and six
   invisible/outlined house hotspots in the original positions.
2. Create six new, companion-specific room backgrounds with one consistent
   camera and aspect ratio, while retaining the themes and placement affordance
   of the originals.
3. Replace furniture name buttons with new object sprites or coherent icon art;
   preserve placement coordinates and z-ordering over the room image.
4. Move editing actions into a contextual selected-item toolbar and restore the
   floating bag plus bottom-drawer inventory.
5. Validate each room at the reported 574x1280 phone ratio with placed items at
   wall, floor, edge, rotated, scaled, and layered positions.

At the time of this audit, the old room and Alley images were treated as
comparison references while a fully new graphic set was the intended direction.

## 0.5.0 implementation note

The user subsequently authorized using the original room and Alley artwork.
Checkpoint 0.5.0 therefore restores those seven source illustrations directly
for immediate parity. The login/Home meadow is newly authored. Furniture object
sprites, companion gift art, contextual item controls, and the visual bag drawer
remain open from the comparison above.
