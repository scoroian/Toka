// functions/src/entitlement/app_store_notifications.ts
//
// Handler de App Store Server Notifications v2 (Apple).
//
// NOTA DE MECANISMO: Apple entrega las ASSN v2 por WEBHOOK HTTPS (un POST con un
// `signedPayload` JWS firmado por Apple), NO por Cloud Pub/Sub. Por eso el
// endpoint correcto es `onRequest` y no `onMessagePublished` (que sí aplica a
// las RTDN de Google). El prompt #06 pedía "onMessagePublished" para ambos por
// simetría, pero seguir eso al pie de la letra crearía una función escuchando
// un topic que Apple no puede publicar. La lógica de reconciliación es la misma
// que la de RTDN (módulo `reconcile_entitlement`); solo cambia el adaptador de
// entrada. Ver Hallazgos.md.
//
//  - REFUND / REVOKE → revoca Premium + plaza.
//  - DID_RENEW / EXPIRED / DID_CHANGE_RENEWAL_STATUS / … → mapea la transacción
//    verificada y reconcilia (extiende/ajusta premiumEndsAt).
//
// SEGURIDAD: este endpoint es un webhook HTTPS PÚBLICO — cualquiera puede hacer
// POST. Por eso NUNCA confiamos en el cuerpo de la notificación: la usamos solo
// como DISPARADOR ("algo cambió en esta suscripción") y RE-VERIFICAMOS el estado
// real contra la App Store Server API (igual que el path de Google RTDN
// re-verifica contra Google Play). Una notificación forjada (p. ej. un
// `DID_RENEW` que pretenda extender Premium, o un `REFUND` que pretenda quitarlo)
// dispara una re-verificación que devuelve la VERDAD de Apple → no puede conceder
// ni revocar Premium. El filtro por `bundleId` y la verificación criptográfica
// de la cadena x5c (pendiente, ver Hallazgos.md H-018) son defensa en profundidad.

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onRequest } from "firebase-functions/v2/https";
import { decodeJwt } from "jose";
import {
  lookupPurchase,
  reconcileVerifiedEntitlement,
  revokeEntitlement,
} from "./reconcile_entitlement";
import {
  type AppStoreTransactionInfo,
  type AppStoreRenewalInfo,
  type VerifiedReceipt,
} from "./store_verifiers";
import {
  getActiveVerifiers,
  type RawReceipt,
} from "./sync_entitlement_helpers";
import { isPremium, normalizePremiumStatus } from "../shared/free_limits";

/** notificationType que implican revocación inmediata de Premium. */
const ASN_REVOKE_TYPES = new Set(["REFUND", "REVOKE"]);

export interface DecodedAsn {
  notificationType: string;
  subtype?: string;
  bundleId?: string;
  environment?: string;
  transactionInfo?: AppStoreTransactionInfo;
  renewalInfo?: AppStoreRenewalInfo;
  subscriptionStatus?: number;
}

/**
 * Decodifica el `signedPayload` (JWS) de Apple y sus JWS anidados
 * (`signedTransactionInfo` / `signedRenewalInfo`). Pura y testable.
 *
 * Decodifica sin verificar la firma (mismo criterio documentado que
 * `store_verifiers.ts`). Lanza si el JWS exterior no es decodificable.
 */
export function decodeAppStoreNotification(signedPayload: string): DecodedAsn {
  const payload = decodeJwt(signedPayload) as unknown as {
    notificationType?: string;
    subtype?: string;
    data?: {
      bundleId?: string;
      environment?: string;
      status?: number;
      signedTransactionInfo?: string;
      signedRenewalInfo?: string;
    };
  };
  const data = payload.data ?? {};

  const transactionInfo = data.signedTransactionInfo
    ? (decodeJwt(data.signedTransactionInfo) as unknown as AppStoreTransactionInfo)
    : undefined;
  const renewalInfo = data.signedRenewalInfo
    ? (decodeJwt(data.signedRenewalInfo) as unknown as AppStoreRenewalInfo)
    : undefined;

  return {
    notificationType: payload.notificationType ?? "UNKNOWN",
    subtype: payload.subtype,
    bundleId: data.bundleId,
    environment: data.environment,
    transactionInfo,
    renewalInfo,
    subscriptionStatus: data.status,
  };
}

export interface HandleAsnOptions {
  expectedBundleId?: string;
}

export interface AsnDeps {
  /** Re-verificador contra la App Store Server API. Inyectable para tests. */
  verifyAppStore?: (r: RawReceipt) => Promise<VerifiedReceipt>;
}

/**
 * Procesa una notificación ASN ya decodificada contra Firestore. Separado del
 * trigger HTTPS para testearlo en el emulador. Lanza en errores de infra para
 * que el wrapper devuelva 5xx y Apple reintente (la reconciliación es idempotente).
 *
 * NUNCA confía en el cuerpo: re-verifica el estado contra Apple y actúa sobre el
 * resultado autoritativo (ver cabecera del fichero).
 */
export async function handleAsnEvent(
  db: admin.firestore.Firestore,
  decoded: DecodedAsn,
  deps: AsnDeps,
  opts: HandleAsnOptions = {},
): Promise<void> {
  if (decoded.notificationType === "TEST") {
    logger.info("ASN test notification recibida (ack)");
    return;
  }
  if (
    opts.expectedBundleId &&
    decoded.bundleId &&
    decoded.bundleId !== opts.expectedBundleId
  ) {
    logger.warn("ASN con bundleId no esperado (ack)", { bundleId: decoded.bundleId });
    return;
  }

  const txInfo = decoded.transactionInfo;
  if (!txInfo?.originalTransactionId) {
    logger.warn("ASN sin originalTransactionId (ack)", {
      notificationType: decoded.notificationType,
    });
    return;
  }

  const purchaseRef = await lookupPurchase(db, txInfo.originalTransactionId);
  if (!purchaseRef) {
    logger.warn("ASN sin purchaseIndex para el originalTransactionId (ack)", {
      notificationType: decoded.notificationType,
    });
    return;
  }

  // Webhook PÚBLICO → no confiar en el cuerpo. Re-verificar contra Apple.
  if (!deps.verifyAppStore) {
    logger.error(
      "ASN sin verificador App Store configurado: no se puede reconciliar (cuerpo ignorado por seguridad)",
      { notificationType: decoded.notificationType },
    );
    return;
  }

  const verified = await deps.verifyAppStore({
    productId: txInfo.productId,
    purchaseToken: txInfo.originalTransactionId,
    transactionId: txInfo.transactionId ?? "",
    source: "app_store_notification",
  });
  const verifiedIsPremium = isPremium(normalizePremiumStatus(verified.status));

  // Refund/revoke CONFIRMADO por Apple (la suscripción ya no da acceso) → revoca
  // Premium + plaza. Si Apple aún la reporta activa (refund forjado/no aplicado),
  // se reconcilia al estado verdadero en vez de revocar (no hay griefing posible).
  if (ASN_REVOKE_TYPES.has(decoded.notificationType) && !verifiedIsPremium) {
    await revokeEntitlement(db, {
      homeId: purchaseRef.homeId,
      uid: purchaseRef.uid,
      chargeId: txInfo.originalTransactionId,
      reason: `apple_${decoded.notificationType.toLowerCase()}`,
    });
    return;
  }

  // Renovación / cambio de estado (o refund no confirmado): aplica el estado
  // verificado (extiende/ajusta premiumEndsAt). No puede conceder Premium gratis
  // porque `verified` viene de Apple, no del cuerpo del POST.
  await reconcileVerifiedEntitlement(db, purchaseRef, verified);
}

export const appStoreServerNotificationsHandler = onRequest(
  { cors: false },
  async (req, res) => {
    const signedPayload = (req.body as { signedPayload?: string } | undefined)
      ?.signedPayload;
    if (!signedPayload) {
      res.status(400).send("missing signedPayload");
      return;
    }

    let decoded: DecodedAsn;
    try {
      decoded = decodeAppStoreNotification(signedPayload);
    } catch (err) {
      // Payload no decodificable: reintentar no ayuda → 400 (no retry).
      logger.error("ASN signedPayload no decodificable", err);
      res.status(400).send("invalid signedPayload");
      return;
    }

    try {
      await handleAsnEvent(
        admin.firestore(),
        decoded,
        { verifyAppStore: getActiveVerifiers().verifyAppStore },
        { expectedBundleId: process.env.APP_STORE_BUNDLE_ID },
      );
      res.status(200).send("ok");
    } catch (err) {
      // Error de infraestructura: 5xx para que Apple reintente (idempotente).
      logger.error("appStoreServerNotificationsHandler error", err);
      res.status(500).send("error");
    }
  },
);
