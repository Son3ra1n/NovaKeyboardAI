#!/usr/bin/env bash
# Export a signed .ipa from an Xcode archive and copy it to the Desktop as .tipa (TrollStore).
#
# 1) Xcode: Product → Archive (signing must succeed for app + keyboard extension + App Group).
# 2) In Organizer: right-click the archive → Show in Finder → drag path below, OR pass it as $1.
#
# Usage:
#   ./scripts/export-tipa-to-desktop.sh
#   ./scripts/export-tipa-to-desktop.sh ~/Library/Developer/Xcode/Archives/2026-05-04/NovaKeyboardAI\ 2026-05-04\,\ 18.00.xcarchive

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PLIST="$SCRIPT_DIR/ExportOptions-development.plist"
DESKTOP="$HOME/Desktop"
OUT_DIR="$(mktemp -d /tmp/nova-export.XXXXXX)"

cleanup() { rm -rf "$OUT_DIR"; }
trap cleanup EXIT

if [[ ! -f "$PLIST" ]]; then
  echo "Missing $PLIST"
  exit 1
fi

ARCHIVE_PATH="${1:-}"

if [[ -z "$ARCHIVE_PATH" ]]; then
  ARCHIVES_DIR="$HOME/Library/Developer/Xcode/Archives"
  if [[ -d "$ARCHIVES_DIR" ]]; then
    # Newest matching archive by mtime (macOS)
    ARCHIVE_PATH="$(find "$ARCHIVES_DIR" -name 'NovaKeyboardAI*.xcarchive' -type d 2>/dev/null | while read -r p; do
      printf '%s\t%s\n' "$(stat -f '%m' "$p" 2>/dev/null || echo 0)" "$p"
    done | sort -t $'\t' -nr | head -1 | cut -f2-)"
  fi
fi

if [[ -z "$ARCHIVE_PATH" || ! -d "$ARCHIVE_PATH" ]]; then
  echo "Could not find an .xcarchive."
  echo "In Xcode: Product → Archive, then run:"
  echo "  $0 /path/to/NovaKeyboardAI.xcarchive"
  echo "(Archives are usually under ~/Library/Developer/Xcode/Archives/<date>/ )"
  exit 1
fi

echo "Using archive: $ARCHIVE_PATH"

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$OUT_DIR" \
  -exportOptionsPlist "$PLIST"

IPA="$(find "$OUT_DIR" -name '*.ipa' -print -quit)"
if [[ -z "$IPA" || ! -f "$IPA" ]]; then
  echo "Export did not produce an .ipa in $OUT_DIR"
  exit 1
fi

DEST="$DESKTOP/NovaKeyboardAI.tipa"
cp "$IPA" "$DEST"
echo ""
echo "Copied to: $DEST"
echo "Install with TrollStore (or rename to .ipa if your tool expects that)."
