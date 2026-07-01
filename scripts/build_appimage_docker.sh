#!/bin/bash
# Build a fully self-contained AppImage inside Docker.
# Includes: patched ScummVM + game data + CJK font + translation table.
# Usage: ./scripts/build_appimage_docker.sh
set -euo pipefail
PROJ_DIR="$(cd "$(dirname "$0")/.." && pwd)"
echo "=== Building Simon CHT AppImage in Docker ==="

docker run --rm --privileged \
    -v "$PROJ_DIR:/work" \
    -w /work \
    -e APPIMAGE_EXTRACT_AND_RUN=1 \
    ubuntu:24.04 \
    bash -c '
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
echo "=== 1. Installing build deps + appimagetool ==="
apt-get update -qq
apt-get install -y -qq \
    build-essential libsdl2-dev libsdl2-net-dev \
    libfreetype6-dev libflac-dev libogg-dev libvorbis-dev \
    libmpeg2-4-dev libmad0-dev libjpeg-turbo8-dev libpng-dev \
    libtheora-dev libfaad-dev libfluidsynth-dev \
    libcurl4-openssl-dev libsndio-dev \
    pkg-config zlib1g-dev nasm wget file > /dev/null 2>&1

# Download appimagetool
wget -q -O /tmp/appimagetool https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x /tmp/appimagetool

echo "=== 2. Building patched ScummVM (AGOS only) ==="
cd /work/scummvm-src
./configure --disable-all-engines --enable-engine=agos --enable-release \
    --disable-mad --disable-vorbis --disable-flac --disable-fluidsynth 2>&1 | tail -3
make -j$(nproc) 2>&1 | tail -5
echo "Binary built: $(ls -lh scummvm | awk "{print \$5}")"

echo "=== 3. Assembling AppDir ==="
APPDIR=/tmp/AppDir
rm -rf $APPDIR
mkdir -p $APPDIR/usr/bin $APPDIR/usr/lib $APPDIR/usr/share/simon1-cht $APPDIR/usr/share/scummvm

# Binary
cp scummvm $APPDIR/usr/bin/

# Libraries (all deps)
ldd scummvm | grep "=> /" | awk "{print \$3}" | xargs -I{} cp -v {} $APPDIR/usr/lib/ 2>/dev/null || true

# CJK font + translation
cp /work/fonts/simon_zh12.dcjk $APPDIR/usr/share/simon1-cht/
cp /work/fonts/simon_zh16.dcjk $APPDIR/usr/share/simon1-cht/
cp /work/fonts/simon_zh.tab   $APPDIR/usr/share/simon1-cht/

# Game data (ALL files from extracted ISO)
cp /work/original_game/extracted/* $APPDIR/usr/share/simon1-cht/ 2>/dev/null || true

# ScummVM engine data
cp /work/scummvm-src/dists/engine-data/encoding.dat  $APPDIR/usr/share/scummvm/ 2>/dev/null || true
cp /work/scummvm-src/dists/engine-data/fonts.dat     $APPDIR/usr/share/scummvm/ 2>/dev/null || true
cp /work/scummvm-src/dists/engine-data/helpdialog.zip $APPDIR/usr/share/scummvm/ 2>/dev/null || true
cp /work/scummvm-src/gui/themes/gui-icons.dat       $APPDIR/usr/share/scummvm/ 2>/dev/null || true

echo "=== 4. Writing AppRun ==="
cat > $APPDIR/AppRun << "APPRUN"
#!/bin/bash
HERE=$(dirname "$(readlink -f "$0")")
export LD_LIBRARY_PATH="$HERE/usr/lib:${LD_LIBRARY_PATH:-}"
GAMEDIR="$HERE/usr/share/simon1-cht"
CFGDIR="${XDG_CONFIG_HOME:-$HOME/.config}/simon1-cht"
mkdir -p "$CFGDIR"
CFG="$CFGDIR/scummvm.ini"

# Always regenerate config to ensure correct path
cat > "$CFG" << INI
[scummvm]
gui_browser_native=false
last_fullscreen_mode=3
[simon1]
engineid=agos
gameid=simon1
description=Simon the Sorcerer (CHT)
path=$GAMEDIR
language=zh
subtitles=1
speech_mute=0
INI

exec "$HERE/usr/bin/scummvm" \
    --config="$CFG" \
    --themepath="$HERE/usr/share/scummvm" \
    --extrapath="$HERE/usr/share/scummvm" \
    simon1 "$@"
APPRUN
chmod +x $APPDIR/AppRun

echo "=== 5. Writing .desktop + icon ==="
cat > $APPDIR/simon1-cht.desktop << "DESKTOP"
[Desktop Entry]
Type=Application
Name=魔法師西蒙 (CHT)
Comment=Simon the Sorcerer (Traditional Chinese)
Exec=scummvm
Icon=simon1-cht
Categories=Game;AdventureGame;
Terminal=false
DESKTOP

cp /work/screenshots/simon_cht_01.png $APPDIR/simon1-cht.png 2>/dev/null || true
ln -sf simon1-cht.png $APPDIR/.DirIcon

echo "=== 6. Verifying AppDir contents ==="
echo "Game files: $(ls $APPDIR/usr/share/simon1-cht/ | wc -l)"
echo "Libs: $(ls $APPDIR/usr/lib/ | wc -l)"
ls $APPDIR/usr/share/simon1-cht/GAMEPC $APPDIR/usr/share/simon1-cht/SIMON.GME
ls $APPDIR/AppRun $APPDIR/simon1-cht.desktop

echo "=== 7. Packing AppImage ==="
cd /tmp
export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH=x86_64
/tmp/appimagetool $APPDIR /work/build/simon1-cht-bundle.AppImage 2>&1 | tail -10

echo "=== 8. Done ==="
ls -lh /work/build/simon1-cht-bundle.AppImage
'