// functions/src/notifications/fcm_tokens.ts
import * as admin from "firebase-admin";

/**
 * Lectura del token FCM de un usuario.
 *
 * PRIVACIDAD (Hallazgo #01): el token vivía en
 * homes/{homeId}/members/{uid}.notificationPrefs.fcmToken, un documento legible
 * por TODO el hogar. El token FCM es un secreto que permite enviar push a ese
 * dispositivo, así que cualquier co-miembro podía leerlo. Ahora se guarda en el
 * doc privado users/{uid}.fcmToken (allow read: if isUser(uid)). Estos helpers
 * son la única fuente de verdad para leerlo desde el backend (Admin SDK, que
 * ignora las reglas).
 */
export async function getUserFcmToken(
  uid: string
): Promise<string | undefined> {
  const snap = await admin.firestore().collection("users").doc(uid).get();
  const token = snap.data()?.["fcmToken"];
  return typeof token === "string" && token.length > 0 ? token : undefined;
}

/**
 * Tokens FCM de varios usuarios, de-duplicados y sin huecos (los uid sin token
 * se omiten). Para envíos multicast (p. ej. alertas de rescate del hogar).
 */
export async function getUserFcmTokens(uids: string[]): Promise<string[]> {
  const tokens = await Promise.all(uids.map((u) => getUserFcmToken(u)));
  const present = tokens.filter((t): t is string => typeof t === "string");
  return [...new Set(present)];
}

export interface FcmTokenEntry {
  uid: string;
  token: string;
}

/**
 * Igual que getUserFcmTokens pero CONSERVA el uid de cada token (un entry por
 * usuario con token). Necesario para envíos multicast en los que, al recibir un
 * error de "token no registrado", hay que poder mapear la respuesta de vuelta al
 * usuario y borrar su token (Hallazgo #17). NO se dedupe entre usuarios: el caso
 * de dos usuarios con el mismo token es patológico y se maneja por uid.
 */
export async function getUserFcmTokenEntries(
  uids: string[]
): Promise<FcmTokenEntry[]> {
  const results = await Promise.all(
    uids.map(async (uid) => {
      const token = await getUserFcmToken(uid);
      return token ? { uid, token } : null;
    })
  );
  return results.filter((e): e is FcmTokenEntry => e !== null);
}

/**
 * Borra users/{uid}.fcmToken SOLO si sigue siendo `deadToken`. La condición
 * (dentro de una transacción) evita una carrera: si el usuario reinstaló y
 * registró un token NUEVO entre el envío fallido y la purga, no debemos borrar
 * el token bueno. Devuelve true si borró. Nunca recibe/loguea el token por log.
 */
export async function clearFcmTokenIfMatches(
  uid: string,
  deadToken: string
): Promise<boolean> {
  const ref = admin.firestore().collection("users").doc(uid);
  return admin.firestore().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists && snap.data()?.["fcmToken"] === deadToken) {
      tx.update(ref, { fcmToken: admin.firestore.FieldValue.delete() });
      return true;
    }
    return false;
  });
}

/**
 * Hallazgo #17: ¿este error de FCM significa que el token ya no sirve?
 *
 * `messaging/registration-token-not-registered` es el código canónico que
 * devuelve FCM cuando el dispositivo desinstaló la app o el token caducó. Es el
 * ÚNICO caso en el que debemos borrar el token: otros errores (server-unavailable,
 * internal-error, quota) son transitorios y borrar el token sería destructivo.
 * Defensivo: nunca lanza, devuelve false ante cualquier valor inesperado.
 */
export function isUnregisteredTokenError(err: unknown): boolean {
  if (!err || typeof err !== "object") return false;
  const code = (err as { code?: unknown }).code;
  return code === "messaging/registration-token-not-registered";
}
