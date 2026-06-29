#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 DMG_PATH VERSION BUILD_NUMBER OUTPUT_DIR" >&2
  exit 64
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DMG_PATH="$1"
VERSION="$2"
BUILD_NUMBER="$3"
OUTPUT_DIR="$4"
APP_NAME="Copybara"
MINIMUM_SYSTEM_VERSION="15.0"
SPARKLE_PRIVATE_ED_KEY="${SPARKLE_PRIVATE_ED_KEY:-}"
GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-showhereco/Copybara}"
APPCAST_BASE_URL="${APPCAST_BASE_URL:-https://github.com/${GITHUB_REPOSITORY}/releases/download/v${VERSION}}"
APPCAST_PATH="$OUTPUT_DIR/appcast.xml"

if [[ ! -f "$DMG_PATH" ]]; then
  echo "DMG not found: $DMG_PATH" >&2
  exit 1
fi

if [[ -z "$SPARKLE_PRIVATE_ED_KEY" ]]; then
  echo "SPARKLE_PRIVATE_ED_KEY is required to sign the Sparkle update archive." >&2
  exit 1
fi

SIGN_UPDATE="${SIGN_UPDATE:-}"
if [[ -z "$SIGN_UPDATE" ]]; then
  SIGN_UPDATE="$(find "$ROOT_DIR/.build/artifacts" -path "*/Sparkle/bin/sign_update" -type f | sort | head -n 1)"
fi

if [[ -z "$SIGN_UPDATE" || ! -x "$SIGN_UPDATE" ]]; then
  echo "Sparkle sign_update tool not found. Expected it under .build/artifacts/sparkle/Sparkle/bin after SwiftPM resolves Sparkle." >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

DMG_NAME="$(basename "$DMG_PATH")"
DMG_URL="$APPCAST_BASE_URL/$DMG_NAME"
RELEASE_URL="https://github.com/${GITHUB_REPOSITORY}/releases/tag/v${VERSION}"
PUB_DATE="$(LC_ALL=C TZ=UTC date '+%a, %d %b %Y %H:%M:%S %z')"
SIGNATURE_ATTRS="$(printf '%s' "$SPARKLE_PRIVATE_ED_KEY" | "$SIGN_UPDATE" --ed-key-file - "$DMG_PATH")"

cat > "$APPCAST_PATH" <<XML
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>${APP_NAME} Updates</title>
    <link>https://github.com/${GITHUB_REPOSITORY}</link>
    <description>Release feed for ${APP_NAME}.</description>
    <language>en</language>
    <item>
      <title>${APP_NAME} ${VERSION}</title>
      <link>${RELEASE_URL}</link>
      <sparkle:version>${BUILD_NUMBER}</sparkle:version>
      <sparkle:shortVersionString>${VERSION}</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>${MINIMUM_SYSTEM_VERSION}</sparkle:minimumSystemVersion>
      <pubDate>${PUB_DATE}</pubDate>
      <enclosure url="${DMG_URL}" ${SIGNATURE_ATTRS} type="application/octet-stream" />
    </item>
  </channel>
</rss>
XML

echo "$APPCAST_PATH"
