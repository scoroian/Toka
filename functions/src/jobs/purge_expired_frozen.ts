// functions/src/jobs/purge_expired_frozen.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { chunked, MAX_BATCH_OPS } from "../shared/batch_utils";
import { logEvent, newCorrelationId } from "../shared/log";

/** Hallazgo #17: TTL efectivo de los docs de deduplicación de notificaciones. */
const SENT_NOTIFICATION_TTL_MS = 2 * 24 * 60 * 60 * 1000; // 2 días

/**
 * Borra los docs antiguos de homes/{id}/sentNotifications (anteriores al TTL).
 * Son solo marcas de deduplicación de envíos por bucket de 15 min; pasados un
 * par de días son basura que crecería sin límite (Hallazgo #17).
 *
 * Usa un único `collectionGroup` filtrado por `sentAt` (NO barre todos los
 * hogares): captura tanto los docs nuevos (que además llevan `expireAt`) como
 * los legacy sin `expireAt`. Requiere el índice COLLECTION_GROUP
 * `sentNotifications(sentAt)` declarado en firestore.indexes.json; el emulador
 * NO lo exige, así que envolvemos la query en try/catch para no quedar en bucle
 * de crash si faltara en prod (ver memoria collectiongroup-index-prod-only).
 *
 * Los borrados se trocean en lotes <= MAX_BATCH_OPS (el emulador no aplica el
 * tope de 500/batch, pero prod sí — ver memoria emulator-no-batch-500-limit).
 */
export async function purgeExpiredSentNotifications(
  db: admin.firestore.Firestore,
  correlationId: string
): Promise<number> {
  const cutoff = admin.firestore.Timestamp.fromMillis(
    Date.now() - SENT_NOTIFICATION_TTL_MS
  );

  let snap: admin.firestore.QuerySnapshot;
  try {
    snap = await db
      .collectionGroup("sentNotifications")
      .where("sentAt", "<=", cutoff)
      .get();
  } catch (err) {
    logEvent("error", "sent_notifications_purge_query_failed", {
      correlationId,
      hint: "¿falta el índice COLLECTION_GROUP sentNotifications(sentAt) en prod?",
      errorCode: (err as { code?: string } | null)?.code ?? null,
    });
    return 0;
  }

  if (snap.empty) return 0;

  for (const group of chunked(snap.docs, MAX_BATCH_OPS)) {
    const batch = db.batch();
    for (const doc of group) batch.delete(doc.ref);
    await batch.commit();
  }

  logEvent("info", "sent_notifications_purged", {
    correlationId,
    deleted: snap.size,
  });
  return snap.size;
}

/**
 * Cron diario a las 10:00 UTC.
 * (1) Cambia hogares 'restorable' a 'purged' cuando restoreUntil <= now.
 * (2) Hallazgo #17: purga los docs antiguos de sentNotifications (TTL 2 días).
 */
export const purgeExpiredFrozen = onSchedule("0 10 * * *", async () => {
  const db = admin.firestore();
  const FieldValue = admin.firestore.FieldValue;
  const now = admin.firestore.Timestamp.now();
  const correlationId = newCorrelationId();

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

  // (2) Purga de sentNotifications caducados. Aislada en su propio try/catch
  // (vía la función helper) para que un fallo aquí no afecte a la purga de
  // hogares ya commiteada.
  await purgeExpiredSentNotifications(db, correlationId);

  logger.info("purgeExpiredFrozen: done");
});
