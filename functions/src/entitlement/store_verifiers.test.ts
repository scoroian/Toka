// functions/src/entitlement/store_verifiers.test.ts
//
// Verificación server-to-server de recibos IAP. Estos tests ejercitan el
// MAPEO real de las respuestas de las stores (Google Play subscriptionsv2 y
// App Store Server API) a nuestro entitlement canónico, y la fontanería de
// verifyGooglePlay/verifyAppStore con un cliente HTTP mockeado (sin red).
//
// Regla del premortem: NO reimplementamos la lógica en el test; importamos y
// ejercitamos las funciones reales con respuestas de store mockeadas.

import {
  mapGooglePlaySubscription,
  mapAppStoreTransaction,
  verifyGooglePlay,
  verifyAppStore,
  type GooglePlaySubscriptionV2,
} from "./store_verifiers";
import type { RawReceipt } from "./sync_entitlement_helpers";

const androidReceipt: RawReceipt = {
  productId: "toka_premium_annual",
  purchaseToken: "gp-token-stable-123",
  transactionId: "GPA.0001",
  source: "google_play",
};

const iosReceipt: RawReceipt = {
  productId: "toka_premium_monthly",
  purchaseToken: "appstore-jws-blob",
  transactionId: "2000000123",
  source: "app_store",
};

const future = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
const past = new Date(Date.now() - 60 * 1000);

describe("mapGooglePlaySubscription", () => {
  function sub(
    state: string,
    expiry: Date,
    autoRenew: boolean,
  ): GooglePlaySubscriptionV2 {
    return {
      subscriptionState: state,
      latestOrderId: "GPA.0001",
      lineItems: [
        {
          productId: "toka_premium_annual",
          expiryTime: expiry.toISOString(),
          autoRenewingPlan: { autoRenewEnabled: autoRenew },
        },
      ],
    };
  }

  it("ACTIVE → active, deriva plan/endsAt/autoRenew y storeVerified=true", () => {
    const r = mapGooglePlaySubscription(
      sub("SUBSCRIPTION_STATE_ACTIVE", future, true),
      androidReceipt,
    );
    expect(r.status).toBe("active");
    expect(r.plan).toBe("annual");
    expect(r.autoRenewEnabled).toBe(true);
    expect(r.storeVerified).toBe(true);
    expect(r.endsAt?.getTime()).toBe(future.getTime());
  });

  it("chargeId se deriva del purchaseToken (estable entre renovaciones), no del orderId", () => {
    const r = mapGooglePlaySubscription(
      sub("SUBSCRIPTION_STATE_ACTIVE", future, true),
      androidReceipt,
    );
    expect(r.chargeId).toBe("gp-token-stable-123");
  });

  it("CANCELED con expiry futuro → cancelledPendingEnd (sigue con acceso)", () => {
    const r = mapGooglePlaySubscription(
      sub("SUBSCRIPTION_STATE_CANCELED", future, false),
      androidReceipt,
    );
    expect(r.status).toBe("cancelledPendingEnd");
    expect(r.autoRenewEnabled).toBe(false);
  });

  it("EXPIRED → expired", () => {
    const r = mapGooglePlaySubscription(
      sub("SUBSCRIPTION_STATE_EXPIRED", past, false),
      androidReceipt,
    );
    expect(r.status).toBe("expired");
  });

  it("IN_GRACE_PERIOD → active (el acceso continúa mientras se reintenta el cobro)", () => {
    const r = mapGooglePlaySubscription(
      sub("SUBSCRIPTION_STATE_IN_GRACE_PERIOD", future, true),
      androidReceipt,
    );
    expect(r.status).toBe("active");
  });

  it("ON_HOLD → expired (acceso suspendido)", () => {
    const r = mapGooglePlaySubscription(
      sub("SUBSCRIPTION_STATE_ON_HOLD", past, true),
      androidReceipt,
    );
    expect(r.status).toBe("expired");
  });
});

describe("mapAppStoreTransaction", () => {
  function tx(expiresMs: number) {
    return {
      originalTransactionId: "1000000999",
      transactionId: "2000000123",
      productId: "toka_premium_monthly",
      expiresDate: expiresMs,
    };
  }

  it("subscriptionStatus active + autoRenew on → active", () => {
    const r = mapAppStoreTransaction(
      tx(future.getTime()),
      { autoRenewStatus: 1 },
      1, // 1 = active
      iosReceipt,
    );
    expect(r.status).toBe("active");
    expect(r.plan).toBe("monthly");
    expect(r.autoRenewEnabled).toBe(true);
    expect(r.endsAt?.getTime()).toBe(future.getTime());
    expect(r.storeVerified).toBe(true);
  });

  it("chargeId se deriva del originalTransactionId (estable entre renovaciones)", () => {
    const r = mapAppStoreTransaction(
      tx(future.getTime()),
      { autoRenewStatus: 1 },
      1,
      iosReceipt,
    );
    expect(r.chargeId).toBe("1000000999");
  });

  it("active pero autoRenew off (cancelada pendiente de fin) → cancelledPendingEnd", () => {
    const r = mapAppStoreTransaction(
      tx(future.getTime()),
      { autoRenewStatus: 0 },
      1,
      iosReceipt,
    );
    expect(r.status).toBe("cancelledPendingEnd");
  });

  it("subscriptionStatus billing-grace (4) → active", () => {
    const r = mapAppStoreTransaction(
      tx(future.getTime()),
      { autoRenewStatus: 1 },
      4,
      iosReceipt,
    );
    expect(r.status).toBe("active");
  });

  it("subscriptionStatus revoked/refunded (5) → expired", () => {
    const r = mapAppStoreTransaction(
      tx(past.getTime()),
      { autoRenewStatus: 0 },
      5,
      iosReceipt,
    );
    expect(r.status).toBe("expired");
  });

  it("subscriptionStatus expired (2) → expired", () => {
    const r = mapAppStoreTransaction(
      tx(past.getTime()),
      { autoRenewStatus: 0 },
      2,
      iosReceipt,
    );
    expect(r.status).toBe("expired");
  });
});

describe("verifyGooglePlay (cliente API mockeado)", () => {
  it("llama al cliente API y mapea la respuesta verificada", async () => {
    const apiClient = jest.fn().mockResolvedValue({
      subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
      latestOrderId: "GPA.0001",
      lineItems: [
        {
          productId: "toka_premium_annual",
          expiryTime: future.toISOString(),
          autoRenewingPlan: { autoRenewEnabled: true },
        },
      ],
    } as GooglePlaySubscriptionV2);

    const r = await verifyGooglePlay(
      androidReceipt,
      { packageName: "com.toka.app", credentialsJson: "{}" },
      apiClient,
    );
    expect(apiClient).toHaveBeenCalledTimes(1);
    expect(r.status).toBe("active");
    expect(r.storeVerified).toBe(true);
    expect(r.chargeId).toBe("gp-token-stable-123");
  });
});

describe("verifyAppStore (cliente API mockeado)", () => {
  it("llama al cliente API y mapea la transacción verificada", async () => {
    const apiClient = jest.fn().mockResolvedValue({
      transactionInfo: {
        originalTransactionId: "1000000999",
        transactionId: "2000000123",
        productId: "toka_premium_monthly",
        expiresDate: future.getTime(),
      },
      renewalInfo: { autoRenewStatus: 1 },
      subscriptionStatus: 1,
    });

    const r = await verifyAppStore(
      iosReceipt,
      {
        issuerId: "issuer",
        keyId: "key",
        privateKey: "-----BEGIN PRIVATE KEY-----\nx\n-----END PRIVATE KEY-----",
        bundleId: "com.toka.app",
        environment: "Production",
      },
      apiClient,
    );
    expect(apiClient).toHaveBeenCalledTimes(1);
    expect(r.status).toBe("active");
    expect(r.chargeId).toBe("1000000999");
    expect(r.storeVerified).toBe(true);
  });
});
