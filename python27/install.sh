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
    # VTi / old images: BusyBox wget has no HTTPS and curl may be missing.
    if [ -n "$PYTHON" ]; then
        "$PYTHON" - "$1" "$2" <<'PYDL' && [ -s "$2" ] && return 0
import sys
try:
    from urllib2 import urlopen, Request
except ImportError:
    from urllib.request import urlopen, Request
req = Request(sys.argv[1], headers={"User-Agent": "TiviMateE2-installer"})
data = urlopen(req, timeout=60).read()
open(sys.argv[2], "wb").write(data)
PYDL
    fi
    return 1
}

info "TiviMateE2 Python 2.7 Installer"
info "Independent Update Channel"
info "Format: $FORMAT"

download "$MANIFEST_URL" "$WORKDIR/update.json" ||
    fail "Cannot download update.json."

"$PYTHON" - "$WORKDIR/update.json" "$FORMAT" > "$WORKDIR/inf
