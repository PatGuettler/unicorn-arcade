# Unicorn Arcade 0.4.1 alpha

Mobile-input and presentation hotfix for the complete Godot prototype.

## Fixed

- Galaxy Unicorn accepts Android touch and drag movement across the full playfield.
- Room decorations continue dragging after the finger leaves the item's button and commit on release.
- Tall Android screens expand to the device aspect ratio instead of showing black letterbox bars.
- Sparkle's home preview preserves its proportions and uses an eye-level front three-quarter camera.

## Validation

- Deterministic parity suite: 75 checks passed.
- Runtime integration suite: 93 checks passed, including synthetic Android drag regressions for Galaxy Unicorn and rooms.
- Real-render review at 574x1280 for home, Sparkle's room, and Galaxy Unicorn.

The Sparkle geometry is still the approved directional prototype and remains scheduled for the separate refinement pass.

## APK

- File: `UnicornArcade-0.4.1-alpha-arm64.apk`
- Package: `com.guettler.unicornarcade`
- Version: `0.4.1-alpha` (`versionCode` 5)
- Size: 31,980,542 bytes
- SHA-256: `94B1CBBAA5FE34F6DE5B3F7C61CAFD1C2A687D59DDD675282E7DC53DC86E0EEF`
- Signature: verified with APK Signature Schemes v2 and v3 (Godot debug signer)
