// functions/src/entitlement/reconcile_entitlement.ts
//
// Núcleo compartido de RECONCILIACIÓN del estado Premium de un hogar con las
// stores. Lo usan los handlers de notificaciones de store (RTDN de Google,
// App Store Server Notifications v2) para:
//
//  - RENOVACIÓN / cambio de estado: aplicar el entitlement verificado al hogar
//    (premiumStatus / premiumEndsAt / autoRenew / dashboard) sin extender nunca
//    el periodo por reintentos fuera de orden (se toma el max de endsAt).
//  - REFUND / chargeback / revoke: revocar Premium (hogar → expiredFree, ads ON)
//    Y la plaza concedida por ese cargo (validForUnlock=false, decrementa
//    lifetimeUnlockedHomeSlots).
//
// La idempotencia es por `chargeId` (purchaseToken en Android /
// originalTransactionId en iOS). El mapeo chargeId → hogar/pagador se mantiene
// en la colección `purchaseIndex/{chargeId}`, escrita por `syncEntitlement` en
// el momento de la compra.

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import type {
  Firestore,
  Transaction,
  DocumentReference,
} from "firebase-admin/firestore";
import { buildBannerAdFlags } from "../shared/ad_constants";
import { isPremium, normalizePremiumStatus } from "../shared/free_limits";
import { applySlotRevokeTx } from "./slot_ledger";
import type { VerifiedReceipt } from "./store_verifiers";

/** Referencia de una compra: a qué hogar y pagador pertenece un chargeId. */
export interface PurchaseRef {
  homeId: string;
  uid: string;
  platform: "ios" | "android";
  productId?: string;
}

const FREE_MAX_MEMBERS = 3;
const PREMIUM_MAX_MEMBERS = 10;

// ---------------------------------------------------------------------------
// Índice de compras (chargeId → hogar/pagador)
// ---------------------------------------------------------------------------

/** Escribe (merge) el mapeo chargeId → {homeId, uid, platform} dentro de tx. */
export function writePurchaseIndexTx(
  tx: Transaction,
  db: Firestore,
  chargeId: string,
  ref: PurchaseRef,
): void {
  tx.set(
    db.collection("purchaseIndex").doc(chargeId),
    {
      homeId: ref.homeId,
      uid: ref.uid,
      platform: ref.platform,
      productId: ref.productId ?? null,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

/** Resuelve un chargeId a su hogar/pagador. `null` si no está indexado. */
export async function lookupPurchase(
  db: Firestore,
  chargeId: string,
): Promise<PurchaseRef | null> {
  const snap = await db.collection("purchaseIndex").doc(chargeId).get();
  if (!snap.exists) return null;
  const d = snap.data() as Record<string, unknown>;
  const homeId = d["homeId"] as string | undefined;
  const uid = d["uid"] as string | undefined;
  const platform = d["platform"] as "ios" | "android" | undefined;
  if (!homeId || !uid || !platform) return null;
  return { homeId, uid, platform, productId: d["productId"] as string | undefined };
}

// ---------------------------------------------------------------------------
// Escritura de flags del dashboard (premium/ads), espejo de syncEntitlement
// ---------------------------------------------------------------------------

export function writeDashboardPremiumFlagsTx(
  tx: Transaction,
  db: Firestore,
  homeId: string,
  premiumStatus: string,
): void {
  const homeIsPremium = isPremium(premiumStatus);
  const dashRef = db
    .collection("homes")
    .doc(homeId)
    .collection("views")
    .doc("dashboard");
  tx.set(
    dashRef,
    {
      premiumFlags: {
        isPremium: homeIsPremium,
        showAds: !homeIsPremium,
        canUseSmartDistribution: homeIsPremium,
        canUseVacations: homeIsPremium,
        canUseReviews: homeIsPremium,
      },
      adFlags: buildBannerAdFlags(!homeIsPremium),
      // Si deja de ser premium, ya no está en ventana de rescate.
      ...(homeIsPremium ? {} : { rescueFlags: { isInRescue: false, daysLeft: null } }),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

// ---------------------------------------------------------------------------
// Reconciliación de un recibo verificado (renovación / cambio de estado)
// ---------------------------------------------------------------------------

function laterTimestamp(
  existing: Timestamp | null | undefined,
  next: Date | null,
): Timestamp | null {
  const nextTs = next ? Timestamp.fromDate(next) : null;
  if (!existing) return nextTs;
  if (!nextTs) return existing;
  // Nunca acortar el periodo por una notificación fuera de orden.
  return nextTs.toMillis() > existing.toMillis() ? nextTs : existing;
}

export interface ReconcileResult {
  applied: boolean;
  status: string;
  reason?: string;
}

/**
 * Aplica un entitlement verificado al hogar. Pensada para notificaciones de
 * renovación/cambio de estado de la store. Si el hogar dejó de existir, no hace
 * nada. NO extiende el periodo hacia atrás (toma el max de premiumEndsAt).
 */
export async function reconcileVerifiedEntitlement(
  db: Firestore,
  ref: PurchaseRef,
  verified: VerifiedReceipt,
): Promise<ReconcileResult> {
  const status = normalizePremiumStatus(verified.status);
  const homeIsPremium = isPremium(status);

  const result = await db.runTransaction(async (tx) => {
    const homeRef = db.collection("homes").doc(ref.homeId);
    const homeSnap = await tx.get(homeRef);
    if (!homeSnap.exists) {
      return { applied: false, status, reason: "home-not-found" } as ReconcileResult;
    }

    const existingEndsAt = homeSnap.data()?.["premiumEndsAt"] as
      | Timestamp
      | null
      | undefined;
    const endsAtTs = homeIsPremium
      ? laterTimestamp(existingEndsAt, verified.endsAt)
      : verified.endsAt
        ? Timestamp.fromDate(verified.endsAt)
        : null;

    tx.update(homeRef, {
      premiumStatus: status,
      premiumPlan: verified.plan,
      premiumEndsAt: endsAtTs,
      autoRenewEnabled: verified.autoRenewEnabled,
      currentPayerUid: ref.uid,
      "limits.maxMembers": homeIsPremium ? PREMIUM_MAX_MEMBERS : FREE_MAX_MEMBERS,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Auditoría: upsert del cargo (no es la clave de idempotencia aquí, solo
    // historial; el chargeId sigue siendo estable durante toda la suscripción).
    const chargeRef = homeRef
      .collection("subscriptions")
      .doc("history")
      .collection("charges")
      .doc(verified.chargeId);
    tx.set(
      chargeRef,
      {
        chargeId: verified.chargeId,
        uid: ref.uid,
        plan: verified.plan,
        platform: ref.platform,
        status,
        productId: verified.productId,
        storeVerified: true,
        premiumEndsAt: endsAtTs,
        source: "store_notification",
        lastEventAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    writeDashboardPremiumFlagsTx(tx, db, ref.homeId, status);
    return { applied: true, status } as ReconcileResult;
  });

  if (result.applied) {
    logger.info("reconcileVerifiedEntitlement applied", {
      homeId: ref.homeId,
      status: result.status,
      chargeId: verified.chargeId,
    });
  } else {
    logger.warn("reconcileVerifiedEntitlement skipped", {
      homeId: ref.homeId,
      reason: result.reason,
    });
  }
  return result;
}

// ---------------------------------------------------------------------------
// Revocación de Premium (refund / chargeback / revoke)
// ---------------------------------------------------------------------------

export interface RevokeArgs {
  homeId: string;
  uid: string;
  chargeId: string;
  reason: string;
}

export interface RevokeResult {
  premiumRevoked: boolean;
  slotRevoked: boolean;
  reason?: string;
}

/**
 * Revoca Premium del hogar y la plaza concedida por el cargo reembolsado.
 *  - Hogar: premiumStatus → 'expiredFree', premiumEndsAt → now, autoRenew off,
 *    limits.maxMembers → Free, dashboard a Free (ads ON).
 *  - Plaza: marca el ledger validForUnlock=false y decrementa
 *    lifetimeUnlockedHomeSlots del pagador.
 *  - Cargo: status='refunded', validForUnlock=false, refundedAt.
 *  - billingState del pagador → formerPayer (conserva acceso al historial).
 *
 * Todo en UNA transacción. Idempotente: re-ejecutar no vuelve a decrementar
 * (la plaza ya está revocada) ni rompe nada.
 */
export async function revokeEntitlement(
  db: Firestore,
  args: RevokeArgs,
): Promise<RevokeResult> {
  const result = await db.runTransaction(async (tx) => {
    const homeRef = db.collection("homes").doc(args.homeId);
    const userRef: DocumentReference = db.collection("users").doc(args.uid);
    const ledgerRef = userRef.collection("slotLedger").doc(args.chargeId);
    const chargeRef = homeRef
      .collection("subscriptions")
      .doc("history")
      .collection("charges")
      .doc(args.chargeId);

    const [homeSnap, userSnap, ledgerSnap] = await Promise.all([
      tx.get(homeRef),
      tx.get(userRef),
      tx.get(ledgerRef),
    ]);

    if (!homeSnap.exists) {
      return { premiumRevoked: false, slotRevoked: false, reason: "home-not-found" };
    }

    // 1) Hogar → estado no-premium efectivo inmediato.
    tx.update(homeRef, {
      premiumStatus: "expiredFree",
      premiumEndsAt: Timestamp.now(),
      autoRenewEnabled: false,
      "limits.maxMembers": FREE_MAX_MEMBERS,
      lastBillingError: `revoked:${args.reason}`,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // 2) Plaza permanente → revocada (decrementa contador del pagador).
    const slotRevoked = applySlotRevokeTx(
      tx,
      userRef,
      userSnap.data(),
      ledgerSnap,
      args.chargeId,
      args.reason,
    );

    // 3) Cargo marcado como reembolsado (auditoría + idempotencia visible).
    tx.set(
      chargeRef,
      {
        status: "refunded",
        validForUnlock: false,
        refundReason: args.reason,
        refundedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    // 4) El pagador pasa a formerPayer (conserva lectura de su historial).
    if (homeSnap.data()?.["currentPayerUid"] === args.uid) {
      tx.set(
        userRef.collection("memberships").doc(args.homeId),
        { billingState: "formerPayer" },
        { merge: true },
      );
    }

    // 5) Dashboard a Free (ads reaparecen).
    writeDashboardPremiumFlagsTx(tx, db, args.homeId, "expiredFree");

    return { premiumRevoked: true, slotRevoked };
  });

  logger.info("revokeEntitlement", {
    homeId: args.homeId,
    uid: args.uid,
    chargeId: args.chargeId,
    reason: args.reason,
    ...result,
  });
  return result;
}

/** Acceso a Firestore (lazy, para no inicializar en import). */
export function db(): Firestore {
  return admin.firestore();
}
