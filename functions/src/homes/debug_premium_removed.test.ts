// functions/src/homes/debug_premium_removed.test.ts
//
// Guard de regresión (premortem #03): la Cloud Function que activaba Premium
// sin pago real (debugSetPremiumStatus) y sus módulos de helpers se ELIMINARON
// por completo. Este test falla si vuelven a aparecer, para garantizar que
// ningún build de producción reintroduzca un camino de Premium gratis.
//
// NOTA: el marker literal se construye desde fragmentos a propósito, para que
// este fichero de test NO dispare el propio guardrail check-debug-premium.js
// (que escanea functions/src en busca del marker).

import * as fs from "fs";
import * as path from "path";
import { execFileSync } from "child_process";

const HOMES_DIR = path.resolve(__dirname);
const FUNCTIONS_ROOT = path.resolve(__dirname, "..", "..");
const SRC_ROOT = path.join(FUNCTIONS_ROOT, "src");
// Se arma en runtime para no incrustar el literal del marker en el código.
const MARKER = ["@DEBUG_PREMIUM_REMOVE", "BEFORE_PRODUCTION_RELEASE"].join("_");
const DEBUG_FN = "debug" + "SetPremiumStatus";

describe("premortem #03 — debug premium eliminado (sin bypass en prod)", () => {
  it("homes/index.ts no exporta la función debug ni contiene el marker", () => {
    const src = fs.readFileSync(path.join(HOMES_DIR, "index.ts"), "utf8");
    expect(src.includes(DEBUG_FN)).toBe(false);
    expect(src.includes(MARKER)).toBe(false);
    expect(src.includes("DEBUG_PREMIUM_ALLOWED_UIDS")).toBe(false);
  });

  it("los módulos de helpers de debug premium no existen", () => {
    expect(fs.existsSync(path.join(HOMES_DIR, "debug_premium_allowlist.ts"))).toBe(
      false
    );
    expect(fs.existsSync(path.join(HOMES_DIR, "debug_premium_flags.ts"))).toBe(
      false
    );
  });

  it("ningún fichero .ts de functions/src contiene el marker de debug premium", () => {
    const offenders: string[] = [];
    const walk = (dir: string): void => {
      for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) walk(full);
        else if (entry.name.endsWith(".ts")) {
          if (fs.readFileSync(full, "utf8").includes(MARKER)) offenders.push(full);
        }
      }
    };
    walk(SRC_ROOT);
    expect(offenders).toEqual([]);
  });

  it("el guardrail check-debug-premium.js pasa (exit 0)", () => {
    // Ejecuta el script real; execFileSync lanza si el exit code != 0.
    expect(() =>
      execFileSync("node", ["scripts/check-debug-premium.js"], {
        cwd: FUNCTIONS_ROOT,
        stdio: "pipe",
      })
    ).not.toThrow();
  });
});
