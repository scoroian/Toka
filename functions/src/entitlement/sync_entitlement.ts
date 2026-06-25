// functions/src/entitlement/sync_entitlement.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { applySlotUnlockTx } from "./slot_ledger";
import {
  parseReceiptData,
  validateReceipt,
  hasConfiguredVerifier,
} from "./sync_entitlement_helpers";
import { writePurchaseIndexTx, writePurchaseIndex } from "./reconcile_entitlement";
import { applyPlusEntitlement } from "./plus_entitlement";
import { isPlusProductId, plusCycleFromProductId } from "./plus_catalog";
import { applyPackEntitlement } from "./pack_entitlement";
import {
  isPackProductId,
  packFromProductId,
  packCycleFromProductId,
  activePacksFromHome,
  type ActivePacks,
} from "./pack_catalog";
import { buildBannerAdFlags } from "../shared/ad_constants";
import { isPremium, normalizePremiumStatus } from "../shared/free_limits";
import { resolveEntitlement, type HomeTier } from "../shared/tier_catalog";
import { isHomeTiersEnabled, isMemberPacksEnabled } from "../shared/feature_flags";

const db = () => admin.firestore();

// Material sensible de verificación contra las stores, gestionado por Secret
// Manager. Al enlazarlos en `secrets:[...]` de la callable, sus valores quedan
// disponibles en `process.env.<NOMBRE>` en runtime (los lee
// `buildVerifiersFromEnv`). La config NO sensible (packageName, bundleId,
// issuerId, keyId, env, STRICT_RECEIPT_VALIDATION) va en `functions/.env.<projectId>`.
const GOOGLE_PLAY_SA_JSON = defineSecret("GOOGLE_PLAY_SA_JSON");
const APP_STORE_PRIVATE_KEY = defineSecret("APP_STORE_PRIVATE_KEY");

/**
 * El desbloqueo de una plaza de hogar es PERMANENTE, así que solo se concede si
 * el recibo está `active` Y fue verificado server-side contra la store
 * (`storeVerified`). En modo inferencia/dev (storeVerified=false) se activa
 * Premium temporalmente pero NUNCA se acumulan créditos de plaza falsos.
 */
export function isValidForSlotUnlock(
  status: string,
  storeVerified: boolean,
): boolean {
  return status === "active" && storeVerified === true;
}

/**
 * Calcula las transiciones de billingState de las memberships. Sin esto el
 * pagador nunca puede leer su historial de cargos (las reglas de subscriptions
 * exigen billingState in ['currentPayer','formerPayer']).
 */
export function computeBillingUpdates(
  payerUid: string,
  prevPayerUid: string | null,
): Array<{ uid: string; billingState: string }> {
  const updates = [{ uid: payerUid, billingState: "currentPayer" }];
  if (prevPayerUid && prevPayerUid !== payerUid) {
    updates.push({ uid: prevPayerUid, billingState: "formerPayer" });
  }
  return updates;
}

// Gate de entrada de la callable:
//  - Si hay un verificador real configurado para la plataforma (credenciales
//    Google Play / App Store), la callable opera por la RUTA SEGURA: el estado
//    Premium se deriva del recibo verificado server-to-store.
//  - Si NO hay verificador, solo se permite la ruta de inferencia (sin verificar)
//    en el emulador o con el flag explícito TOKA_ALLOW_UNVERIFIED_RECEIPTS — en
//    producción, sin verificador y sin flag, la callable se bloquea y Premium NO
//    se puede activar sin verificación real.
function receiptValidationAllowed(platform: "ios" | "android"): boolean {
  if (hasConfiguredVerifier(platform)) {
    return true;
  }
  return process.env.FUNCTIONS_EMULATOR === "true" ||
    process.env.TOKA_ALLOW_UNVERIFIED_RECEIPTS === "true";
}

// `appCheck: true` exige que la petición venga de un cliente con attestation
// válida (DeviceCheck en iOS, Play Integrity en Android). Combinado con la
// validación server-side de `purchaseToken` contra Google/Apple cierra el
// vector de "cliente forja recibo y obtiene Premium gratis".
export const syncEntitlement = onCall(
  {
    enforceAppCheck: true,
    secrets: [GOOGLE_PLAY_SA_JSON, APP_STORE_PRIVATE_KEY],
  },
  async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const uid = request.auth.uid;
  // NOTA: el `chargeId` que envía el cliente se IGNORA a propósito. La clave de
  // idempotencia se deriva server-side del recibo verificado (purchaseToken /
  // originalTransactionId), no de `purchase.purchaseID` (que puede ser nulo en
  // iOS restored y es manipulable por el cliente).
  const { homeId, receiptData, platform } = request.data as {
    homeId: string;
    receiptData: string;
    platform: "ios" | "android";
  };

  // `homeId` solo es obligatorio para el eje HOGAR; el eje Plus es per-usuario.
  if (!receiptData || !platform) {
    throw new HttpsError(
      "invalid-argument",
      "receiptData and platform are required",
    );
  }
  if (platform !== "ios" && platform !== "android") {
    throw new HttpsError("invalid-argument", "platform must be ios or android");
  }

  if (!receiptValidationAllowed(platform)) {
    throw new HttpsError(
      "failed-precondition",
      "store-receipt-validation-not-enabled",
    );
  }

  const firestore = db();

  // Parsear el recibo: el cliente solo envía datos firmables por la store
  // (productId, purchaseToken, transactionId), no el estado Premium.
  const rawReceipt = parseReceiptData(receiptData);

  // ── Mapa productId → efecto ──────────────────────────────────────────────
  // Si el SKU es de Toka Plus, escribe el eje de entitlement INDIVIDUAL
  // (users/{uid}/entitlements/plus) y NO toca el hogar. No exige homeId ni
  // membresía: Plus es ortogonal al hogar.
  if (isPlusProductId(rawReceipt.productId)) {
    const validatedPlus = await validateReceipt(rawReceipt, platform);
    const plusStatus = normalizePremiumStatus(validatedPlus.status);
    const cycle = plusCycleFromProductId(rawReceipt.productId);
    const { active } = await applyPlusEntitlement(firestore, {
      uid,
      status: plusStatus,
      cycle,
      endsAt: validatedPlus.endsAt,
      autoRenewEnabled: validatedPlus.autoRenewEnabled,
      productId: rawReceipt.productId,
      platform,
      chargeId: validatedPlus.chargeId,
      source: "purchase",
    });
    // Índice de compras chargeId → usuario (kind 'plus') para que los handlers
    // de notificaciones de store reconcilien renovaciones/refunds del Plus.
    await writePurchaseIndex(firestore, validatedPlus.chargeId, {
      uid,
      platform,
      productId: rawReceipt.productId,
      kind: "plus",
    });
    logger.info("Toka Plus entitlement synced", {
      uid,
      status: plusStatus,
      active,
      chargeId: validatedPlus.chargeId,
    });
    return { success: true, plus: { status: plusStatus, active, cycle } };
  }

  // ── Eje HOGAR (tier) ─────────────────────────────────────────────────────
  if (!homeId) {
    throw new HttpsError("invalid-argument", "homeId is required");
  }

  // Validar que el usuario es miembro activo del hogar
  const memberRef = firestore
    .collection("homes")
    .doc(homeId)
    .collection("members")
    .doc(uid);
  const memberSnap = await memberRef.get();
  if (!memberSnap.exists || memberSnap.data()?.["status"] !== "active") {
    throw new HttpsError("permission-denied", "User is not an active member of this home");
  }

  // ── Eje PACK de miembro ────────────────────────────────────────────────────
  // Un SKU de pack amplía el tope del hogar (eje aditivo) SIN tocar el estado
  // premium/tier. Requiere que el hogar esté en tier Grupo: se rechaza
  // server-side sobre Pareja/Familia/Free o en modo binario (no existe Grupo).
  // El flag `member_packs_enabled` NO rechaza: con él OFF el pack se registra
  // pero sus plazas quedan dormidas (lo decide `applyPackEntitlement`).
  if (isPackProductId(rawReceipt.productId)) {
    const validatedPack = await validateReceipt(rawReceipt, platform);
    const packStatus = normalizePremiumStatus(validatedPack.status);
    const kind = packFromProductId(rawReceipt.productId);
    if (!kind) {
      throw new HttpsError("invalid-argument", "unknown-pack-product");
    }

    const tiersEnabled = await isHomeTiersEnabled();
    const homeData =
      (await firestore.collection("homes").doc(homeId).get()).data() ?? {};
    const tierResolved = resolveEntitlement({
      premiumStatus: homeData["premiumStatus"] as string | undefined,
      tier: (homeData["premiumTier"] as HomeTier | null | undefined) ?? null,
      tiersEnabled,
    });
    if (tierResolved.tier !== "grupo") {
      throw new HttpsError("failed-precondition", "pack-requires-grupo", {
        tier: tierResolved.tier,
      });
    }

    const packResult = await applyPackEntitlement(firestore, {
      homeId,
      kind,
      status: packStatus,
      cycle: packCycleFromProductId(rawReceipt.productId),
      endsAt: validatedPack.endsAt,
      autoRenewEnabled: validatedPack.autoRenewEnabled,
      productId: rawReceipt.productId,
      platform,
      chargeId: validatedPack.chargeId,
      source: "purchase",
    });

    // Índice chargeId → hogar (kind 'pack') para que RTDN/ASN reconcilien
    // renovaciones/refunds del pack.
    await writePurchaseIndex(firestore, validatedPack.chargeId, {
      homeId,
      uid,
      platform,
      productId: rawReceipt.productId,
      kind: "pack",
    });

    logger.info("Member pack entitlement synced", {
      uid,
      homeId,
      kind,
      active: packResult.active,
      maxMembers: packResult.maxMembers,
    });
    return {
      success: true,
      pack: { kind, active: packResult.active, maxMembers: packResult.maxMembers },
    };
  }

  // Validar contra la store (Google Play / App Store). Si hay verificador
  // configurado, deriva status/plan/fechas/chargeId del recibo verificado.
  // En dev (sin verificador y sin strict) infiere por productId con
  // storeVerified=false — App Check sigue siendo el gate primario.
  const validated = await validateReceipt(rawReceipt, platform);
  const status = normalizePremiumStatus(validated.status);
  const { plan, endsAt, autoRenewEnabled, storeVerified } = validated;
  // chargeId DERIVADO SERVER-SIDE del recibo verificado (purchaseToken /
  // originalTransactionId), nunca del purchaseID del cliente.
  const chargeId = validated.chargeId;
  const endsAtTs = endsAt ? Timestamp.fromDate(endsAt) : null;

  // Flags de Remote Config leídos fuera de la tx (cacheados). El tope se computa
  // DENTRO de la tx para incluir los packs activos del hogar: un re-sync del
  // recibo de Grupo en un hogar con packs NO debe bajar el tope a 10.
  const tiersEnabled = await isHomeTiersEnabled();
  const packsEnabled = await isMemberPacksEnabled();

  const homeRef = firestore.collection("homes").doc(homeId);
  const userRef = firestore.collection("users").doc(uid);
  const chargeRef = homeRef
    .collection("subscriptions")
    .doc("history")
    .collection("charges")
    .doc(chargeId);

  // TODA la escritura del hogar (premiumStatus, premiumEndsAt, currentPayerUid,
  // billingState) + el registro del cargo + el unlock de plaza ocurren en UNA
  // sola transacción guardada por `chargeSnap.exists`. Así un reintento o dos
  // peticiones concurrentes con el MISMO chargeId no extienden premiumEndsAt ni
  // duplican el slot: la segunda ve el charge existente y no toca nada.
  //
  // Firestore exige TODAS las lecturas antes de cualquier escritura, por eso
  // leemos charge + home + user por adelantado y luego escribimos.
  //
  // Importante: NO envolver en try/catch que trague el error. Si la transacción
  // falla debe propagarse al cliente.
  const result = await firestore.runTransaction(async (tx) => {
    const [chargeSnap, homeSnap, userSnap] = await Promise.all([
      tx.get(chargeRef),
      tx.get(homeRef),
      tx.get(userRef),
    ]);

    // Packs activos del hogar (eje aditivo) para el tope efectivo.
    const activePacks = activePacksFromHome(homeSnap.data(), Date.now());

    if (chargeSnap.exists) {
      // Ya procesado — idempotencia total: no se reescribe el hogar. El dashboard
      // se reescribe (idempotente) reflejando el estado EXISTENTE + packs.
      const existingStatus = normalizePremiumStatus(
        homeSnap.data()?.["premiumStatus"] as string | undefined,
      );
      const existingResolved = resolveEntitlement({
        premiumStatus: existingStatus,
        tier: (homeSnap.data()?.["premiumTier"] as HomeTier | null | undefined) ?? null,
        tiersEnabled,
        packsEnabled,
        packs: activePacks,
      });
      return {
        status: existingStatus,
        unlocked: false,
        alreadyProcessed: true,
        tier: existingResolved.tier,
        maxMembers: existingResolved.maxMembers,
        effectivePacks: effectivePacksFor(existingResolved.tier, packsEnabled, activePacks),
      };
    }

    // Tier efectivo + tope (productId del recibo + packs + flags). Único punto.
    const resolved = resolveEntitlement({
      premiumStatus: status,
      productId: rawReceipt.productId,
      tiersEnabled,
      packsEnabled,
      packs: activePacks,
    });
    if (resolved.failSafe) {
      logger.error("syncEntitlement: producto premium no catalogado, fail-safe a Free", {
        homeId,
        productId: rawReceipt.productId,
      });
    }

    const prevPayerUid =
      (homeSnap.data()?.["currentPayerUid"] as string | null | undefined) ??
      null;
    const validForUnlock = isValidForSlotUnlock(status, storeVerified);

    // 1) Estado Premium del hogar + tier y tope efectivo de miembros.
    tx.update(homeRef, {
      premiumStatus: status,
      premiumPlan: plan,
      premiumTier: resolved.tier,
      premiumEndsAt: endsAtTs,
      autoRenewEnabled: autoRenewEnabled,
      currentPayerUid: uid,
      "limits.maxMembers": resolved.maxMembers,
      updatedAt: FieldValue.serverTimestamp(),
    });

    // 2) Historial del cargo (clave de idempotencia).
    tx.set(chargeRef, {
      chargeId,
      uid,
      plan,
      platform,
      status,
      validForUnlock,
      productId: rawReceipt.productId,
      transactionId: rawReceipt.transactionId,
      // Marca explícita de si el recibo fue verificado contra la store.
      storeVerified,
      createdAt: FieldValue.serverTimestamp(),
    });

    // 2.bis) Índice de compras chargeId → hogar/pagador. Lo consultan los
    // handlers de notificaciones de store (RTDN / App Store) para reconciliar
    // renovaciones y reembolsos, que llegan con el purchaseToken /
    // originalTransactionId pero sin saber a qué hogar pertenecen.
    writePurchaseIndexTx(tx, firestore, chargeId, {
      homeId,
      uid,
      platform,
      productId: rawReceipt.productId,
    });

    // 3) billingState de las memberships.
    for (const upd of computeBillingUpdates(uid, prevPayerUid)) {
      tx.set(
        firestore
          .collection("users").doc(upd.uid)
          .collection("memberships").doc(homeId),
        { billingState: upd.billingState },
        { merge: true },
      );
    }

    // 4) Unlock de plaza permanente (solo si recibo verificado y active).
    let unlocked = false;
    if (validForUnlock) {
      unlocked = applySlotUnlockTx(tx, userRef, userSnap.data(), chargeId);
    }

    return {
      status,
      unlocked,
      alreadyProcessed: false,
      tier: resolved.tier,
      maxMembers: resolved.maxMembers,
      effectivePacks: effectivePacksFor(resolved.tier, packsEnabled, activePacks),
    };
  });

  if (result.unlocked) {
    logger.info("Slot unlocked", { uid, chargeId });
  } else {
    logger.debug("Slot not unlocked", {
      uid,
      chargeId,
      status: result.status,
      alreadyProcessed: result.alreadyProcessed,
    });
  }

  // Actualizar premiumFlags en dashboard (derivado/idempotente).
  await updatePremiumFlagsInDashboard(
    firestore,
    homeId,
    result.status,
    result.tier,
    result.maxMembers,
    result.effectivePacks,
  );

  return { success: true, premiumStatus: result.status };
});

/**
 * Packs que CONTRIBUYEN plazas ahora mismo (efectivos): solo si el tier efectivo
 * es Grupo y el flag está ON. Para el dashboard denormalizado de la Fase 7.
 */
function effectivePacksFor(
  tier: string | null,
  packsEnabled: boolean,
  activePacks: ActivePacks,
): ActivePacks {
  if (tier !== "grupo" || !packsEnabled) return { plus5: false, plus10: false };
  return { plus5: activePacks.plus5 === true, plus10: activePacks.plus10 === true };
}

async function updatePremiumFlagsInDashboard(
  firestore: admin.firestore.Firestore,
  homeId: string,
  premiumStatus: string,
  tier: string | null,
  maxMembers: number,
  effectivePacks: ActivePacks = {},
): Promise<void> {
  const homeIsPremium = isPremium(premiumStatus);
  const dashRef = firestore
    .collection("homes")
    .doc(homeId)
    .collection("views")
    .doc("dashboard");
  await dashRef.set(
    {
      premiumFlags: {
        isPremium: homeIsPremium,
        showAds: !homeIsPremium,
        canUseSmartDistribution: homeIsPremium,
        canUseVacations: homeIsPremium,
        canUseReviews: homeIsPremium,
        // Tier efectivo + tope denormalizados para que el cliente no recompute.
        tier,
        maxMembers,
        memberPacks: {
          plus5: effectivePacks.plus5 === true,
          plus10: effectivePacks.plus10 === true,
        },
      },
      adFlags: buildBannerAdFlags(!homeIsPremium),
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}
