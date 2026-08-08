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
RELEASE_PACKAGE_NAME="${RELEASE_PACKAGE_NAME:-com.grapegames.wlarcade}"
DEBUG_PACKAGE_NAME="${DEBUG_PACKAGE_NAME:-com.guettler.unicornarcade}"

PRESET_PATH=""
PRESET_BACKUP=""

restore_export_preset() {
	if [[ -n "$PRESET_BACKUP" && -f "$PRESET_BACKUP" && -n "$PRESET_PATH" ]]; then
		cp "$PRESET_BACKUP" "$PRESET_PATH"
		rm -f "$PRESET_BACKUP"
		git -C "$ROOT" diff --exit-code -- godot/export_presets.cfg
	fi
}

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
	local template_dir
	template_dir="$(android_export_template_dir)"
	mkdir -p "$HOME/.local/share/godot/export_templates/${template_dir}"
	unzip -qo "$cache/$tpz" -d "$cache/templates_unpack"
	cp -a "$cache/templates_unpack/templates/." \
		"$HOME/.local/share/godot/export_templates/${template_dir}/"
	[[ -s "$HOME/.local/share/godot/export_templates/${template_dir}/android_source.zip" ]] || {
		echo "ERROR: export templates missing android_source.zip under ${template_dir}" >&2
		exit 1
	}
}

write_admob_config() {
	local enabled="${ADMOB_ADS_ENABLED:-true}"
	local banner="${ADMOB_BANNER_UNIT_ID:-ca-app-pub-3940256099942544/6300978111}"
	mkdir -p "$PROJECT/config"
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

# Poing AdMob AARs live under addons/admob/android/bin (gitignored). Without them,
# Godot export skips the native plugin and device builds never show banners.
install_admob_android_binaries() {
	local plugin_version="${ADMOB_PLUGIN_VERSION:-v5.0.0}"
	local godot_tag="v${GODOT_VERSION}"
	local zip_name="android-template-${godot_tag}.zip"
	local url="https://github.com/poingstudios/godot-admob-plugin/releases/download/${plugin_version}/${zip_name}"
	local cache="${ADMOB_CACHE_DIR:-$HOME/.cache/unicorn-arcade/admob}"
	local bin_dir="$PROJECT/addons/admob/android/bin"
	local marker="$bin_dir/ads/libs/poing-godot-admob-ads-release.aar"

	if [[ -f "$marker" && -f "$bin_dir/package.gd" ]]; then
		echo "AdMob Android binaries already present ($(du -sh "$bin_dir" | cut -f1))"
		return 0
	fi

	mkdir -p "$cache" "$bin_dir"
	if [[ ! -f "$cache/$zip_name" ]]; then
		echo "Downloading AdMob Android template ${zip_name} (${plugin_version})..."
		curl -fsSL -o "$cache/$zip_name" "$url"
	fi
	echo "Extracting AdMob Android binaries into $bin_dir..."
	unzip -qo "$cache/$zip_name" -d "$bin_dir"
	if [[ ! -f "$marker" || ! -f "$bin_dir/package.gd" ]]; then
		echo "ERROR: AdMob Android binaries missing after extract (expected $marker)" >&2
		exit 1
	fi
	echo "AdMob Android binaries installed ($(du -sh "$bin_dir" | cut -f1))"
}

# Match main Capacitor CI: versionCode = run number, versionName = "1.<run_number>".
bump_version() {
	local preset="$PROJECT/export_presets.cfg"
	local version_name="${VERSION_NAME:-1.${VERSION_CODE}}"
	sed -i "s/^version\\/code=.*/version\\/code=${VERSION_CODE}/" "$preset"
	sed -i "s/^version\\/name=.*/version\\/name=\"${version_name}\"/" "$preset"
	echo "Android versionCode=${VERSION_CODE} versionName=${version_name}"
}

set_package_name() {
	local package_name="$1"
	local preset="$PROJECT/export_presets.cfg"
	sed -i "s|^package/unique_name=.*|package/unique_name=\"${package_name}\"|" "$preset"
}

godot_import_is_warm() {
	local probe imported_count
	probe="$(ls -1 "$PROJECT/.godot/imported"/unicorn_house_home_v1.png-*.ctex 2>/dev/null | head -1 || true)"
	[[ -n "$probe" && -s "$probe" ]] || return 1
	imported_count="$(find "$PROJECT/.godot/imported" -type f | wc -l | tr -d ' ')"
	# Fresh checkouts with a partial cache can have the probe but almost nothing else.
	[[ "${imported_count:-0}" -ge 200 ]]
}

android_export_template_dir() {
	local template_dir="${GODOT_VERSION}.stable"
	if [[ -f "$PROJECT/android/.build_version" ]]; then
		template_dir="$(tr -d '\r\n' <"$PROJECT/android/.build_version")"
	fi
	printf '%s\n' "$template_dir"
}

sanitize_android_build_template() {
	local build_dir="$PROJECT/android/build"
	# The editor-created installer adds this marker, but android_source.zip does
	# not. Without it, Godot scans generated Android resources and writes files
	# such as icon_background.webp.import, which Android's resource merger rejects.
	: >"$build_dir/.gdignore"
	find "$build_dir" -type f -name '*.import' -delete
}

ensure_android_build_template() {
	local marker="$PROJECT/android/build/build.gradle"
	local godot_aar template_dir android_source
	godot_aar="$(find "$PROJECT/android/build/libs" -name 'godot-lib*.aar' -type f 2>/dev/null | head -1 || true)"
	if [[ -f "$marker" && -n "$godot_aar" && -s "$godot_aar" ]]; then
		sanitize_android_build_template
		echo "Android build template already present; skipping install."
		return 0
	fi

	# Never call `godot --install-android-build-template` alone in CI: headless Godot
	# prints the engine banner and then sits in the editor until the job times out.
	# Extract android_source.zip from the export templates instead (same payload).
	template_dir="$(android_export_template_dir)"
	android_source="$HOME/.local/share/godot/export_templates/${template_dir}/android_source.zip"
	[[ -s "$android_source" ]] || {
		echo "ERROR: missing Android source template at $android_source" >&2
		exit 1
	}

	echo "Installing Android build template from ${android_source} (unzip, no Godot)..."
	rm -rf "$PROJECT/android/build"
	mkdir -p "$PROJECT/android/build"
	unzip -qo "$android_source" -d "$PROJECT/android/build"
	chmod +x "$PROJECT/android/build/gradlew"
	printf '%s\n' "$template_dir" >"$PROJECT/android/build/.build_version"
	printf '%s\n' "$template_dir" >"$PROJECT/android/.build_version"
	sanitize_android_build_template

	godot_aar="$(find "$PROJECT/android/build/libs" -name 'godot-lib*.aar' -type f 2>/dev/null | head -1 || true)"
	[[ -f "$marker" && -n "$godot_aar" && -s "$godot_aar" ]] || {
		echo "ERROR: Android build template extract did not produce godot-lib*.aar" >&2
		exit 1
	}
	echo "Android build template ready ($(du -sh "$PROJECT/android/build" | cut -f1))"
}

build_legacy_profile_bridge() {
	local bridge="$PROJECT/android/legacy_profile_bridge"
	local output="$PROJECT/android/plugins"
	local godot_aar
	[[ -d "$bridge" ]] || { echo "ERROR: legacy bridge source missing" >&2; exit 1; }
	godot_aar="$(find "$PROJECT/android/build/libs/release" -name 'godot-lib*.aar' -type f | head -1)"
	[[ -z "$godot_aar" ]] && godot_aar="$(find "$PROJECT/android/build/libs" -name 'godot-lib*.aar' -type f | head -1)"
	[[ -n "$godot_aar" && -f "$godot_aar" ]] || { echo "ERROR: generated Godot library AAR missing" >&2; exit 1; }
	mkdir -p "$output"
	GODOT_ANDROID_LIBRARY_AAR="$godot_aar" LEGACY_BRIDGE_OUTPUT_DIR="$output" \
		"$PROJECT/android/build/gradlew" -p "$bridge" copyReleaseAar
	[[ -s "$output/legacy_profile_bridge.aar" ]] || { echo "ERROR: legacy bridge AAR was not built" >&2; exit 1; }
}

set_export_format() {
	local format="$1"
	local preset="$PROJECT/export_presets.cfg"
	sed -i "s/^gradle_build\/export_format=.*/gradle_build\/export_format=${format}/" "$preset"
}

standalone_bundletool() {
	local version="${BUNDLETOOL_VERSION:-1.16.0}"
	local cache_dir="${BUNDLETOOL_CACHE_DIR:-$HOME/.cache/unicorn-arcade/bundletool}"
	local jar="${BUNDLETOOL_JAR:-$cache_dir/bundletool-all-${version}.jar}"
	if [[ ! -s "$jar" ]]; then
		mkdir -p "$cache_dir"
		# Status must go to stderr: callers capture stdout as the jar path.
		echo "Downloading official Bundletool ${version} for AAB validation..." >&2
		curl -fsSL -o "$jar" "https://github.com/google/bundletool/releases/download/${version}/bundletool-all-${version}.jar"
	fi
	[[ -s "$jar" ]] || { echo "ERROR: standalone Bundletool download is empty" >&2; exit 1; }
	java -jar "$jar" version >/dev/null || { echo "ERROR: standalone Bundletool is not executable" >&2; exit 1; }
	printf '%s\n' "$jar"
}

validate_artifact() {
	local artifact="$1" package_name="$2" expected_code="$3" expected_name="$4"
	[[ -s "$artifact" ]] || { echo "ERROR: missing Android artifact $artifact" >&2; exit 1; }
	if [[ "$artifact" == *.apk ]]; then
		local apkanalyzer="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/apkanalyzer"
		[[ -x "$apkanalyzer" ]] || apkanalyzer="$(find "${ANDROID_SDK_ROOT}/cmdline-tools" -name apkanalyzer -type f | head -1)"
		[[ -x "$apkanalyzer" ]] || { echo "ERROR: apkanalyzer is required for APK metadata validation" >&2; exit 1; }
		[[ "$("$apkanalyzer" manifest application-id "$artifact")" == "$package_name" ]] || { echo "ERROR: APK package mismatch" >&2; exit 1; }
		[[ "$("$apkanalyzer" manifest version-code "$artifact")" == "$expected_code" ]] || { echo "ERROR: APK versionCode mismatch" >&2; exit 1; }
		[[ "$("$apkanalyzer" manifest version-name "$artifact")" == "$expected_name" ]] || { echo "ERROR: APK versionName mismatch" >&2; exit 1; }
	else
		local bundletool
		bundletool="$(standalone_bundletool)"
		[[ "$(java -jar "$bundletool" dump manifest --bundle="$artifact" --xpath=/manifest/@package)" == "$package_name" ]] || { echo "ERROR: AAB package mismatch" >&2; exit 1; }
		[[ "$(java -jar "$bundletool" dump manifest --bundle="$artifact" --xpath=/manifest/@android:versionCode)" == "$expected_code" ]] || { echo "ERROR: AAB versionCode mismatch" >&2; exit 1; }
		[[ "$(java -jar "$bundletool" dump manifest --bundle="$artifact" --xpath=/manifest/@android:versionName)" == "$expected_name" ]] || { echo "ERROR: AAB versionName mismatch" >&2; exit 1; }
	fi
}

ensure_godot_import() {
	# Cold import of this project's GLBs/textures is ~30+ minutes. Skip when a
	# validated Actions cache already has the imported .ctex tree.
	if [[ "${FORCE_GODOT_IMPORT:-0}" != "1" ]] && godot_import_is_warm; then
		echo "Warm Godot import cache detected ($(du -sh "$PROJECT/.godot/imported" | cut -f1)); skipping --import."
		return 0
	fi
	echo "Importing project assets (cold or forced)..."
	godot --headless --path "$PROJECT" --import
	if ! godot_import_is_warm; then
		echo "ERROR: Godot import did not produce a usable .godot/imported cache" >&2
		exit 1
	fi
	echo "Godot import OK ($(du -sh "$PROJECT/.godot/imported" | cut -f1))"
}

export_android() {
	mkdir -p "$PROJECT/build/android"
	PRESET_PATH="$PROJECT/export_presets.cfg"
	PRESET_BACKUP="$(mktemp)"
	cp "$PRESET_PATH" "$PRESET_BACKUP"
	trap restore_export_preset EXIT
	install_admob_android_binaries
	write_admob_config
	bump_version
	set_export_format 1
	configure_godot_android_paths
	start_adb_server
	ensure_godot_import
	# Template install before bridge + export so we only pay for one Godot project load.
	ensure_android_build_template
	build_legacy_profile_bridge

	local ads_aar="$PROJECT/addons/admob/android/bin/ads/libs/poing-godot-admob-ads-release.aar"
	if [[ ! -f "$ads_aar" ]]; then
		echo "ERROR: Refusing to export without AdMob AAR at $ads_aar" >&2
		exit 1
	fi

	echo "Exporting Play release AAB as ${RELEASE_PACKAGE_NAME}..."
	set_package_name "$RELEASE_PACKAGE_NAME"
	set_export_format 1
	godot --headless --path "$PROJECT" --verbose \
		--export-release "$EXPORT_PRESET" "$PROJECT/build/android/UnicornArcade.aab"
	validate_artifact "$PROJECT/build/android/UnicornArcade.aab" "$RELEASE_PACKAGE_NAME" "$VERSION_CODE" "${VERSION_NAME:-1.${VERSION_CODE}}"

	echo "Exporting installable debug APK as ${DEBUG_PACKAGE_NAME}..."
	set_package_name "$DEBUG_PACKAGE_NAME"
	local preset="$PROJECT/export_presets.cfg"
	set_export_format 0
	sed -i 's|^export_path=.*|export_path="build/android/UnicornArcade-debug.apk"|' "$preset"
	godot --headless --path "$PROJECT" --verbose \
		--export-debug "$EXPORT_PRESET" "$PROJECT/build/android/UnicornArcade-debug.apk"
	validate_artifact "$PROJECT/build/android/UnicornArcade-debug.apk" "$DEBUG_PACKAGE_NAME" "$VERSION_CODE" "${VERSION_NAME:-1.${VERSION_CODE}}"
	set_export_format 1
	sed -i 's|^export_path=.*|export_path="build/android/UnicornArcade.aab"|' "$preset"
	restore_export_preset
	trap - EXIT
}

install_godot
export_android
echo "Done: $PROJECT/build/android/UnicornArcade.aab"
echo "Done: $PROJECT/build/android/UnicornArcade-debug.apk"
