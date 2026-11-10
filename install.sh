#!/bin/sh
set -eu

# TiviMateE2 Installer — Version 1.0.33-r142 (Python 3 + Python 2.7)

BASE="https://raw.githubusercontent.com/opesboy/TiviMateE2/main"

IPK="enigma2-plugin-extensions-tivimatee2_1.0.33_all.ipk"
DEB="enigma2-plugin-extensions-tivimatee2_1.0.33_all.deb"

IPK_SHA256="44964a764ddff739f4ed552cb8a0a82870eac6cdbb388af0c1281ed3f01ab062"
DEB_SHA256="18eec7e5144f5ccdb6d8d026609f8f93fb580d6c29b8b7a5ea707beabed02e8d"

if command -v dpkg >/dev/null 2>&1; then F="$DEB"; S="$DEB_SHA256"; else F="$IPK"; S="$IPK_SHA256"; fi
P="/tmp/$F"

wget --no-check-certificate -q -O "$P" "$BASE/$F" || curl -k -L -s -o "$P" "$BASE/$F"
[ "$(sha256sum "$P" | aw
