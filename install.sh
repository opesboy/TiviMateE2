#!/bin/sh
set -eu

# TiviMateE2 Installer — Version 1.0.29-r137 (Python 3 + Python 2.7)

BASE="https://raw.githubusercontent.com/opesboy/TiviMateE2/main"

IPK="enigma2-plugin-extensions-tivimatee2_1.0.29_all.ipk"
DEB="enigma2-plugin-extensions-tivimatee2_1.0.29_all.deb"

IPK_SHA256="8de3d225ba4d4d31cd3a44b03da0524567e4ee20f2f3c2ce75aa4e5a17164735"
DEB_SHA256="464286f6099c40e10c1819acd51f3d092b23c8ab88a72588908b960bae14e649"

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

# Download package (wget -> curl -> python for VTi/old image
