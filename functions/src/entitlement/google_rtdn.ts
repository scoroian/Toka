// functions/src/entitlement/google_rtdn.ts
//
// Handler de Real-time Developer Notifications (RTDN) de Google Play.
//
// Google publica en un topic de Cloud Pub/Sub cada cambio de estado de una
// suscripción (compra, renovación, cancelación, expiración, REVOKE por
// reembolso/chargeback) y los reembolsos a nivel de pedido
// (voidedPurchaseNotification). Este handler los consume y reconcilia el estado
// Premium del hogar:
//
//  - REVOKED (12) / voidedPurchaseNotification → revoca Premium + plaza.
//  - resto (renovación, cancelación, gracia, expiración) → RE-VERIFICA el
//    purchaseToken contra Google Play (fuente de verdad) y aplica el estado.
//
// El topic se configura en Play Console y en `GOOGLE_RTDN_TOPIC`
// (default `play-rtdn`).

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onMessagePublished } from "firebase-functions/v2/pubsub";
import { defineSecret } from "firebase-functions/params";
import { getActiveVerifiers } from "./sync_entitlement_helpers";
import {
  lookupPurchase,
  reconcileVerifiedEntitlement,
  revokeEntitlement,
} from "./reconcile_entitlement";
import { reconcileVerifiedPlus, revokePlus } from "./plus_entitlement";
import { reconcileVerifiedPack, revokePack } from "./pack_entitlement";
import { packFromProductId } from "./pack_catalog";
import type { RawReceipt } from "./sync_entitlement_helpers";

const GOOGLE_PLAY_SA_JSON = defineSecret("GOOGLE_PLAY_SA_JSON");

// notificationType de subscriptionNotification que nos interesan explícitamente.
export const RTDN_TYPE = {
  REVOKED: 12, // reembolso / chargeback → revocar plaza
} as const;

export interface RtdnEvent {
  kind: "subscription" | "voided" | "test" | "unknown";
  purchaseToken?: string;
  subscriptionId?: string; // productId
  notificationType?: number;
}

/**
 * Decodifica el mensaje Pub/Sub (base64 JSON) a un evento normalizado.
 * Pura y testable.
 */
export function parseRtdnMessage(dataBase64: string | undefined): RtdnEvent {
  if (!dataBase64) return { kind: "unknown" };
  let payload: Record<string, unknown>;
  try {
    payload = JSON.parse(Buffer.from(dataBase64, "base64").toString("utf8"));
  } catch {
    return { kind: "unknown" };
  }

  if (payload["testNotification"]) {
    return { kind: "test" };
  }

  const voided = payload["voidedPurchaseNotification"] as
    | Record<string, unknown>
    | undefined;
  if (voided) {
    return {
      kind: "voided",
      purchaseToken: voided["purchaseToken"] as string | undefined,
    };
  }

  const sub = payload["subscriptionNotification"] as
    | Record<string, unknown>
    | undefined;
  if (sub) {
    return {
      kind: "subscription",
      purchaseToken: sub["purchaseToken"] as string | undefined,
      subscriptionId: sub["subscriptionId"] as string | undefined,
      notificationType: sub["notificationType"] as number | undefined,
    };
  }

  return { kind: "unknown" };
}

export interface RtdnDeps {
  verifyGooglePlay?: (r: RawReceipt) => Promise<import("./store_verifiers").VerifiedReceipt>;
}

/**
 * Procesa un evento RTDN ya parseado contra Firestore. Separa la lógica del
 * trigger para poder testearla en el emulador sin simular la entrega Pub/Sub.
 */
export async function handleRtdnEvent(
  db: admin.firestore.Firestore,
  event: RtdnEvent,
  deps: RtdnDeps,
): Promise<void> {
  if (event.kind === "test") {
    logger.info("RTDN test notification recibida (ack)");
    return;
  }
  if (event.kind === "unknown" || !event.purchaseToken) {
    logger.warn("RTDN sin purchaseToken o tipo desconocido (ack)", {
      kind: event.kind,
    });
    return;
  }

  const purchaseRef = await lookupPurchase(db, event.purchaseToken);
  if (!purchaseRef) {
    // El hogar establece el mapeo chargeId→hogar al comprar (syncEntitlement).
    // Si llega una notificación de una compra que nunca se sincronizó, no hay
    // a qué hogar aplicarla; ack para no reintentar indefinidamente.
    logger.warn("RTDN sin purchaseIndex para el token (ack)", {
      kind: event.kind,
    });
    return;
  }

  // ── Eje Toka Plus (per-usuario) ──────────────────────────────────────────
  // Mismo criterio que el hogar: refund/void/revoke → revoca; resto → re-verifica
  // contra Google Play y aplica el estado real. Nunca toca el hogar.
  if (purchaseRef.kind === "plus") {
    if (event.kind === "voided" || event.notificationType === RTDN_TYPE.REVOKED) {
      await revokePlus(db, {
        uid: purchaseRef.uid,
        chargeId: event.purchaseToken,
        reason: event.kind === "voided" ? "google_voided" : "google_revoked",
      });
      return;
    }
    if (!deps.verifyGooglePlay) {
      logger.error("RTDN Plus sin verificador Google Play: no se puede reconciliar", {
        notificationType: event.notificationType,
      });
      return;
    }
    const verifiedPlus = await deps.verifyGooglePlay({
      productId: event.subscriptionId ?? purchaseRef.productId ?? "",
      purchaseToken: event.purchaseToken,
      transactionId: "",
      source: "google_play_rtdn",
    });
    await reconcileVerifiedPlus(
      db,
      { uid: purchaseRef.uid, platform: purchaseRef.platform },
      verifiedPlus,
    );
    return;
  }

  // ── Eje pack de miembro (ligado al hogar, aditivo) ─────────────────────────
  // Mismo criterio que el hogar: refund/void/revoke → revoca el pack (congela
  // excedentes); resto → re-verifica contra Google Play y reconcilia el pack.
  // NO toca el estado premium/tier del hogar.
  if (purchaseRef.kind === "pack") {
    const packHomeId = purchaseRef.homeId;
    if (!packHomeId) {
      logger.warn("RTDN pack sin homeId en el índice de compras (ack)");
      return;
    }
    if (event.kind === "voided" || event.notificationType === RTDN_TYPE.REVOKED) {
      const kind = packFromProductId(event.subscriptionId ?? purchaseRef.productId);
      if (!kind) {
        logger.warn("RTDN pack: productId no catalogado (ack)", {
          productId: purchaseRef.productId,
        });
        return;
      }
      await revokePack(db, {
        homeId: packHomeId,
        kind,
        chargeId: event.purchaseToken,
        reason: event.kind === "voided" ? "google_voided" : "google_revoked",
      });
      return;
    }
    if (!deps.verifyGooglePlay) {
      logger.error("RTDN pack sin verificador Google Play: no se puede reconciliar", {
        notificationType: event.notificationType,
      });
      return;
    }
    const verifiedPack = await deps.verifyGooglePlay({
      productId: event.subscriptionId ?? purchaseRef.productId ?? "",
      purchaseToken: event.purchaseToken,
      transactionId: "",
      source: "google_play_rtdn",
    });
    await reconcileVerifiedPack(
      db,
      { homeId: packHomeId, uid: purchaseRef.uid, platform: purchaseRef.platform },
      verifiedPack,
    );
    return;
  }

  // ── Eje hogar ────────────────────────────────────────────────────────────
  const homeId = purchaseRef.homeId;
  if (!homeId) {
    logger.warn("RTDN hogar sin homeId en el índice de compras (ack)");
    return;
  }

  // Reembolso a nivel de pedido o REVOKE de suscripción → revocar plaza.
  if (
    event.kind === "voided" ||
    event.notificationType === RTDN_TYPE.REVOKED
  ) {
    await revokeEntitlement(db, {
      homeId,
      uid: purchaseRef.uid,
      chargeId: event.purchaseToken,
      reason: event.kind === "voided" ? "google_voided" : "google_revoked",
    });
    return;
  }

  // Resto de transiciones (renovación, cancelación, gracia, expiración): la
  // fuente de verdad es el estado actual en Google Play, no el tipo de evento.
  if (!deps.verifyGooglePlay) {
    logger.error("RTDN sin verificador Google Play configurado: no se puede reconciliar", {
      notificationType: event.notificationType,
    });
    return;
  }

  const verified = await deps.verifyGooglePlay({
    productId: event.subscriptionId ?? purchaseRef.productId ?? "",
    purchaseToken: event.purchaseToken,
    transactionId: "",
    source: "google_play_rtdn",
  });
  await reconcileVerifiedEntitlement(db, purchaseRef, verified);
}

export const googlePlayRtdnHandler = onMessagePublished(
  {
    topic: process.env.GOOGLE_RTDN_TOPIC ?? "play-rtdn",
    secrets: [GOOGLE_PLAY_SA_JSON],
  },
  async (event) => {
    const messageData = event.data.message.data;
    const parsed = parseRtdnMessage(messageData);
    try {
      await handleRtdnEvent(admin.firestore(), parsed, {
        verifyGooglePlay: getActiveVerifiers().verifyGooglePlay,
      });
    } catch (err) {
      // Loguear pero NO relanzar: relanzar haría que Pub/Sub reintregue el
      // mensaje en bucle. La reconciliación es idempotente y el cron de
      // downgrade es la red de seguridad.
      logger.error("googlePlayRtdnHandler error", err);
    }
  },
);
