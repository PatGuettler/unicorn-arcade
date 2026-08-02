# Store Item Modeling Sheets v1

These sheets are primary-angle concept inputs for generating improved 3D decor models. Each sheet uses a fixed 2-by-3 spatial layout on white with six isolated objects and no labels, borders, overlap, or shared base.

## Reconstruction and separation workflow

1. Generate one 3D scene from the complete sheet.
2. Separate the result by the six spatial grid regions, not only by loose geometry. This keeps an item's disconnected functional pieces—such as chair wheels or trophy handles—grouped together.
3. Preserve each region's UVs and materials while extracting it to an individual scene.
4. Remove any generated ground plane or reconstruction debris.
5. Recenter each item at its floor-contact origin, normalize its real game scale, repair hidden/back surfaces where necessary, and validate it in Godot.

The concept images define the primary visible design. Hidden surfaces inferred by the reconstruction service still require visual review.

## Sheet 01

File: `store_items_sheet_01.png`

| Position | Catalog ID | Item |
| --- | --- | --- |
| Top left | `lamp` | Lava Lamp |
| Top center | `rug` | Fluffy Rug |
| Top right | `plant` | Magic Plant |
| Bottom left | `chair` | Gaming Chair |
| Bottom center | `arcade` | Mini Arcade |
| Bottom right | `trophy` | Gold Trophy |

Shared direction: polished stylized 3D props, rounded mobile-game forms, cohesive pastel fantasy palette, warm gold accents, and a slightly elevated front-left three-quarter primary view.
