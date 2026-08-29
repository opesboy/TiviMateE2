#!/bin/sh
set -e

BASE="https://raw.githubusercontent.com/opesboy/TiviMateE2/main"
IPK="enigma2-plugin-extensions-tivimatee2_1.0.09_all.ipk"
DEB="enigma2-plugin-extensions-tivimatee2_1.0.09_all.deb"

if command -v opkg >/dev/null 2>&1; then
    wget -qO "/tmp/$IPK" "$BASE/$IPK"
    opkg install --force-reinstall "/tmp/$IPK"

elif command -v dpkg >/dev/null 2>&1; then
    wget -qO "/tmp/$DEB" "$BASE/$DEB"
    dpkg -i "/tmp/$DEB"

else
    echo "Unsupported system: opkg/dpkg not found"
    exit 1
fi

exit 0
