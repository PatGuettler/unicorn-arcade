# Unicorn Arcade 0.9.2 Alpha

Android arm64 playtest build.

## What changed

- Replaces the shared prototype unicorn with six distinct authored, rigged, and textured GLBs: Sparkle, Rainbow, Star, Cloud, Dreamer, and Mystic.
- Preserves each package's four embedded clips: idle, walk, rear-up, and its companion-specific signature animation.
- Home and room unicorns now choose a random non-idle action every 10 to 30 seconds.
- Walk actions turn, travel across the stage, pivot back, return to the exact starting transform, and resume idle.
- Marketplace unicorns remain deliberately static in authored idle poses.
- Updates the shared companion camera and per-model scaling so horns, hooves, tails, and Mystic's wings remain inside phone and room frames.

## Install

Install `UnicornArcade-0.9.2-alpha-arm64.apk` on an arm64 Android device. It uses package ID `com.guettler.unicornarcade`, version code 17, and the established upgrade-compatible playtest signer.

APK size: 129,057,832 bytes (123.08 MiB)

Signing certificate SHA-256: `97dcac80c34ab36c9b1e0da8cef5dc87c14911ffdb26d30aa0bc039f1e8be42b`

APK SHA-256: `aab05ffcbfac983580eb957e6372d2459b67a5fceb92ae60dbb0abcca7483ec2`

## Verification

- 77 deterministic gameplay/parity checks passed, including all 24 embedded companion clips.
- 157 runtime and interaction checks passed, including static Marketplace models, the 10-to-30-second interval, and the full turn-walk-return route.
- All six home presentations, all six production rooms, and the complete Marketplace catalog were visually reviewed at 574 x 1280 with the actual Godot renderer.

