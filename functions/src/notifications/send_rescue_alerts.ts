// functions/src/notifications/send_rescue_alerts.ts
import * as admin from "firebase-admin";
import {
  getUserFcmTokenEntries,
  clearFcmTokenIfMatches,
  isUnregisteredTokenError,
} from "./fcm_tokens";
import { logEvent, newCorrelationId } from "../shared/log";

const db = admin.firestore();
const messaging = admin.messaging();

export async function sendRescueAlerts(homeId: string, daysLeft: number): Promise<void> {
  const correlationId = newCorrelationId();

  const membersSnap = await db
    .collection("homes").doc(homeId).collection("members")
    .where("status", "==", "active")
    .get();

  const homeSnap = await db.collection("homes").doc(homeId).get();
  const homeName: string = homeSnap.data()?.["name"] ?? "Hogar";

  // Los tokens FCM ya NO están en los docs de miembro (Hallazgo #01): se leen de
  // los docs privados users/{uid}. Conservamos el uid por token para poder
  // purgar los muertos (Hallazgo #17).
  const entries = await getUserFcmTokenEntries(membersSnap.docs.map((d) => d.id));

  if (!entries.length) return;

  const tokens = entries.map((e) => e.token);
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

  // Hallazgo #17: inspeccionar responses[] y purgar los tokens muertos. Cada
  // respuesta corresponde por índice al token (y por tanto al uid) enviado. NO
  // se loguea el token (secreto): identificamos la purga por uid.
  let purged = 0;
  await Promise.all(
    results.responses.map(async (resp, i) => {
      if (resp.success) return;
      if (!isUnregisteredTokenError(resp.error)) return;
      const { uid, token } = entries[i];
      const removed = await clearFcmTokenIfMatches(uid, token);
      if (removed) {
        purged++;
        logEvent("info", "fcm_token_purged", {
          homeId,
          uid,
          correlationId,
          source: "sendRescueAlerts",
        });
      }
    })
  );

  logEvent("info", "rescue_alerts_sent", {
    homeId,
    correlationId,
    sent: results.successCount,
    total: tokens.length,
    purged,
  });
}
