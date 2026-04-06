// functions/src/jobs/purge_expired_frozen.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";

/**
 * Cron diario a las 10:00 UTC.
 * Cambia hogares 'restorable' a 'purged' cuando restoreUntil <= now.
 */
export const purgeExpiredFrozen = onSchedule("0 10 * * *", async () => {
  const db = admin.firestore();
  const FieldValue = admin.firestore.FieldValue;
  const now = admin.firestore.Timestamp.now();

  const snapshot = await db
    .collection("homes")
    .where("premiumStatus", "==", "restorable")
    .where("restoreUntil", "<=", now)
    .get();

  logger.info(`purgeExpiredFrozen: ${snapshot.size} homes to purge`);

  const batch = db.batch();
  for (const doc of snapshot.docs) {
    batch.update(doc.ref, {
      premiumStatus: "purged",
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
  await batch.commit();
  logger.info("purgeExpiredFrozen: done");
});
