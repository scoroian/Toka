#!/usr/bin/env node
/* eslint-disable no-console */
// Escanea functions/src en busca del marker que identifica código de debug
// premium que debe eliminarse antes de una release real a producción.
// Exit 1 si encuentra el marker, 0 si el repo está limpio.
//
// Usarlo desde functions/: `npm run check:release-safety`
// O como parte de `npm run deploy:release`.

const fs = require("fs");
const path = require("path");

const MARKER = "@DEBUG_PREMIUM_REMOVE_BEFORE_PRODUCTION_RELEASE";
const ROOT = path.resolve(__dirname, "..", "src");

function walk(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) walk(full, out);
    else if (entry.isFile() && /\.(ts|js)$/.test(entry.name)) out.push(full);
  }
  return out;
}

const files = walk(ROOT);
const hits = [];
for (const file of files) {
  const content = fs.readFileSync(file, "utf8");
  const lines = content.split(/\r?\n/);
  lines.forEach((line, idx) => {
    if (line.includes(MARKER)) {
      hits.push({ file: path.relative(process.cwd(), file), line: idx + 1 });
    }
  });
}

if (hits.length === 0) {
  console.log("[check-debug-premium] OK — no hay código de debug premium residual.");
  process.exit(0);
}

console.error("");
console.error("================================================================");
console.error("  ❌  RELEASE BLOQUEADA — CÓDIGO DE DEBUG PREMIUM TODAVÍA PRESENTE");
console.error("================================================================");
console.error("");
console.error(`  Marker detectado: ${MARKER}`);
console.error("");
console.error("  Localizaciones:");
for (const hit of hits) {
  console.error(`    - ${hit.file}:${hit.line}`);
}
console.error("");
console.error("  Antes de subir a producción debes eliminar:");
console.error("    1. La función debugSetPremiumStatus en functions/src/homes/index.ts");
console.error("    2. functions/.env.<projectId> con DEBUG_PREMIUM_ALLOWED_UIDS");
console.error("    3. El botón de debug premium en la UI Flutter");
console.error("    4. El método debugSetPremiumStatus del repo + ViewModel");
console.error("");
console.error("================================================================");
console.error("");
process.exit(1);
