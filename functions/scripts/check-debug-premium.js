#!/usr/bin/env node
/* eslint-disable no-console */
// Escanea functions/src en busca del marker que identifica código de debug
// premium que debe eliminarse antes de una release real a producción, y
// además verifica que ningún archivo .env.<projectId> tenga la allowlist
// DEBUG_PREMIUM_ALLOWED_UIDS con valor (un UID en la allowlist permite forzar
// Premium en ese proyecto, así que no debe quedar en una release).
// Exit 1 si encuentra cualquiera de los dos, 0 si el repo está limpio.
//
// Usarlo desde functions/: `npm run check:release-safety`
// O como parte de `npm run deploy:release`.

const fs = require("fs");
const path = require("path");

const MARKER = "@DEBUG_PREMIUM_REMOVE_BEFORE_PRODUCTION_RELEASE";
const SRC_ROOT = path.resolve(__dirname, "..", "src");
const FUNCTIONS_ROOT = path.resolve(__dirname, "..");

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, out);
    else if (entry.isFile() && /\.(ts|js)$/.test(entry.name)) out.push(full);
  }
  return out;
}

// 1) Marker en el código fuente
const markerHits = [];
for (const file of walk(SRC_ROOT)) {
  const lines = fs.readFileSync(file, "utf8").split(/\r?\n/);
  lines.forEach((line, idx) => {
    if (line.includes(MARKER)) {
      markerHits.push({ file: path.relative(process.cwd(), file), line: idx + 1 });
    }
  });
}

// 2) Allowlist no vacía en archivos .env.<projectId> (excepto .env.example)
const envHits = [];
for (const entry of fs.readdirSync(FUNCTIONS_ROOT, { withFileTypes: true })) {
  if (!entry.isFile()) continue;
  if (!entry.name.startsWith(".env")) continue;
  if (entry.name === ".env.example") continue;
  const content = fs.readFileSync(path.join(FUNCTIONS_ROOT, entry.name), "utf8");
  content.split(/\r?\n/).forEach((line, idx) => {
    const m = line.match(/^\s*DEBUG_PREMIUM_ALLOWED_UIDS\s*=\s*(.+?)\s*$/);
    if (m && m[1].length > 0) {
      envHits.push({ file: entry.name, line: idx + 1, value: m[1] });
    }
  });
}

if (markerHits.length === 0 && envHits.length === 0) {
  console.log("[check-debug-premium] OK — sin código de debug premium ni allowlist residual.");
  process.exit(0);
}

console.error("");
console.error("================================================================");
console.error("  ❌  RELEASE BLOQUEADA — DEBUG PREMIUM TODAVÍA PRESENTE");
console.error("================================================================");
console.error("");
if (markerHits.length > 0) {
  console.error(`  Marker en código: ${MARKER}`);
  for (const hit of markerHits) console.error(`    - ${hit.file}:${hit.line}`);
  console.error("");
}
if (envHits.length > 0) {
  console.error("  Allowlist DEBUG_PREMIUM_ALLOWED_UIDS con valor:");
  for (const hit of envHits) console.error(`    - ${hit.file}:${hit.line}`);
  console.error("");
}
console.error("  Antes de subir a producción debes eliminar:");
console.error("    1. La función debugSetPremiumStatus en functions/src/homes/index.ts");
console.error("    2. DEBUG_PREMIUM_ALLOWED_UIDS en functions/.env.<projectId>");
console.error("    3. El botón de debug premium en la UI Flutter");
console.error("    4. El método debugSetPremiumStatus del repo + ViewModel");
console.error("");
console.error("================================================================");
console.error("");
process.exit(1);
