
#!/bin/sh
# TiviMateE2 Installer - Version 1.0.36-r145 (Python 3 + Python 2.7)
# wget -q --no-check-certificate "https://raw.githubusercontent.com/opesboy/TiviMateE2/main/installer.sh" -O - | /bin/sh

VERSION="1.0.36-r145"
BASE="https://raw.githubusercontent.com/opesboy/TiviMateE2/main"
IPK="enigma2-plugin-extensions-tivimatee2_1.0.36_all.ipk"
DEB="enigma2-plugin-extensions-tivimatee2_1.0.36_all.deb"
PKG_NAME="enigma2-plugin-extensions-tivimatee2"
SHA256="07b4b811ca92987537d70618da053205f73d7b551ca51bf0a91780779d508e3c"
NEED_KB=60000

ok()   { echo "[ OK ] $*"; }
info() { echo "[ .. ] $*"; }
fail() { echo "[FAIL] $*"; exit 1; }

cat <<'BANNER'

 _______  ___   __   __  ___   __   __  _______  _______  _______
|       ||   | |  | |  ||   | |  |_|  ||   _   ||       ||       |
|_     _||   | |  |_|  ||   | |       ||  |_|  ||_     _||    ___|
  |   |  |   | |       ||   | |       ||       |  |   |  |   |___
  |   |  |   | |       ||   | |       ||       |  |   |  |    ___|
  |   |  |   |  |     | |   | | ||_|| ||   _   |  |   |  |   |___
  |___|  |___|   |___|  |___| |_|   |_||__| |__|  |___|  |_______|

                       _______  _______
                      |       ||       |
                      |    ___||____   |
                      |   |___  ____|  |
                      |    ___|| ______|
                      |   |___ | |_____
                      |_______||_______|

                TiviMate E2 - online installer
                 Version 1.0.36-r145
     -------------------------------------------------------------
BANNER
echo "--------------------------------------------"

# ---- image -----------------------------------------------------------------
IMAGE=""
if [ -f /etc/image-version ]; then
    D=$(grep -i '^distro=' /etc/image-version | head -n1 | cut -d= -f2)
    V=$(grep -iE '^(imageversion|version)=' /etc/image-version | head -n1 | cut -d= -f2)
    [ -n "$D" ] && IMAGE="$D $V"
fi
[ -z "$IMAGE" ] && [ -f /etc/vtiversion.info ] && IMAGE="VTi $(head -n1 /etc/vtiversion.info)"
[ -z "$IMAGE" ] && [ -f /etc/issue ] && IMAGE=$(head -n1 /etc/issue | sed 's/\\[a-z]//g')
[ -z "$IMAGE" ] && IMAGE="Enigma2"
case "$(echo "$IMAGE" | tr 'A-Z' 'a-z')" in
    openatv*) IMAGE="OpenATV ${IMAGE#* }" ;;
    pure2*)   IMAGE="PurE2 ${IMAGE#* }" ;;
    openpli*) IMAGE="OpenPLi ${IMAGE#* }" ;;
esac
IMAGE=$(echo "$IMAGE" | tr -s ' ')

PY=""
for p in python3 python python2; do
    if command -v "$p" >/dev/null 2>&1; then
        PY=$("$p" -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null) && break
    fi
done
case "$PY" in
    3.*|2.7) ok "Image: $IMAGE  (supported)" ;;
    "")      fail "Image: $IMAGE  - Python not found" ;;
    *)       fail "Image: $IMAGE  - Python $PY not supported" ;;
esac
ok "Python: $PY"

# ---- free space ------------------------------------------------------------
free_kb() { df -k "$1" 2>/dev/null | awk 'NR>1 {v=$(NF-2)} END {print v+0}'; }
TMPDIR=""
for d in /tmp /var/volatile/tmp /media/hdd /media/usb; do
    [ -d "$d" ] && [ -w "$d" ] || continue
    if [ "$(free_kb "$d")" -ge 25000 ]; then TMPDIR="$d"; break; fi
done
[ -n "$TMPDIR" ] || fail "Not enough free space to download the package"
FLASH=$(free_kb /usr)
info "Free space: download area $(free_kb "$TMPDIR") kB, receiver flash $FLASH kB"
[ "$FLASH" -ge "$NEED_KB" ] || fail "Receiver flash needs at least $NEED_KB kB free"

# ---- versions --------------------------------------------------------------
info "Latest version: $VERSION"
if command -v dpkg >/dev/null 2>&1; then
    MGR="dpkg"; F="$DEB"
    CUR=$(dpkg-query -W -f='${Version}' "$PKG_NAME" 2>/dev/null)
else
    MGR="opkg"; F="$IPK"
    CUR=$(opkg status "$PKG_NAME" 2>/dev/null | awk '/^Version:/ {print $2}')
fi
if [ -n "$CUR" ]; then info "Installed version: $CUR"; else info "Installed version: none"; fi

# ---- download --------------------------------------------------------------
P="$TMPDIR/$F"
rm -f "$P"
info "Downloading the package ..."
wget -q --no-check-certificate -O "$P" "$BASE/$F" 2>/dev/null || \
    curl -k -L -s -o "$P" "$BASE/$F" 2>/dev/null || { rm -f "$P"; fail "Download failed - check the internet connection"; }
[ -s "$P" ] || { rm -f "$P"; fail "Downloaded file is empty"; }
SIZE=$(( $(wc -c < "$P") / 1024 ))
ok "Downloaded $SIZE kB"

if command -v sha256sum >/dev/null 2>&1; then
    [ "$(sha256sum "$P" | awk '{print $1}')" = "$SHA256" ] || { rm -f "$P"; fail "Checksum error - file is damaged, try again"; }
    ok "Checksum verified"
fi

# ---- install ---------------------------------------------------------------
info "Installing TiviMate $VERSION ..."
if [ "$MGR" = "dpkg" ]; then
    dpkg -i --force-overwrite "$P" >/dev/null 2>&1 || apt-get -f -y install >/dev/null 2>&1 || { rm -f "$P"; fail "Install failed"; }
else
    opkg install --force-reinstall --force-overwrite "$P" >/dev/null 2>&1 || { rm -f "$P"; fail "Install failed"; }
fi
rm -f "$P"
EXT=/usr/lib/enigma2/python/Plugins/Extensions
[ -d "$EXT/TiviMateE2" ] || [ -d "$EXT/TiviMateE2Py27" ] || fail "Install failed - plugin files not found"
ok "TiviMate $VERSION installed"

echo "--------------------------------------------"
info "Restarting Enigma2 in 3 seconds ..."
sleep 3
killall -9 enigma2 >/dev/null 2>&1 || true
exit 0
