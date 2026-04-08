// functions/src/entitlement/sync_entitlement_helpers.test.ts
import { parseReceiptData } from "./sync_entitlement_helpers";
import { HttpsError } from "firebase-functions/v2/https";

describe("parseReceiptData", () => {
  it("parsea recibo válido con todos los campos", () => {
    const input = JSON.stringify({
      status: "active",
      plan: "annual",
      endsAt: "2027-01-01T00:00:00Z",
      autoRenewEnabled: true,
    });
    const result = parseReceiptData(input);
    expect(result.status).toBe("active");
    expect(result.plan).toBe("annual");
    expect(result.endsAt).toBeInstanceOf(Date);
    expect(result.autoRenewEnabled).toBe(true);
  });

  it("usa defaults si faltan campos", () => {
    const result = parseReceiptData("{}");
    expect(result.status).toBe("active");
    expect(result.plan).toBe("monthly");
    expect(result.endsAt).toBeNull();
    expect(result.autoRenewEnabled).toBe(true);
  });

  it("lanza HttpsError para JSON inválido", () => {
    try {
      parseReceiptData("not-json");
      fail("should have thrown");
    } catch (e) {
      expect(e).toBeInstanceOf(HttpsError);
      expect((e as HttpsError).code).toBe("invalid-argument");
    }
  });

  it("lanza HttpsError para endsAt con fecha inválida", () => {
    try {
      parseReceiptData(JSON.stringify({ endsAt: "not-a-date" }));
      fail("should have thrown");
    } catch (e) {
      expect(e).toBeInstanceOf(HttpsError);
      expect((e as HttpsError).code).toBe("invalid-argument");
    }
  });

  it("endsAt null cuando no se provee", () => {
    const result = parseReceiptData(JSON.stringify({ status: "active" }));
    expect(result.endsAt).toBeNull();
  });

  it("autoRenewEnabled false si se indica", () => {
    const result = parseReceiptData(JSON.stringify({ autoRenewEnabled: false }));
    expect(result.autoRenewEnabled).toBe(false);
  });
});
