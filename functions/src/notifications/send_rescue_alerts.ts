// functions/src/notifications/send_rescue_alerts.ts
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

const db = admin.firestore();
const messaging = admin.messaging();

export async function sendRescueAlerts(homeId: string, daysLeft: number): Promise<void> {
  const membersSnap = await db
    .collection("homes").doc(homeId).collection("members")
    .where("status", "==", "active")
    .get();

  const homeSnap = await db.collection("homes").doc(homeId).get();
  const homeName: string = homeSnap.data()?.["name"] ?? "Hogar";

  const tokens: string[] = [];
  for (const mDoc of membersSnap.docs) {
    const mData = mDoc.data();
    const notifPrefs = mData["notificationPrefs"] as Record<string, unknown> | undefined;
    const token = notifPrefs?.["fcmToken"] as string | undefined;
    if (token) tokens.push(token);
  }

  if (!tokens.length) return;

  const results = await messaging.sendEachForMulticast({
    tokens,
    notification: {
      title: `🚨 ${homeName}: Rescate Premium`,
      body: `Tu suscripción vence en ${daysLeft} días. Renueva para conservar tus datos.`,
    },
    data: {
      type: "rescue_alert",
      homeId,
      daysLeft: String(daysLeft),
    },
  });

  logger.info(`sendRescueAlerts: sent to ${results.successCount}/${tokens.length} members of ${homeId}`);
}
