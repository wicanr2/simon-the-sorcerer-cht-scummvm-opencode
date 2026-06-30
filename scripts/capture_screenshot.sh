#!/bin/bash
# Headless screenshot capture for Simon CHT
set -e
apt-get update -qq && apt-get install -y -qq xvfb python3-pip libsdl2-2.0-0 libsdl2-net-2.0-0 libjpeg-turbo8 libpng16-16t64 libfreetype6 libvorbisfile3 libogg0 libtheora0 libsndio7.0 libcurl4t64 libmpg123-0t64 libfluidsynth3 libmad0 libfaad2 > /dev/null 2>&1
pip install -q Pillow 2>/dev/null

export DISPLAY=:99
Xvfb :99 -screen 0 640x480x24 +extension RANDR &
sleep 1

cd /src
./scummvm --path=/game agos:simon1 &
GAME_PID=$!
sleep 6

python3 -c "
from PIL import ImageGrab
img = ImageGrab.grab()
img.save('/game/screenshots/simon_cht_01.png')
print('Saved:', img.size)
" 2>&1

kill $GAME_PID 2>/dev/null
ls -lh /game/screenshots/
