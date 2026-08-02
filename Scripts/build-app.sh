#!/bin/bash
# Builds the SwiftPM executable and wraps it into a runnable ActionsBar.app
# (menu bar apps need a real bundle: Info.plist + LSUIElement + bundle ID
# for Keychain/UserNotifications to work).
set -euo pipefail
cd "$(dirname "$0")/.."

CONFIG="${1:-debug}"
swift build -c "$CONFIG"
BIN_PATH=$(swift build -c "$CONFIG" --show-bin-path)

APP="ActionsBar.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_PATH/ActionsBar" "$APP/Contents/MacOS/ActionsBar"
cp -R "$BIN_PATH/ActionsBar_ActionsBar.bundle" "$APP/Contents/MacOS/ActionsBar_ActionsBar.bundle"
cp Resources/Info.plist "$APP/Contents/Info.plist"

# Ad-hoc sign so Keychain + UserNotifications work locally.
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true

echo "Built $APP"
echo "Run: open $APP"
