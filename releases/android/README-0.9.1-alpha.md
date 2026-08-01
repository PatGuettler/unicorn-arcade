# Unicorn Arcade 0.9.1 Alpha

Android arm64 playtest build.

## What changed

- Restores visual icons to the four game-category cards using polished, scalable pictograms that match the navy, pastel, and gold interface.
- Gives all 22 game cards distinct code-native pictograms instead of text-only cards or platform-dependent emoji.
- Makes the marketplace substantially easier to scroll on phones by recognizing vertical drags across the full catalog card, including action areas.
- Prevents a swipe ending over Buy or Sell from accidentally triggering a purchase.
- Pages the 107-item All catalog into 18 live 3D previews at a time, reducing the render and input load while keeping every item accessible through Show More and category filters.
- Leaves all unicorn and companion models unchanged.

## Install

Install `UnicornArcade-0.9.1-alpha-arm64.apk` on an arm64 Android device. It uses package ID `com.guettler.unicornarcade`, version code 16, and the established upgrade-compatible playtest signer.

Signing certificate SHA-256: `97dcac80c34ab36c9b1e0da8cef5dc87c14911ffdb26d30aa0bc039f1e8be42b`

APK SHA-256: `a9554e7122cf018621fd178c5041f0739c3ea023405cd9e12c524efaf8f95e36`

## Verification

- 77 deterministic gameplay/parity checks passed.
- 151 runtime, interaction, pictogram, pagination, modeled-decor, accessibility, and Android-drag checks passed.
- Game Categories, Word Games, and the paged Marketplace were visually reviewed at 574 x 1280.
