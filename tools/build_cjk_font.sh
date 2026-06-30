#!/bin/bash
# Build CJK bitmap font inside docker (keeps host clean).
# Usage: ./tools/build_cjk_font.sh [--size 16] [--out fonts/simon_zh16.dcjk] [--subset strings/chars.txt]
#
# System font paths inside container are mapped from host.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJ_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SIZE=16
OUT="fonts/simon_zh16.dcjk"
FONT=""
SUBSET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --size) SIZE="$2"; shift 2;;
        --out)  OUT="$2"; shift 2;;
        --font) FONT="--font $2"; shift 2;;
        --subset) SUBSET="--subset $2"; shift 2;;
        *) echo "Unknown arg: $1"; exit 1;;
    esac
done

echo "=== Building CJK font (size=${SIZE}) ==="

docker run --rm \
    -v "$PROJ_DIR:/work" \
    -v /usr/share/fonts:/usr/share/fonts:ro \
    -w /work \
    python:3.12-slim \
    bash -c "
        pip install -q freetype-py 2>/dev/null
        python3 /work/tools/build_cjk_font.py --size ${SIZE} --out /work/${OUT} ${SUBSET} ${FONT}
    "

echo "=== Done: ${OUT} ==="
ls -lh "$PROJ_DIR/$OUT" 2>/dev/null || echo "(!) Output file not found"
