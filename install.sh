
#!/bin/sh
set -eu

BASE="https://raw.githubusercontent.com/opesboy/TiviMateE2/main"
IPK="enigma2-plugin-extensions-tivimatee2_1.0.27_all.ipk"
DEB="enigma2-plugin-extensions-tivimatee2_1.0.27_all.deb"
SHA256="96f99a56d5f1c24db94a19912c56dc601828869467e795c1f8a0505162446e72"

if command -v opkg >/dev/null 2>&1; then
    PACKAGE="$IPK"
    MANAGER="opkg"
elif command -v dpkg >/dev/null 2>&1; then
    PACKAGE="$DEB"
    MANAGER="dpkg"
else
    echo "Unsupported system: opkg/dpkg not found" >&2
    exit 1
fi

TEMP_DIR=$(mktemp -d /tmp/tivimatee2.XXXXXX)
trap 'rm -rf "$TEMP_DIR"' 0
PACKAGE_PATH="$TEMP_DIR/$PACKAGE"

if ! wget -qO "$PACKAGE_PATH" "$BASE/$PACKAGE"; then
    echo "Download failed: $BASE/$PACKAGE" >&2
    exit 1
fi

if command -v sha256sum >/dev/null 2>&1; then
    printf '%s  %s\n' "$SHA256" "$PACKAGE_PATH" | sha256sum -c - >/dev/null || {
        echo "SHA-256 mismatch: installation cancelled" >&2
        exit 1
    }
elif command -v busybox >/dev/null 2>&1 && busybox sha256sum --help >/dev/null 2>&1; then
    printf '%s  %s\n' "$SHA256" "$PACKAGE_PATH" | busybox sha256sum -c - >/dev/null || {
        echo "SHA-256 mismatch: installation cancelled" >&2
        exit 1
    }
else
    echo "SHA-256 verification unavailable: installation cancelled" >&2
    exit 1
fi

if [ "$MANAGER" = "opkg" ]; then
    opkg install --force-reinstall "$PACKAGE_PATH"
else
    dpkg -i "$PACKAGE_PATH"
fi

echo "TiviMateE2 1.0.27-r135 installed successfully"
