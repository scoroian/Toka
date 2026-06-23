// functions/src/notifications/fcm_tokens.test.ts
//
// Hallazgo #17: clasificación del error de FCM que indica un token muerto
// (dispositivo desinstalado / token caducado) para poder purgarlo. NO se testea
// aquí el borrado en Firestore (eso va en integración): solo la lógica pura de
// "¿este error significa que el token ya no sirve?".

import { isUnregisteredTokenError } from "./fcm_tokens";

describe("isUnregisteredTokenError", () => {
  it("código messaging/registration-token-not-registered → true", () => {
    expect(
      isUnregisteredTokenError({
        code: "messaging/registration-token-not-registered",
      })
    ).toBe(true);
  });

  it("otro código de messaging → false (no borrar tokens por errores transitorios)", () => {
    expect(
      isUnregisteredTokenError({ code: "messaging/server-unavailable" })
    ).toBe(false);
    expect(
      isUnregisteredTokenError({ code: "messaging/internal-error" })
    ).toBe(false);
    expect(
      isUnregisteredTokenError({ code: "messaging/invalid-argument" })
    ).toBe(false);
  });

  it("error sin code → false", () => {
    expect(isUnregisteredTokenError(new Error("boom"))).toBe(false);
    expect(isUnregisteredTokenError({})).toBe(false);
  });

  it("valores nulos/no-objeto → false (defensivo, nunca lanza)", () => {
    expect(isUnregisteredTokenError(null)).toBe(false);
    expect(isUnregisteredTokenError(undefined)).toBe(false);
    expect(isUnregisteredTokenError("string")).toBe(false);
    expect(isUnregisteredTokenError(42)).toBe(false);
  });
});
