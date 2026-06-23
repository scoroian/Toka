// functions/src/entitlement/sync_entitlement_helpers.test.ts
import {
  parseReceiptData,
  validateReceipt,
  type ReceiptVerifiers,
} from "./sync_entitlement_helpers";
import type { VerifiedReceipt } from "./store_verifiers";
import { HttpsError } from "firebase-functions/v2/https";

describe("parseReceiptData", () => {
  it("parsea recibo válido con todos los campos", () => {
    const input = JSON.stringify({
      productId: "toka_premium_annual",
      purchaseToken: "abc-token-123",
      transactionId: "txn-1",
      source: "google_play",
    });
    const result = parseReceiptData(input);
    expect(result.productId).toBe("toka_premium_annual");
    expect(result.purchaseToken).toBe("abc-token-123");
    expect(result.transactionId).toBe("txn-1");
    expect(result.source).toBe("google_play");
  });

  it("acepta transactionId/source vacíos como defaults", () => {
    const input = JSON.stringify({
      productId: "toka_premium_monthly",
      purchaseToken: "tok",
    });
    const result = parseReceiptData(input);
    expect(result.productId).toBe("toka_premium_monthly");
    expect(result.purchaseToken).toBe("tok");
    expect(result.transactionId).toBe("");
    expect(result.source).toBe("");
  });

  it("rechaza recibo sin productId (vector de ataque)", () => {
    try {
      parseReceiptData(JSON.stringify({ purchaseToken: "tok" }));
      fail("should have thrown");
    } catch (e) {
      expect(e).toBeInstanceOf(HttpsError);
      expect((e as HttpsError).code).toBe("invalid-argument");
    }
  });

  it("rechaza recibo sin purchaseToken (vector de ataque)", () => {
    try {
      parseReceiptData(JSON.stringify({ productId: "toka_premium_annual" }));
      fail("should have thrown");
    } catch (e) {
      expect(e).toBeInstanceOf(HttpsError);
      expect((e as HttpsError).code).toBe("invalid-argument");
    }
  });

  it("rechaza payload con status calculado por el cliente", () => {
    // El antiguo formato tenía status/plan/endsAt; ahora debe rechazarse
    // por faltar productId/purchaseToken. Esto previene el bypass donde
    // el cliente dice "soy Premium activo" y el backend lo creía.
    try {
      parseReceiptData(
        JSON.stringify({ status: "active", plan: "annual" }),
      );
      fail("should have thrown");
    } catch (e) {
      expect(e).toBeInstanceOf(HttpsError);
    }
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
});

describe("validateReceipt", () => {
  const baseReceipt = {
    productId: "toka_premium_annual",
    purchaseToken: "tok-1",
    transactionId: "txn-1",
    source: "google_play",
  };

  afterEach(() => {
    delete process.env.STRICT_RECEIPT_VALIDATION;
  });

  it("modo dev: infiere plan annual desde productId", async () => {
    process.env.STRICT_RECEIPT_VALIDATION = "false";
    const result = await validateReceipt(baseReceipt, "android");
    expect(result.plan).toBe("annual");
    expect(result.status).toBe("active");
    expect(result.storeVerified).toBe(false);
    expect(result.endsAt).toBeInstanceOf(Date);
  });

  it("modo dev: infiere plan monthly cuando productId no contiene 'annual'", async () => {
    process.env.STRICT_RECEIPT_VALIDATION = "false";
    const result = await validateReceipt(
      { ...baseReceipt, productId: "toka_premium_monthly" },
      "android",
    );
    expect(result.plan).toBe("monthly");
  });

  it("modo strict: rechaza si verificador real no está configurado", async () => {
    process.env.STRICT_RECEIPT_VALIDATION = "true";
    await expect(validateReceipt(baseReceipt, "android")).rejects.toThrow(
      HttpsError,
    );
  });

  it("modo dev: chargeId se deriva server-side del purchaseToken (no del cliente)", async () => {
    process.env.STRICT_RECEIPT_VALIDATION = "false";
    const result = await validateReceipt(baseReceipt, "android");
    expect(result.chargeId).toBe("tok-1");
  });
});

describe("validateReceipt — con verificador inyectado (server-to-store)", () => {
  const androidReceipt = {
    productId: "toka_premium_annual",
    purchaseToken: "gp-token-xyz",
    transactionId: "GPA.1",
    source: "google_play",
  };
  const iosReceipt = {
    productId: "toka_premium_monthly",
    purchaseToken: "ios-blob",
    transactionId: "2000000123",
    source: "app_store",
  };

  function verified(over: Partial<VerifiedReceipt>): VerifiedReceipt {
    return {
      status: "active",
      plan: "annual",
      endsAt: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
      autoRenewEnabled: true,
      storeVerified: true,
      chargeId: "gp-token-xyz",
      productId: "toka_premium_annual",
      ...over,
    };
  }

  afterEach(() => {
    delete process.env.STRICT_RECEIPT_VALIDATION;
  });

  it("android: usa verifyGooglePlay y deriva estado del recibo verificado", async () => {
    const verifiers: ReceiptVerifiers = {
      verifyGooglePlay: jest.fn().mockResolvedValue(verified({})),
    };
    const result = await validateReceipt(androidReceipt, "android", verifiers);
    expect(verifiers.verifyGooglePlay).toHaveBeenCalledTimes(1);
    expect(result.storeVerified).toBe(true);
    expect(result.status).toBe("active");
    expect(result.plan).toBe("annual");
    expect(result.chargeId).toBe("gp-token-xyz");
  });

  it("ios: usa verifyAppStore y deriva chargeId del originalTransactionId", async () => {
    const verifiers: ReceiptVerifiers = {
      verifyAppStore: jest.fn().mockResolvedValue(
        verified({
          plan: "monthly",
          productId: "toka_premium_monthly",
          chargeId: "1000000999",
        }),
      ),
    };
    const result = await validateReceipt(iosReceipt, "ios", verifiers);
    expect(verifiers.verifyAppStore).toHaveBeenCalledTimes(1);
    expect(result.chargeId).toBe("1000000999");
    expect(result.storeVerified).toBe(true);
  });

  it("recibo verificado como expirado NO activa (status expired)", async () => {
    const verifiers: ReceiptVerifiers = {
      verifyGooglePlay: jest.fn().mockResolvedValue(
        verified({ status: "expired", endsAt: new Date(Date.now() - 1000) }),
      ),
    };
    const result = await validateReceipt(androidReceipt, "android", verifiers);
    expect(result.status).toBe("expired");
    expect(result.storeVerified).toBe(true);
  });

  it("si hay verificador configurado, se usa AUNQUE strict esté desactivado (no cae a inferencia)", async () => {
    process.env.STRICT_RECEIPT_VALIDATION = "false";
    const verifyGooglePlay = jest.fn().mockResolvedValue(verified({}));
    const result = await validateReceipt(androidReceipt, "android", {
      verifyGooglePlay,
    });
    expect(verifyGooglePlay).toHaveBeenCalledTimes(1);
    expect(result.storeVerified).toBe(true);
  });
});
