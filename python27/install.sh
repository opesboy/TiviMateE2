#!/bin/sh
# TiviMateE2 Python 2.7 - DreamOS / Enigma2 installer
# Dedicated update channel: opesboy/TiviMateE2/main/python27
# Does not read the Python 3 update.json or install the Python 3 package.
set -eu

CHANNEL_URL='https://raw.githubusercontent.com/opesboy/TiviMateE2/main/python27/update.json'
PACKAGE_ID='enigma2-plugin-extensions-tivimatee2-py27'

if [ -t 1 ]; then
  GREEN=$(printf '\033[1;32m')
  YELLOW=$(printf '\033[1;33m')
  RED=$(printf '\033[1;31m')
  RESET=$(printf '\033[0m')
else
  GREEN=''; YELLOW=''; RED=''; RESET=''
fi

info() { printf '%s[+]%s %s\n' "$GREEN" "$RESET" "$*"; }
warn() { printf '%s[!]%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
fail() { printf '%s[x]%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }

FORMAT=''
case "${1:-}" in
  '') ;;
  --deb) FORMAT='deb' ;;
  --ipk) FORMAT='ipk' ;;
  --help|-h)
    printf 'Usage: sh install.sh [--deb|--ipk]\n'
    printf 'Without options, DEB is selected on dpkg/DreamOS and IPK on opkg receivers.\n'
    exit 0 ;;
  *) fail 'Unknown option. Use --deb or --ipk.' ;;
esac

[ "$(id -u)" = '0' ] || fail 'Run as root (SSH root login).'

if [ -z "$FORMAT" ]; then
  if command -v dpkg >/dev/null 2>&1 && [ -f /var/lib/dpkg/status ]; then
    FORMAT='deb'
  elif command -v opkg >/dev/null 2>&1; then
    FORMAT='ipk'
  elif command -v dpkg >/dev/null 2>&1; then
    FORMAT='deb'
  else
    fail 'Neither dpkg nor opkg is available.'
  fi
fi

if [ "$FORMAT" = 'deb' ]; then
  command -v dpkg >/dev/null 2>&1 || fail 'DEB selected but dpkg is unavailable.'
else
  command -v opkg >/dev/null 2>&1 || fail 'IPK selected but opkg is unavailable.'
fi

PYTHON=''
for candidate in python2 python python3; do
  if command -v "$candidate" >/dev/null 2>&1; then
    PYTHON="$candidate"
    break
  fi
done
[ -n "$PYTHON" ] || fail 'Python is required to parse and validate update.json.'

if ! command -v sha256sum >/dev/null 2>&1 && ! command -v openssl >/dev/null 2>&1; then
  fail 'sha256sum or openssl is required for secure package verification.'
fi

WORK_BASE='/tmp'
for candidate in /media/hdd /media/usb; do
  if [ -d "$candidate" ] && [ -w "$candidate" ] && grep -q " $candidate " /proc/mounts 2>/dev/null; then
    WORK_BASE="$candidate"
    break
  fi
done
WORKDIR=$(mktemp -d "$WORK_BASE/tivimatee2-py27.XXXXXX") || fail 'Cannot create temporary download folder.'
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT HUP INT TERM

fetch() {
  url="$1"; target="$2"
  if command -v wget >/dev/null 2>&1 && wget -q -O "$target" "$url"; then
    [ -s "$target" ] && return 0
  fi
  if command -v curl >/dev/null 2>&1 && curl -fsSL --connect-timeout 15 -o "$target" "$url"; then
    [ -s "$target" ] && return 0
  fi
  return 1
}

info 'TiviMateE2 Python 2.7 - independent update channel'
info "Package format: $FORMAT"
info 'Fetching dedicated python27/update.json...'
fetch "$CHANNEL_URL" "$WORKDIR/update.json" || fail 'Cannot download Python 2.7 update manifest.'

# The manifest is parsed with Python 2 / 3 stdlib (no external JSON dependency).
# Require the exact Python 2.7 package and repo path, with version X.Y.Z only.
if ! "$PYTHON" - "$WORKDIR/update.json" "$FORMAT" > "$WORKDIR/metadata" <<'PY'
from __future__ import print_function
import json, re, sys
with open(sys.argv[1], 'rb') as stream:
    data = json.load(stream)
fmt = sys.argv[2]
pkg = 'enigma2-plugin-extensions-tivimatee2-py27'
assert data.get('channel') == 'python27', 'Wrong update channel'
assert data.get('package_id') == pkg, 'Wrong package identifier'
assert data.get('enabled') is True, 'Update channel is disabled'
version = str(data.get('version') or '')
assert re.match(r'^[0-9]+\.[0-9]+\.[0-9]+$', version), 'Bad version'
entry = data.get('packages', {}).get(fmt) or {}
url = entry.get('url') or ''
sha = (entry.get('sha256') or '').lower()
expected = ('https://raw.githubusercontent.com/opesboy/TiviMateE2/main/'
            'python27/%s_%s_all.%s' % (pkg, version, fmt))
assert url == expected, 'Package URL must be in the dedicated python27 folder'
assert re.match(r'^[0-9a-f]{64}$', sha), 'Invalid SHA-256'
print(version)
print(url)
print(sha)
PY
then
  fail 'Invalid or unsafe Python 2.7 update manifest.'
fi

VERSION=$(sed -n '1p' "$WORKDIR/metadata")
DOWNLOAD_URL=$(sed -n '2p' "$WORKDIR/metadata")
EXPECTED_SHA=$(sed -n '3p' "$WORKDIR/metadata")
PACKAGE_FILE="$WORKDIR/${PACKAGE_ID}_${VERSION}_all.${FORMAT}"

info "Target version: $VERSION (no revision suffix)"
info 'Downloading verified package...'
fetch "$DOWNLOAD_URL" "$PACKAGE_FILE" || fail 'Package download failed.'

if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL_SHA=$(sha256sum "$PACKAGE_FILE" | awk '{print $1}')
else
  ACTUAL_SHA=$(openssl dgst -sha256 "$PACKAGE_FILE" | sed 's/^.*= //')
fi
[ "$ACTUAL_SHA" = "$EXPECTED_SHA" ] || fail 'SHA-256 mismatch: package will NOT be installed.'
info 'SHA-256 verified.'

# Verify the embedded control package name when local package inspection is available.
if [ "$FORMAT" = 'deb' ] && command -v dpkg-deb >/dev/null 2>&1; then
  INTERNAL_ID=$(dpkg-deb -f "$PACKAGE_FILE" Package 2>/dev/null || true)
  [ "$INTERNAL_ID" = "$PACKAGE_ID" ] || fail 'DEB contains a different package identifier.'
fi

info "Installing TiviMateE2 Python 2.7 ${VERSION}..."
if [ "$FORMAT" = 'deb' ]; then
  dpkg -i "$PACKAGE_FILE" || fail 'dpkg reported installation failure. Check missing dependencies.'
else
  opkg install "$PACKAGE_FILE" || fail 'opkg reported installation failure. Check missing dependencies.'
fi
info 'Installation completed. Restart the Enigma2 GUI to load the plugin.'
