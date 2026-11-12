#!/bin/sh
set -eu

umask 077

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
KEY_DIR=${IOS_UDID_CERT_DIR:-"$HOME/.config/ios-udid-reader"}
KEY_PATH="$KEY_DIR/ca.key"
CERT_PATH="$PROJECT_DIR/public/myCA.pem"
PROFILE_PATH="$PROJECT_DIR/public/profile.mobileconfig"
SIGNED_PROFILE_PATH="$PROJECT_DIR/public/profile_signed.mobileconfig"

if ! command -v openssl >/dev/null 2>&1; then
    echo "Error: OpenSSL is required to sign the configuration profile." >&2
    exit 1
fi

mkdir -p "$KEY_DIR"
chmod 700 "$KEY_DIR"

key_was_created=false
if [ ! -f "$KEY_PATH" ]; then
    openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$KEY_PATH"
    chmod 600 "$KEY_PATH"
    key_was_created=true
fi

create_certificate() {
    openssl req -x509 -new -key "$KEY_PATH" -sha256 -days 365 \
        -out "$CERT_PATH" \
        -subj "/CN=UDID Reader Profile Signing CA" \
        -addext "basicConstraints=critical,CA:TRUE" \
        -addext "keyUsage=critical,digitalSignature,keyCertSign,cRLSign" \
        -addext "subjectKeyIdentifier=hash" \
        -addext "authorityKeyIdentifier=keyid:always"
}

if [ "$key_was_created" = true ] || [ ! -f "$CERT_PATH" ]; then
    create_certificate
elif ! openssl x509 -in "$CERT_PATH" -noout >/dev/null 2>&1; then
    echo "Error: $CERT_PATH is not a valid certificate; refusing to overwrite it." >&2
    exit 1
else
    key_public=$(mktemp)
    cert_public=$(mktemp)
    trap 'rm -f "$key_public" "$cert_public"' EXIT HUP INT TERM
    openssl pkey -in "$KEY_PATH" -pubout -outform DER > "$key_public"
    openssl x509 -in "$CERT_PATH" -pubkey -noout |
        openssl pkey -pubin -outform DER > "$cert_public"
    if ! cmp -s "$key_public" "$cert_public"; then
        echo "Error: the signing key does not match $CERT_PATH." >&2
        echo "Restore the matching key or set IOS_UDID_CERT_DIR to its directory." >&2
        exit 1
    fi
fi

if [ ! -f "$PROFILE_PATH" ]; then
    echo "Error: configuration profile not found: $PROFILE_PATH" >&2
    exit 1
fi

temporary_profile=$(mktemp "$PROJECT_DIR/public/profile_signed.mobileconfig.XXXXXX")
trap 'rm -f "${key_public:-}" "${cert_public:-}" "$temporary_profile"' EXIT HUP INT TERM
openssl smime -sign -binary -in "$PROFILE_PATH" \
    -out "$temporary_profile" -signer "$CERT_PATH" -inkey "$KEY_PATH" \
    -outform DER -nodetach
openssl smime -verify -binary -inform DER -in "$temporary_profile" \
    -noverify -out /dev/null
mv "$temporary_profile" "$SIGNED_PROFILE_PATH"

echo "Signed profile created and verified: $SIGNED_PROFILE_PATH"
echo "Public certificate: $CERT_PATH"
echo "Private signing key stays outside the repository: $KEY_PATH"
if [ "$key_was_created" = true ]; then
    echo "A new CA was created. Devices must install and trust this certificate."
fi
