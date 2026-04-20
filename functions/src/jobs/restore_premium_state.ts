// functions/src/jobs/restore_premium_state.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";

/**
 * Callable: restaura el estado Premium de un hogar si está dentro de la
 * ventana de restauración (premiumStatus == 'restorable').
 */
export const restorePremiumState = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }

  const uid = request.auth.uid;
  const { homeId } = request.data as { homeId: string };
  if (!homeId) throw new HttpsError("invalid-argument", "homeId is required");

  const db = admin.firestore();
  const FieldValue = admin.firestore.FieldValue;

  const homeRef = db.collection("homes").doc(homeId);
  const homeSnap = await homeRef.get();
  if (!homeSnap.exists) throw new HttpsError("not-found", "Home not found");

  const home = homeSnap.data() as Record<string, unknown>;
  if (home["ownerUid"] !== uid) {
    throw new HttpsError("permission-denied", "Only the owner can restore premium");
  }

  const premiumStatus = home["premiumStatus"] as string;
  if (premiumStatus === "purged") {
    throw new HttpsError("failed-precondition", "restore_window_expired");
  }
  if (premiumStatus !== "restorable") {
    throw new HttpsError(
      "failed-precondition",
      `Home is not in restorable state: ${premiumStatus}`
    );
  }

  const frozenMembersSnap = await db
    .collection("homes")
    .doc(homeId)
    .collection("members")
    .where("status", "==", "frozen")
    .get();

  const frozenTasksSnap = await db
    .collection("homes")
    .doc(homeId)
    .collection("tasks")
    .where("status", "==", "frozen")
    .get();

  const batch = db.batch();

  for (const memberDoc of frozenMembersSnap.docs) {
    batch.update(memberDoc.ref, {
      status: "active",
      frozenAt: FieldValue.delete(),
    });
  }

  for (const taskDoc of frozenTasksSnap.docs) {
    batch.update(taskDoc.ref, {
      status: "active",
      frozenAt: FieldValue.delete(),
    });
  }

  batch.update(homeRef, {
    premiumStatus: "active",
    restoreUntil: FieldValue.delete(),
    "limits.maxMembers": 10,
    updatedAt: FieldValue.serverTimestamp(),
  });

  const dashRef = db
    .collection("homes")
    .doc(homeId)
    .collection("views")
    .doc("dashboard");

  batch.set(
    dashRef,
    {
      premiumFlags: {
        isPremium: true,
        showAds: false,
        canUseSmartDistribution: true,
        canUseVacations: true,
        canUseReviews: true,
      },
      adFlags: {
        showBanner: false,
        bannerUnit: "",
      },
      rescueFlags: { isInRescue: false, daysLeft: null },
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );

  await batch.commit();
  logger.info(`restorePremiumState: home ${homeId} restored by ${uid}`);

  return { success: true };
});
