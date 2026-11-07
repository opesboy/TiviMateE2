
#!/bin/sh
# TiviMateE2 Python 2.7 - Independent Installer
# DreamOS DEB / Enigma2 IPK
# Updates: python27 only

set -eu

BASE_URL="https://raw.githubusercontent.com/opesboy/TiviMateE2/main/python27"
MANIFEST_URL="$BASE_URL/update.json"
PACKAGE_ID="enigma2-plugin-extensions-tivimatee2-py27"

GREEN="$(printf '\033[1;32m')"
YELLOW="$(printf '\033[1;33m')"
RED="$(printf '\033[1;31m')"
RESET="$(printf '\033[0m')"

info() {
    printf '%s[+]%s %s\n' "$GREEN" "$RESET" "$1"
}

fail() {
    printf '%s[ERROR]%s %s\n' "$RED" "$RESET" "$1" >&2
    exit 1
}

[ "$(id -u)" = "0" ] || fail "Please run as root."

FORMAT=""
case "${1:-}" in
    "") ;;
    --deb) FORMAT="deb" ;;
    --ipk) FORMAT="ipk" ;;
    *) fail "Use --deb or --ipk" ;;
esac

if [ -z "$FORMAT" ]; then
    if command -v dpkg >/dev/null 2>&1 &&
       [ -f /var/lib/dpkg/status ]; then
        FORMAT="deb"
    elif command -v opkg >/dev/null 2>&1; then
        FORMAT="ipk"
    else
        fail "No supported package manager."
    fi
fi

if [ "$FORMAT" = "deb" ]; then
    command -v dpkg >/dev/null 2>&1 ||
        fail "dpkg is not available."
else
    command -v opkg >/dev/null 2>&1 ||
        fail "opkg is not available."
fi

PYTHON=""
for candidate in python2 python python3; do
    if command -v "$candidate" >/dev/null 2>&1; then
        PYTHON="$candidate"
        break
    fi
done

[ -n "$PYTHON" ] || fail "Python is required."

WORKDIR="$(mktemp -d /tmp/tivimate-py27.XXXXXX)" ||
    fail "Cannot create temporary directory."

trap 'rm -rf "$WORKDIR"' EXIT
trap 'exit 1' HUP INT TERM

download() {
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$2" "$1" && [ -s "$2" ] && return 0
    fi
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$2" "$1" &&
            [ -s "$2" ] && return 0
    fi
    return 1
}

info "TiviMateE2 Python 2.7 Installer"
info "Independent Update Channel"
info "Format: $FORMAT"

download "$MANIFEST_URL" "$WORKDIR/update.json" ||
    fail "Cannot download update.json."

"$PYTHON" - "$WORKDIR/update.json" "$FORMAT" > "$WORKDIR/info" <<'PY'
from __future__ import print_function
import json
import re
import sys

with open(sys.argv[1], "rb") as f:
    data = json.load(f)

fmt = sys.argv[2]
package = "enigma2-plugin-extensions-tivimatee2-py27"

assert data.get("channel") == "python27"
assert data.get("package_id") == package
assert data.get("enabled") is True

version = str(data.get("version", ""))
assert re.match(r"^[0-9]+\.[0-9]+\.[0-9]+$", version)

entry = data.get("packages", {}).get(fmt, {})
url = entry.get("url", "")
sha = entry.get("sha256", "").lower()

expected = (
    "https://raw.githubusercontent.com/opesboy/"
    "TiviMateE2/main/python27/"
    "%s_%s_all.%s" % (package, version, fmt)
)

assert url == expected
assert re.match(r"^[a-f0-9]{64}$", sha)

print(version)
print(url)
print(sha)
PY

VERSION="$(sed -n '1p' "$WORKDIR/info")"
URL="$(sed -n '2p' "$WORKDIR/info")"
EXPECTED_SHA="$(sed -n '3p' "$WORKDIR/info")"

[ -n "$VERSION" ] || fail "Invalid version."
[ -n "$URL" ] || fail "Invalid package URL."

PACKAGE="$WORKDIR/${PACKAGE_ID}_${VERSION}_all.${FORMAT}"

info "Version: $VERSION"
info "Downloading package..."

download "$URL" "$PACKAGE" ||
    fail "Package download failed."

if command -v sha256sum >/dev/null 2>&1; then
    ACTUAL_SHA="$(sha256sum "$PACKAGE" | awk '{print $1}')"
elif command -v openssl >/dev/null 2>&1; then
    ACTUAL_SHA="$(openssl dgst -sha256 "$PACKAGE" |
        sed 's/^.*= //')"
else
    fail "SHA-256 verification unavailable."
fi

[ "$ACTUAL_SHA" = "$EXPECTED_SHA" ] ||
    fail "SHA-256 mismatch. Installation cancelled."

info "SHA-256 verified."

if [ "$FORMAT" = "deb" ]; then
    if command -v dpkg-deb >/dev/null 2>&1; then
        INTERNAL_ID="$(dpkg-deb -f "$PACKAGE" Package)"
        [ "$INTERNAL_ID" = "$PACKAGE_ID" ] ||
            fail "Incorrect package identifier."
    fi

    info "Installing DEB..."
    dpkg -i "$PACKAGE" ||
        fail "DEB installation failed."
else
    info "Installing IPK..."
    opkg install "$PACKAGE" ||
        fail "IPK installation failed."
fi

info "Installation completed: $VERSION"
info "Please restart Enigma2 GUI."
