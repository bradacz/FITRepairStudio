#!/usr/bin/env bash
set -euo pipefail

APP_NAME="FITRepairStudio"
BUNDLE_ID="${FIT_REPAIR_BUNDLE_ID:-com.local.fit-repair-studio}"
MIN_SYSTEM_VERSION="13.0"
SIGN_IDENTITY="${FIT_REPAIR_SIGN_IDENTITY:--}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR="/private/tmp/fitrepairstudio-package"
APP_BUNDLE="$STAGE_DIR/$APP_NAME.app"
DIST_APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
ZIP_PATH="$DIST_DIR/FITRepairStudio-mac.zip"
APP_ICON="$ROOT_DIR/Assets/AppIcon.icns"

cd "$ROOT_DIR"

swift build -c release
swift build -c release --triple x86_64-apple-macosx13.0
ARM_BINARY="$(swift build -c release --show-bin-path)/$APP_NAME"
X86_BINARY="$(swift build -c release --triple x86_64-apple-macosx13.0 --show-bin-path)/$APP_NAME"

rm -rf "$STAGE_DIR" "$DIST_APP_BUNDLE" "$ZIP_PATH"
if [[ ! -f "$APP_ICON" ]]; then
  python3 "$ROOT_DIR/script/create_app_icon.py"
fi

mkdir -p "$APP_MACOS" "$APP_RESOURCES"
/usr/bin/lipo -create -output "$APP_BINARY" "$ARM_BINARY" "$X86_BINARY"
chmod +x "$APP_BINARY"
cp "$APP_ICON" "$APP_RESOURCES/AppIcon.icns"
cp -R "$ROOT_DIR/Sources/FITRepairStudio/Resources/"*.lproj "$APP_RESOURCES/"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleName</key>
  <string>FIT Repair Studio</string>
  <key>CFBundleDisplayName</key>
  <string>FIT Repair Studio</string>
  <key>CFBundleDevelopmentRegion</key>
  <string>cs</string>
  <key>CFBundleLocalizations</key>
  <array>
    <string>cs</string>
    <string>en</string>
  </array>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>CFBundleDocumentTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeName</key>
      <string>FIT Activity File</string>
      <key>CFBundleTypeExtensions</key>
      <array>
        <string>fit</string>
      </array>
      <key>CFBundleTypeRole</key>
      <string>Editor</string>
      <key>LSHandlerRank</key>
      <string>Alternate</string>
    </dict>
  </array>
</dict>
</plist>
PLIST

if command -v xattr >/dev/null 2>&1; then
  xattr -cr "$APP_BUNDLE"
fi

if command -v codesign >/dev/null 2>&1; then
  SIGNING_ARGS=(--force --deep --sign "$SIGN_IDENTITY")
  if [[ "$SIGN_IDENTITY" == "-" ]]; then
    SIGNING_ARGS+=(--timestamp=none)
    echo "Signing ad-hoc for local testing"
  else
    SIGNING_ARGS+=(--options runtime --timestamp)
    echo "Signing with Developer ID identity: $SIGN_IDENTITY"
  fi

  codesign "${SIGNING_ARGS[@]}" "$APP_BUNDLE"
  codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"
fi

COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"
COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc "$APP_BUNDLE" "$DIST_APP_BUNDLE"

echo "$DIST_APP_BUNDLE"
echo "$ZIP_PATH"
