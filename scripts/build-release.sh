#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/lotus.xcodeproj"
SCHEME="lotus"
CONFIGURATION="Release"
DERIVED_DATA_PATH="$ROOT_DIR/build/release"
PRODUCTS_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION"
APP_NAME="lotus.app"
APP_SOURCE_PATH="$PRODUCTS_PATH/$APP_NAME"
SHARE_PATH="$ROOT_DIR/build/share"
APP_OUTPUT_PATH="$SHARE_PATH/$APP_NAME"
ZIP_OUTPUT_PATH="$SHARE_PATH/lotus-macos-universal.zip"

mkdir -p "$SHARE_PATH"
rm -rf "$APP_OUTPUT_PATH" "$ZIP_OUTPUT_PATH"

xcodebuild \
  -scheme "$SCHEME" \
  -project "$PROJECT_PATH" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -destination "generic/platform=macOS" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  build

cp -R "$APP_SOURCE_PATH" "$APP_OUTPUT_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_OUTPUT_PATH" "$ZIP_OUTPUT_PATH"

echo
echo "Release app:"
echo "  $APP_OUTPUT_PATH"
echo "Zip archive:"
echo "  $ZIP_OUTPUT_PATH"
echo
echo "Architectures:"
lipo -info "$APP_OUTPUT_PATH/Contents/MacOS/lotus"
echo
echo "Signing:"
codesign -dv --verbose=2 "$APP_OUTPUT_PATH" 2>&1 | sed -n '1,8p'
