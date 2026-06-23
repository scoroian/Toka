// functions/src/users/cleanup_user.ts
//
// Limpieza de datos cuando se elimina una cuenta de usuario. Se invoca desde:
//   - el trigger `auth.user().onDelete` (functions/src/users/index.ts), que
//     cubre el borrado por CUALQUIER vía (app, consola Firebase, Admin SDK).
//
// Problema que resuelve (QA 2026-06-16, §3): al borrar la cuenta de Firebase
// Auth, el documento homes/{homeId}/members/{uid} quedaba con status="active"
// (miembro "fantasma" con cuenta inexistente), users/{uid} seguía existiendo,
// las tareas asignadas al usuario quedaban con currentAssigneeUid huérfano y
// los contadores del dashboard (totalMembers/totalAdmins) quedaban inflados.
//
// Estrategia: marcar el miembro como "left" (conservando el documento como
// SNAPSHOT para que el historial/valoraciones de otros miembros sigan
// resolviendo nombre/foto), traspasar la propiedad si el borrado era el owner,
// liberar al pagador, reasignar las tareas, borrar users/{uid} y reconstruir el
// dashboard (que recuenta miembros y admins). Idempotente: re-ejecutarla sobre
// una cuenta ya limpiada es un no-op.

import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { updateHomeDashboard } from "../tasks/update_dashboard";
import { chunked, MAX_BATCH_OPS } from "../shared/batch_utils";
import {
  pickReplacementOwner,
  computeTaskReassignment,
  type MemberSnapshot,
} from "./cleanup_user_helpers";

// Re-export para consumidores que importan desde este módulo.
export {
  pickReplacementOwner,
  computeTaskReassignment,
  type MemberSnapshot,
} from "./cleanup_user_helpers";

// ---------------------------------------------------------------------------
// Limpieza con efectos (Firestore)
// ---------------------------------------------------------------------------

function db(): admin.firestore.Firestore {
  return admin.firestore();
}

/**
 * Resuelve el nombre del bucket de Storage por defecto.
 *
 * En el runtime de Functions desplegado, `FIREBASE_CONFIG` trae `storageBucket`
 * y `admin.storage().bucket()` ya funciona; pero `index.ts` hace
 * `initializeApp()` sin opciones y el harness de integración inicializa la app
 * solo con `projectId`, así que resolvemos el nombre explícitamente para que el
 * borrado de Storage funcione también contra el emulador.
 */
function defaultBucketName(): string | null {
  const cfg = process.env.FIREBASE_CONFIG;
  if (cfg) {
    try {
      const parsed = JSON.parse(cfg) as { storageBucket?: string };
      if (parsed.storageBucket) return parsed.storageBucket;
    } catch {
      // FIREBASE_CONFIG mal formado: caemos al resto de heurísticas.
    }
  }
  if (process.env.STORAGE_BUCKET) return process.env.STORAGE_BUCKET;
  const project = process.env.GCLOUD_PROJECT ?? process.env.GCP_PROJECT;
  return project ? `${project}.appspot.com` : null;
}

/**
 * Borra la foto de perfil del usuario en Cloud Storage (todo el prefijo
 * `users/{uid}/`, que cubre `profile.jpg` y cualquier otro objeto suyo).
 *
 * GDPR / derecho al olvido (Art. 17, Hallazgo #04): el `photoUrl` denormalizado
 * en los snapshots de miembro es una download URL tokenizada que SALTA las
 * Storage rules, por lo que limpiar Firestore no basta; hay que borrar el objeto
 * real. Borrarlo invalida la URL (pasa a 404) = revocación efectiva del token.
 * Best-effort: un fallo de Storage no aborta el resto de la limpieza.
 */
async function deleteUserStorage(uid: string): Promise<void> {
  try {
    const bucketName = defaultBucketName();
    const bucket = bucketName
      ? admin.storage().bucket(bucketName)
      : admin.storage().bucket();
    await bucket.deleteFiles({ prefix: `users/${uid}/` });
  } catch (err) {
    logger.error(
      `cleanupDeletedUser: borrado de Storage users/${uid}/ falló`,
      err
    );
  }
}

/**
 * Limpia la pertenencia del usuario en UN hogar:
 *  - marca su documento de miembro como "left" (snapshot conservado),
 *  - traspasa la propiedad si era el owner (o marca el hogar huérfano),
 *  - libera al pagador si era el currentPayerUid,
 *  - reasigna las tareas en las que participaba,
 *  - reconstruye el dashboard del hogar.
 */
async function cleanupUserInHome(uid: string, homeId: string): Promise<void> {
  const FieldValue = admin.firestore.FieldValue;
  const homeRef = db().collection("homes").doc(homeId);

  // --- Transacción: miembro + owner + payer (datos pequeños) ---
  await db().runTransaction(async (tx) => {
    const homeDoc = await tx.get(homeRef);
    const membersSnap = await tx.get(homeRef.collection("members"));

    const members: MemberSnapshot[] = membersSnap.docs.map((d) => {
      const m = d.data();
      return {
        uid: d.id,
        role: (m["role"] as string) ?? "member",
        status: (m["status"] as string) ?? "active",
        joinedAtMillis:
          (m["joinedAt"] as admin.firestore.Timestamp | undefined)?.toMillis() ??
          0,
      };
    });

    const now = FieldValue.serverTimestamp();
    const targetExists = membersSnap.docs.some((d) => d.id === uid);

    // a) Marcar el miembro como "left". Conservamos el documento (nickname y
    //    stats) como snapshot pseudonimizado para no romper el historial/las
    //    valoraciones de OTROS miembros, pero borramos la PII de contacto.
    //
    //    GDPR / derecho al olvido (Art. 17, Hallazgo #04): el snapshot es
    //    legible por todo el hogar, así que al borrar la cuenta hay que eliminar
    //    el teléfono y la foto del usuario. El `photoUrl` es una download URL
    //    tokenizada que SALTA las Storage rules (cualquier co-miembro con la URL
    //    veía la foto); ponerlo a null aquí + borrar el objeto de Storage
    //    (deleteUserStorage) cierra la fuga. El fcmToken ya se migró a
    //    users/{uid} en el #01; lo borramos por si quedan docs antiguos.
    if (targetExists) {
      tx.update(homeRef.collection("members").doc(uid), {
        status: "left",
        leftAt: now,
        accountDeleted: true,
        leftReason: "accountDeleted",
        phone: null,
        photoUrl: null,
        "notificationPrefs.fcmToken": FieldValue.delete(),
      });
    }

    if (!homeDoc.exists) return;
    const homeData = homeDoc.data()!;
    const homeUpdate: Record<string, unknown> = {};

    // b) Owner borrado → traspasar a un sustituto, o marcar el hogar huérfano.
    if (homeData["ownerUid"] === uid) {
      const replacement = pickReplacementOwner(members, uid);
      if (replacement) {
        homeUpdate["ownerUid"] = replacement;
        tx.update(homeRef.collection("members").doc(replacement), {
          role: "owner",
        });
        tx.set(
          db()
            .collection("users")
            .doc(replacement)
            .collection("memberships")
            .doc(homeId),
          { role: "owner" },
          { merge: true }
        );
      } else {
        // Nadie más en el hogar → queda huérfano. Lo marcamos "purged" (igual
        // que closeHome) para que los crons lo ignoren y no quede premium
        // colgando sin owner.
        homeUpdate["premiumStatus"] = "purged";
        homeUpdate["ownerUid"] = null;
      }
    }

    // c) Pagador borrado → liberar el payer y cortar la auto-renovación. El
    //    periodo Premium ya pagado se respeta (premiumEndsAt intacto); el cron
    //    de downgrade hará el resto al expirar.
    if (homeData["currentPayerUid"] === uid) {
      homeUpdate["currentPayerUid"] = null;
      homeUpdate["lastPayerUid"] = uid;
      homeUpdate["autoRenewEnabled"] = false;
    }

    if (Object.keys(homeUpdate).length > 0) {
      homeUpdate["updatedAt"] = now;
      tx.update(homeRef, homeUpdate);
    }
  });

  // --- Reasignar/limpiar tareas (fuera de la transacción, en batch) ---
  await reassignTasksFromDeletedUser(uid, homeId);

  // --- Reconstruir dashboard (recuenta miembros activos, admins y asignados) ---
  await updateHomeDashboard(homeId);
}

/**
 * Quita a un miembro AUSENTE (cuenta borrada, expulsado o que abandonó) de las
 * tareas activas del hogar: lo elimina de `assignmentOrder` y, si era el
 * responsable actual, reasigna al siguiente miembro elegible (o `null` si no
 * queda ninguno). Reutilizada por `leaveHome`/`removeMember` (Hallazgo #08)
 * además del borrado de cuenta, para que ninguna tarea quede "pegada" a un
 * ex-miembro (fantasma) ni este permanezca en la rotación.
 *
 * NO se emite ningún `taskEvent` de reasignación a propósito: el parser de
 * historial del cliente (`task_event.dart`) mapea cualquier `eventType`
 * desconocido a `completed`, así que un evento aquí aparecería como una tarea
 * "completada" fantasma en el historial de otros miembros. La reasignación
 * (currentAssigneeUid + assignmentOrder) es suficiente y no rompe esa UI.
 */
export async function reassignTasksFromDeletedUser(
  uid: string,
  homeId: string
): Promise<void> {
  const FieldValue = admin.firestore.FieldValue;
  const homeRef = db().collection("homes").doc(homeId);

  // Miembros no elegibles para recibir tareas: left/frozen/absent.
  const membersSnap = await homeRef.collection("members").get();
  const excludedUids: string[] = [];
  for (const d of membersSnap.docs) {
    const st = d.data()["status"] as string | undefined;
    if (st === "left" || st === "frozen" || st === "absent") {
      excludedUids.push(d.id);
    }
  }
  if (!excludedUids.includes(uid)) excludedUids.push(uid);

  const tasksSnap = await homeRef
    .collection("tasks")
    .where("status", "==", "active")
    .get();

  // Hallazgo #16: un hogar Premium grande puede tener >500 tareas asignadas al
  // ex-miembro. Un único `batch` reventaría el límite DURO de 500 escrituras EN
  // PRODUCCIÓN (el emulador NO lo aplica → falso verde). Troceamos en lotes
  // ≤MAX_BATCH_OPS. Cada update es independiente e idempotente.
  const updates: { ref: admin.firestore.DocumentReference; data: Record<string, unknown> }[] = [];
  for (const taskDoc of tasksSnap.docs) {
    const t = taskDoc.data();
    const order: string[] = (t["assignmentOrder"] as string[] | undefined) ?? [];
    const current = (t["currentAssigneeUid"] as string | null) ?? null;
    if (!order.includes(uid) && current !== uid) continue;

    const { newOrder, newAssignee } = computeTaskReassignment(
      order,
      current,
      uid,
      excludedUids
    );

    const update: Record<string, unknown> = {
      assignmentOrder: newOrder,
      updatedAt: FieldValue.serverTimestamp(),
    };
    if (current === uid) update["currentAssigneeUid"] = newAssignee;
    updates.push({ ref: taskDoc.ref, data: update });
  }

  for (const group of chunked(updates, MAX_BATCH_OPS)) {
    const batch = db().batch();
    for (const u of group) batch.update(u.ref, u.data);
    await batch.commit();
  }
}

/**
 * Punto de entrada: limpia TODA la huella del usuario tras borrar su cuenta.
 * Idempotente. Best-effort por hogar (un fallo en un hogar no aborta el resto).
 */
export async function cleanupDeletedUser(uid: string): Promise<void> {
  const userRef = db().collection("users").doc(uid);

  // 1. Hogares del usuario (vía sus memberships).
  const membershipsSnap = await userRef.collection("memberships").get();
  const homeIds = membershipsSnap.docs.map((d) => d.id);

  // 2. Limpiar cada hogar.
  for (const homeId of homeIds) {
    try {
      await cleanupUserInHome(uid, homeId);
    } catch (err) {
      logger.error(
        `cleanupDeletedUser: fallo limpiando home=${homeId} uid=${uid}`,
        err
      );
    }
  }

  // 3. Borrar la foto de perfil en Cloud Storage (Art. 17). Antes de borrar
  //    users/{uid}: el objeto vive en users/{uid}/profile.jpg y su download URL
  //    quedó copiada en snapshots de miembro (ya saneados arriba).
  await deleteUserStorage(uid);

  // 4. Borrar el documento de usuario y sus subcolecciones (memberships,
  //    rateLimits…). Las valoraciones/estadísticas viven bajo homes/ y se
  //    conservan como snapshot pseudonimizado (uid + nickname congelado).
  try {
    await db().recursiveDelete(userRef);
  } catch (err) {
    logger.error(`cleanupDeletedUser: recursiveDelete users/${uid} falló`, err);
  }

  logger.info(
    `cleanupDeletedUser: completado uid=${uid} homes=${homeIds.length}`
  );
}
