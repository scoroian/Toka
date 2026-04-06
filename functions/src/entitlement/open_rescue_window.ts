// functions/src/entitlement/open_rescue_window.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";

/**
 * Job diario a las 09:00 UTC.
 * Cambia a 'rescue' los hogares cuyo premiumEndsAt <= 3 días desde ahora
 * y que aún no están en rescue.
 */
export const openRescueWindow = onSchedule("0 9 * * *", async () => {
  const db = admin.firestore();
  const FieldValue = admin.firestore.FieldValue;
  const threeDaysFromNow = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);

  const snapshot = await db
    .collection("homes")
    .where("premiumStatus", "==", "cancelled_pending_end")
    .where("premiumEndsAt", "<=", admin.firestore.Timestamp.fromDate(threeDaysFromNow))
    .get();

  logger.info(`openRescueWindow: ${snapshot.size} homes to update`);

  const batch = db.batch();
  for (const doc of snapshot.docs) {
    const data = doc.data();
    const rescueFlags = data["rescueFlags"] as { isInRescue?: boolean } | undefined;
    if (rescueFlags?.isInRescue) continue;

    const endsAt = (data["premiumEndsAt"] as admin.firestore.Timestamp | undefined)?.toDate();
    const daysLeft = endsAt
      ? Math.max(0, Math.ceil((endsAt.getTime() - Date.now()) / (1000 * 60 * 60 * 24)))
      : 0;

    batch.update(doc.ref, {
      premiumStatus: "rescue",
      updatedAt: FieldValue.serverTimestamp(),
    });

    const dashRef = db.collection("homes").doc(doc.id).collection("views").doc("dashboard");
    batch.set(
      dashRef,
      {
        rescueFlags: { isInRescue: true, daysLeft },
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  }

  await batch.commit();
  logger.info("openRescueWindow: batch committed");
});
