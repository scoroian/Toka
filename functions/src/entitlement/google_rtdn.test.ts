// functions/src/entitlement/google_rtdn.test.ts
import { parseRtdnMessage, RTDN_TYPE } from "./google_rtdn";

function encode(obj: unknown): string {
  return Buffer.from(JSON.stringify(obj), "utf8").toString("base64");
}

describe("parseRtdnMessage", () => {
  it("subscriptionNotification → kind subscription con token/tipo/productId", () => {
    const msg = encode({
      version: "1.0",
      packageName: "com.toka.app",
      subscriptionNotification: {
        version: "1.0",
        notificationType: 2, // RENEWED
        purchaseToken: "gp-token-xyz",
        subscriptionId: "toka_premium_monthly",
      },
    });
    const ev = parseRtdnMessage(msg);
    expect(ev.kind).toBe("subscription");
    expect(ev.purchaseToken).toBe("gp-token-xyz");
    expect(ev.notificationType).toBe(2);
    expect(ev.subscriptionId).toBe("toka_premium_monthly");
  });

  it("notificationType REVOKED reconocido como 12", () => {
    const msg = encode({
      subscriptionNotification: { notificationType: RTDN_TYPE.REVOKED, purchaseToken: "t" },
    });
    expect(parseRtdnMessage(msg).notificationType).toBe(12);
  });

  it("voidedPurchaseNotification → kind voided con token", () => {
    const msg = encode({
      voidedPurchaseNotification: { purchaseToken: "gp-token-void", orderId: "GPA.1", refundType: 1 },
    });
    const ev = parseRtdnMessage(msg);
    expect(ev.kind).toBe("voided");
    expect(ev.purchaseToken).toBe("gp-token-void");
  });

  it("testNotification → kind test", () => {
    const msg = encode({ testNotification: { version: "1.0" } });
    expect(parseRtdnMessage(msg).kind).toBe("test");
  });

  it("data ausente o corrupta → kind unknown (no lanza)", () => {
    expect(parseRtdnMessage(undefined).kind).toBe("unknown");
    expect(parseRtdnMessage("no-es-base64-json!!!").kind).toBe("unknown");
  });
});
