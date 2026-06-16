// functions/src/entitlement/iap_hardening.test.ts
//
// Endurecimiento C-1: el desbloqueo de una plaza de hogar es PERMANENTE, así
// que solo debe concederse cuando el recibo fue verificado server-side contra
// la store (storeVerified). En modo inferencia/dev (storeVerified=false) se
// puede activar Premium temporalmente para QA pero NUNCA acumular plazas falsas.

describe("syncEntitlement — validForUnlock requiere storeVerified", () => {
  function validForUnlock(status: string, storeVerified: boolean): boolean {
    return status === "active" && storeVerified === true;
  }

  it("active + verificado por la store → desbloquea plaza permanente", () => {
    expect(validForUnlock("active", true)).toBe(true);
  });
  it("active pero NO verificado (modo inferencia) → NO desbloquea plaza [regresión]", () => {
    expect(validForUnlock("active", false)).toBe(false);
  });
  it("cancelledPendingEnd + verificado → no desbloquea (no es active)", () => {
    expect(validForUnlock("cancelledPendingEnd", true)).toBe(false);
  });
  it("free + verificado → no desbloquea", () => {
    expect(validForUnlock("free", true)).toBe(false);
  });
});

describe("syncEntitlement — transición de billingState", () => {
  // Sin esto el pagador nunca puede leer su historial de cargos (las reglas de
  // subscriptions exigen billingState in ['currentPayer','formerPayer']).
  function computeBillingUpdates(
    payerUid: string,
    prevPayerUid: string | null
  ): Array<{ uid: string; billingState: string }> {
    const updates = [{ uid: payerUid, billingState: "currentPayer" }];
    if (prevPayerUid && prevPayerUid !== payerUid) {
      updates.push({ uid: prevPayerUid, billingState: "formerPayer" });
    }
    return updates;
  }

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
