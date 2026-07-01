#!/bin/bash
# Build Simon the Sorcerer CHT AppImage.
# Requires: appimagetool-x86_64.AppImage and linuxdeploy-x86_64.AppImage.
# Usage: ./scripts/build_appimage.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJ_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APPIMAGE_TOOLS="$PROJ_DIR/build/appimage-tools"
BUILD_DIR="$PROJ_DIR/build/appimage"

echo "=== Building Simon CHT AppImage ==="

# Ensure tools exist
mkdir -p "$APPIMAGE_TOOLS"
if [ ! -f "$APPIMAGE_TOOLS/appimagetool-x86_64.AppImage" ]; then
    echo "Downloading appimagetool..."
    wget -q -O "$APPIMAGE_TOOLS/appimagetool-x86_64.AppImage" \
        "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$APPIMAGE_TOOLS/appimagetool-x86_64.AppImage"
fi
if [ ! -f "$APPIMAGE_TOOLS/linuxdeploy-x86_64.AppImage" ]; then
    echo "Downloading linuxdeploy..."
    wget -q -O "$APPIMAGE_TOOLS/linuxdeploy-x86_64.AppImage" \
        "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage"
    chmod +x "$APPIMAGE_TOOLS/linuxdeploy-x86_64.AppImage"
fi

# Prepare AppDir
APPDIR="$BUILD_DIR/AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/lib" "$APPDIR/usr/share/simon1-cht"

# Copy binary
cp "$PROJ_DIR/scummvm-src/scummvm" "$APPDIR/usr/bin/"

# Copy CJK font and translation table (runtime assets)
cp "$PROJ_DIR/fonts/simon_zh12.dcjk" "$APPDIR/usr/share/simon1-cht/"
cp "$PROJ_DIR/fonts/simon_zh16.dcjk" "$APPDIR/usr/share/simon1-cht/"
cp "$PROJ_DIR/fonts/simon_zh.tab" "$APPDIR/usr/share/simon1-cht/"

# Copy game data files (user must provide their own)
cp "$PROJ_DIR/original_game/extracted/GAMEPC" "$APPDIR/usr/share/simon1-cht/"
cp "$PROJ_DIR/original_game/extracted/SIMON.GME" "$APPDIR/usr/share/simon1-cht/"
cp "$PROJ_DIR/original_game/extracted/STRIPPED.TXT" "$APPDIR/usr/share/simon1-cht/"
cp "$PROJ_DIR/original_game/extracted/TBLLIST" "$APPDIR/usr/share/simon1-cht/"
cp "$PROJ_DIR/original_game/extracted/ICON.DAT" "$APPDIR/usr/share/simon1-cht/"
cp "$PROJ_DIR/original_game/extracted/EFFECTS.VOC" "$APPDIR/usr/share/simon1-cht/" 2>/dev/null || true
cp "$PROJ_DIR/original_game/extracted/SIMON.VOC" "$APPDIR/usr/share/simon1-cht/" 2>/dev/null || true
cp "$PROJ_DIR/original_game/extracted/MT_FM.IBK" "$APPDIR/usr/share/simon1-cht/" 2>/dev/null || true

# Copy ScummVM GUI data
mkdir -p "$APPDIR/usr/share/scummvm"
cp "$PROJ_DIR/scummvm-src/dists/encoding.dat" "$APPDIR/usr/share/scummvm/" 2>/dev/null || true
cp "$PROJ_DIR/scummvm-src/dists/gui-icons.dat" "$APPDIR/usr/share/scummvm/" 2>/dev/null || true
cp "$PROJ_DIR/scummvm-src/dists/fonts.dat" "$APPDIR/usr/share/scummvm/" 2>/dev/null || true
cp "$PROJ_DIR/scummvm-src/dists/fonts-cjk.dat" "$APPDIR/usr/share/scummvm/" 2>/dev/null || true
cp "$PROJ_DIR/scummvm-src/dists/helpdialog.zip" "$APPDIR/usr/share/scummvm/" 2>/dev/null || true
cp "$PROJ_DIR/scummvm-src/dists/scummclassic.zip" "$APPDIR/usr/share/scummvm/" 2>/dev/null || true
cp "$PROJ_DIR/scummvm-src/dists/macgui.dat" "$APPDIR/usr/share/scummvm/" 2>/dev/null || true
cp "$PROJ_DIR/scummvm-src/dists/residualvm.zip" "$APPDIR/usr/share/scummvm/" 2>/dev/null || true

# Create AppRun wrapper
cat > "$APPDIR/AppRun" << 'APPRUN'
#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/usr/lib:${LD_LIBRARY_PATH:-}"
GAMEDIR="$HERE/usr/share/simon1-cht"
CFGDIR="${XDG_CONFIG_HOME:-$HOME/.config}/simon1-cht"
mkdir -p "$CFGDIR"
CFG="$CFGDIR/scummvm.ini"

# Auto-generate config if missing
if [ ! -f "$CFG" ]; then
    cat > "$CFG" << INI
[scummvm]
gui_browser_native=false
last_fullscreen_mode=3
[subtitles]
subtitles=1
speech_mute=0
[simon1]
engineid=agos
gameid=simon1
description=Simon the Sorcerer (CHT)
path=$GAMEDIR
language=zh
subtitles=1
speech_mute=0
INI
fi

exec "$HERE/usr/bin/scummvm" \
    --config="$CFG" \
    --themepath="$HERE/usr/share/scummvm" \
    --extrapath="$HERE/usr/share/scummvm" \
    simon1 "$@"
APPRUN
chmod +x "$APPDIR/AppRun"

# Create .desktop file
cat > "$APPDIR/simon1-cht.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=魔法師西蒙 繁體中文版
Comment=Simon the Sorcerer (Traditional Chinese)
Exec=scummvm
Icon=simon1-cht
Categories=Game;AdventureGame;
Terminal=false
DESKTOP

# Copy icon (use game's screenshot or default)
cp "$PROJ_DIR/screenshots/simon_cht_01.png" "$APPDIR/simon1-cht.png" 2>/dev/null || \
    cp "$PROJ_DIR/scummvm-src/icons/scummvm_256.png" "$APPDIR/simon1-cht.png" 2>/dev/null || \
    cp "$PROJ_DIR/scummvm-src/icons/scummvm_128.png" "$APPDIR/simon1-cht.png" 2>/dev/null || true

# Bundle shared libraries (use linuxdeploy)
echo "=== Bundling libraries with linuxdeploy... ==="
export OUTPUT="$APPDIR/simon1-cht.desktop"
export APPIMAGE_EXTRACT_AND_RUN=1
ARCH=x86_64 "$APPIMAGE_TOOLS/linuxdeploy-x86_64.AppImage" \
    --appdir "$APPDIR" \
    --desktop-file "$APPDIR/simon1-cht.desktop" \
    --icon-file "$APPDIR/simon1-cht.png" \
    --output appimage 2>&1 | tail -10

# Find the produced AppImage
APPIMAGE=$(ls "$BUILD_DIR"/*.AppImage 2>/dev/null | head -1)
if [ -z "$APPIMAGE" ]; then
    echo "=== AppImage not found. linuxdeploy failed? Trying manual ==="
    # Manual library bundling
    ldd "$APPDIR/usr/bin/scummvm" | grep "=> /" | awk '{print $3}' | \
        xargs -I{} cp -v {} "$APPDIR/usr/lib/" 2>/dev/null || true
fi

echo "=== AppImage build complete ==="
ls -lh "$BUILD_DIR"/*.AppImage 2>/dev/null || echo "No AppImage produced - check errors above"