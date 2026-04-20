// functions/src/entitlement/sync_entitlement.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { unlockSlotIfEligibleTx } from "./slot_ledger";
import { parseReceiptData } from "./sync_entitlement_helpers";

const db = () => admin.firestore();

export const syncEntitlement = onCall(async (request) => {
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

  // Parsear el recibo (en producción: llamar a Apple/Google para validar server-side)
  const { status, plan, endsAt, autoRenewEnabled } = parseReceiptData(receiptData);

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
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}
