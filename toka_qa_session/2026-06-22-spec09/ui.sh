#!/usr/bin/env bash
# Helper de UI dump + búsqueda + tap por texto.
# Uso:
#   ./ui.sh <serial> dump                 -> vuelca XML y lo lista (nodos con texto/clickables)
#   ./ui.sh <serial> find "<query>"       -> busca substring en text|desc|id
#   ./ui.sh <serial> tap  "<query>"       -> tap en el centro del PRIMER nodo que coincide
#   ./ui.sh <serial> tapn <n> "<query>"   -> tap en el n-ésimo (1-based) nodo que coincide
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
S="$1"; CMD="$2"
XML="/mnt/c/tmp/toka/uidump_${S}.xml"
dump() {
  # uiautomator en MIUI escupe una excepción de tema y devuelve exit!=0 PERO igual
  # escribe el archivo; por eso ignoramos el código de salida.
  adb.exe -s "$S" shell uiautomator dump /sdcard/window_dump.xml >/dev/null 2>&1 || true
  # adb.exe es binario Windows: no entiende rutas WSL en `pull`. Usamos exec-out cat
  # con redirección de bash (que sí escribe en la ruta WSL).
  adb.exe -s "$S" exec-out cat /sdcard/window_dump.xml > "$XML" 2>/dev/null || true
}
case "$CMD" in
  dump) dump; python3 "$DIR/uifind.py" "$XML" ;;
  find) dump; python3 "$DIR/uifind.py" "$XML" "$3" ;;
  tap)
    dump
    line=$(python3 "$DIR/uifind.py" "$XML" "$3" | head -1)
    coords=$(echo "$line" | grep -oE '^[0-9]+,[0-9]+' || true)
    if [ -z "$coords" ]; then echo "NO MATCH: $3"; exit 2; fi
    x=${coords%,*}; y=${coords#*,}
    adb.exe -s "$S" shell input tap "$x" "$y"
    echo "tap $coords <- $3"
    ;;
  tapn)
    n="$3"; q="$4"; dump
    line=$(python3 "$DIR/uifind.py" "$XML" "$q" | sed -n "${n}p")
    coords=$(echo "$line" | grep -oE '^[0-9]+,[0-9]+' || true)
    if [ -z "$coords" ]; then echo "NO MATCH #$n: $q"; exit 2; fi
    x=${coords%,*}; y=${coords#*,}
    adb.exe -s "$S" shell input tap "$x" "$y"
    echo "tap $coords <- #$n $q"
    ;;
  *) echo "uso: ui.sh <serial> dump|find|tap|tapn"; exit 1 ;;
esac
