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

Templates install to `~/.local/share/godot/export_templates/<version>/`.

## Verify project loads

```bash
godot --headless --path godot --import
godot --headless --path godot --quit-after 2
```

## Android export (local)

Requires `ANDROID_HOME`, JDK 17, release keystore env vars (`SIGNING_*` same as Capacitor CI).

```bash
mkdir -p build/godot
godot --headless --path godot --export-release "Android" build/godot/unicorn-arcade.aab
```

Export preset: `godot/export_presets.cfg` (AAB via Gradle build).

## Data sync from React app

```bash
npm run export:godot-data
```

Sources: `src/data/godotCatalog.js`, `src/data/furnitureCatalog.js`, word list modules.
