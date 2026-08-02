# Unicorn Arcade 0.9.7 Alpha

Android arm64 playtest build.

## What changed

- Moves the equipped unicorn lower and closer in the Home meadow as the foreground hero.
- Adds every other owned unicorn to the distant meadow, where each uses the existing timed Walk behavior to mill around.
- Changes the default presentation to a clearer opposite-facing profile view and softens the frontal lighting so textures and leg spacing read cleanly.
- Expands room companion canvases and widens their cameras proportionally, keeping the same apparent room size while preventing horn and hoof clipping.

## Install

Install `UnicornArcade-0.9.7-alpha-arm64.apk` on an arm64 Android device. It uses package ID `com.guettler.unicornarcade`, version code 22, and the established upgrade-compatible playtest signer.

APK size: 381,395,440 bytes (363.73 MiB)

Signing certificate SHA-256: `97dcac80c34ab36c9b1e0da8cef5dc87c14911ffdb26d30aa0bc039f1e8be42b`

APK SHA-256: `4f941f43250d53f51b7e54265431d064518fc69345d2641c4f3da5bb65ae8123`

## Verification

- 77 deterministic gameplay/import checks passed.
- 166 runtime and interaction checks passed, including the owned meadow ensemble, opposite-facing profile cameras, and expanded room clearance.
- Real NVIDIA Compatibility-renderer captures at the Pixel's aspect ratio verify Mystic's complete horn, the foreground hero, and all five distant owned companions.
