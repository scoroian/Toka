#!/usr/bin/env bash
# Escribe texto carácter a carácter (fiable con autocompletado agresivo MIUI).
# Uso: ./type.sh <serial> <texto>   (usa %s literal para espacios si lo prefieres)
set -e
S="$1"; shift
TXT="$*"
len=${#TXT}
for (( i=0; i<len; i++ )); do
  ch="${TXT:$i:1}"
  if [ "$ch" = " " ]; then ch="%s"; fi
  adb.exe -s "$S" shell input text "$ch" >/dev/null 2>&1
  sleep 0.06
done
