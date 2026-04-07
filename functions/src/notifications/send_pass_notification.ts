// functions/src/notifications/send_pass_notification.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();
const messaging = admin.messaging();

export async function sendPassNotification(
  homeId: string,
  taskId: string,
  taskTitle: string,
  toUid: string,
  fromUid: string
): Promise<void> {
  const memberRef = db.collection("homes").doc(homeId).collection("members").doc(toUid);
  const memberSnap = await memberRef.get();
  if (!memberSnap.exists) return;

  const memberData = memberSnap.data()!;
  const notifPrefs = memberData["notificationPrefs"] as Record<string, unknown> | undefined;
  const fcmToken = notifPrefs?.["fcmToken"] as string | undefined;
  if (!fcmToken) return;

  const homeSnap = await db.collection("homes").doc(homeId).get();
  const homeName: string = homeSnap.data()?.["name"] ?? "Hogar";

  try {
    await messaging.send({
      token: fcmToken,
      notification: {
        title: `🔁 Turno recibido: ${taskTitle}`,
        body: `Ahora es tu turno en ${homeName}.`,
      },
      data: {
        type: "task_passed_to_you",
        homeId,
        taskId,
        fromUid,
      },
    });
    logger.info(`sendPassNotification: sent to ${toUid} for task ${taskId}`);
  } catch (err) {
    logger.warn(`sendPassNotification failed for token ${fcmToken}:`, err);
  }
}
