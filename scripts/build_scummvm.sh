#!/bin/bash
# Build patched ScummVM in docker (keeps host clean).
# Usage: ./scripts/build_scummvm.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJ_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "=== Building patched ScummVM (AGOS engine + Simon CHT) ==="

docker run --rm \
    -v "$PROJ_DIR/scummvm-src:/src" \
    -v "$PROJ_DIR/build:/build" \
    -w /src \
    ubuntu:24.04 \
    bash -c "
        apt-get update -qq && apt-get install -y -qq \
            build-essential libsdl2-dev libsdl2-net-dev \
            libfreetype6-dev libflac-dev libogg-dev libvorbis-dev \
            libmpeg2-4-dev libmad0-dev libjpeg-turbo8-dev libpng-dev \
            libtheora-dev libfaad-dev libfluidsynth-dev \
            libcurl4-openssl-dev libsndio-dev \
            pkg-config zlib1g-dev nasm > /dev/null 2>&1

        echo '=== Configuring... ==='
        ./configure --disable-all-engines --enable-engine=agos --enable-release \
            --disable-mad --disable-vorbis --disable-flac --disable-fluidsynth \
            2>&1 | tail -5

        echo '=== Building... ==='
        make -j\$(nproc) 2>&1 | tail -20

        echo '=== Done ==='
        ls -lh scummvm
    "

echo "=== Build complete ==="
ls -lh "$PROJ_DIR/build/scummvm" 2>/dev/null || echo "Binary not found in build/"
