#!/usr/bin/env bash
# Captura + redimensiona una pantalla y devuelve la ruta WSL del PNG listo para Read.
# Uso: ./shot.sh <serial> <nombre>
# Ej:  ./shot.sh emulator-5554 hoy-01
set -e
SERIAL="$1"
NAME="$2"
MAGICK="/mnt/c/Program Files/ImageMagick-7.1.2-Q16-HDRI/magick.exe"
WIN_DIR='C:\tmp\toka'
WSL_DIR='/mnt/c/tmp/toka'
adb.exe -s "$SERIAL" exec-out screencap -p > "$WSL_DIR/$NAME.png"
"$MAGICK" "$WIN_DIR\\$NAME.png" -resize "1900x1900>" "$WIN_DIR\\${NAME}_s.png"
echo "$WSL_DIR/${NAME}_s.png"
