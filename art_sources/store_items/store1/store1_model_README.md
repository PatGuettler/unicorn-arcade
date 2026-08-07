# Store Sheet 01 Model Integration

`store1_mobile.glb` is the approved image-to-3D reconstruction for concept sheet 01. It contains six named furniture mesh nodes sharing one PBR material and texture set.

## Runtime node mapping

| Catalog ID | Imported node | Item |
| --- | --- | --- |
| `lamp` | `lamp` | Lava Lamp |
| `rug` | `rug` | Fluffy Rug |
| `plant` | `plant` | Magic Plant |
| `chair` | `chair` | Gaming Chair |
| `arcade` | `arcade` | Mini Arcade |
| `trophy` | `trophy` | Gold Trophy |

The runtime extracts only the requested node, resets its sheet-layout transform, and applies item-specific presentation scale. Other catalog items retain their procedural fallback until their authored model sheets are reconstructed and integrated.

## Processing record

- User-supplied source: `store1.glb`
- Source SHA-256: `5F68D5DF80C81E30B7CEFFC73D05BAE800F5523890DCF8CFDB58B8D6ABDE16EC`
- Source structure: one mesh, 199 disconnected components, 553,596 triangles.
- Separation: six spatially isolated catalog objects; two reconstruction bridges were removed after matched-view inspection.
- Mobile output: approximately 151,000 triangles total.
- Shared base-color and normal maps: reduced from 4096 px to 2048 px.
- Shared metallic/roughness and emissive maps: reduced from 2048 px to 1024 px.
- Source reconstruction retained outside Git; the optimized Blender source, mobile GLB, processing reports, and approval contact sheet are retained here.

The model is static furniture. It does not alter or replace any unicorn character asset.
