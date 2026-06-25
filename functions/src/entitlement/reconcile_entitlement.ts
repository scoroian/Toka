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
import { resolveEntitlement } from "../shared/tier_catalog";
import { isHomeTiersEnabled, isMemberPacksEnabled } from "../shared/feature_flags";
import { autoSelectForDowngrade } from "./downgrade_helpers";
import { applySlotRevokeTx } from "./slot_ledger";
import { activePacksFromHome, type ActivePacks } from "./pack_catalog";
import type { VerifiedReceipt } from "./store_verifiers";

/**
 * Referencia de una compra indexada por chargeId.
 *
 * `kind` distingue el EJE de entitlement:
 *  - 'home': compra de tier de hogar → `homeId` presente (pagador = `uid`).
 *  - 'plus': compra del eje individual Toka Plus → sin `homeId` (es per-usuario).
 *  - 'pack': compra de un pack de miembro → `homeId` presente (amplía el tope
 *    del hogar Grupo; el `productId` identifica el pack +5/+10).
 *
 * `kind` es opcional para retrocompatibilidad con índices escritos antes de
 * existir el eje Plus: ausente ⇒ 'home'.
 */
export interface PurchaseRef {
  /** Hogar de la compra (ejes 'home'/'pack'); ausente en compras de Plus. */
  homeId?: string;
  uid: string;
  platform: "ios" | "android";
  productId?: string;
  kind?: "home" | "plus" | "pack";
}

// ---------------------------------------------------------------------------
// Índice de compras (chargeId → hogar/pagador)
// ---------------------------------------------------------------------------

/** Payload del índice de compras (compartido tx / no-tx). */
function purchaseIndexPayload(ref: PurchaseRef): Record<string, unknown> {
  return {
    homeId: ref.homeId ?? null,
    uid: ref.uid,
    platform: ref.platform,
    productId: ref.productId ?? null,
    kind: ref.kind ?? "home",
    updatedAt: FieldValue.serverTimestamp(),
  };
}

/** Escribe (merge) el mapeo chargeId → {homeId/uid/platform/kind} dentro de tx. */
export function writePurchaseIndexTx(
  tx: Transaction,
  db: Firestore,
  chargeId: string,
  ref: PurchaseRef,
): void {
  tx.set(db.collection("purchaseIndex").doc(chargeId), purchaseIndexPayload(ref), {
    merge: true,
  });
}

/**
 * Variante NO transaccional: la usa la ruta de compra de Toka Plus, que no
 * envuelve el índice en la misma transacción que el doc de entitlement.
 */
export async function writePurchaseIndex(
  db: Firestore,
  chargeId: string,
  ref: PurchaseRef,
): Promise<void> {
  await db
    .collection("purchaseIndex")
    .doc(chargeId)
    .set(purchaseIndexPayload(ref), { merge: true });
}

/**
 * Resuelve un chargeId a su referencia de compra. `null` si no está indexado o
 * le falta lo esencial. Para el eje 'home' se exige `homeId`; para 'plus' no.
 */
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
  // Retrocompat: índices sin `kind` son del eje hogar.
  const kind = (d["kind"] as "home" | "plus" | "pack" | undefined) ?? "home";
  if (!uid || !platform) return null;
  // Los ejes ligados al hogar (tier y packs) exigen homeId; Plus no.
  if ((kind === "home" || kind === "pack") && !homeId) return null;
  return {
    homeId: homeId ?? undefined,
    uid,
    platform,
    productId: d["productId"] as string | undefined,
    kind,
  };
}

// ---------------------------------------------------------------------------
// Escritura de flags del dashboard (premium/ads), espejo de syncEntitlement
// ---------------------------------------------------------------------------

export function writeDashboardPremiumFlagsTx(
  tx: Transaction,
  db: Firestore,
  homeId: string,
  premiumStatus: string,
  tier: string | null,
  maxMembers: number,
  effectivePacks: ActivePacks = {},
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
        // Tier efectivo + tope denormalizados (cliente no recomputa).
        tier,
        maxMembers,
        // Packs que CONTRIBUYEN plazas ahora mismo (efectivos: grupo + flag ON).
        // El cliente de Fase 7 los lee sin recomputar el cap.
        memberPacks: {
          plus5: effectivePacks.plus5 === true,
          plus10: effectivePacks.plus10 === true,
        },
      },
      adFlags: buildBannerAdFlags(!homeIsPremium),
      // Si deja de ser premium, ya no está en ventana de rescate.
      ...(homeIsPremium ? {} : { rescueFlags: { isInRescue: false, daysLeft: null } }),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

/**
 * Lee los miembros activos del hogar dentro de la transacción y devuelve los
 * docs que deben CONGELARSE para respetar `maxMembers`: el owner siempre se
 * mantiene; entre el resto gana el más participativo (criterio compartido con el
 * downgrade vía `autoSelectForDowngrade`). Devuelve [] si no hay excedente.
 *
 * READ-ONLY: solo lee (Firestore exige todas las lecturas antes de las
 * escrituras). El caller aplica la marca de congelación. Compartido por la
 * bajada de tier (`reconcileVerifiedEntitlement`) y la pérdida de pack
 * (`pack_entitlement`).
 */
export async function selectExcessActiveMembersTx(
  tx: Transaction,
  homeRef: DocumentReference,
  ownerId: string,
  maxMembers: number,
): Promise<admin.firestore.QueryDocumentSnapshot[]> {
  const membersSnap = await tx.get(
    homeRef.collection("members").where("status", "==", "active"),
  );
  if (membersSnap.size <= maxMembers) return [];
  const members = membersSnap.docs.map((d) => ({
    uid: d.id,
    status: "active",
    completions60d: (d.data()["completions60d"] as number) ?? 0,
    lastCompletedAt: (d.data()["lastCompletedAt"] as Timestamp | null) ?? null,
    joinedAt: d.data()["joinedAt"] as Timestamp,
  }));
  const { selectedMemberIds } = autoSelectForDowngrade(
    members,
    [],
    ownerId,
    maxMembers,
  );
  const keep = new Set(selectedMemberIds);
  return membersSnap.docs.filter((d) => !keep.has(d.id));
}

// ---------------------------------------------------------------------------
// Reconciliación de un recibo verificado (renovación / cambio de estado)
// ---------------------------------------------------------------------------

/**
 * Devuelve el MAYOR entre el `endsAt` existente y el nuevo: nunca acorta el
 * periodo por una notificación fuera de orden. Compartido con el eje Plus
 * (`plus_entitlement.ts`).
 */
export function laterTimestamp(
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

  // Guard de tipo: esta reconciliación es del eje HOGAR; sin homeId no aplica.
  const homeId = ref.homeId;
  if (!homeId) {
    logger.warn("reconcileVerifiedEntitlement sin homeId (no es eje hogar); skip");
    return { applied: false, status, reason: "no-home-id" };
  }

  // Flags de RC leídos fuera de la tx (cacheados). El tope se recomputa DENTRO
  // de la tx para incluir los packs activos del hogar (eje aditivo): así una
  // renovación de un Grupo con packs NO baja el tope a 10 ni congela de más.
  const tiersEnabled = await isHomeTiersEnabled();
  const packsEnabled = await isMemberPacksEnabled();

  const result = await db.runTransaction(async (tx) => {
    const homeRef = db.collection("homes").doc(homeId);
    const homeSnap = await tx.get(homeRef);
    if (!homeSnap.exists) {
      return { applied: false, status, reason: "home-not-found" } as ReconcileResult;
    }
    const homeData = homeSnap.data() ?? {};

    // Packs activos del hogar (verdad de la store) + tope efectivo (tier + packs,
    // gateado por el flag). El productId del recibo es del TIER, no de los packs:
    // los packs se conservan tal cual están persistidos.
    const activePacks = activePacksFromHome(homeData, Timestamp.now().toMillis());
    const resolved = resolveEntitlement({
      premiumStatus: status,
      productId: verified.productId,
      tiersEnabled,
      packsEnabled,
      packs: activePacks,
    });
    if (resolved.failSafe) {
      logger.error("reconcileVerifiedEntitlement: producto premium no catalogado, fail-safe a Free", {
        homeId,
        productId: verified.productId,
      });
    }
    const effectivePacks: ActivePacks =
      resolved.tier === "grupo" && packsEnabled ? activePacks : {};

    // Si el hogar sigue premium y el nuevo tope es menor que los miembros
    // activos (bajada de tier), congelamos los excedentes reutilizando el mismo
    // criterio que el downgrade a Free (owner + más activos). Las tareas NO se
    // tocan: sigue siendo premium. Lectura ANTES de cualquier escritura.
    const ownerId = homeData["ownerUid"] as string;
    const toFreeze = homeIsPremium
      ? await selectExcessActiveMembersTx(tx, homeRef, ownerId, resolved.maxMembers)
      : [];

    const existingEndsAt = homeData["premiumEndsAt"] as
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
      premiumTier: resolved.tier,
      premiumEndsAt: endsAtTs,
      autoRenewEnabled: verified.autoRenewEnabled,
      currentPayerUid: ref.uid,
      "limits.maxMembers": resolved.maxMembers,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // Congelar excedentes (mismo marcado que apply_downgrade_plan).
    for (const d of toFreeze) {
      tx.update(d.ref, {
        status: "frozen",
        frozenAt: FieldValue.serverTimestamp(),
      });
    }

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

    writeDashboardPremiumFlagsTx(
      tx, db, homeId, status, resolved.tier, resolved.maxMembers, effectivePacks,
    );
    return { applied: true, status } as ReconcileResult;
  });

  if (result.applied) {
    logger.info("reconcileVerifiedEntitlement applied", {
      homeId,
      status: result.status,
      chargeId: verified.chargeId,
    });
  } else {
    logger.warn("reconcileVerifiedEntitlement skipped", {
      homeId,
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
  // Tras revocar, el hogar es Free: tope 3 (y tier 'free'/null según flag).
  const tiersEnabled = await isHomeTiersEnabled();
  const resolved = resolveEntitlement({ premiumStatus: "expiredFree", tiersEnabled });
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
      premiumTier: resolved.tier,
      premiumEndsAt: Timestamp.now(),
      autoRenewEnabled: false,
      "limits.maxMembers": resolved.maxMembers,
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
    writeDashboardPremiumFlagsTx(tx, db, args.homeId, "expiredFree", resolved.tier, resolved.maxMembers);

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
