#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="FITRepairStudio"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
ZIP_PATH="$DIST_DIR/FITRepairStudio-mac.zip"
NOTARY_PROFILE="${FIT_REPAIR_NOTARY_PROFILE:-FITRepairStudioNotary}"

if [[ -z "${FIT_REPAIR_SIGN_IDENTITY:-}" ]]; then
  cat >&2 <<'EOF'
FIT_REPAIR_SIGN_IDENTITY is required for notarization.

Example:
  export FIT_REPAIR_SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
  export FIT_REPAIR_BUNDLE_ID="com.yourcompany.fitrepairstudio"
  ./script/notarize_mac.sh
EOF
  exit 2
fi

if [[ -z "${FIT_REPAIR_BUNDLE_ID:-}" ]]; then
  cat >&2 <<'EOF'
FIT_REPAIR_BUNDLE_ID is required for notarization.

Use a stable reverse-DNS identifier owned by you, for example:
  export FIT_REPAIR_BUNDLE_ID="com.yourcompany.fitrepairstudio"
EOF
  exit 2
fi

if [[ "$FIT_REPAIR_SIGN_IDENTITY" != Developer\ ID\ Application:* ]]; then
  echo "Warning: signing identity does not look like a Developer ID Application certificate." >&2
fi

"$ROOT_DIR/script/package_mac.sh"

codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

xcrun notarytool submit "$ZIP_PATH" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

xcrun stapler staple "$APP_BUNDLE"
xcrun stapler validate "$APP_BUNDLE"
spctl --assess --type execute --verbose=4 "$APP_BUNDLE"

rm -f "$ZIP_PATH"
COPYFILE_DISABLE=1 /usr/bin/ditto --norsrc -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo "$APP_BUNDLE"
echo "$ZIP_PATH"
