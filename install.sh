#!/bin/sh
set -eu

# TiviMateE2 Installer — Version 1.0.30-r138 (Python 3 + Python 2.7)

BASE="https://raw.githubusercontent.com/opesboy/TiviMateE2/main"

IPK="enigma2-plugin-extensions-tivimatee2_1.0.30_all.ipk"
DEB="enigma2-plugin-extensions-tivimatee2_1.0.30_all.deb"

IPK_SHA256="07726c87413f49e4f392c6b984c25d7f6a637953631e816d110bb778601cdaf3"
DEB_SHA256="b9110e01892315c7cb3d6d7f65b96dd6f6bb31c7cf0162b9bca78d762a2c9cf5"

# Detect package manager
if command -v opkg >/dev/null 2>&1; then
