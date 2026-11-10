#!/bin/sh
set -eu

# TiviMateE2 Installer — Version 1.0.32-r140 (Python 3 + Python 2.7)

BASE="https://raw.githubusercontent.com/opesboy/TiviMateE2/main"

IPK="enigma2-plugin-extensions-tivimatee2_1.0.32_all.ipk"
DEB="enigma2-plugin-extensions-tivimatee2_1.0.32_all.deb"

IPK_SHA256="42513d7d4349c04e7d661a44fbfd5105304ec530f05a78dc7d60fee596e949f1"
DEB_SHA256="06a02501a6c1044284bbf08ce8fb8859b5000225e88b81773830fa939e814649"

if command -v dpkg >/dev/null 2>&1; then F="$DEB"; S="$DEB_SHA256"; else F="$IPK"; S="$IPK_SHA256"; fi
P="/tmp/$F"

wget --no-check-certificate -q -O "$P" "$BASE/$F" || curl -k -L -s -o "$P" "$BASE/$F"
[ "$(sha256sum "$P" | awk '{print $1}')" = "$S" ] || { echo "Checksum error"; rm -f "$P"; exit 1; }

if command -v dpkg >/dev/null 2>&1; then
    dpkg -i --force-overwrite "$P" || apt-get -f -y install
else
    opkg install --force-reinstall --force-overwrite "$P"
fi
rm -f "$P"

echo "TiviMateE2 1.0.32-r140 installed. Restarting Enigma2..."
sleep 2
killall -9 enigma2 || true
