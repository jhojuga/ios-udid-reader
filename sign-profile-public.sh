#!/bin/sh
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROFILE_PATH="$PROJECT_DIR/public/profile.mobileconfig"
OUTPUT_PATH="$PROJECT_DIR/public/profile_signed.mobileconfig"

if [ "$#" -ne 3 ]; then
    echo "Usage: sh ./sign-profile-public.sh <signer.crt> <signer.key> <chain.pem>" >&2
    exit 1
fi

SIGNER_CERT="$1"
SIGNER_KEY="$2"
CHAIN_FILE="$3"

if ! command -v openssl >/dev/null 2>&1; then
    echo "Error: OpenSSL is required." >&2
    exit 1
fi

for f in "$PROFILE_PATH" "$SIGNER_CERT" "$SIGNER_KEY" "$CHAIN_FILE"; do
    if [ ! -f "$f" ]; then
        echo "Error: file not found: $f" >&2
        exit 1
    fi
done

TMP_OUT=$(mktemp "$PROJECT_DIR/public/profile_signed.mobileconfig.XXXXXX")
trap 'rm -f "$TMP_OUT"' EXIT HUP INT TERM

openssl smime -sign -binary \
    -in "$PROFILE_PATH" \
    -out "$TMP_OUT" \
    -outform DER \
    -nodetach \
    -signer "$SIGNER_CERT" \
    -inkey "$SIGNER_KEY" \
    -certfile "$CHAIN_FILE"

openssl smime -verify -binary -inform DER -in "$TMP_OUT" -noverify -out /dev/null
mv "$TMP_OUT" "$OUTPUT_PATH"

echo "Signed profile created: $OUTPUT_PATH"
