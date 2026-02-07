#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="DrawSesh"
BUNDLE_ID="com.drawsesh.app"

BUILD_DIR="$ROOT_DIR/.build/release"
BIN="$BUILD_DIR/GestureDrawApp"
DIST="$ROOT_DIR/dist"
APP="$DIST/${APP_NAME}.app"
CONTENTS="$APP/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

ICONSET_SRC="$ROOT_DIR/Sources/GestureDrawApp/Resources/Assets.xcassets/AppIcon.appiconset"
ICONSET_TMP="$ROOT_DIR/.build/AppIcon.iconset"

export TMPDIR="$ROOT_DIR/.build/tmp"
export XDG_CACHE_HOME="$ROOT_DIR/.build/cache"
export CLANG_MODULE_CACHE_PATH="$ROOT_DIR/.build/clang-module-cache"
export SWIFTPM_DISABLE_SANDBOX=1
mkdir -p "$TMPDIR" "$XDG_CACHE_HOME" "$CLANG_MODULE_CACHE_PATH"

swift build -c release

rm -rf "$APP"
mkdir -p "$MACOS" "$RESOURCES"

cp "$BIN" "$MACOS/$APP_NAME"
chmod +x "$MACOS/$APP_NAME"

if [ -d "$ICONSET_SRC" ]; then
  rm -rf "$ICONSET_TMP"
  mkdir -p "$ICONSET_TMP"
  cp "$ICONSET_SRC"/*.png "$ICONSET_TMP"/
  iconutil -c icns "$ICONSET_TMP" -o "$RESOURCES/AppIcon.icns"
fi

cat > "$CONTENTS/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>${APP_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>${BUNDLE_ID}</string>
  <key>CFBundleName</key>
  <string>${APP_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${APP_NAME}</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
</dict>
</plist>
EOF

echo "Built app bundle at: $APP"
