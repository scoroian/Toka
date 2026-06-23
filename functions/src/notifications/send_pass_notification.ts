// functions/src/notifications/send_pass_notification.ts
import * as admin from "firebase-admin";
import {
  getUserFcmToken,
  clearFcmTokenIfMatches,
  isUnregisteredTokenError,
} from "./fcm_tokens";
import { logEvent, newCorrelationId } from "../shared/log";

const db = admin.firestore();
const messaging = admin.messaging();

export async function sendPassNotification(
  homeId: string,
  taskId: string,
  taskTitle: string,
  toUid: string,
  fromUid: string
): Promise<void> {
  // Solo notificamos a miembros del hogar.
  const memberRef = db.collection("homes").doc(homeId).collection("members").doc(toUid);
  const memberSnap = await memberRef.get();
  if (!memberSnap.exists) return;

  // El token FCM ya NO está en el doc de miembro (Hallazgo #01): se lee del doc
  // privado users/{uid}.
  const fcmToken = await getUserFcmToken(toUid);
  if (!fcmToken) return;

  const homeSnap = await db.collection("homes").doc(homeId).get();
  const homeName: string = homeSnap.data()?.["name"] ?? "Hogar";
  const correlationId = newCorrelationId();

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
    logEvent("info", "pass_notification_sent", {
      homeId,
      uid: toUid,
      correlationId,
      taskId,
    });
  } catch (err) {
    // No loguear el fcmToken (secreto). Identificamos por toUid + taskId.
    logEvent("warn", "pass_notification_failed", {
      homeId,
      uid: toUid,
      correlationId,
      taskId,
      errorCode: (err as { code?: string } | null)?.code ?? null,
    });
    // Hallazgo #17: purgar el token si el dispositivo ya no está registrado.
    if (isUnregisteredTokenError(err)) {
      const removed = await clearFcmTokenIfMatches(toUid, fcmToken);
      if (removed) {
        logEvent("info", "fcm_token_purged", {
          homeId,
          uid: toUid,
          correlationId,
          source: "sendPassNotification",
        });
      }
    }
  }
}
