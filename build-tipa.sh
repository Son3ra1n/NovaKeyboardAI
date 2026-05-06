#!/bin/bash
# build-tipa.sh — Build NovaKeyboardAI.tipa with proper entitlements
# Usage: ./build-tipa.sh
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
DERIVED="$PROJECT_DIR/DerivedDataRelease"
OUTPUT="$HOME/Desktop/NovaKeyboardAI_FINAL.tipa"

HOST_ENT="$PROJECT_DIR/NovaKeyboardAI/NovaKeyboardAI.entitlements"
EXT_ENT="$PROJECT_DIR/NovaKeyboard/NovaKeyboard.entitlements"

echo "=== 1/4  Building Release (unsigned) ==="
xcodebuild -project "$PROJECT_DIR/NovaKeyboardAI.xcodeproj" \
  -scheme NovaKeyboardAI \
  -sdk iphoneos \
  -configuration Release \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  ARCHS=arm64 \
  -derivedDataPath "$DERIVED" \
  clean build 2>&1 | grep -E "error:|BUILD"

APP_PATH=$(find "$DERIVED" -name "NovaKeyboardAI.app" -type d | head -1)
if [ -z "$APP_PATH" ]; then
  echo "ERROR: NovaKeyboardAI.app not found in DerivedData"
  exit 1
fi

echo ""
echo "=== 2/4  Signing with ldid + entitlements ==="

# Sign extension first (inner binary)
APPEX="$APP_PATH/PlugIns/NovaKeyboard.appex/NovaKeyboard"
echo "  ldid extension: $APPEX"
ldid -S"$EXT_ENT" "$APPEX"

# Sign host app
HOST_BIN="$APP_PATH/NovaKeyboardAI"
echo "  ldid host app:  $HOST_BIN"
ldid -S"$HOST_ENT" "$HOST_BIN"

echo ""
echo "=== 3/4  Verifying entitlements ==="
echo "--- Host App ---"
ldid -e "$HOST_BIN" 2>/dev/null | grep -A2 "application-groups" || echo "  WARNING: No app group found!"
echo "--- Extension ---"
ldid -e "$APPEX" 2>/dev/null | grep -A2 "application-groups" || echo "  WARNING: No app group found!"

echo ""
echo "=== 4/4  Packaging .tipa ==="
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/Payload"
cp -r "$APP_PATH" "$TMPDIR/Payload/"
rm -f "$OUTPUT"
(cd "$TMPDIR" && zip -qr "$OUTPUT" Payload/)
rm -rf "$TMPDIR"

SIZE=$(ls -lh "$OUTPUT" | awk '{print $5}')
echo ""
echo "✅ Done! $OUTPUT ($SIZE)"
echo ""
echo "Install via TrollStore / SideStore and verify:"
echo "  1. Open Nova app → enter Groq API key → save"
echo "  2. Switch to any app → open Nova keyboard"
echo "  3. Swipe down → should translate (not show 'API key missing')"
