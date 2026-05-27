#!/usr/bin/env bash
# Create Android debug + release keystores under keystores/ and write .signing.env.
# Both keystores/ and .signing.env are gitignored by the overlay.
# iOS signing is separate: set TEAM_ID in iosApp/Configuration/Config.xcconfig.
#
# Usage: setup_signing.sh

set -euo pipefail
cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
mkdir -p keystores

KEYSTORE_DEBUG=keystores/debug.keystore
KEYSTORE_RELEASE=keystores/release.keystore
SIGNING_ENV=.signing.env

command -v keytool >/dev/null || { echo "Missing 'keytool' — install a JDK." >&2; exit 1; }

# --- Debug -------------------------------------------------------
if [ ! -f "$KEYSTORE_DEBUG" ]; then
    echo ">> Creating debug keystore (password: android, alias: androiddebugkey)"
    keytool -genkey -noprompt \
        -keystore "$KEYSTORE_DEBUG" \
        -storepass android \
        -keypass android \
        -alias androiddebugkey \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -dname "CN=Android Debug,O=Android,C=US"
else
    echo ">> Debug keystore already present: $KEYSTORE_DEBUG"
fi

# --- Release -----------------------------------------------------
if [ -f "$KEYSTORE_RELEASE" ]; then
    echo ">> Release keystore already present: $KEYSTORE_RELEASE"
    exit 0
fi

echo
echo ">> Creating release keystore."
echo "   !! BACK THIS UP OFF-MACHINE. Lose it and you cannot update the Play Store listing. !!"
echo

read -r -p "Alias [release]: " ALIAS
ALIAS="${ALIAS:-release}"
read -r -s -p "Keystore password: " STOREPASS; echo
read -r -s -p "Confirm keystore password: " STOREPASS2; echo
[ "$STOREPASS" = "$STOREPASS2" ] || { echo "Passwords don't match." >&2; exit 1; }
read -r -s -p "Key password (empty = same as keystore): " KEYPASS; echo
KEYPASS="${KEYPASS:-$STOREPASS}"

read -r -p "CN (common name, e.g. Your Name): " CN
read -r -p "O (organization): " O
read -r -p "L (city): " L
read -r -p "ST (state/region): " ST
read -r -p "C (country code, 2 letters): " C

keytool -genkey -noprompt \
    -keystore "$KEYSTORE_RELEASE" \
    -storepass "$STOREPASS" \
    -keypass "$KEYPASS" \
    -alias "$ALIAS" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -dname "CN=$CN, O=$O, L=$L, ST=$ST, C=$C"

umask 077
cat > "$SIGNING_ENV" <<EOF
KEYSTORE_PATH=$KEYSTORE_RELEASE
KEYSTORE_PASSWORD=$STOREPASS
KEY_ALIAS=$ALIAS
KEY_PASSWORD=$KEYPASS
EOF
chmod 600 "$SIGNING_ENV"

echo
echo "✓ Keystores created. BACK UP $KEYSTORE_RELEASE NOW."
