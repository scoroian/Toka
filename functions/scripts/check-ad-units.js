#!/usr/bin/env node
/* eslint-disable no-console */
// Guardrail de release (premortem #05): impide desplegar a un proyecto marcado
// como RELEASE con los banner unit IDs de PRUEBA de Google (cero revenue).
//
// Un proyecto se marca como release poniendo en su functions/.env.<projectId>:
//   TOKA_REQUIRE_REAL_AD_UNITS=true
// y entonces DEBE definir ADMOB_BANNER_UNIT_ANDROID y ADMOB_BANNER_UNIT_IOS con
// unit IDs reales (no de prueba). Los proyectos de dev (sin el flag) no se
// exigen, así que se sigue pudiendo desplegar a dev con los IDs de prueba.
//
// Exit 1 si algún .env.<projectId> release incumple; 0 si todo está limpio.
//
// Usarlo desde functions/: `node scripts/check-ad-units.js [--dir <ruta>]`
// (se ejecuta dentro de `npm run check:release-safety`).

const fs = require("fs");
const path = require("path");

const TEST_AD_UNIT_PREFIX = "ca-app-pub-3940256099942544";

function parseDirArg(argv) {
  const i = argv.indexOf("--dir");
  if (i !== -1 && argv[i + 1]) return path.resolve(argv[i + 1]);
  return path.resolve(__dirname, "..");
}

// Lee un valor `KEY=...` de un contenido .env (última aparición gana). Devuelve
// undefined si la clave no existe (distinto de "" = clave presente pero vacía).
function readEnvValue(content, key) {
  let value;
  for (const line of content.split(/\r?\n/)) {
    const m = line.match(new RegExp(`^\\s*${key}\\s*=\\s*(.*?)\\s*$`));
    if (m) value = m[1];
  }
  return value;
}

function isTestAdUnit(unit) {
  return typeof unit === "string" && unit.startsWith(TEST_AD_UNIT_PREFIX);
}

function checkDir(rootDir) {
  const offenders = [];
  for (const entry of fs.readdirSync(rootDir, { withFileTypes: true })) {
    if (!entry.isFile()) continue;
    if (!entry.name.startsWith(".env")) continue;
    if (entry.name === ".env.example") continue;

    const content = fs.readFileSync(path.join(rootDir, entry.name), "utf8");
    const requireReal = (readEnvValue(content, "TOKA_REQUIRE_REAL_AD_UNITS") || "")
      .toLowerCase();
    if (requireReal !== "true") continue; // proyecto de dev → no se exige

    const android = (readEnvValue(content, "ADMOB_BANNER_UNIT_ANDROID") || "").trim();
    const ios = (readEnvValue(content, "ADMOB_BANNER_UNIT_IOS") || "").trim();

    const problems = [];
    if (android.length === 0) problems.push("ADMOB_BANNER_UNIT_ANDROID vacío");
    else if (isTestAdUnit(android)) problems.push(`ADMOB_BANNER_UNIT_ANDROID es de PRUEBA (${android})`);
    if (ios.length === 0) problems.push("ADMOB_BANNER_UNIT_IOS vacío");
    else if (isTestAdUnit(ios)) problems.push(`ADMOB_BANNER_UNIT_IOS es de PRUEBA (${ios})`);

    if (problems.length > 0) offenders.push({ file: entry.name, problems });
  }
  return offenders;
}

const rootDir = parseDirArg(process.argv.slice(2));
const offenders = checkDir(rootDir);

if (offenders.length === 0) {
  console.log("[check-ad-units] OK — ningún proyecto release usa banner units de prueba.");
  process.exit(0);
}

console.error("");
console.error("================================================================");
console.error("  ❌  RELEASE BLOQUEADA — BANNER AD UNITS DE PRUEBA EN PRODUCCIÓN");
console.error("================================================================");
console.error("");
for (const o of offenders) {
  console.error(`  ${o.file} (TOKA_REQUIRE_REAL_AD_UNITS=true):`);
  for (const p of o.problems) console.error(`    - ${p}`);
}
console.error("");
console.error("  Configura los unit IDs reales de AdMob por plataforma:");
console.error("    ADMOB_BANNER_UNIT_ANDROID=ca-app-pub-XXXX/YYYY");
console.error("    ADMOB_BANNER_UNIT_IOS=ca-app-pub-XXXX/ZZZZ");
console.error("");
console.error("================================================================");
console.error("");
process.exit(1);
