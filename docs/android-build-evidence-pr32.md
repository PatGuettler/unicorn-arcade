# PR32 Android build evidence

Date: 2026-08-10 (America/Chicago)

## Toolchain and cache contract

- Godot: project-local 4.7.1 (`.tools/godot-4.7.1`) through `tools/run_godot.cmd`.
- Android SDK: `.tools/pr32-android/sdk` (API 36, Build Tools 36.1.0, NDK 29.0.14206865); Gradle and Android user data stayed under `.tools/pr32-android` on `E:`.
- `scripts/ci/test-android-template-cache.sh` passed: current marker accepted; missing and stale markers rejected; the tracked marker guard passed.
- The Android template marker was `4.7.1.stable`, with a nonempty Godot AAR and `build.gradle`.

## Artifacts

| Artifact | Package | Version | ABI | Size | SHA-256 |
| --- | --- | --- | --- | ---: | --- |
| `godot/build/android/UnicornArcade.aab` | `com.grapegames.wlarcade` | 32 / 1.32 | arm64-v8a | 450,884,965 bytes | `FBA81A825DE9665142EEB7A8381F04C75E89552D4188CDAD1D7AC2B0E68ADE2B` |
| `godot/build/android/UnicornArcade-debug.apk` | `com.guettler.unicornarcade` | 32 / 1.32 | arm64-v8a | 522,083,123 bytes | `DBD27988E5D02975B6E4F3624B2E25FD4E863BE317A5EC8639663BC2D5AFF988` |

- AAB entries: 1,711; verified `base/manifest/AndroidManifest.xml` and `base/lib/arm64-v8a/libgodot_android.so`.
- APK entries: 1,700; `aapt dump badging` verified the debug package, version 32/1.32, and arm64-v8a native code.
- Release Gradle invoked `validateSigningStandardRelease` and `signStandardReleaseBundle` successfully.

## Device install

The authorized Pixel 9 Pro (`adb-45291FDAP0080L-NMUskl._adb-tls-connect._tcp`) accepted a non-destructive `adb install -r` update of the debug APK.

- `pm path com.guettler.unicornarcade`: `/data/app/.../com.guettler.unicornarcade-.../base.apk`
- `dumpsys package`: `versionCode=32`, `versionName=1.32`, `primaryCpuAbi=arm64-v8a`.

## Cleanup

`godot/export_presets.cfg` was restored exactly to HEAD after export (`ece1761e99f7f68e1880babc4364a124a25e67f4`). Task-created Gradle daemon PID 17208 was stopped after completion; no task crash/error dialog remained.

## Post-build bounded manifest

The complete non-monolithic CI manifest then passed through the project-local wrapper: bootstrap import, parser smoke, parity rules, dead-code audit, ten explicit runtime integrations, four bounded runtime suites, and five focused scope/layout scenes (23 Godot invocations). The historical `runtime_integration.tscn` aggregate was intentionally excluded. Per-scene logs and PID-survivor snapshots are under `.tools/pr32-android/logs/bounded-*`.
