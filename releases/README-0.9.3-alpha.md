# Unicorn Arcade 0.9.3 Alpha

Android arm64 playtest build.

## What changed

- Expands animated companion camera framing to preserve visible space above horns and below hooves throughout authored actions.
- Shifts animated framing upward without changing the viewing angle, protecting the elevated rear-up pose while retaining ground clearance.
- Keeps Marketplace companions at their tighter static catalog framing.
- Enlarges room companion placement viewports so the additional animation buffer does not make in-room unicorns feel undersized.
- Adds capture support for inspecting exact animation progress during phone-frame QA.

## Install

Install `UnicornArcade-0.9.3-alpha-arm64.apk` on an arm64 Android device. It uses package ID `com.guettler.unicornarcade`, version code 18, and the established upgrade-compatible playtest signer.

APK size: 129,057,832 bytes (123.08 MiB)

Signing certificate SHA-256: `97dcac80c34ab36c9b1e0da8cef5dc87c14911ffdb26d30aa0bc039f1e8be42b`

APK SHA-256: `5377db3906ccb4dc47175b55f8b1ebf1fa056763e91cd16d493091c013adb4b6`

## Verification

- 77 deterministic gameplay/parity checks passed.
- 159 runtime and interaction checks passed, including the animation-safe camera and larger room viewport assertions.
- Rear-up was visually sampled at multiple points for Sparkle and at its elevated midpoint for Rainbow, Star, Cloud, Dreamer, and Mystic.
- The smaller room presentation was also reviewed at the rear-up midpoint using the actual Godot renderer at 574 x 1280.

