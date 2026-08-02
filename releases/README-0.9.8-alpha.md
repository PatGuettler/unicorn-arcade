# Unicorn Arcade 0.9.8 Alpha

Android arm64 playtest build.

## What changed

- Grounds the five background meadow unicorns in the grass while preserving the closer equipped companion.
- Moves each background unicorn and its contact shadow through one shared travel root, so the shadow follows throughout the Walk journey.
- Keeps the opposite-facing profile presentation, softer lighting, and expanded room framing introduced in 0.9.7.

## Install

Install `UnicornArcade-0.9.8-alpha-arm64.apk` on an arm64 Android device. It uses package ID `com.guettler.unicornarcade`, version code 23, and the established upgrade-compatible playtest signer.

APK size: 381,395,440 bytes (363.73 MiB)

Signing certificate SHA-256: `97dcac80c34ab36c9b1e0da8cef5dc87c14911ffdb26d30aa0bc039f1e8be42b`

APK SHA-256: `aee3951bcc797a371aa2a5d2e0955908311019d478d094e9eae17cd391185698`

## Verification

- 77 deterministic gameplay/import checks passed.
- 167 runtime and interaction checks passed, including shared movement roots for background unicorns and their contact shadows.
- Real NVIDIA Compatibility-renderer captures at the Pixel's aspect ratio verify all five background unicorns on the meadow at rest and a deterministic mid-Walk frame.
