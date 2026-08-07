# Unicorn Arcade 0.9.0 Alpha

Android arm64 playtest build.

## What changed

- Rebuilds the decor marketplace as production card art with framed 3D previews, rarity treatments, readable inventory counts, horizontal category chips, search, and large full-width purchase actions.
- Replaces the repeated category placeholders with item-specific 3D silhouettes across beds, rugs, tables, lighting, pets, toys, electronics, seasonal decor, kitchen pieces, nature items, luxury decor, wall art, and cozy objects.
- Replaces Coin Count's four text boxes with illustrated penny, nickel, dime, and quarter controls using recognizable materials, faces, rim detail, and true relative sizes.
- Preserves Coin Count's exact target, overshoot, reward, and level behavior while retaining large accessible touch targets.
- Leaves the companion/unicorn model pipeline unchanged so the separate character-model revision can continue independently.

## Install

Install `UnicornArcade-0.9.0-alpha-arm64.apk` on an arm64 Android device. It uses package ID `com.guettler.unicornarcade`, version code 15, and the established upgrade-compatible playtest signer, so it installs over earlier alpha builds while retaining save data.

Signing certificate SHA-256: `97dcac80c34ab36c9b1e0da8cef5dc87c14911ffdb26d30aa0bc039f1e8be42b`

APK SHA-256: `f4eeb712f89268133ac491dea90cb9582d25738285f6f5a54d28813c7c427150`

## Verification

- 77 deterministic gameplay/parity checks passed.
- 145 runtime, interaction, modeled-decor, accessibility, and UI checks passed.
- Coin Count, the full decor catalog, and the modeled Beds category were visually reviewed at 574 x 1280.
