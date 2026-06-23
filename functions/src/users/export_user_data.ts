// functions/src/users/export_user_data.ts
//
// Exportación de datos personales del usuario (GDPR Art. 15 derecho de acceso /
// Art. 20 portabilidad, Hallazgo #04). Callable que devuelve un JSON con los
// datos personales del PROPIO usuario autenticado. No escribe nada (solo lee).
//
// Alcance (decisión "Perfil + actividad propia"):
//   - profile        → users/{uid} completo (incl. phone/locale/fcmToken: es el
//                      propio sujeto, tiene derecho a recibirlos)
//   - memberships    → users/{uid}/memberships/*
//   - slotLedger     → users/{uid}/slotLedger/*
//   - homes[]        → por cada membership: nombre del hogar + su propio doc de
//                      miembro (rol/estado/estadísticas)
//   - reviewsAuthored→ reseñas que ESCRIBIÓ el usuario (notas privadas suyas)
//
// Las reseñas RECIBIDAS (notas que otros escribieron sobre él) quedan fuera de
// este alcance por decisión de producto; son fáciles de añadir (mismo
// collectionGroup con where('performerUid','==',uid)) si se amplía el alcance.

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { onCall, HttpsError } from "firebase-functions/v2/https";

function db(): admin.firestore.Firestore {
  return admin.firestore();
}

/**
 * Convierte recursivamente un valor de Firestore a algo JSON-serializable
 * limpio: los Timestamp pasan a ISO-8601 y los GeoPoint a {lat,lng}. Sin esto,
 * el protocolo callable serializaría los Timestamp como {_seconds,_nanoseconds}.
 */
export function toJsonSafe(value: unknown): unknown {
  if (value === null || value === undefined) return null;
  if (value instanceof admin.firestore.Timestamp) {
    return value.toDate().toISOString();
  }
  if (value instanceof admin.firestore.GeoPoint) {
    return { latitude: value.latitude, longitude: value.longitude };
  }
  if (Array.isArray(value)) return value.map(toJsonSafe);
  if (typeof value === "object") {
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(value as Record<string, unknown>)) {
      out[k] = toJsonSafe(v);
    }
    return out;
  }
  return value;
}

export const exportUserData = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Not authenticated");
  }
  const uid = request.auth.uid;
  const firestore = db();

  // Perfil + subcolecciones propias del usuario.
  const [userSnap, membershipsSnap, slotLedgerSnap] = await Promise.all([
    firestore.collection("users").doc(uid).get(),
    firestore.collection("users").doc(uid).collection("memberships").get(),
    firestore.collection("users").doc(uid).collection("slotLedger").get(),
  ]);

  const memberships = membershipsSnap.docs.map((d) => ({
    homeId: d.id,
    ...d.data(),
  }));
  const slotLedger = slotLedgerSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

  // Por cada hogar: nombre + su propio doc de miembro (rol/estado/estadísticas).
  const homes = await Promise.all(
    membershipsSnap.docs.map(async (m) => {
      const homeId = m.id;
      const [homeSnap, memberSnap] = await Promise.all([
        firestore.collection("homes").doc(homeId).get(),
        firestore
          .collection("homes")
          .doc(homeId)
          .collection("members")
          .doc(uid)
          .get(),
      ]);
      return {
        homeId,
        homeName: (homeSnap.data()?.["name"] as string | undefined) ?? null,
        member: memberSnap.exists ? memberSnap.data() : null,
      };
    })
  );

  // Reseñas que ESCRIBIÓ el usuario. collectionGroup sobre 'reviews' filtrando
  // por reviewerUid (el campo real que escribe submit_review.ts; el data-model
  // dice 'byUid' pero manda el código). Requiere un índice de campo único con
  // scope COLLECTION_GROUP (declarado en firestore.indexes.json). Lo envolvemos
  // en try/catch: si el índice aún se está construyendo o falla por cualquier
  // motivo, el resto del export (perfil, hogares…) NO debe caerse — Art. 15 se
  // sirve igual y marcamos el sub-bloque como no disponible.
  let reviewsAuthored: Array<Record<string, unknown>> = [];
  let reviewsAuthoredError: string | null = null;
  try {
    const reviewsSnap = await firestore
      .collectionGroup("reviews")
      .where("reviewerUid", "==", uid)
      .get();
    reviewsAuthored = reviewsSnap.docs.map((d) => ({
      path: d.ref.path,
      ...d.data(),
    }));
  } catch (err) {
    reviewsAuthoredError = "unavailable";
    logger.warn(`exportUserData: reviews query falló uid=${uid}`, err);
  }

  logger.info(
    `exportUserData: uid=${uid} homes=${homes.length} reviews=${reviewsAuthored.length}`
  );

  return toJsonSafe({
    schemaVersion: 1,
    exportedAt: new Date().toISOString(),
    uid,
    profile: userSnap.exists ? userSnap.data() : null,
    memberships,
    slotLedger,
    homes,
    reviewsAuthored,
    reviewsAuthoredError,
  });
});
