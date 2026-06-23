// functions/src/entitlement/app_store_notifications.test.ts
import { decodeAppStoreNotification } from "./app_store_notifications";

// jose.decodeJwt no verifica la firma: basta con un JWS bien formado
// (header.payload.signature en base64url) para ejercitar el decodificador.
function b64url(obj: unknown): string {
  return Buffer.from(JSON.stringify(obj), "utf8").toString("base64url");
}
function fakeJws(payload: unknown): string {
  return `${b64url({ alg: "ES256" })}.${b64url(payload)}.sig`;
}

describe("decodeAppStoreNotification", () => {
  it("decodifica notificationType, bundleId y los JWS anidados de transacción/renovación", () => {
    const signedTransactionInfo = fakeJws({
      originalTransactionId: "orig-tx-1",
      transactionId: "tx-1",
      productId: "toka_premium_annual",
      expiresDate: 1893456000000, // 2030-01-01
    });
    const signedRenewalInfo = fakeJws({ autoRenewStatus: 1 });
    const signedPayload = fakeJws({
      notificationType: "DID_RENEW",
      subtype: "",
      data: {
        bundleId: "com.toka.app",
        environment: "Production",
        status: 1,
        signedTransactionInfo,
        signedRenewalInfo,
      },
    });

    const decoded = decodeAppStoreNotification(signedPayload);
    expect(decoded.notificationType).toBe("DID_RENEW");
    expect(decoded.bundleId).toBe("com.toka.app");
    expect(decoded.environment).toBe("Production");
    expect(decoded.subscriptionStatus).toBe(1);
    expect(decoded.transactionInfo?.originalTransactionId).toBe("orig-tx-1");
    expect(decoded.transactionInfo?.productId).toBe("toka_premium_annual");
    expect(decoded.transactionInfo?.expiresDate).toBe(1893456000000);
    expect(decoded.renewalInfo?.autoRenewStatus).toBe(1);
  });

  it("REFUND con transacción → notificationType REFUND y originalTransactionId", () => {
    const signedTransactionInfo = fakeJws({
      originalTransactionId: "orig-tx-refund",
      productId: "toka_premium_monthly",
      expiresDate: 1893456000000,
    });
    const signedPayload = fakeJws({
      notificationType: "REFUND",
      data: { bundleId: "com.toka.app", signedTransactionInfo },
    });
    const decoded = decodeAppStoreNotification(signedPayload);
    expect(decoded.notificationType).toBe("REFUND");
    expect(decoded.transactionInfo?.originalTransactionId).toBe("orig-tx-refund");
  });

  it("payload sin data → notificationType presente, sin transacción", () => {
    const decoded = decodeAppStoreNotification(fakeJws({ notificationType: "TEST" }));
    expect(decoded.notificationType).toBe("TEST");
    expect(decoded.transactionInfo).toBeUndefined();
  });
});
