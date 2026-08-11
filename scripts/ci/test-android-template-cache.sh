#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_PARENT="${PR32_TEST_TMP_ROOT:-${TMPDIR:-/tmp}}"
mkdir -p "$TEST_PARENT"
FIXTURE_ROOT="$(mktemp -d "$TEST_PARENT/pr32-android-cache.XXXXXX")"
trap 'find "$FIXTURE_ROOT" -depth -delete' EXIT

export GODOT_CI_ROOT="$ROOT"
export GODOT_PROJECT="$FIXTURE_ROOT/project"
export GODOT_VERSION="4.7.1"
export GODOT_CHANNEL="stable"
export GODOT_SHARE_DIR="$FIXTURE_ROOT/share"
export GODOT_CACHE_DIR="$FIXTURE_ROOT/cache"
mkdir -p "$GODOT_PROJECT/android" "$GODOT_SHARE_DIR/export_templates/4.7.1.stable" "$FIXTURE_ROOT/template/libs/release"
printf '%s\n' '4.7.1.stable' >"$GODOT_PROJECT/android/.build_version"
printf '%s\n' '// fixture' >"$FIXTURE_ROOT/template/build.gradle"
printf '%s\n' '#!/usr/bin/env sh' >"$FIXTURE_ROOT/template/gradlew"
printf '%s\n' 'fixture aar' >"$FIXTURE_ROOT/template/libs/release/godot-lib.release.aar"
printf '%s\n' 'fixture archive placeholder' >"$GODOT_SHARE_DIR/export_templates/4.7.1.stable/android_source.zip"

# Source-only mode is intentional: the main guard must not install tooling or export.
# shellcheck source=godot-export-android.sh
source "$ROOT/scripts/ci/godot-export-android.sh"

# Keep this regression independent of host zip tooling while exercising the
# real cache decision/replacement path. Production continues to use unzip.
unzip() {
	local destination=""
	while [[ $# -gt 0 ]]; do
		if [[ "$1" == '-d' ]]; then
			destination="$2"
			break
		fi
		shift
	done
	[[ -n "$destination" ]] || { echo 'fixture unzip destination missing' >&2; return 1; }
	cp -a "$FIXTURE_ROOT/template/." "$destination/"
}

make_structurally_valid_cache() {
	rm -rf "$GODOT_PROJECT/android/build"
	mkdir -p "$GODOT_PROJECT/android/build/libs/release"
	cp "$FIXTURE_ROOT/template/build.gradle" "$GODOT_PROJECT/android/build/build.gradle"
	cp "$FIXTURE_ROOT/template/gradlew" "$GODOT_PROJECT/android/build/gradlew"
	cp "$FIXTURE_ROOT/template/libs/release/godot-lib.release.aar" "$GODOT_PROJECT/android/build/libs/release/godot-lib.release.aar"
	printf '%s\n' 'must survive only current cache' >"$GODOT_PROJECT/android/build/cache-sentinel"
}

make_structurally_valid_cache
printf '%s\n' '4.7.1.stable' >"$GODOT_PROJECT/android/build/.build_version"
ensure_android_build_template
[[ -f "$GODOT_PROJECT/android/build/cache-sentinel" ]] || { echo 'current cache was unexpectedly replaced' >&2; exit 1; }
echo 'PR32_CACHE_CURRENT_ACCEPTED'

make_structurally_valid_cache
ensure_android_build_template
[[ ! -e "$GODOT_PROJECT/android/build/cache-sentinel" ]] || { echo 'missing-marker cache was accepted' >&2; exit 1; }
[[ "$(tr -d '\r\n' <"$GODOT_PROJECT/android/build/.build_version")" == '4.7.1.stable' ]] || { echo 'missing-marker cache was not replaced with the current marker' >&2; exit 1; }
echo 'PR32_CACHE_MISSING_REJECTED'

make_structurally_valid_cache
printf '%s\n' '4.6.2.stable' >"$GODOT_PROJECT/android/build/.build_version"
ensure_android_build_template
[[ ! -e "$GODOT_PROJECT/android/build/cache-sentinel" ]] || { echo 'stale cache was accepted' >&2; exit 1; }
[[ "$(tr -d '\r\n' <"$GODOT_PROJECT/android/build/.build_version")" == '4.7.1.stable' ]] || { echo 'stale cache was not replaced with the current marker' >&2; exit 1; }
echo 'PR32_CACHE_STALE_REJECTED'

printf '%s\n' '4.6.2.stable' >"$GODOT_PROJECT/android/.build_version"
if validate_tracked_android_build_version; then
	echo 'stale tracked marker was accepted' >&2
	exit 1
fi
printf '%s\n' '4.7.1.stable' >"$GODOT_PROJECT/android/.build_version"
validate_tracked_android_build_version
echo 'PR32_TRACKED_MARKER_CONTRACT_OK'
echo 'PR32_ANDROID_TEMPLATE_CACHE_TEST_OK'
