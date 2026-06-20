#!/usr/bin/env bash
# Vuelca la UI y lista, por nodo: bounds :: (texto o content-desc).
# Coords reales del dispositivo. Centro = ((x1+x2)/2, (y1+y2)/2).
# Uso: ./ui.sh <serial>
set -e
S="$1"
adb.exe -s "$S" shell uiautomator dump /sdcard/ui.xml >/dev/null 2>&1
adb.exe -s "$S" shell cat /sdcard/ui.xml 2>/dev/null | tr '<' '\n<' \
  | grep -E '(content-desc|text)="[^"]+"' \
  | sed -E 's/.*(content-desc|text)="([^"]*)".*bounds="([^"]*)".*/\3  ::  \2/' \
  | grep -vE '^\[0,0\]\[1080,(11|[0-9])\]' \
  | awk '!seen[$0]++'
