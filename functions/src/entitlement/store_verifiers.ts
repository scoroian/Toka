// functions/src/entitlement/store_verifiers.ts
//
// Verificación server-to-server de recibos IAP contra las stores reales.
//
//  - Google Play: Android Publisher API v3, recurso
//    `purchases.subscriptionsv2.get` (estado de la suscripción + lineItems).
//  - App Store: App Store Server API v1, `GET /inApps/v1/subscriptions/{txId}`
//    (estado de la suscripción + JWS firmados de transacción y renovación).
//
// El estado Premium (status/plan/endsAt/autoRenew) y el `chargeId` de
// idempotencia se DERIVAN del recibo verificado por la store, NUNCA de datos
// calculados por el cliente.
//
// La parte de red/credenciales está aislada detrás de un "API client"
// inyectable (`GooglePlayApiClient` / `AppStoreApiClient`). El mapeo a nuestro
// entitlement canónico es una función pura — así los tests ejercitan la lógica
// real con respuestas de store mockeadas, sin tocar la red.

import * as logger from "firebase-functions/logger";
import { GoogleAuth } from "google-auth-library";
import { SignJWT, importPKCS8, decodeJwt } from "jose";
import type { RawReceipt } from "./sync_entitlement_helpers";

/** Entitlement derivado de un recibo verificado server-side contra la store. */
export interface VerifiedReceipt {
  status: string; // active | cancelledPendingEnd | expired | free
  plan: string; // monthly | annual
  endsAt: Date | null;
  autoRenewEnabled: boolean;
  storeVerified: true;
  /** Id estable server-side para idempotencia (purchaseToken / originalTransactionId). */
  chargeId: string;
  productId: string;
}

function planFromProductId(productId: string): string {
  return productId.toLowerCase().includes("annual") ? "annual" : "monthly";
}

// ---------------------------------------------------------------------------
// Google Play (Android Publisher v3 — purchases.subscriptionsv2)
// ---------------------------------------------------------------------------

export interface GooglePlayConfig {
  packageName: string;
  /** JSON de service account con scope androidpublisher. */
  credentialsJson: string;
}

/** Subconjunto del recurso SubscriptionPurchaseV2 que usamos. */
export interface GooglePlaySubscriptionV2 {
  subscriptionState?: string;
  latestOrderId?: string;
  lineItems?: Array<{
    productId?: string;
    expiryTime?: string; // RFC3339
    autoRenewingPlan?: { autoRenewEnabled?: boolean };
  }>;
}

export type GooglePlayApiClient = (
  receipt: RawReceipt,
  config: GooglePlayConfig,
) => Promise<GooglePlaySubscriptionV2>;

/**
 * Mapea la respuesta de subscriptionsv2 a nuestro entitlement canónico.
 * Pura y testable: no toca red.
 */
export function mapGooglePlaySubscription(
  resp: GooglePlaySubscriptionV2,
  receipt: RawReceipt,
): VerifiedReceipt {
  const line = resp.lineItems?.[0];
  const productId = line?.productId ?? receipt.productId;
  const endsAt = line?.expiryTime ? new Date(line.expiryTime) : null;
  const autoRenewEnabled = line?.autoRenewingPlan?.autoRenewEnabled ?? false;
  const now = Date.now();
  const hasFutureAccess = endsAt !== null && endsAt.getTime() > now;

  let status: string;
  switch (resp.subscriptionState) {
    case "SUBSCRIPTION_STATE_ACTIVE":
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
      // Acceso vigente (en gracia el cobro se reintenta pero el usuario
      // conserva Premium).
      status = "active";
      break;
    case "SUBSCRIPTION_STATE_CANCELED":
      // Auto-renovación desactivada: sigue con acceso hasta expiry.
      status = hasFutureAccess ? "cancelledPendingEnd" : "expired";
      break;
    case "SUBSCRIPTION_STATE_ON_HOLD":
    case "SUBSCRIPTION_STATE_PAUSED":
    case "SUBSCRIPTION_STATE_EXPIRED":
    case "SUBSCRIPTION_STATE_PENDING":
    default:
      status = "expired";
      break;
  }

  return {
    status,
    plan: planFromProductId(productId),
    endsAt,
    autoRenewEnabled,
    storeVerified: true,
    // El purchaseToken es estable durante toda la vida de la suscripción
    // (incl. renovaciones) → una sola plaza por suscripción.
    chargeId: receipt.purchaseToken,
    productId,
  };
}

/** Cliente real contra Google Play. Aislado para poder mockearlo en tests. */
export const defaultGooglePlayApiClient: GooglePlayApiClient = async (
  receipt,
  config,
) => {
  const auth = new GoogleAuth({
    credentials: JSON.parse(config.credentialsJson),
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const client = await auth.getClient();
  const token = (await client.getAccessToken()).token;
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/` +
    `${encodeURIComponent(config.packageName)}/purchases/subscriptionsv2/tokens/` +
    `${encodeURIComponent(receipt.purchaseToken)}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${token}` },
  });
  if (!res.ok) {
    const body = await res.text();
    logger.error("Google Play verify failed", { status: res.status, body });
    throw new Error(`google-play-verify-failed-${res.status}`);
  }
  return (await res.json()) as GooglePlaySubscriptionV2;
};

export async function verifyGooglePlay(
  receipt: RawReceipt,
  config: GooglePlayConfig,
  apiClient: GooglePlayApiClient = defaultGooglePlayApiClient,
): Promise<VerifiedReceipt> {
  const resp = await apiClient(receipt, config);
  return mapGooglePlaySubscription(resp, receipt);
}

// ---------------------------------------------------------------------------
// App Store (App Store Server API v1 — subscriptions status)
// ---------------------------------------------------------------------------

export interface AppStoreConfig {
  issuerId: string;
  keyId: string;
  /** Contenido de la clave privada .p8 (PKCS#8). */
  privateKey: string;
  bundleId: string;
  environment: "Production" | "Sandbox";
}

/** Subconjunto del JWSTransactionDecodedPayload que usamos. */
export interface AppStoreTransactionInfo {
  originalTransactionId: string;
  transactionId?: string;
  productId: string;
  expiresDate?: number; // epoch ms
}

/** Subconjunto del JWSRenewalInfoDecodedPayload que usamos. */
export interface AppStoreRenewalInfo {
  autoRenewStatus?: number; // 0 = off, 1 = on
}

export interface AppStoreVerifyResult {
  transactionInfo: AppStoreTransactionInfo;
  renewalInfo: AppStoreRenewalInfo;
  /** status del array data[]: 1 active, 2 expired, 3 billing-retry, 4 grace, 5 revoked. */
  subscriptionStatus: number;
}

export type AppStoreApiClient = (
  receipt: RawReceipt,
  config: AppStoreConfig,
) => Promise<AppStoreVerifyResult>;

/**
 * Mapea la transacción/renovación verificadas a nuestro entitlement canónico.
 * Pura y testable: no toca red.
 */
export function mapAppStoreTransaction(
  txInfo: AppStoreTransactionInfo,
  renewalInfo: AppStoreRenewalInfo,
  subscriptionStatus: number,
  receipt: RawReceipt,
): VerifiedReceipt {
  const productId = txInfo.productId ?? receipt.productId;
  const endsAt = txInfo.expiresDate ? new Date(txInfo.expiresDate) : null;
  const autoRenewEnabled = renewalInfo.autoRenewStatus === 1;
  const now = Date.now();
  const hasFutureAccess = endsAt !== null && endsAt.getTime() > now;

  let status: string;
  switch (subscriptionStatus) {
    case 1: // active
    case 4: // billing grace period — acceso vigente
      // Si el usuario desactivó la renovación pero sigue con acceso, es una
      // cancelación pendiente de fin.
      status =
        !autoRenewEnabled && hasFutureAccess ? "cancelledPendingEnd" : "active";
      break;
    case 2: // expired
    case 3: // billing retry (sin acceso)
    case 5: // revoked / refunded
    default:
      status = "expired";
      break;
  }

  return {
    status,
    plan: planFromProductId(productId),
    endsAt,
    autoRenewEnabled,
    storeVerified: true,
    // El originalTransactionId es estable durante toda la vida de la
    // suscripción → una sola plaza por suscripción.
    chargeId: txInfo.originalTransactionId,
    productId,
  };
}

/** Genera el JWT ES256 que autentica las llamadas a la App Store Server API. */
async function buildAppStoreJwt(config: AppStoreConfig): Promise<string> {
  const key = await importPKCS8(config.privateKey, "ES256");
  const nowSec = Math.floor(Date.now() / 1000);
  return new SignJWT({ bid: config.bundleId })
    .setProtectedHeader({ alg: "ES256", kid: config.keyId, typ: "JWT" })
    .setIssuer(config.issuerId)
    .setIssuedAt(nowSec)
    .setExpirationTime(nowSec + 60 * 30)
    .setAudience("appstoreconnect-v1")
    .sign(key);
}

/** Cliente real contra App Store Server API. Aislado para mockear en tests. */
export const defaultAppStoreApiClient: AppStoreApiClient = async (
  receipt,
  config,
) => {
  const jwt = await buildAppStoreJwt(config);
  const host =
    config.environment === "Production"
      ? "https://api.storekit.itunes.apple.com"
      : "https://api.storekit-sandbox.itunes.apple.com";
  // El transactionId que envía el cliente sirve para localizar la suscripción.
  const txId = receipt.transactionId || receipt.purchaseToken;
  const url = `${host}/inApps/v1/subscriptions/${encodeURIComponent(txId)}`;
  const res = await fetch(url, {
    headers: { Authorization: `Bearer ${jwt}` },
  });
  if (!res.ok) {
    const body = await res.text();
    logger.error("App Store verify failed", { status: res.status, body });
    throw new Error(`app-store-verify-failed-${res.status}`);
  }
  const json = (await res.json()) as {
    data?: Array<{
      lastTransactions?: Array<{
        status?: number;
        signedTransactionInfo?: string;
        signedRenewalInfo?: string;
      }>;
    }>;
  };
  const last = json.data?.[0]?.lastTransactions?.[0];
  if (!last?.signedTransactionInfo) {
    throw new Error("app-store-verify-no-transaction");
  }
  // Los JWS vienen firmados por Apple sobre un canal TLS autenticado; aquí
  // decodificamos el payload. (La verificación de la cadena x5c contra la raíz
  // de Apple es un endurecimiento posterior — ver Hallazgos.md.)
  const transactionInfo = decodeJwt(
    last.signedTransactionInfo,
  ) as unknown as AppStoreTransactionInfo;
  const renewalInfo = last.signedRenewalInfo
    ? (decodeJwt(last.signedRenewalInfo) as unknown as AppStoreRenewalInfo)
    : {};
  return {
    transactionInfo,
    renewalInfo,
    subscriptionStatus: last.status ?? 0,
  };
};

export async function verifyAppStore(
  receipt: RawReceipt,
  config: AppStoreConfig,
  apiClient: AppStoreApiClient = defaultAppStoreApiClient,
): Promise<VerifiedReceipt> {
  const r = await apiClient(receipt, config);
  return mapAppStoreTransaction(
    r.transactionInfo,
    r.renewalInfo,
    r.subscriptionStatus,
    receipt,
  );
}
