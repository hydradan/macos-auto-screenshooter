#!/usr/bin/env zsh
set -e

APP_NAME="AutoScreenshooter"
BUILD_DIR="$(pwd)/.build/release"
EXEC="$BUILD_DIR/$APP_NAME"
BUNDLE="$BUILD_DIR/$APP_NAME.app"

# 1. Create bundle skeleton
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

# 2. Copy executable and icon
cp "$EXEC"             "$BUNDLE/Contents/MacOS/$APP_NAME"
cp Sources/AutoScreenshooter/Resources/*.icns "$BUNDLE/Contents/Resources/" || echo "Warning: No icon files found, continuing without them."

# 3. Write Info.plist that points at the icon
cat >"$BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>     <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>     <string>com.example.$APP_NAME</string>
  <key>CFBundleName</key>           <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>    <string>APPL</string>
  <key>CFBundleIconFile</key>       <string>autoshooter</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key>        <string>1.0</string>
</dict>
</plist>
EOF

echo "✨  Created $BUNDLE"
open -R "$BUNDLE"