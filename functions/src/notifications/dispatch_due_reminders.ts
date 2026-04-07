// functions/src/notifications/dispatch_due_reminders.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onSchedule } from "firebase-functions/v2/scheduler";

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Job cada 15 minutos.
 * Busca tareas activas cuyo nextDueAt cae en los próximos 15 minutos
 * y envía notificaciones push a los responsables que tengan token FCM
 * y hayan activado notifyOnDue.
 */
export const dispatchDueReminders = onSchedule("*/15 * * * *", async () => {
  const now = new Date();
  const in15 = new Date(now.getTime() + 15 * 60 * 1000);

  const homesSnap = await db.collection("homes").get();
  let sent = 0;

  for (const homeDoc of homesSnap.docs) {
    const homeId = homeDoc.id;

    const tasksSnap = await db
      .collection("homes").doc(homeId).collection("tasks")
      .where("status", "==", "active")
      .where("nextDueAt", ">=", admin.firestore.Timestamp.fromDate(now))
      .where("nextDueAt", "<=", admin.firestore.Timestamp.fromDate(in15))
      .get();

    for (const taskDoc of tasksSnap.docs) {
      const task = taskDoc.data();
      const assigneeUid: string | null = task["currentAssigneeUid"] ?? null;
      if (!assigneeUid) continue;

      const memberRef = db.collection("homes").doc(homeId).collection("members").doc(assigneeUid);
      const memberSnap = await memberRef.get();
      if (!memberSnap.exists) continue;

      const memberData = memberSnap.data()!;
      const notifPrefs = memberData["notificationPrefs"] as Record<string, unknown> | undefined;
      const fcmToken = notifPrefs?.["fcmToken"] as string | undefined;
      const notifyOnDue = (notifPrefs?.["notifyOnDue"] as boolean | undefined) ?? true;

      if (!fcmToken || !notifyOnDue) continue;

      // Deduplicate per 15-min bucket: round minutes to 0, 15, 30, or 45
      const bucket = Math.floor(now.getMinutes() / 15) * 15;
      const notifKey = `${taskDoc.id}_${now.toISOString().slice(0, 11)}${String(now.getHours()).padStart(2, '0')}${String(bucket).padStart(2, '0')}`;
      const sentRef = db.collection("homes").doc(homeId)
        .collection("sentNotifications").doc(notifKey);
      const sentSnap = await sentRef.get();
      if (sentSnap.exists) continue;

      const homeName: string = homeDoc.data()["name"] ?? "Hogar";
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
        await sentRef.set({ sentAt: admin.firestore.FieldValue.serverTimestamp() });
        sent++;
      } catch (err) {
        logger.warn(`FCM send failed for token ${fcmToken}:`, err);
      }
    }
  }

  logger.info(`dispatchDueReminders: sent ${sent} notifications`);
});
