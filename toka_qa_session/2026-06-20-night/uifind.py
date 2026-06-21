#!/usr/bin/env python3
# Parsea un volcado uiautomator y localiza nodos por texto/desc/resource-id.
# Uso: python3 uifind.py <xml> [query]
#   - sin query: lista todos los nodos click/ con texto
#   - con query: filtra por substring (case-insensitive) en text|desc|resource-id
# Imprime: cx cy | clickable | class | text | desc | id | bounds
import sys, re
import xml.etree.ElementTree as ET

xml = sys.argv[1]
query = sys.argv[2].lower() if len(sys.argv) > 2 else None

def center(bounds):
    m = re.match(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", bounds)
    if not m: return None
    x1,y1,x2,y2 = map(int, m.groups())
    return ((x1+x2)//2, (y1+y2)//2)

try:
    tree = ET.parse(xml)
except Exception as e:
    print("ERR parse:", e); sys.exit(1)

rows = []
for node in tree.iter("node"):
    text = node.get("text","")
    desc = node.get("content-desc","")
    rid  = node.get("resource-id","")
    cls  = node.get("class","")
    clk  = node.get("clickable","false")
    bounds = node.get("bounds","")
    c = center(bounds)
    if not c: continue
    blob = f"{text} {desc} {rid}".lower()
    if query is not None:
        if query not in blob: continue
    else:
        # sin query: solo nodos con texto, desc o clickables
        if not (text or desc or clk=="true"): continue
    short = cls.split(".")[-1]
    rows.append((c[0], c[1], clk, short, text, desc, rid.split("/")[-1], bounds))

for r in rows:
    print(f"{r[0]},{r[1]} | clk={r[2]} | {r[3]} | text={r[4]!r} | desc={r[5]!r} | id={r[6]} | {r[7]}")
if not rows:
    print("(sin coincidencias)")
