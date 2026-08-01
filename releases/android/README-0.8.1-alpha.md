# Unicorn Arcade 0.8.1 Alpha

Android arm64 playtest build.

## What changed

- Rebuilds shell headers with equal left and right rails so every title is centered on the physical screen rather than the space left after Back, Home, or coin controls.
- Places the approved ornate `UNICORN ARCADE` sign on the home meadow.
- Replaces the generic Unicorn Alley button with a production illustrated directional street sign while retaining a real accessible button and focus state.
- Adds regression checks for exact header centering and both home-sign assets.

## Install

Install `UnicornArcade-0.8.1-alpha-arm64.apk` on an arm64 Android device. It uses package ID `com.guettler.unicornarcade`, version code 14, and the established upgrade-compatible playtest signer, so it installs over 0.5.0 through 0.8.0 while retaining save data.

Signing certificate SHA-256: `97dcac80c34ab36c9b1e0da8cef5dc87c14911ffdb26d30aa0bc039f1e8be42b`

APK SHA-256: `ca275bd65e6ed6d54cf401c2c4a0d6ab22e924e1c6234ce4d0087d4ad6119c17`

## Verification

- 77 deterministic gameplay/parity checks passed.
- 140 runtime, interaction, 3D-preview, accessibility, centering, and sign checks passed.
- Home, category, and game-selection screens were visually reviewed at 574 x 1280.
