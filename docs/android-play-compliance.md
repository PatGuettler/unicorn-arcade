# Android and Google Play (Capacitor → Godot)

## Current stack (until Godot cutover)

Production builds are usually done via GitHub Actions (`.github/workflows/deploy-android.yml`), not Android Studio. The workflow installs **Android SDK 36** and runs `./gradlew bundleRelease` with `targetSdk` / `compileSdk` from [`variables.gradle`](android/variables.gradle).

## Target API and versioning

| Setting | Value | File |
|---------|--------|------|
| `targetSdk` / `compileSdk` | **36** (Android 16) | [`variables.gradle`](variables.gradle) |
| `minSdk` | **24** (Android 7.0) | [`variables.gradle`](variables.gradle) |
| User-visible version | **2.0.0** | [`version.properties`](version.properties) → `versionName` |
| Internal version code | CI: `github.run_number`; local: `VERSION_CODE` in `version.properties` | [`app/build.gradle`](app/build.gradle) |

Google Play policy ([target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878)): new updates must target **API 36+** from **August 31, 2026**. This project is configured for that bar.

After each release, bump `VERSION_NAME` in `version.properties` (semver). **Never** ship a lower `versionCode` than a previous Play upload.

## Display name

Launcher label: **Unicorn Arcade** ([`strings.xml`](app/src/main/res/values/strings.xml)). Package ID stays **`com.grapegames.wlarcade`**.

## When Godot replaces Capacitor (cleanup checklist)

**Do not delete `android/` until the Godot AAB is tested and ready to replace the WebView app.** At cutover, remove Capacitor-specific pieces:

- Directory: `android/` (entire Capacitor shell)
- npm: `@capacitor/*`, `@capacitor/cli`, `capacitor.config.json`
- Scripts/docs referencing `cap sync`, `cap open android`
- Workflow [`.github/workflows/deploy-android.yml`](../.github/workflows/deploy-android.yml) → replace with Godot headless export (same signing secrets, same `com.grapegames.wlarcade`)

**Keep:**

- `src/` can be archived or removed only after Godot parity signoff
- Playwright e2e for the web app optional until web is retired
- Godot project under `godot/` with its own `export_presets.cfg` (also target API **36**)

## Godot export (future)

Mirror these values in Godot **Export → Android**: package name, `target_sdk` 36, `min_sdk` 24, version from the same semver policy.
