#!/bin/bash
# Build LeetFlame.app. Pass --install to also copy it to /Applications
# (relaunching the installed copy if it was running).
set -euo pipefail
cd "$(dirname "$0")"

APP_NAME="LeetFlame"
BUNDLE_ID="com.ioanndousse.leetflame"
VERSION="1.0"
BUILD_DIR=".build/release"
APP_DIR="$BUILD_DIR/$APP_NAME.app"

swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BUILD_DIR/LeetCodeStreakWidget" "$APP_DIR/Contents/MacOS/$APP_NAME"
cp Assets/AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"

cat > "$APP_DIR/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# Ad-hoc signature: keeps macOS from re-prompting network/security checks on
# every rebuild. Replace "-" with a Developer ID for distribution.
codesign --force --deep --sign - "$APP_DIR"

echo "Built: $APP_DIR"

if [[ "${1:-}" == "--install" ]]; then
    WAS_RUNNING=0
    if pgrep -x "$APP_NAME" > /dev/null; then
        WAS_RUNNING=1
        osascript -e "tell application \"$APP_NAME\" to quit" 2>/dev/null || pkill -x "$APP_NAME" || true
        sleep 1
    fi
    rm -rf "/Applications/$APP_NAME.app"
    cp -R "$APP_DIR" "/Applications/$APP_NAME.app"
    echo "Installed: /Applications/$APP_NAME.app"
    if [[ $WAS_RUNNING == 1 ]]; then
        open "/Applications/$APP_NAME.app"
        echo "Relaunched."
    fi
fi
