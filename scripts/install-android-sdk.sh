#!/usr/bin/env bash
# Install the Android command-line SDK required by Godot exports.
set -euo pipefail

SDK_ROOT="${ANDROID_HOME:-${HOME}/Android/Sdk}"
TOOLS_REVISION="${ANDROID_TOOLS_REVISION:-13114758}"
TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-${TOOLS_REVISION}_latest.zip"
SDKMANAGER="${SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager"

if [[ ! -x "$SDKMANAGER" ]]; then
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  mkdir -p "$SDK_ROOT/cmdline-tools"
  echo "Downloading Android command-line tools..."
  curl -fsSL "$TOOLS_URL" -o "$tmp/tools.zip"
  unzip -q "$tmp/tools.zip" -d "$tmp/unpacked"
  rm -rf "$SDK_ROOT/cmdline-tools/latest"
  mv "$tmp/unpacked/cmdline-tools" "$SDK_ROOT/cmdline-tools/latest"
fi

export ANDROID_HOME="$SDK_ROOT"
export ANDROID_SDK_ROOT="$SDK_ROOT"
yes | "$SDKMANAGER" --licenses >/dev/null || true
"$SDKMANAGER" \
  "platform-tools" \
  "platforms;android-36" \
  "build-tools;36.0.0"

echo "Android SDK ready at $SDK_ROOT"
echo "Export ANDROID_HOME=$SDK_ROOT"
