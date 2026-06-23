// functions/src/entitlement/iap_hardening.test.ts
//
// Endurecimiento IAP. A diferencia de la versión anterior (que reimplementaba
// la lógica en el propio test — "test espejo"), estos tests ejercitan las
// funciones REALES exportadas por sync_entitlement.ts.
//
//  - C-1: el desbloqueo de una plaza de hogar es PERMANENTE, así que solo se
//    concede cuando el recibo fue verificado server-side (storeVerified).
//  - Transición de billingState: sin esto el pagador nunca puede leer su
//    historial de cargos (las reglas exigen billingState in
//    ['currentPayer','formerPayer']).

import {
  isValidForSlotUnlock,
  computeBillingUpdates,
} from "./sync_entitlement";

describe("isValidForSlotUnlock (función real)", () => {
  it("active + verificado por la store → desbloquea plaza permanente", () => {
    expect(isValidForSlotUnlock("active", true)).toBe(true);
  });
  it("active pero NO verificado (modo inferencia) → NO desbloquea plaza [regresión]", () => {
    expect(isValidForSlotUnlock("active", false)).toBe(false);
  });
  it("cancelledPendingEnd + verificado → no desbloquea (no es active)", () => {
    expect(isValidForSlotUnlock("cancelledPendingEnd", true)).toBe(false);
  });
  it("free + verificado → no desbloquea", () => {
    expect(isValidForSlotUnlock("free", true)).toBe(false);
  });
  it("expired + verificado → no desbloquea", () => {
    expect(isValidForSlotUnlock("expired", true)).toBe(false);
  });
});

describe("computeBillingUpdates (función real)", () => {
  it("primer pago (sin pagador previo) → solo currentPayer", () => {
    expect(computeBillingUpdates("u1", null)).toEqual([
      { uid: "u1", billingState: "currentPayer" },
    ]);
  });
  it("renovación del mismo pagador → solo currentPayer (sin formerPayer)", () => {
    expect(computeBillingUpdates("u1", "u1")).toEqual([
      { uid: "u1", billingState: "currentPayer" },
    ]);
  });
  it("cambio de pagador → nuevo currentPayer + anterior formerPayer", () => {
    expect(computeBillingUpdates("u2", "u1")).toEqual([
      { uid: "u2", billingState: "currentPayer" },
      { uid: "u1", billingState: "formerPayer" },
    ]);
  });
});
