#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 APP_PATH VERSION OUTPUT_DIR" >&2
  exit 64
fi

APP_PATH="$1"
VERSION="$2"
OUTPUT_DIR="$3"
APP_NAME="$(basename "$APP_PATH" .app)"
ARCHIVE_NAME="$APP_NAME-$VERSION-macos.zip"
ARCHIVE_PATH="$OUTPUT_DIR/$ARCHIVE_NAME"

if [[ ! -d "$APP_PATH" ]]; then
  echo "App bundle not found: $APP_PATH" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
rm -f "$ARCHIVE_PATH" "$ARCHIVE_PATH.sha256"

ditto -c -k --keepParent "$APP_PATH" "$ARCHIVE_PATH"
shasum -a 256 "$ARCHIVE_PATH" > "$ARCHIVE_PATH.sha256"

echo "$ARCHIVE_PATH"
