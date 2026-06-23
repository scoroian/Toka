// functions/src/notifications/dispatch_due_reminders.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";
import {
  getUserFcmToken,
  clearFcmTokenIfMatches,
  isUnregisteredTokenError,
} from "./fcm_tokens";
import { logEvent, newCorrelationId } from "../shared/log";

const db = admin.firestore();
const messaging = admin.messaging();

// Hallazgo #17: los docs de homes/{id}/sentNotifications solo sirven para
// deduplicar envíos dentro de su bucket de 15 min; pasados un par de días son
// basura. Les ponemos un `expireAt` para TTL nativo + purga por cron.
export const SENT_NOTIFICATION_TTL_MS = 2 * 24 * 60 * 60 * 1000; // 2 días

/**
 * Job cada 15 minutos.
 * Busca tareas activas cuyo nextDueAt cae en los próximos 15 minutos
 * y envía notificaciones push a los responsables que tengan token FCM
 * y hayan activado notifyOnDue.
 *
 * Hallazgo #15 (coste lineal): en vez de barrer TODOS los hogares
 * (`db.collection("homes").get()` + una query de tareas por hogar, coste
 * O(N) en reads aunque ningún hogar tenga tareas que vencen), usamos un único
 * `collectionGroup("tasks")` filtrado por la ventana. Así el coste depende del
 * nº de tareas que vencen (actividad) y NO del nº total de hogares. El homeId
 * se resuelve desde la ruta del doc (`task.ref.parent.parent`).
 *
 * Requiere el índice COLLECTION_GROUP `tasks(status ASC, nextDueAt ASC)`
 * declarado en `firestore.indexes.json`. El emulador NO exige ese índice, así
 * que envolvemos la query en try/catch para no quedar en bucle de crash si el
 * índice faltara en prod (ver memoria collectiongroup-index-prod-only).
 */
export const dispatchDueReminders = onSchedule("*/15 * * * *", async () => {
  const correlationId = newCorrelationId();
  const now = admin.firestore.Timestamp.now().toDate();
  const in15 = new Date(now.getTime() + 15 * 60 * 1000);

  let tasksSnap: admin.firestore.QuerySnapshot;
  try {
    tasksSnap = await db
      .collectionGroup("tasks")
      .where("status", "==", "active")
      .where("nextDueAt", ">=", admin.firestore.Timestamp.fromDate(now))
      .where("nextDueAt", "<=", admin.firestore.Timestamp.fromDate(in15))
      .get();
  } catch (err) {
    logger.error(
      "dispatchDueReminders: collectionGroup query failed " +
        "(¿falta el índice COLLECTION_GROUP tasks(status, nextDueAt) en prod?)",
      err
    );
    return;
  }

  // Cache de nombres de hogar: leemos cada home doc como mucho una vez, y sólo
  // los hogares que tienen alguna tarea venciendo (no todos).
  const homeNameCache = new Map<string, string>();
  let sent = 0;

  for (const taskDoc of tasksSnap.docs) {
    const homeRef = taskDoc.ref.parent.parent; // homes/{homeId}
    if (!homeRef) continue;
    const homeId = homeRef.id;
    const task = taskDoc.data();

    const assigneeUid: string | null = task["currentAssigneeUid"] ?? null;
    if (!assigneeUid) continue;

    const memberRef = db.collection("homes").doc(homeId).collection("members").doc(assigneeUid);
    const memberSnap = await memberRef.get();
    if (!memberSnap.exists) continue;

    const memberData = memberSnap.data()!;
    const notifPrefs = memberData["notificationPrefs"] as Record<string, unknown> | undefined;
    const notifyOnDue = (notifPrefs?.["notifyOnDue"] as boolean | undefined) ?? true;
    if (!notifyOnDue) continue;

    // El token FCM ya NO está en el doc de miembro (Hallazgo #01): se lee del
    // doc privado users/{uid}.
    const fcmToken = await getUserFcmToken(assigneeUid);
    if (!fcmToken) continue;

    // Deduplicate per 15-min bucket: round minutes to 0, 15, 30, or 45
    const bucket = Math.floor(now.getMinutes() / 15) * 15;
    const notifKey = `${taskDoc.id}_${now.toISOString().slice(0, 11)}${String(now.getHours()).padStart(2, '0')}${String(bucket).padStart(2, '0')}`;
    const sentRef = db.collection("homes").doc(homeId)
      .collection("sentNotifications").doc(notifKey);
    const sentSnap = await sentRef.get();
    if (sentSnap.exists) continue;

    let homeName = homeNameCache.get(homeId);
    if (homeName === undefined) {
      const homeDoc = await homeRef.get();
      homeName = (homeDoc.data()?.["name"] as string | undefined) ?? "Hogar";
      homeNameCache.set(homeId, homeName);
    }
    const taskTitle: string = task["title"] ?? "Tarea";

    try {
      await messaging.send({
        token: fcmToken,
        notification: {
          title: `⏰ ${taskTitle}`,
          body: `Tu turno en ${homeName} vence pronto.`,
        },
        data: {
          type: "task_due",
          homeId,
          taskId: taskDoc.id,
        },
      });
      // Hallazgo #17: TTL de sentNotifications. Escribimos `expireAt` (sentAt +
      // 2 días) para que una política TTL nativa de Firestore pueda auto-borrar
      // estos docs de deduplicación, y para que la purga del cron los localice.
      const expireAt = admin.firestore.Timestamp.fromMillis(
        now.getTime() + SENT_NOTIFICATION_TTL_MS
      );
      await sentRef.set({
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        expireAt,
      });
      sent++;
    } catch (err) {
      // No loguear el fcmToken: es un secreto que permite enviar push a ese
      // dispositivo. Identificamos el envío por assigneeUid + taskId.
      logEvent("warn", "fcm_send_failed", {
        homeId,
        uid: assigneeUid,
        correlationId,
        taskId: taskDoc.id,
        errorCode: (err as { code?: string } | null)?.code ?? null,
      });
      // Hallazgo #17: si el token está muerto (dispositivo desinstalado / token
      // caducado) lo purgamos para no reintentar en silencio cada 15 minutos.
      if (isUnregisteredTokenError(err)) {
        const removed = await clearFcmTokenIfMatches(assigneeUid, fcmToken);
        if (removed) {
          logEvent("info", "fcm_token_purged", {
            homeId,
            uid: assigneeUid,
            correlationId,
            source: "dispatchDueReminders",
          });
        }
      }
    }
  }

  logEvent("info", "due_reminders_sent", { correlationId, sent });
});
