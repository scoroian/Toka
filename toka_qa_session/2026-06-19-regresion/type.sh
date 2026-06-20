#!/usr/bin/env bash
# Escribe texto carácter a carácter (fiable en teclados con autocompletado agresivo).
# Uso: ./type.sh <serial> <texto-sin-espacios>
# Para espacios usa %s dentro del texto.
set -e
S="$1"; shift
TXT="$*"
len=${#TXT}
for (( i=0; i<len; i++ )); do
  ch="${TXT:$i:1}"
  if [ "$ch" = " " ]; then ch="%s"; fi
  adb.exe -s "$S" shell input text "$ch" >/dev/null 2>&1
  sleep 0.07
done
