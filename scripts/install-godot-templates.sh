#!/usr/bin/env bash
# Install Godot export templates matching tools/godot-version.txt (Linux).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/tools/godot-version.txt")"
# Godot reports a full build string, but template folders use <major>.<minor>.stable.
TEMPLATE_VERSION="${VERSION%%.official*}"
TEMPLATE_DIR="${HOME}/.local/share/godot/export_templates/${TEMPLATE_VERSION}"

if [[ -f "$TEMPLATE_DIR/version.txt" ]] || [[ -f "$TEMPLATE_DIR/android_debug.apk" ]]; then
  echo "Export templates already present at $TEMPLATE_DIR"
  exit 0
fi

# Map official build string to GitHub release tag (e.g. 4.7.stable.official.* -> 4.7-stable)
MAJOR_MINOR="$(echo "$VERSION" | cut -d. -f1-2)"
RELEASE_TAG="${MAJOR_MINOR}-stable"
ARCHIVE="Godot_v${RELEASE_TAG}_export_templates.tpz"
URL="https://github.com/godotengine/godot/releases/download/${RELEASE_TAG}/${ARCHIVE}"

mkdir -p "$TEMPLATE_DIR"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Downloading $URL ..."
curl -fsSL "$URL" -o "$TMP/templates.tpz"
unzip -q "$TMP/templates.tpz" -d "$TMP/extract"
if [[ -d "$TMP/extract/templates" ]]; then
  cp -a "$TMP/extract/templates/." "$TEMPLATE_DIR/"
else
  EXTRACTED="$(find "$TMP/extract" -maxdepth 1 -type d -name 'templates_*' | head -1)"
  if [[ -n "$EXTRACTED" ]]; then
    cp -a "$EXTRACTED/." "$TEMPLATE_DIR/"
  else
    cp -a "$TMP/extract/." "$TEMPLATE_DIR/"
  fi
fi
echo "Installed export templates to $TEMPLATE_DIR"
