#!/usr/bin/env bash
# Export Godot Android release (AAB) + debug APK. Run from repo root on Ubuntu CI or locally.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PROJECT="$ROOT/godot"
GODOT_VERSION="${GODOT_VERSION:-4.7.1}"
GODOT_CHANNEL="${GODOT_CHANNEL:-stable}"
GODOT_TAG="${GODOT_VERSION}-${GODOT_CHANNEL}"
EXPORT_PRESET="${EXPORT_PRESET:-Android Alpha}"
VERSION_CODE="${VERSION_CODE:-1}"

export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "${ANDROID_SDK_ROOT}" ]]; then
	echo "ANDROID_SDK_ROOT or ANDROID_HOME must be set" >&2
	exit 1
fi

configure_godot_android_paths() {
	local settings_dir="$HOME/.config/godot"
	mkdir -p "$settings_dir"
	local settings_file="$settings_dir/editor_settings-4.tres"
	local java_home="${JAVA_HOME:-}"
	if [[ -z "$java_home" ]] && command -v java >/dev/null 2>&1; then
		java_home="$(readlink -f "$(command -v java)" | sed 's|/bin/java||')"
	fi
	cat >"$settings_file" <<EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "${ANDROID_SDK_ROOT}"
export/android/java_sdk_path = "${java_home}"
EOF
}

start_adb_server() {
	local adb_bin="${ANDROID_SDK_ROOT}/platform-tools/adb"
	if [[ -x "$adb_bin" ]]; then
		"$adb_bin" start-server >/dev/null 2>&1 || true
	elif command -v adb >/dev/null 2>&1; then
		adb start-server >/dev/null 2>&1 || true
	fi
}

install_godot() {
	if command -v godot >/dev/null 2>&1; then
		return 0
	fi
	local cache="$HOME/.cache/unicorn-arcade/godot"
	mkdir -p "$cache"
	local zip="Godot_v${GODOT_TAG}_linux.x86_64.zip"
	local tpz="Godot_v${GODOT_TAG}_export_templates.tpz"
	if [[ ! -f "$cache/$zip" ]]; then
		curl -fsSL -o "$cache/$zip" \
			"https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/${zip}"
	fi
	if [[ ! -f "$cache/$tpz" ]]; then
		curl -fsSL -o "$cache/$tpz" \
			"https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/${tpz}"
	fi
	unzip -qo "$cache/$zip" -d "$cache"
	install -m 755 "$cache/Godot_v${GODOT_TAG}_linux.x86_64" "$HOME/.local/bin/godot"
	local template_dir="${GODOT_VERSION}.stable"
	if [[ -f "$PROJECT/android/.build_version" ]]; then
		template_dir="$(tr -d '\r\n' <"$PROJECT/android/.build_version")"
	fi
	mkdir -p "$HOME/.local/share/godot/export_templates/${template_dir}"
	unzip -qo "$cache/$tpz" -d "$cache/templates_unpack"
	cp -a "$cache/templates_unpack/templates/." \
		"$HOME/.local/share/godot/export_templates/${template_dir}/"
}

write_admob_config() {
	local enabled="${ADMOB_ADS_ENABLED:-true}"
	local banner="${ADMOB_BANNER_UNIT_ID:-ca-app-pub-3940256099942544/6300978111}"
	cat >"$PROJECT/config/admob.json" <<EOF
{
  "ads_enabled": ${enabled},
  "android_app_id": "ca-app-pub-2846735043546429~3696195593",
  "android_banner_unit_id": "${banner}",
  "child_directed": true,
  "tag_for_under_age_of_consent": true,
  "max_ad_content_rating": "G",
  "show_on_login": false,
  "banner_height_dp": 60
}
EOF
}

bump_version_code() {
	local preset="$PROJECT/export_presets.cfg"
	sed -i "s/^version\\/code=.*/version\\/code=${VERSION_CODE}/" "$preset"
}

export_android() {
	mkdir -p "$PROJECT/build/android"
	write_admob_config
	bump_version_code
	configure_godot_android_paths
	start_adb_server

	echo "Importing project assets (this can take several minutes on first run)..."
	godot --headless --path "$PROJECT" --import

	echo "Installing Android build template..."
	godot --headless --path "$PROJECT" --install-android-build-template 2>&1 | grep -v "cannot connect to daemon" || true

	echo "Exporting release AAB..."
	godot --headless --path "$PROJECT" --verbose \
		--export-release "$EXPORT_PRESET" "$PROJECT/build/android/UnicornArcade.aab"

	echo "Exporting debug APK (install artifact)..."
	local preset="$PROJECT/export_presets.cfg"
	sed -i 's/^gradle_build\/export_format=.*/gradle_build\/export_format=0/' "$preset"
	sed -i 's|^export_path=.*|export_path="build/android/UnicornArcade-debug.apk"|' "$preset"
	godot --headless --path "$PROJECT" --verbose \
		--export-debug "$EXPORT_PRESET" "$PROJECT/build/android/UnicornArcade-debug.apk"
	sed -i 's/^gradle_build\/export_format=.*/gradle_build\/export_format=1/' "$preset"
	sed -i 's|^export_path=.*|export_path="build/android/UnicornArcade.aab"|' "$preset"
}

install_godot
export_android
echo "Done: $PROJECT/build/android/UnicornArcade.aab"
echo "Done: $PROJECT/build/android/UnicornArcade-debug.apk"
