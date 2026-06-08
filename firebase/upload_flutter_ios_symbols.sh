#!/usr/bin/env bash
set -euo pipefail

# Upload Flutter obfuscation symbols to Crashlytics for iOS.
# Usage:
#   ./firebase/upload_flutter_ios_symbols.sh <split-debug-info-dir>
#
# Example build + upload:
#   flutter build ipa --release --obfuscate --split-debug-info=build/symbols/ios
#   ./firebase/upload_flutter_ios_symbols.sh build/symbols/ios

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <split-debug-info-dir>"
  exit 1
fi

SYMBOLS_DIR="$1"
if [[ ! -d "$SYMBOLS_DIR" ]]; then
  echo "Error: symbols directory not found: $SYMBOLS_DIR"
  exit 1
fi

if ! command -v firebase >/dev/null 2>&1; then
  echo "Error: Firebase CLI is not installed or not on PATH."
  exit 1
fi

PLIST_PATH="ios/Runner/GoogleService-Info.plist"
if [[ ! -f "$PLIST_PATH" ]]; then
  echo "Error: missing $PLIST_PATH"
  exit 1
fi

APP_ID="$(/usr/libexec/PlistBuddy -c 'Print :GOOGLE_APP_ID' "$PLIST_PATH" 2>/dev/null || true)"
if [[ -z "$APP_ID" ]]; then
  echo "Error: GOOGLE_APP_ID not found in $PLIST_PATH"
  exit 1
fi

echo "Uploading Flutter symbols for app: $APP_ID"
firebase crashlytics:symbols:upload --app="$APP_ID" "$SYMBOLS_DIR"
echo "Crashlytics symbol upload complete."
