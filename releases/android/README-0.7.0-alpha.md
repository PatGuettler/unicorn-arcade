# Unicorn Arcade 0.7.0 alpha

This checkpoint replaces room placeholders with live 3D content and keeps the
upgrade-compatible Android signing identity introduced in 0.6.1. It uses version
code 11 and installs directly over the working 0.5.0 or 0.6.1 build.

Certificate SHA-256: `97dcac80c34ab36c9b1e0da8cef5dc87c14911ffdb26d30aa0bc039f1e8be42b`

Included changes:

- Each owned room automatically displays its live unicorn model, with distinct companion material variants.
- The Home meadow is brighter, includes a grounded model shadow, and uses randomized idle, look, tail, bow, and step animations.
- All 107 decoration records render as lightweight 3D furniture/object families in rooms and the Furniture Bag.
- Independent 3D preview worlds prevent neighboring furniture cameras from seeing the companion or other objects.
- Unicorn Alley removes floating door labels; unlocked houses glow through their door seam and keyhole while locked doors remain shut.
- Existing room drag, rotate, resize, z-order, bag, inventory, and reset behavior remains intact.
- Galaxy Unicorn's slower level-scaled enemy pacing and global phone safe areas remain included.

Validation: 77 deterministic checks and 106 runtime integration checks pass, plus real 574 x 1280 GPU captures for Home, room, Alley, and Marketplace presentation.
