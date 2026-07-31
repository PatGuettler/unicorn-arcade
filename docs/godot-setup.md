# Godot toolchain (Unicorn Arcade)

| Item | Value |
|------|--------|
| Engine | Godot **4.7** stable (`tools/godot-version.txt`) |
| Project | `godot/project.godot` |
| Package | `com.grapegames.wlarcade` |
| Display name | Unicorn Arcade |
| minSdk | 24 |
| targetSdk | 36 |

## Install export templates

Godot binary is expected on `PATH` (e.g. `/usr/local/bin/godot`).

```bash
chmod +x scripts/install-godot-templates.sh
bash scripts/install-godot-templates.sh
```

Templates install to `~/.local/share/godot/export_templates/<engine-version>/` (files like `android_debug.apk` at the top level). The `.tpz` archive contains a `templates/` folder; the install script copies those files into the versioned directory.

The full engine build string in `tools/godot-version.txt` is normalized to the
template directory Godot expects (for example, `4.7.stable`).

## Install Android SDK

```bash
chmod +x scripts/install-android-sdk.sh
bash scripts/install-android-sdk.sh
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
```

The script installs platform-tools, Android API 36, and build-tools 36.0.0.

## Verify project loads

```bash
godot --headless --path godot --import
godot --headless --path godot --quit-after 2
```

## Android export (local)

Requires `ANDROID_HOME`, JDK 17, release keystore env vars (`SIGNING_*` same as Capacitor CI).

```bash
mkdir -p build/godot
godot --headless --path godot \
  --install-android-build-template \
  --export-release "Android" \
  build/godot/unicorn-arcade.aab
```

Export preset: `godot/export_presets.cfg` (AAB via Gradle build).

`.github/workflows/build-godot-android.yml` performs the same smoke export with
an ephemeral CI keystore and uploads an artifact. It never publishes to Play.

## Data sync from React app

```bash
npm run export:godot-data
```

Sources: `src/data/godotCatalog.js`, `src/data/furnitureCatalog.js`, word list modules.
