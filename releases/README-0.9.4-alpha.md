# Unicorn Arcade 0.9.4 Alpha

Android arm64 playtest build.

## What changed

- Replaces Sparkle, Rainbow, Star, Cloud, Dream, and Mystic with the six supplied higher-detail textured models.
- Retargets the previously verified four-beat Walk to each model's own rig.
- Ships only the `Walk` clip in this checkpoint; idle, rear-up, and signature animations are intentionally deferred.
- Keeps the established out-and-back room journey, with a static first-frame Walk pose between journeys.
- Adds same-camera three-quarter and side reviews at frames 1, 7, 13, and 19 for all six companions.

## Install

Install `UnicornArcade-0.9.4-alpha-arm64.apk` on an arm64 Android device. It uses package ID `com.guettler.unicornarcade`, version code 19, and the established upgrade-compatible playtest signer.

APK size: 381,395,440 bytes (363.73 MiB)

Signing certificate SHA-256: `97dcac80c34ab36c9b1e0da8cef5dc87c14911ffdb26d30aa0bc039f1e8be42b`

APK SHA-256: `6d1039af90dc29d50979b07af7c58d79dbf7bca97899875d6672afe3138cfe61`

## Verification

- Blender round-trip validation confirms one skinned mesh, one armature, four embedded PBR textures, and exactly one `Walk` clip per model.
- 77 deterministic gameplay/import checks passed across all six textured GLBs and their Walk-only contract.
- 160 runtime and interaction checks passed, including model presentation, animation scheduling, and the complete out-and-back Walk route.
- Visual review covers both three-quarter presentation and the exact side view used for tail/hind-leg clearance diagnosis.
