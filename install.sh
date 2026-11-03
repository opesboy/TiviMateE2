#!/bin/sh
set -eu

# TiviMateE2 Installer — Version 1.0.28-r136

BASE="https://raw.githubusercontent.com/opesboy/TiviMateE2/main"

IPK="enigma2-plugin-extensions-tivimatee2_1.0.28_all.ipk"
DEB="enigma2-plugin-extensions-tivimatee2_1.0.28_all.deb"

IPK_SHA256="8cbbedac2876bf73cff4f56391bdce4a9ad12f67c19d7c812f8634a0b280f68e"
DEB_SHA256="e2f556581b15f10e60816814b3ff475cd9d6d56ef3300b484b3e6e8626ef1055"

# Detect package manager
if command -v opkg >/dev/null 2>&1; then
    PACKAGE="$IPK"
    SHA256="$IPK_SHA256"
    MANAGER="opkg"
elif command -v dpkg >/dev/null 2>&1; then
    PACKAGE="$DEB"
    SHA256="$DEB_SHA256"
    MANAGER="dpkg"
else
    echo "Unsupported system: opkg/dpkg not found" >&2
    exit 1
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d /tmp/tivimatee2.XXXXXX)
trap 'rm -rf "$TEMP_DIR"' EXIT

PACKAGE_PATH="$TEMP_DIR/$PACKAGE"

# Download package
if ! wget -qO "$PACKAGE_PATH" "$BASE/$PACKAGE"; then
    echo "Download failed: $BASE/$PACKAGE" >&2
    exit 1
fi

# Verify SHA256
if command -v sha256sum >/dev/null 2>&1; then
    printf '%s  %s\n' "$SHA256" "$PACKAGE_PATH" |
        sha256sum -c - >/dev/null || {
            echo "SHA-256 mismatch: installation cancelled" >&2
            exit 1
        }
elif command -v busybox >/dev/null 2>&1 &&
     busybox sha256sum --help >/dev/null 2>&1; then
    printf '%s  %s\n' "$SHA256" "$PACKAGE_PATH" |
        busybox sha256sum -c - >/dev/null || {
            echo "SHA-256 mismatch: installation cancelled" >&2
            exit 1
        }
else
    echo "SHA-256 verification unavailable" >&2
    exit 1
fi

# Install package
if [ "$MANAGER" = "opkg" ]; then
    opkg install --force-reinstall "$PACKAGE_PATH"
else
    dpkg -i "$PACKAGE_PATH"
fi

echo "TiviMateE2 1.0.28-r136 installed successfully"
