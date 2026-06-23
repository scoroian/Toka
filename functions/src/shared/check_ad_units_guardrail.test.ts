// Guardrail de release (premortem #05): scripts/check-ad-units.js bloquea el
// deploy de un proyecto marcado como release (TOKA_REQUIRE_REAL_AD_UNITS=true)
// cuyos banner unit IDs sigan siendo los de PRUEBA de Google (cero revenue).
// Los proyectos de dev (sin el flag) no se ven afectados.

import * as fs from "fs";
import * as os from "os";
import * as path from "path";
import { execFileSync } from "child_process";

const FUNCTIONS_ROOT = path.resolve(__dirname, "..", "..");
const SCRIPT = path.join(FUNCTIONS_ROOT, "scripts", "check-ad-units.js");

const TEST_UNIT = "ca-app-pub-3940256099942544/6300978111";
const REAL_ANDROID = "ca-app-pub-1111111111111111/2222222222";
const REAL_IOS = "ca-app-pub-1111111111111111/3333333333";

/** Corre el guardrail contra `dir`; devuelve el exit code (0 = OK). */
function runGuardrail(dir: string): number {
  try {
    execFileSync("node", [SCRIPT, "--dir", dir], { stdio: "pipe" });
    return 0;
  } catch (err) {
    return (err as { status?: number }).status ?? 1;
  }
}

function fixtureDir(envFiles: Record<string, string>): string {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "adunits-"));
  for (const [name, content] of Object.entries(envFiles)) {
    fs.writeFileSync(path.join(dir, name), content);
  }
  return dir;
}

describe("premortem #05 — guardrail check-ad-units.js", () => {
  it("proyecto release (flag true) con units reales → exit 0", () => {
    const dir = fixtureDir({
      ".env.prod": `TOKA_REQUIRE_REAL_AD_UNITS=true\nADMOB_BANNER_UNIT_ANDROID=${REAL_ANDROID}\nADMOB_BANNER_UNIT_IOS=${REAL_IOS}\n`,
    });
    expect(runGuardrail(dir)).toBe(0);
  });

  it("proyecto release (flag true) con units de PRUEBA → exit 1", () => {
    const dir = fixtureDir({
      ".env.prod": `TOKA_REQUIRE_REAL_AD_UNITS=true\nADMOB_BANNER_UNIT_ANDROID=${TEST_UNIT}\nADMOB_BANNER_UNIT_IOS=${TEST_UNIT}\n`,
    });
    expect(runGuardrail(dir)).toBe(1);
  });

  it("proyecto release (flag true) sin units configurados → exit 1", () => {
    const dir = fixtureDir({
      ".env.prod": "TOKA_REQUIRE_REAL_AD_UNITS=true\n",
    });
    expect(runGuardrail(dir)).toBe(1);
  });

  it("proyecto dev (sin flag) con units de prueba → exit 0 (no se exige)", () => {
    const dir = fixtureDir({
      ".env.toka-dd241": "ADMOB_BANNER_UNIT_ANDROID=\nADMOB_BANNER_UNIT_IOS=\n",
    });
    expect(runGuardrail(dir)).toBe(0);
  });

  it(".env.example se ignora aunque tenga el flag", () => {
    const dir = fixtureDir({
      ".env.example": "TOKA_REQUIRE_REAL_AD_UNITS=true\n",
    });
    expect(runGuardrail(dir)).toBe(0);
  });

  it("el repo real pasa el guardrail (exit 0)", () => {
    expect(runGuardrail(FUNCTIONS_ROOT)).toBe(0);
  });
});
