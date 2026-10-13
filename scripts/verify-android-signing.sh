#!/usr/bin/env bash
# Local check: same keystore + passwords GitHub Actions uses.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROPS="$ROOT/android/key.properties"
JKS="$ROOT/android/upload-keystore.jks"

if [[ ! -f "$PROPS" ]]; then
  echo "Missing $PROPS — copy from android/key.properties.example"
  exit 1
fi
if [[ ! -f "$JKS" ]]; then
  echo "Missing $JKS — copy your .jks here as upload-keystore.jks"
  exit 1
fi

storePassword=$(grep '^storePassword=' "$PROPS" | cut -d= -f2-)
keyPassword=$(grep '^keyPassword=' "$PROPS" | cut -d= -f2-)
keyAlias=$(grep '^keyAlias=' "$PROPS" | cut -d= -f2-)

echo "Keystore: $JKS ($(wc -c < "$JKS" | tr -d ' ') bytes)"
echo "Alias from key.properties: [$keyAlias]"

if ! keytool -list -keystore "$JKS" -storepass "$storePassword" -alias "$keyAlias" >/dev/null 2>&1; then
  echo "FAIL: store password or alias does not match this .jks file."
  echo "Aliases in keystore (store password only):"
  keytool -list -keystore "$JKS" -storepass "$storePassword" 2>/dev/null | grep -E '^\w' || true
  exit 1
fi

if [[ "$storePassword" != "$keyPassword" ]]; then
  echo "Note: store and key passwords differ — set both GitHub secrets correctly."
else
  echo "Store password + alias OK (store and key password are the same locally)."
fi

echo ""
echo "Regenerate ANDROID_KEYSTORE_BASE64 from THIS file only:"
echo "  base64 -i android/upload-keystore.jks | tr -d '\\n' | pbcopy"
echo "GitHub secrets must match android/key.properties (no extra spaces)."
