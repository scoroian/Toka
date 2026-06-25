// functions/src/entitlement/plus_entitlement.ts
//
// Núcleo de persistencia y reconciliación del eje de entitlement INDIVIDUAL
// "Toka Plus". Es el equivalente per-usuario de `reconcile_entitlement.ts`
// (que es per-hogar): escribe SOLO `users/{uid}/entitlements/plus` y la
// proyección denormalizada `homes/{homeId}/members/{uid}.plusActive`, sin tocar
// NUNCA el doc del hogar, su estado premium, su tier ni a otros miembros.
//
// La idempotencia y el "no acortar el periodo" se heredan de la maquinaria de
// hogar (`laterTimestamp`): renovaciones fuera de orden no reducen `endsAt`, y
// reprocesar el mismo recibo es un no-op. El `chargeId` (purchaseToken en
// Android / originalTransactionId en iOS) es estable durante toda la suscripción
// y sirve de guarda para no revocar un Plus más reciente con un refund antiguo.

import * as logger from "firebase-functions/logger";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import type { Firestore, DocumentReference } from "firebase-admin/firestore";
import { chunked, MAX_BATCH_OPS } from "../shared/batch_utils";
import { normalizePremiumStatus } from "../shared/free_limits";
import { laterTimestamp } from "./reconcile_entitlement";
import { isPlusActive, plusCycleFromProductId, type PlusCycle } from "./plus_catalog";
import type { VerifiedReceipt } from "./store_verifiers";

/** Ruta canónica del entitlement Plus de un usuario. */
export function plusEntitlementRef(
  db: Firestore,
  uid: string,
): DocumentReference {
  return db
    .collection("users")
    .doc(uid)
    .collection("entitlements")
    .doc("plus");
}

/**
 * Lee el booleano `active` (verdad de la store, sin gatear por flag) del
 * entitlement Plus de un usuario. `false` si no hay doc. Lo usa el backfill de
 * `plusActive` al crear/reactivar un doc de miembro (alta de hogar / join /
 * reinstate), para que la proyección esté completa también cuando el usuario ya
 * tenía Plus ANTES de entrar a ese hogar.
 */
export async function readPlusActive(
  db: Firestore,
  uid: string,
): Promise<boolean> {
  const snap = await plusEntitlementRef(db, uid).get();
  return snap.data()?.["active"] === true;
}

export interface PlusWriteInput {
  uid: string;
  /** status crudo (se normaliza dentro). */
  status: string;
  cycle: PlusCycle;
  endsAt: Date | null;
  autoRenewEnabled: boolean;
  productId: string;
  platform: "ios" | "android";
  chargeId: string;
  /** Origen: 'purchase' (sync de compra) o 'store_notification' (reconciliación). */
  source: string;
}

export interface PlusWriteResult {
  active: boolean;
  status: string;
}

/**
 * Escribe/actualiza el entitlement Plus de un usuario en una transacción.
 * `active` se deriva del status (verdad de la store, SIN gatear por flag: el
 * flag `toka_plus_enabled` se aplica al consumir). `startsAt`/`createdAt` son
 * sticky (solo se fijan en la primera escritura). Tras la transacción propaga la
 * proyección `plusActive` a los docs de miembro del usuario.
 */
export async function applyPlusEntitlement(
  db: Firestore,
  input: PlusWriteInput,
): Promise<PlusWriteResult> {
  const status = normalizePremiumStatus(input.status);
  const active = isPlusActive(status);
  const ref = plusEntitlementRef(db, input.uid);

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const existing = snap.data();
    const existingEndsAt = existing?.["endsAt"] as Timestamp | null | undefined;
    // Sigue activo → nunca acortar (max). Ya no activo → fijar el endsAt nuevo
    // (o conservar el existente si la notificación no trae fecha).
    const endsAtTs = active
      ? laterTimestamp(existingEndsAt, input.endsAt)
      : input.endsAt
        ? Timestamp.fromDate(input.endsAt)
        : existingEndsAt ?? null;

    tx.set(
      ref,
      {
        status,
        active,
        cycle: input.cycle,
        startsAt: existing?.["startsAt"] ?? FieldValue.serverTimestamp(),
        endsAt: endsAtTs,
        autoRenewEnabled: input.autoRenewEnabled,
        productId: input.productId,
        platform: input.platform,
        chargeId: input.chargeId,
        source: input.source,
        createdAt: existing?.["createdAt"] ?? FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });

  await propagatePlusActiveToMembers(db, input.uid, active);
  return { active, status };
}

/**
 * Adaptador: aplica un recibo verificado contra la store al eje Plus. Lo usan
 * los handlers de notificaciones (RTDN / App Store) para renovaciones y cambios
 * de estado. El ciclo se deriva del productId verificado.
 */
export async function reconcileVerifiedPlus(
  db: Firestore,
  ref: { uid: string; platform: "ios" | "android" },
  verified: VerifiedReceipt,
): Promise<PlusWriteResult> {
  return applyPlusEntitlement(db, {
    uid: ref.uid,
    status: verified.status,
    cycle: plusCycleFromProductId(verified.productId),
    endsAt: verified.endsAt,
    autoRenewEnabled: verified.autoRenewEnabled,
    productId: verified.productId,
    platform: ref.platform,
    chargeId: verified.chargeId,
    source: "store_notification",
  });
}

export interface RevokePlusArgs {
  uid: string;
  chargeId: string;
  reason: string;
}

export interface RevokePlusResult {
  revoked: boolean;
  reason?: string;
}

/**
 * Revoca el eje Plus de un usuario (refund / chargeback / revoke). Marca
 * `status='refunded'`, `active=false`, `endsAt=now` y propaga la desactivación a
 * los docs de miembro. Idempotente. GUARDA por chargeId: si el doc vigente
 * pertenece a OTRO cargo (el usuario ya se resuscribió), no revoca el Plus nuevo.
 */
export async function revokePlus(
  db: Firestore,
  args: RevokePlusArgs,
): Promise<RevokePlusResult> {
  const ref = plusEntitlementRef(db, args.uid);
  const out = await db.runTransaction(async (tx): Promise<RevokePlusResult> => {
    const snap = await tx.get(ref);
    if (!snap.exists) return { revoked: false, reason: "no-plus-doc" };
    const currentChargeId = snap.data()?.["chargeId"] as string | undefined;
    if (currentChargeId && currentChargeId !== args.chargeId) {
      // El refund es de una suscripción superada por otra más reciente.
      return { revoked: false, reason: "charge-superseded" };
    }
    tx.set(
      ref,
      {
        status: "refunded",
        active: false,
        autoRenewEnabled: false,
        endsAt: Timestamp.now(),
        revokedReason: args.reason,
        revokedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return { revoked: true };
  });

  if (out.revoked) {
    await propagatePlusActiveToMembers(db, args.uid, false);
    logger.info("revokePlus", {
      uid: args.uid,
      chargeId: args.chargeId,
      reason: args.reason,
    });
  } else {
    logger.debug("revokePlus skipped", { uid: args.uid, reason: out.reason });
  }
  return out;
}

/**
 * Proyecta el booleano `plusActive` (verdad de la store, sin gatear por flag) en
 * `homes/{homeId}/members/{uid}` de TODOS los hogares del usuario, para que los
 * co-miembros vigentes puedan leerlo (la matriz de ads de la Fase 5 puede
 * necesitar saber si otro miembro tiene Plus). El doc de entitlement crudo sigue
 * siendo privado del propio usuario. Troceado para no chocar con el límite de
 * 500 ops/batch.
 */
export async function propagatePlusActiveToMembers(
  db: Firestore,
  uid: string,
  active: boolean,
): Promise<void> {
  const memberships = await db
    .collection("users")
    .doc(uid)
    .collection("memberships")
    .get();
  if (memberships.empty) return;

  const memberRefs = memberships.docs.map((d) =>
    db.collection("homes").doc(d.id).collection("members").doc(uid),
  );

  for (const group of chunked(memberRefs, MAX_BATCH_OPS)) {
    const batch = db.batch();
    for (const r of group) {
      batch.set(r, { plusActive: active }, { merge: true });
    }
    await batch.commit();
  }
}
