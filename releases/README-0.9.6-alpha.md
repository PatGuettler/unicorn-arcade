# Unicorn Arcade 0.9.6 Alpha

Android arm64 playtest build.

## What changed

- Gives Home its own padded camera framing so the selected companion's complete head and feet remain visible.
- Holds Home and Marketplace models in each rig's neutral rest pose instead of freezing the first Walk gait frame, correcting the distorted-looking front legs.
- Adds extra Marketplace clearance around horns, hooves, tails, and Mystic's wings while retaining the uniform 3x display scale.
- Retains the Walk-only animation contract during actual travel; additional animations remain intentionally deferred.

## Install

Install `UnicornArcade-0.9.6-alpha-arm64.apk` on an arm64 Android device. It uses package ID `com.guettler.unicornarcade`, version code 21, and the established upgrade-compatible playtest signer.

APK size: 381,395,440 bytes (363.73 MiB)

Signing certificate SHA-256: `97dcac80c34ab36c9b1e0da8cef5dc87c14911ffdb26d30aa0bc039f1e8be42b`

APK SHA-256: `c9e30a54a1b7ddab509620bf50cb381a4a444eb8b9e1c3a5c238d9b4bbafd4ee`

## Verification

- 77 deterministic gameplay/import checks passed.
- 165 runtime and interaction checks passed, including exact 3x display scale, head-first travel, neutral rest posing, and safe Home/Marketplace framing.
- Real NVIDIA Compatibility-renderer phone captures verify full model clearance in Home and all six Marketplace cards.
