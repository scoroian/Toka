// functions/src/entitlement/sync_entitlement.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { unlockSlotIfEligible } from "./slot_ledger";

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

  // Guardar historial del cargo
  const chargeRef = firestore
    .collection("homes")
    .doc(homeId)
    .collection("subscriptions")
    .doc("history")
    .collection("charges")
    .doc(chargeId);
  const chargeSnap = await chargeRef.get();
  const validForUnlock = !chargeSnap.exists && status === "active";

  await chargeRef.set(
    {
      chargeId,
      uid,
      plan,
      platform,
      status,
      validForUnlock,
      createdAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  // Intentar desbloquear plaza permanente si es un cobro válido nuevo
  if (validForUnlock) {
    try {
      await unlockSlotIfEligible(firestore, uid, chargeId);
    } catch (err) {
      logger.error("Error unlocking slot", err);
    }
  }

  // Actualizar premiumFlags en dashboard
  await updatePremiumFlagsInDashboard(firestore, homeId, status);

  return { success: true, premiumStatus: status };
});

function parseReceiptData(receiptData: string): {
  status: string;
  plan: string;
  endsAt: Date | null;
  autoRenewEnabled: boolean;
} {
  try {
    const parsed = JSON.parse(receiptData) as {
      status?: string;
      plan?: string;
      endsAt?: string;
      autoRenewEnabled?: boolean;
    };
    return {
      status: parsed.status ?? "active",
      plan: parsed.plan ?? "monthly",
      endsAt: parsed.endsAt ? new Date(parsed.endsAt) : null,
      autoRenewEnabled: parsed.autoRenewEnabled ?? true,
    };
  } catch {
    throw new HttpsError("invalid-argument", "Invalid receipt data format");
  }
}

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
