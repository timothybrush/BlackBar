#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
ZIP=${1:?"Usage: $0 BlackBar-<version>.zip"}
FEED_URL=${2:-"https://raw.githubusercontent.com/steipete/BlackBar/main/appcast.xml"}
PRIVATE_KEY_FILE=${SPARKLE_PRIVATE_KEY_FILE:-}

if [[ -z "$PRIVATE_KEY_FILE" ]]; then
  echo "Set SPARKLE_PRIVATE_KEY_FILE to your Sparkle ed25519 private key." >&2
  exit 1
fi
[[ -f "$ZIP" ]] || { echo "Zip not found: $ZIP" >&2; exit 1; }

ZIP_DIR=$(cd "$(dirname "$ZIP")" && pwd)
ZIP_NAME=$(basename "$ZIP")
ZIP_BASE="${ZIP_NAME%.zip}"
VERSION=${SPARKLE_RELEASE_VERSION:-}
if [[ -z "$VERSION" ]]; then
  if [[ "$ZIP_NAME" =~ ^BlackBar-([0-9]+(\.[0-9]+){1,2}([-.][^.]*)?)\.zip$ ]]; then
    VERSION="${BASH_REMATCH[1]}"
  else
    echo "Could not infer version from $ZIP_NAME; set SPARKLE_RELEASE_VERSION." >&2
    exit 1
  fi
fi

NOTES_HTML="$ZIP_DIR/$ZIP_BASE.html"
"$ROOT/Scripts/changelog-to-html.sh" "$VERSION" "$ROOT/CHANGELOG.md" > "$NOTES_HTML"

if ! command -v generate_appcast >/dev/null; then
  echo "generate_appcast not found in PATH. Install Sparkle tools." >&2
  exit 1
fi

WORK_DIR=$(mktemp -d /tmp/blackbar-appcast.XXXXXX)
cleanup() {
  rm -rf "$WORK_DIR"
  [[ "${KEEP_SPARKLE_NOTES:-0}" == "1" ]] || rm -f "$NOTES_HTML"
}
trap cleanup EXIT

cp "$ROOT/appcast.xml" "$WORK_DIR/appcast.xml"
cp "$ZIP" "$WORK_DIR/$ZIP_NAME"
cp "$NOTES_HTML" "$WORK_DIR/$ZIP_BASE.html"

DOWNLOAD_URL_PREFIX=${SPARKLE_DOWNLOAD_URL_PREFIX:-"https://github.com/steipete/BlackBar/releases/download/v${VERSION}/"}

pushd "$WORK_DIR" >/dev/null
generate_appcast \
  --ed-key-file "$PRIVATE_KEY_FILE" \
  --download-url-prefix "$DOWNLOAD_URL_PREFIX" \
  --embed-release-notes \
  --link "$FEED_URL" \
  "$WORK_DIR"
popd >/dev/null

cp "$WORK_DIR/appcast.xml" "$ROOT/appcast.xml"
echo "Appcast generated: appcast.xml"
