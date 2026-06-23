// functions/src/jobs/restore_premium_state.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { buildBannerAdFlags } from "../shared/ad_constants";
import { chunked, MAX_BATCH_OPS } from "../shared/batch_utils";

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

  // Hallazgo #16: un hogar Premium grande puede tener cientos/miles de tareas
  // congeladas (Premium no tiene tope de tareas). Un único `batch` superaría el
  // límite DURO de 500 escrituras y reventaría en producción (el emulador NO lo
  // aplica → falso verde). Troceamos en lotes ≤MAX_BATCH_OPS las descongelaciones
  // de miembros y tareas, y dejamos el flip del hogar + dashboard para el FINAL:
  // si algo falla a mitad, el hogar sigue 'restorable' y reintentar es idempotente
  // (volver a descongelar lo ya activo es un no-op).
  const unfreezeData = { status: "active", frozenAt: FieldValue.delete() };
  const refs: admin.firestore.DocumentReference[] = [
    ...frozenMembersSnap.docs.map((d) => d.ref),
    ...frozenTasksSnap.docs.map((d) => d.ref),
  ];
  for (const group of chunked(refs, MAX_BATCH_OPS)) {
    const batch = db.batch();
    for (const ref of group) batch.update(ref, unfreezeData);
    await batch.commit();
  }

  const dashRef = db
    .collection("homes")
    .doc(homeId)
    .collection("views")
    .doc("dashboard");

  const finalBatch = db.batch();
  finalBatch.update(homeRef, {
    premiumStatus: "active",
    restoreUntil: FieldValue.delete(),
    "limits.maxMembers": 10,
    updatedAt: FieldValue.serverTimestamp(),
  });
  finalBatch.set(
    dashRef,
    {
      premiumFlags: {
        isPremium: true,
        showAds: false,
        canUseSmartDistribution: true,
        canUseVacations: true,
        canUseReviews: true,
      },
      adFlags: buildBannerAdFlags(false),
      rescueFlags: { isInRescue: false, daysLeft: null },
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  await finalBatch.commit();
  logger.info(
    `restorePremiumState: home ${homeId} restored by ${uid} ` +
      `(${frozenMembersSnap.size} members, ${frozenTasksSnap.size} tasks unfrozen)`
  );

  return { success: true };
});
