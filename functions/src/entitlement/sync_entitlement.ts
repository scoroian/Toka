// functions/src/entitlement/sync_entitlement.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { unlockSlotIfEligibleTx } from "./slot_ledger";
import { parseReceiptData, validateReceipt } from "./sync_entitlement_helpers";
import { DEFAULT_BANNER_UNIT_ID } from "../shared/ad_constants";

const db = () => admin.firestore();

// `appCheck: true` exige que la petición venga de un cliente con attestation
// válida (DeviceCheck en iOS, Play Integrity en Android). Combinado con la
// validación server-side de `purchaseToken` contra Google/Apple cierra el
// vector de "cliente forja recibo y obtiene Premium gratis".
export const syncEntitlement = onCall({ enforceAppCheck: true }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const uid = request.auth.uid;
  const { homeId, receiptData, platform, chargeId } = request.data as {
    homeId: string;
    receiptData: string;
    platform: "ios" | "android";
    chargeId: string;
  };

  if (!homeId || !receiptData || !platform || !chargeId) {
    throw new HttpsError(
      "invalid-argument",
      "homeId, receiptData, platform and chargeId are required",
    );
  }
  if (platform !== "ios" && platform !== "android") {
    throw new HttpsError("invalid-argument", "platform must be ios or android");
  }

  const firestore = db();

  // Validar que el usuario es miembro del hogar
  const memberRef = firestore
    .collection("homes")
    .doc(homeId)
    .collection("members")
    .doc(uid);
  const memberSnap = await memberRef.get();
  if (!memberSnap.exists) {
    throw new HttpsError("permission-denied", "User is not a member of this home");
  }

  // Parsear el recibo: el cliente solo envía datos firmables por la store
  // (productId, purchaseToken, transactionId), no el estado Premium.
  const rawReceipt = parseReceiptData(receiptData);
  // Validar contra la store (Google Play / App Store). En modo strict
  // hace verificación server-side real y rechaza si la suscripción no
  // está activa o el token está corrupto. En dev infiere por productId
  // con warnings — App Check sigue siendo el gate primario.
  const { status, plan, endsAt, autoRenewEnabled, storeVerified } =
    await validateReceipt(rawReceipt, platform);

  // Actualizar el hogar
  const homeRef = firestore.collection("homes").doc(homeId);
  await homeRef.update({
    premiumStatus: status,
    premiumPlan: plan,
    premiumEndsAt: endsAt ? Timestamp.fromDate(endsAt) : null,
    autoRenewEnabled: autoRenewEnabled,
    currentPayerUid: uid,
    updatedAt: FieldValue.serverTimestamp(),
  });

  // Guardar historial del cargo + intentar unlock en UNA sola transacción.
  // Esto previene la carrera en la que dos peticiones concurrentes con el
  // mismo chargeId leen "charge no existe" y ambas incrementan el slot.
  const chargeRef = firestore
    .collection("homes")
    .doc(homeId)
    .collection("subscriptions")
    .doc("history")
    .collection("charges")
    .doc(chargeId);

  // Importante: NO envolver en try/catch que trague el error. Si la transacción
  // falla debe propagarse al cliente — de lo contrario el cargo no queda
  // persistido, el slot no se desbloquea, y el cliente asume éxito, rompiendo
  // la idempotencia que este flujo debe garantizar.
  const unlocked = await firestore.runTransaction(async (tx) => {
    const chargeSnap = await tx.get(chargeRef);
    if (chargeSnap.exists) {
      return false; // ya procesado — idempotencia
    }

    const validForUnlock = status === "active";

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
      // Útil para auditar producción y detectar slots desbloqueados sin
      // verificación real.
      storeVerified,
      createdAt: FieldValue.serverTimestamp(),
    });

    if (!validForUnlock) {
      return false;
    }

    return await unlockSlotIfEligibleTx(tx, firestore, uid, chargeId);
  });

  if (unlocked) {
    logger.info("Slot unlocked", { uid, chargeId });
  } else {
    logger.debug("Slot not unlocked", { uid, chargeId, status });
  }

  // Actualizar premiumFlags en dashboard
  await updatePremiumFlagsInDashboard(firestore, homeId, status);

  return { success: true, premiumStatus: status };
});

async function updatePremiumFlagsInDashboard(
  firestore: admin.firestore.Firestore,
  homeId: string,
  premiumStatus: string,
): Promise<void> {
  const isPremium = ["active", "cancelled_pending_end", "rescue"].includes(premiumStatus);
  const dashRef = firestore
    .collection("homes")
    .doc(homeId)
    .collection("views")
    .doc("dashboard");
  await dashRef.set(
    {
      premiumFlags: {
        isPremium,
        showAds: !isPremium,
        canUseSmartDistribution: isPremium,
        canUseVacations: isPremium,
        canUseReviews: isPremium,
      },
      adFlags: {
        showBanner: !isPremium,
        bannerUnit: isPremium ? "" : DEFAULT_BANNER_UNIT_ID,
      },
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}
