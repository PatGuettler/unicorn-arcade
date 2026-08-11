#!/usr/bin/env bash
# Shared Godot 4.7.1 installer for CI export and test jobs. Source this file,
# call install_godot for the editor, and install_godot_export_templates only
# for exports that actually require the large template archive.

GODOT_CI_ROOT="${GODOT_CI_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
GODOT_PROJECT="${GODOT_PROJECT:-$GODOT_CI_ROOT/godot}"
GODOT_VERSION="${GODOT_VERSION:-4.7.1}"
GODOT_CHANNEL="${GODOT_CHANNEL:-stable}"
GODOT_TAG="${GODOT_VERSION}-${GODOT_CHANNEL}"
GODOT_CACHE_DIR="${GODOT_CACHE_DIR:-$HOME/.cache/unicorn-arcade/godot}"
GODOT_BIN_DIR="${GODOT_BIN_DIR:-$HOME/.local/bin}"
GODOT_SHARE_DIR="${GODOT_SHARE_DIR:-$HOME/.local/share/godot}"


expected_android_build_version() {
	printf '%s.%s\n' "$GODOT_VERSION" "$GODOT_CHANNEL"
}


validate_tracked_android_build_version() {
	local marker="$GODOT_PROJECT/android/.build_version"
	local expected actual
	expected="$(expected_android_build_version)"
	[[ -f "$marker" ]] || {
		echo "ERROR: tracked Android build marker is missing: $marker (expected $expected)" >&2
		return 1
	}
	actual="$(tr -d '\r\n' <"$marker")"
	[[ "$actual" == "$expected" ]] || {
		echo "ERROR: tracked Android build marker is '$actual'; requested engine requires '$expected'" >&2
		return 1
	}
}


android_export_template_dir() {
	validate_tracked_android_build_version || return 1
	expected_android_build_version
}


install_godot() {
	local zip="Godot_v${GODOT_TAG}_linux.x86_64.zip"
	local binary="$GODOT_BIN_DIR/godot"
	mkdir -p "$GODOT_CACHE_DIR" "$GODOT_BIN_DIR"
	export PATH="$GODOT_BIN_DIR:$PATH"

	if [[ ! -x "$binary" || "$("$binary" --version 2>/dev/null || true)" != "${GODOT_VERSION}"* ]]; then
		if [[ ! -f "$GODOT_CACHE_DIR/$zip" ]]; then
			curl -fsSL -o "$GODOT_CACHE_DIR/$zip" \
				"https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/${zip}"
		fi
		unzip -qo "$GODOT_CACHE_DIR/$zip" -d "$GODOT_CACHE_DIR"
		install -m 755 "$GODOT_CACHE_DIR/Godot_v${GODOT_TAG}_linux.x86_64" "$binary"
	fi
	"$binary" --version
}


install_godot_export_templates() {
	local tpz="Godot_v${GODOT_TAG}_export_templates.tpz"
	local template_dir
	local unpack_dir
	install_godot
	if [[ ! -f "$GODOT_CACHE_DIR/$tpz" ]]; then
		curl -fsSL -o "$GODOT_CACHE_DIR/$tpz" \
			"https://github.com/godotengine/godot/releases/download/${GODOT_TAG}/${tpz}"
	fi
	template_dir="$(android_export_template_dir)"
	mkdir -p "$GODOT_SHARE_DIR/export_templates/${template_dir}"
	unpack_dir="$(mktemp -d "$GODOT_CACHE_DIR/templates-${GODOT_TAG}.XXXXXX")"
	(
		trap 'find "$unpack_dir" -depth -delete' EXIT
		unzip -qo "$GODOT_CACHE_DIR/$tpz" -d "$unpack_dir"
		cp -a "$unpack_dir/templates/." \
			"$GODOT_SHARE_DIR/export_templates/${template_dir}/"
	)
	[[ -s "$GODOT_SHARE_DIR/export_templates/${template_dir}/android_source.zip" ]] || {
		echo "ERROR: export templates missing android_source.zip under ${template_dir}" >&2
		return 1
	}
}
