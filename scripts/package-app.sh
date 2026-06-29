#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Copybara"
BUNDLE_ID="co.showhere.copybara"
APP_VERSION="${APP_VERSION:-$(tr -d '[:space:]' < "$ROOT_DIR/VERSION")}"
APP_BUILD_NUMBER="${APP_BUILD_NUMBER:-1}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
SIGN_KEYCHAIN="${SIGN_KEYCHAIN:-}"
SWIFT_BUILD_ARCHS="${SWIFT_BUILD_ARCHS:-arm64 x86_64}"
BUILD_DIR="$ROOT_DIR/.build"
MODULE_CACHE="$BUILD_DIR/module-cache"
CACHE_CONTEXT="$BUILD_DIR/package-cache-context"
BUILD_HOME="$BUILD_DIR/home"
SWIFTPM_CACHE="$BUILD_DIR/swiftpm-cache"
SWIFTPM_CONFIG="$BUILD_DIR/swiftpm-config"
SWIFTPM_SECURITY="$BUILD_DIR/swiftpm-security"
APP_DIR="$BUILD_DIR/release/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

CURRENT_CACHE_CONTEXT="ROOT_DIR=$ROOT_DIR
MODULE_CACHE=$MODULE_CACHE
SWIFT_BUILD_ARCHS=$SWIFT_BUILD_ARCHS"

if [[ -d "$MODULE_CACHE" ]] && [[ ! -f "$CACHE_CONTEXT" || "$(cat "$CACHE_CONTEXT")" != "$CURRENT_CACHE_CONTEXT" ]]; then
  rm -rf "$MODULE_CACHE" "$BUILD_DIR"/manifest.db*
fi

mkdir -p "$MODULE_CACHE" "$BUILD_HOME" "$SWIFTPM_CACHE" "$SWIFTPM_CONFIG" "$SWIFTPM_SECURITY"
printf '%s\n' "$CURRENT_CACHE_CONTEXT" > "$CACHE_CONTEXT"

export HOME="$BUILD_HOME"
export CLANG_MODULE_CACHE_PATH="$MODULE_CACHE"
export SWIFTPM_MODULECACHE_OVERRIDE="$MODULE_CACHE"

ARCH_ARGS=()
for arch in $SWIFT_BUILD_ARCHS; do
  ARCH_ARGS+=(--arch "$arch")
done

swift build \
  --package-path "$ROOT_DIR" \
  --scratch-path "$BUILD_DIR" \
  --cache-path "$SWIFTPM_CACHE" \
  --config-path "$SWIFTPM_CONFIG" \
  --security-path "$SWIFTPM_SECURITY" \
  --manifest-cache local \
  --disable-sandbox \
  -c release \
  "${ARCH_ARGS[@]}" \
  -Xswiftc -module-cache-path \
  -Xswiftc "$MODULE_CACHE" >&2

BUILT_EXECUTABLE="$BUILD_DIR/apple/Products/Release/$APP_NAME"
if [[ ! -f "$BUILT_EXECUTABLE" ]]; then
  BUILT_EXECUTABLE="$BUILD_DIR/release/$APP_NAME"
fi

if [[ ! -f "$BUILT_EXECUTABLE" ]]; then
  echo "Built executable not found." >&2
  exit 1
fi

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BUILT_EXECUTABLE" "$MACOS_DIR/$APP_NAME"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"

cat > "$CONTENTS_DIR/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>en</string>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleSignature</key>
  <string>????</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>$APP_VERSION</string>
  <key>CFBundleVersion</key>
  <string>$APP_BUILD_NUMBER</string>
  <key>LSMinimumSystemVersion</key>
  <string>15.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSServices</key>
  <array>
    <dict>
      <key>NSMenuItem</key>
      <dict>
        <key>default</key>
        <string>Copy Link with Copybara</string>
      </dict>
      <key>NSMessage</key>
      <string>copyLinkWithCopybara</string>
      <key>NSPortName</key>
      <string>$APP_NAME</string>
      <key>NSSendFileTypes</key>
      <array>
        <string>public.item</string>
      </array>
    </dict>
  </array>
  <key>NSHumanReadableCopyright</key>
  <string>Copyright © 2026</string>
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleURLName</key>
      <string>$BUNDLE_ID</string>
      <key>CFBundleURLSchemes</key>
      <array>
        <string>copybara</string>
        <string>dropifier</string>
      </array>
    </dict>
  </array>
</dict>
</plist>
PLIST

printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

CODESIGN_ARGS=(--force)
if [[ -n "$SIGN_KEYCHAIN" ]]; then
  CODESIGN_ARGS+=(--keychain "$SIGN_KEYCHAIN")
fi

if [[ "$SIGN_IDENTITY" == "-" ]]; then
  codesign "${CODESIGN_ARGS[@]}" --sign - "$APP_DIR" >&2
else
  codesign "${CODESIGN_ARGS[@]}" --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP_DIR" >&2
fi

echo "$APP_DIR"
