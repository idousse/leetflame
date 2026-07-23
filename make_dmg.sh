#!/bin/bash
# Build LeetFlame.app and package it into a drag-to-Applications DMG
# for distribution via GitHub Releases.
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="LeetFlame"
VERSION="${1:-1.0}"
DMG_NAME="LeetFlame-$VERSION.dmg"
APP_DIR=".build/release/$APP_NAME.app"
STAGING="$(mktemp -d)"

# Build the signed .app bundle.
./build_app.sh

# Stage the app next to an /Applications symlink so the DMG shows the
# familiar "drag the icon into Applications" layout.
cp -R "$APP_DIR" "$STAGING/$APP_NAME.app"
ln -s /Applications "$STAGING/Applications"

rm -f "$DMG_NAME"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING" \
    -ov -format UDZO \
    "$DMG_NAME"

rm -rf "$STAGING"
echo ""
echo "Created: $DMG_NAME"
