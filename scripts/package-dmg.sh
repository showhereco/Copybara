#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 APP_PATH VERSION OUTPUT_DIR" >&2
  exit 64
fi

APP_PATH="$1"
VERSION="$2"
OUTPUT_DIR="$3"
SIGN_IDENTITY="${SIGN_IDENTITY:-}"
SIGN_KEYCHAIN="${SIGN_KEYCHAIN:-}"
APP_NAME="$(basename "$APP_PATH" .app)"
DMG_NAME="$APP_NAME-$VERSION-macos.dmg"
DMG_PATH="$OUTPUT_DIR/$DMG_NAME"
STAGING_DIR="$OUTPUT_DIR/dmg-staging"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found: $APP_PATH" >&2
  exit 1
fi

rm -rf "$STAGING_DIR"
mkdir -p "$OUTPUT_DIR" "$STAGING_DIR"

ditto "$APP_PATH" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >&2

rm -rf "$STAGING_DIR"

if [[ -n "$SIGN_IDENTITY" && "$SIGN_IDENTITY" != "-" ]]; then
  CODESIGN_ARGS=(--force --timestamp)
  if [[ -n "$SIGN_KEYCHAIN" ]]; then
    CODESIGN_ARGS+=(--keychain "$SIGN_KEYCHAIN")
  fi
  codesign "${CODESIGN_ARGS[@]}" --sign "$SIGN_IDENTITY" "$DMG_PATH" >&2
fi

hdiutil verify "$DMG_PATH" >&2

echo "$DMG_PATH"
