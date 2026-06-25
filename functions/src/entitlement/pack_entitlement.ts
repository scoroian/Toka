// functions/src/entitlement/pack_entitlement.ts
//
// Núcleo de persistencia y reconciliación del eje PACKS DE MIEMBRO (aditivo y
// reversible sobre un hogar Grupo). Escribe la entrada del pack en
// `homes/{homeId}.memberPacks.{kind}`, recalcula el TOPE EFECTIVO de miembros
// (tier + packs, gateado por el flag `member_packs_enabled`) y, si el tope baja
// por debajo de los miembros activos (pérdida de pack), CONGELA los excedentes
// reutilizando exactamente la maquinaria de downgrade (`autoSelectForDowngrade`
// vía `selectExcessActiveMembersTx`). Las tareas NO se tocan: el hogar sigue
// premium.
//
// Ejes que NO toca (separación consciente):
//   - El estado premium / tier del hogar (`premiumStatus`/`premiumTier`).
//   - Los slots de hogar permanentes (`lifetimeUnlockedHomeSlots`): los packs
//     son una SUSCRIPCIÓN reversible, no créditos permanentes.
//   - El eje individual Toka Plus.
//
// Idempotencia y "no acortar el periodo" se heredan de `laterTimestamp`:
// renovaciones fuera de orden no reducen `endsAt`, y reprocesar el mismo recibo
// es un no-op (la selección de congelación es determinista). El `chargeId`
// (purchaseToken / originalTransactionId) es estable durante toda la suscripción
// del pack y sirve de guarda para no revocar un pack más reciente con un refund
// antiguo.

import * as logger from "firebase-functions/logger";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import type { Firestore } from "firebase-admin/firestore";
import { isPremium, normalizePremiumStatus } from "../shared/free_limits";
import { resolveEntitlement, type HomeTier } from "../shared/tier_catalog";
import { isHomeTiersEnabled, isMemberPacksEnabled } from "../shared/feature_flags";
import {
  laterTimestamp,
  selectExcessActiveMembersTx,
  writeDashboardPremiumFlagsTx,
} from "./reconcile_entitlement";
import {
  isPackActive,
  isPackEntryActive,
  packFromProductId,
  packCycleFromProductId,
  type ActivePacks,
  type PackKind,
  type PackCycle,
} from "./pack_catalog";
import type { VerifiedReceipt } from "./store_verifiers";

/** El "otro" pack distinto de `kind` (solo hay dos: plus5 / plus10). */
function otherPack(kind: PackKind): PackKind {
  return kind === "plus5" ? "plus10" : "plus5";
}

export interface PackApplyInput {
  homeId: string;
  kind: PackKind;
  /** status crudo del recibo (se normaliza dentro). */
  status: string;
  cycle: PackCycle;
  endsAt: Date | null;
  autoRenewEnabled: boolean;
  productId: string;
  platform: "ios" | "android";
  chargeId: string;
  /** Origen: 'purchase' (sync de compra) o 'store_notification' (reconciliación). */
  source: string;
}

export interface PackApplyResult {
  applied: boolean;
  active: boolean;
  status: string;
  /** Tope efectivo tras aplicar el pack. */
  maxMembers: number;
  /** Nº de miembros congelados por bajada de tope. */
  frozen: number;
  reason?: string;
}

/**
 * Escribe/actualiza una entrada de pack del hogar en una transacción y recalcula
 * el tope efectivo. Si el tope baja por debajo de los activos, congela los
 * excedentes. NO toca el estado premium/tier del hogar ni los slots permanentes.
 *
 * Tolerante a tier no-Grupo y a flag OFF: en esos casos registra la entrada
 * (verdad de la store) pero las plazas quedan DORMIDAS (tope = tope del tier).
 */
export async function applyPackEntitlement(
  db: Firestore,
  input: PackApplyInput,
): Promise<PackApplyResult> {
  const status = normalizePremiumStatus(input.status);
  const active = isPackActive(status);
  const tiersEnabled = await isHomeTiersEnabled();
  const packsEnabled = await isMemberPacksEnabled();

  const result = await db.runTransaction(async (tx): Promise<PackApplyResult> => {
    const homeRef = db.collection("homes").doc(input.homeId);
    const homeSnap = await tx.get(homeRef);
    if (!homeSnap.exists) {
      return { applied: false, active, status, maxMembers: 0, frozen: 0, reason: "home-not-found" };
    }
    const homeData = homeSnap.data() ?? {};
    const ownerId = homeData["ownerUid"] as string;
    const premiumStatus = homeData["premiumStatus"] as string | undefined;
    const tier = (homeData["premiumTier"] as HomeTier | null | undefined) ?? null;
    const existingPacks = (homeData["memberPacks"] ?? {}) as Record<string, Record<string, unknown>>;
    const existingEntry = existingPacks[input.kind];

    // endsAt: si sigue activo, nunca acortar (max); si no, fijar el nuevo (o
    // conservar el existente si la notificación no trae fecha).
    const existingEndsAt = existingEntry?.["endsAt"] as Timestamp | null | undefined;
    const endsAtTs = active
      ? laterTimestamp(existingEndsAt, input.endsAt)
      : input.endsAt
        ? Timestamp.fromDate(input.endsAt)
        : (existingEndsAt ?? null);

    // Packs activos resultantes (verdad de la store): este kind según la entrada
    // que vamos a escribir; el otro, tal cual está persistido.
    const nowMs = Timestamp.now().toMillis();
    const thisActive = isPackEntryActive({ status, endsAt: endsAtTs }, nowMs);
    const activePacks: ActivePacks = {
      [input.kind]: thisActive,
      [otherPack(input.kind)]: isPackEntryActive(existingPacks[otherPack(input.kind)], nowMs),
    } as ActivePacks;

    const resolved = resolveEntitlement({
      premiumStatus,
      tier,
      tiersEnabled,
      packsEnabled,
      packs: activePacks,
    });
    const effectivePacks: ActivePacks =
      resolved.tier === "grupo" && packsEnabled ? activePacks : {};

    // Congelar excedentes solo si el hogar es premium (mismo guard que la bajada
    // de tier). Si no es premium, el tope lo gobierna la maquinaria de downgrade.
    const toFreeze = isPremium(premiumStatus)
      ? await selectExcessActiveMembersTx(tx, homeRef, ownerId, resolved.maxMembers)
      : [];

    tx.update(homeRef, {
      [`memberPacks.${input.kind}`]: {
        status,
        active,
        cycle: input.cycle,
        productId: input.productId,
        platform: input.platform,
        chargeId: input.chargeId,
        autoRenewEnabled: input.autoRenewEnabled,
        endsAt: endsAtTs,
        source: input.source,
        startsAt: existingEntry?.["startsAt"] ?? FieldValue.serverTimestamp(),
        createdAt: existingEntry?.["createdAt"] ?? FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      "limits.maxMembers": resolved.maxMembers,
      updatedAt: FieldValue.serverTimestamp(),
    });

    for (const d of toFreeze) {
      tx.update(d.ref, { status: "frozen", frozenAt: FieldValue.serverTimestamp() });
    }

    writeDashboardPremiumFlagsTx(
      tx, db, input.homeId, premiumStatus ?? "free", resolved.tier, resolved.maxMembers, effectivePacks,
    );

    return {
      applied: true,
      active,
      status,
      maxMembers: resolved.maxMembers,
      frozen: toFreeze.length,
    };
  });

  if (result.applied) {
    logger.info("applyPackEntitlement", {
      homeId: input.homeId,
      kind: input.kind,
      status: result.status,
      active: result.active,
      maxMembers: result.maxMembers,
      frozen: result.frozen,
    });
  } else {
    logger.warn("applyPackEntitlement skipped", {
      homeId: input.homeId,
      kind: input.kind,
      reason: result.reason,
    });
  }
  return result;
}

/**
 * Adaptador: aplica un recibo de pack verificado contra la store al eje de packs.
 * Lo usan los handlers de notificaciones (RTDN / App Store) para renovaciones y
 * cambios de estado. El kind y el ciclo se derivan del productId verificado.
 */
export async function reconcileVerifiedPack(
  db: Firestore,
  ref: { homeId: string; uid: string; platform: "ios" | "android" },
  verified: VerifiedReceipt,
): Promise<PackApplyResult> {
  const kind = packFromProductId(verified.productId);
  if (!kind) {
    logger.warn("reconcileVerifiedPack: productId no es de pack (skip)", {
      productId: verified.productId,
    });
    return {
      applied: false, active: false, status: verified.status,
      maxMembers: 0, frozen: 0, reason: "not-a-pack",
    };
  }
  return applyPackEntitlement(db, {
    homeId: ref.homeId,
    kind,
    status: verified.status,
    cycle: packCycleFromProductId(verified.productId),
    endsAt: verified.endsAt,
    autoRenewEnabled: verified.autoRenewEnabled,
    productId: verified.productId,
    platform: ref.platform,
    chargeId: verified.chargeId,
    source: "store_notification",
  });
}

export interface RevokePackArgs {
  homeId: string;
  kind: PackKind;
  chargeId: string;
  reason: string;
}

export interface RevokePackResult {
  revoked: boolean;
  maxMembers?: number;
  frozen?: number;
  reason?: string;
}

/**
 * Revoca un pack del hogar (refund / chargeback / void). Marca la entrada
 * `status='refunded'`, `active=false`, `endsAt=now`, recalcula el tope efectivo y
 * congela los excedentes. GUARDA por chargeId: si la entrada vigente pertenece a
 * OTRO cargo (el hogar ya renovó/recompró ese pack), no revoca el pack nuevo.
 * Idempotente. NUNCA toca `lifetimeUnlockedHomeSlots` (eje permanente separado).
 */
export async function revokePack(
  db: Firestore,
  args: RevokePackArgs,
): Promise<RevokePackResult> {
  const tiersEnabled = await isHomeTiersEnabled();
  const packsEnabled = await isMemberPacksEnabled();

  const out = await db.runTransaction(async (tx): Promise<RevokePackResult> => {
    const homeRef = db.collection("homes").doc(args.homeId);
    const homeSnap = await tx.get(homeRef);
    if (!homeSnap.exists) return { revoked: false, reason: "home-not-found" };
    const homeData = homeSnap.data() ?? {};
    const existingPacks = (homeData["memberPacks"] ?? {}) as Record<string, Record<string, unknown>>;
    const entry = existingPacks[args.kind];
    if (!entry) return { revoked: false, reason: "no-pack-entry" };

    const currentChargeId = entry["chargeId"] as string | undefined;
    if (currentChargeId && currentChargeId !== args.chargeId) {
      // El refund es de un pack superado por una compra/renovación más reciente.
      return { revoked: false, reason: "charge-superseded" };
    }
    if (entry["active"] === false && entry["status"] === "refunded") {
      return { revoked: false, reason: "already-revoked" };
    }

    const ownerId = homeData["ownerUid"] as string;
    const premiumStatus = homeData["premiumStatus"] as string | undefined;
    const tier = (homeData["premiumTier"] as HomeTier | null | undefined) ?? null;
    const nowMs = Timestamp.now().toMillis();
    const activePacks: ActivePacks = {
      [args.kind]: false,
      [otherPack(args.kind)]: isPackEntryActive(existingPacks[otherPack(args.kind)], nowMs),
    } as ActivePacks;

    const resolved = resolveEntitlement({
      premiumStatus,
      tier,
      tiersEnabled,
      packsEnabled,
      packs: activePacks,
    });
    const effectivePacks: ActivePacks =
      resolved.tier === "grupo" && packsEnabled ? activePacks : {};

    const toFreeze = isPremium(premiumStatus)
      ? await selectExcessActiveMembersTx(tx, homeRef, ownerId, resolved.maxMembers)
      : [];

    tx.update(homeRef, {
      [`memberPacks.${args.kind}.status`]: "refunded",
      [`memberPacks.${args.kind}.active`]: false,
      [`memberPacks.${args.kind}.autoRenewEnabled`]: false,
      [`memberPacks.${args.kind}.endsAt`]: Timestamp.now(),
      [`memberPacks.${args.kind}.revokedReason`]: args.reason,
      [`memberPacks.${args.kind}.revokedAt`]: FieldValue.serverTimestamp(),
      [`memberPacks.${args.kind}.updatedAt`]: FieldValue.serverTimestamp(),
      "limits.maxMembers": resolved.maxMembers,
      updatedAt: FieldValue.serverTimestamp(),
    });

    for (const d of toFreeze) {
      tx.update(d.ref, { status: "frozen", frozenAt: FieldValue.serverTimestamp() });
    }

    writeDashboardPremiumFlagsTx(
      tx, db, args.homeId, premiumStatus ?? "free", resolved.tier, resolved.maxMembers, effectivePacks,
    );

    return { revoked: true, maxMembers: resolved.maxMembers, frozen: toFreeze.length };
  });

  if (out.revoked) {
    logger.info("revokePack", {
      homeId: args.homeId, kind: args.kind, chargeId: args.chargeId,
      reason: args.reason, maxMembers: out.maxMembers, frozen: out.frozen,
    });
  } else {
    logger.debug("revokePack skipped", {
      homeId: args.homeId, kind: args.kind, reason: out.reason,
    });
  }
  return out;
}
