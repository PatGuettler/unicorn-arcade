# Unicorn Arcade 0.9.5 Alpha

Android arm64 playtest build.

## What changed

- Corrects the walk journey so every supplied unicorn faces its direction of travel instead of moving backward.
- Displays all six unicorns at three times the prior in-engine model scale.
- Expands and lifts the Marketplace camera to keep enlarged horns, hooves, tails, and Mystic's wings visible.
- Retains the Walk-only animation contract from 0.9.4; additional animations remain intentionally deferred.

## Install

Install `UnicornArcade-0.9.5-alpha-arm64.apk` on an arm64 Android device. It uses package ID `com.guettler.unicornarcade`, version code 20, and the established upgrade-compatible playtest signer.

APK size: 381,395,440 bytes (363.73 MiB)

Signing certificate SHA-256: `97dcac80c34ab36c9b1e0da8cef5dc87c14911ffdb26d30aa0bc039f1e8be42b`

APK SHA-256: `042531cc0e20c1b551c32120a63c863ec85f92836f1fc429012fd00f3c1c3629`

## Verification

- 77 deterministic gameplay/import checks passed.
- 163 runtime and interaction checks passed, including exact 3x display scale, head-first travel, and safe Marketplace framing.
- Real NVIDIA Compatibility-renderer phone captures verify the enlarged room presentation and all six Marketplace cards.
