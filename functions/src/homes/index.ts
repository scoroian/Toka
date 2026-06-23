import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { randomInt } from "crypto";
import {
  buildNewMemberDoc,
  readMemberProfileFields,
  sanitizeMemberPhone,
} from "./member_factory";
import {
  FREE_LIMITS,
  FREE_LIMIT_CODES,
  PREMIUM_LIMITS,
  isPremium,
} from "../shared/free_limits";
import { buildBannerAdFlags } from "../shared/ad_constants";
import { normalizeTimeZone } from "../tasks/today_window";
import { reassignTasksFromDeletedUser } from "../users/cleanup_user";
import { updateHomeDashboard } from "../tasks/update_dashboard";

const db = admin.firestore();
const FieldValue = admin.firestore.FieldValue;

// ---------------------------------------------------------------------------
// createHome
// Input:  { name: string, emoji?: string }
// Output: { homeId: string }
// ---------------------------------------------------------------------------
export const createHome = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  const uid = request.auth.uid;
  const data = request.data as { name?: string; emoji?: string; timezone?: string };
  const name = data.name?.trim();

  if (!name) {
    throw new HttpsError("invalid-argument", "Home name is required");
  }
  // Validación de longitud: evita documentos abusivos / overflow en UI.
  if (name.length > 60) {
    throw new HttpsError("invalid-argument", "Home name too long (max 60 chars)");
  }
  if (data.emoji && data.emoji.length > 8) {
    throw new HttpsError("invalid-argument", "Emoji too long");
  }

  // Check available slots
  const userDoc = await db.collection("users").doc(uid).get();
  const userData = userDoc.exists ? userDoc.data()! : {};
  // Leer los campos CANÓNICOS de plazas. slot_ledger escribe
  // baseHomeSlots/lifetimeUnlockedHomeSlots/homeSlotCap y BORRA los legacy
  // baseSlots/lifetimeUnlocked. Si solo leyéramos los legacy (como antes),
  // tras comprar una plaza extra createHome vería siempre 2 y nunca dejaría
  // crear los hogares pagados. Mantenemos fallback a legacy para datos viejos.
  const baseSlots =
    (userData["baseHomeSlots"] as number) ??
    (userData["baseSlots"] as number) ??
    2;
  const lifetimeUnlocked =
    (userData["lifetimeUnlockedHomeSlots"] as number) ??
    (userData["lifetimeUnlocked"] as number) ??
    0;
  const totalSlots =
    (userData["homeSlotCap"] as number) ?? baseSlots + lifetimeUnlocked;

  const membershipsSnap = await db
    .collection("users")
    .doc(uid)
    .collection("memberships")
    .where("status", "==", "active")
    .get();

  if (membershipsSnap.size >= totalSlots) {
    throw new HttpsError("resource-exhausted", "No available home slots");
  }

  const homeRef = db.collection("homes").doc();
  const now = FieldValue.serverTimestamp();

  const homeData: Record<string, unknown> = {
    name,
    ownerUid: uid,
    currentPayerUid: null,
    lastPayerUid: null,
    premiumStatus: "free",
    premiumPlan: null,
    premiumEndsAt: null,
    restoreUntil: null,
    autoRenewEnabled: false,
    limits: { maxMembers: 5 },
    // Zona horaria del hogar: define qué cuenta como "hoy" en el dashboard.
    // El cliente puede enviarla; si no, o si es inválida, cae a Europe/Madrid.
    timezone: normalizeTimeZone(data.timezone),
    createdAt: now,
    updatedAt: now,
  };
  if (data.emoji) homeData["emoji"] = data.emoji;

  const membershipData = {
    homeNameSnapshot: name,
    // El hogar recién creado todavía no tiene foto; el avatar se sube después
    // y el trigger `syncHomeSnapshotToMemberships` propaga el cambio.
    homePhotoSnapshot: null,
    role: "owner",
    billingState: "none",
    status: "active",
    joinedAt: now,
    leftAt: null,
  };

  // Fetch user display name for the member document
  const userSnap = await db.collection("users").doc(uid).get();
  const userData2 = userSnap.exists ? userSnap.data()! : {};
  const { nickname, photoUrl, phone, phoneVisibility } =
    readMemberProfileFields(userData2);

  const memberData = buildNewMemberDoc({
    uid,
    nickname,
    role: "owner",
    photoUrl,
    phone,
    phoneVisibility,
  });

  const batch = db.batch();
  batch.set(homeRef, homeData);
  batch.set(
    db.collection("users").doc(uid).collection("memberships").doc(homeRef.id),
    membershipData
  );
  // Crear documento de miembro en la subcolección del hogar
  batch.set(
    homeRef.collection("members").doc(uid),
    memberData
  );
  // Inicializar documento dashboard vacío para que Flutter no entre en modo fallback
  batch.set(
    homeRef.collection("views").doc("dashboard"),
    {
      activeTasksPreview: [],
      doneTasksPreview: [],
      counters: {
        totalActiveTasks: 0,
        totalMembers: 1,
        tasksDueToday: 0,
        tasksDoneToday: 0,
      },
      memberPreview: [{
        uid,
        name: nickname,
        photoUrl,
        role: "owner",
        status: "active",
        tasksDueCount: 0,
      }],
      planCounters: {
        activeMembers: 1,
        activeTasks: 0,
        automaticRecurringTasks: 0,
        totalAdmins: 1, // el owner cuenta como admin-equivalente
      },
      premiumFlags: {
        isPremium: false,
        showAds: true,
        canUseSmartDistribution: false,
        canUseVacations: false,
        canUseReviews: false,
      },
      adFlags: buildBannerAdFlags(true),
      rescueFlags: {
        isInRescue: false,
        daysLeft: null,
      },
      updatedAt: now,
    }
  );
  await batch.commit();

  logger.info(`Home created: ${homeRef.id} by ${uid}`);
  return { homeId: homeRef.id };
});

// ---------------------------------------------------------------------------
// joinHome
// Called from onboarding after finding invitation in Firestore client-side.
// Input:  { homeId: string, invitationId: string }
// ---------------------------------------------------------------------------
export const joinHome = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  const uid = request.auth.uid;
  const data = request.data as { homeId?: string; invitationId?: string };
  const { homeId, invitationId } = data;

  if (!homeId || !invitationId) {
    throw new HttpsError("invalid-argument", "homeId and invitationId required");
  }

  const homeRef = db.collection("homes").doc(homeId);
  const invRef = homeRef.collection("invitations").doc(invitationId);
  const userRef = db.collection("users").doc(uid);
  const memberRef = homeRef.collection("members").doc(uid);

  await db.runTransaction(async (tx) => {
    const [invDoc, homeDoc, userDoc, existingMember] = await Promise.all([
      tx.get(invRef),
      tx.get(homeRef),
      tx.get(userRef),
      tx.get(memberRef),
    ]);

    if (!invDoc.exists) {
      throw new HttpsError("not-found", "Invitation not found");
    }
    if (!homeDoc.exists) {
      throw new HttpsError("not-found", "Home not found");
    }

    const invData = invDoc.data()!;
    if (invData["used"] === true) {
      throw new HttpsError("deadline-exceeded", "Invitation already used");
    }

    const expiresAt = (invData["expiresAt"] as admin.firestore.Timestamp | undefined)?.toDate();
    if (expiresAt && admin.firestore.Timestamp.now().toDate() > expiresAt) {
      throw new HttpsError("deadline-exceeded", "Invitation expired");
    }

    // Free-plan gate: max N active members per home. Solo contamos como nuevo
    // si no existe doc previo o si estaba en estado distinto a "active"
    // (rejoin). El owner siempre cuenta en el total.
    const homeDataTx = homeDoc.data()!;
    const isAlreadyActiveMember = existingMember.exists &&
      existingMember.data()?.["status"] === "active";
    if (!isPremium(homeDataTx["premiumStatus"] as string | undefined) &&
        !isAlreadyActiveMember) {
      const activeMembersSnap = await tx.get(
        homeRef.collection("members").where("status", "==", "active")
      );
      if (activeMembersSnap.size >= FREE_LIMITS.maxActiveMembers) {
        throw new HttpsError("failed-precondition", FREE_LIMIT_CODES.members);
      }
    }

    const homeName = homeDataTx["name"] as string;
    const profile = readMemberProfileFields(userDoc.data());
    const now = FieldValue.serverTimestamp();

    // Rejoin: preservar rol previo (admin/member) si el doc ya existía.
    const preservedRole =
      (existingMember.data()?.["role"] as string | undefined) ?? "member";

    tx.update(invRef, { used: true, usedAt: now, usedBy: uid });
    tx.set(
      db.collection("users").doc(uid).collection("memberships").doc(homeId),
      {
        homeNameSnapshot: homeName,
        homePhotoSnapshot: (homeDataTx["photoUrl"] as string | undefined) ?? null,
        role: preservedRole,
        billingState: "none",
        status: "active",
        joinedAt: now,
        leftAt: null,
      }
    );
    if (existingMember.exists) {
      tx.update(memberRef, {
        nickname: profile.nickname,
        photoUrl: profile.photoUrl,
        phone: sanitizeMemberPhone(profile.phone, profile.phoneVisibility),
        phoneVisibility: profile.phoneVisibility,
        status: "active",
        rejoinedAt: now,
      });
    } else {
      tx.set(
        memberRef,
        buildNewMemberDoc({
          uid,
          nickname: profile.nickname,
          role: "member",
          photoUrl: profile.photoUrl,
          phone: profile.phone,
          phoneVisibility: profile.phoneVisibility,
        })
      );
    }
  });
});

// ---------------------------------------------------------------------------
// joinHomeByCode
// Called from HomeSettingsScreen invite flow.
// Input:  { code: string }
// ---------------------------------------------------------------------------
export const joinHomeByCode = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  const uid = request.auth.uid;
  const data = request.data as { code?: string };
  const code = data.code?.trim().toUpperCase();

  if (!code) {
    throw new HttpsError("invalid-argument", "code is required");
  }

  // Rate-limiting: defensa contra fuerza bruta de códigos de invitación.
  // Máx JOIN_MAX_ATTEMPTS intentos por usuario en una ventana de JOIN_WINDOW_MS.
  // El código es un secreto de 6 chars consultable por collectionGroup, así que
  // sin esto un usuario autenticado podría enumerar códigos activos ajenos.
  const JOIN_WINDOW_MS = 60 * 60 * 1000; // 1 hora
  const JOIN_MAX_ATTEMPTS = 10;
  const rlRef = db
    .collection("users").doc(uid)
    .collection("rateLimits").doc("joinHomeByCode");
  const nowMs = Date.now();
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(rlRef);
    const d = snap.data();
    const windowStart = (d?.["windowStart"] as number | undefined) ?? 0;
    const count = (d?.["count"] as number | undefined) ?? 0;
    if (nowMs - windowStart > JOIN_WINDOW_MS) {
      tx.set(rlRef, { windowStart: nowMs, count: 1 });
    } else if (count >= JOIN_MAX_ATTEMPTS) {
      throw new HttpsError(
        "resource-exhausted",
        "too-many-join-attempts",
      );
    } else {
      tx.update(rlRef, { count: count + 1 });
    }
  });

  const query = await db
    .collectionGroup("invitations")
    .where("code", "==", code)
    .where("used", "==", false)
    .limit(1)
    .get();

  if (query.empty) {
    throw new HttpsError("not-found", "Invalid invite code");
  }

  const invDoc = query.docs[0];
  const invData = invDoc.data();
  const expiresAt = (invData["expiresAt"] as admin.firestore.Timestamp | undefined)?.toDate();
  if (expiresAt && admin.firestore.Timestamp.now().toDate() > expiresAt) {
    throw new HttpsError("deadline-exceeded", "Invite code has expired");
  }

  const homeRef = invDoc.ref.parent.parent!;
  const invRef = invDoc.ref;
  const userRef = db.collection("users").doc(uid);
  const memberRef = homeRef.collection("members").doc(uid);

  await db.runTransaction(async (tx) => {
    const [homeDoc, freshInv, userDoc, existingMember] = await Promise.all([
      tx.get(homeRef),
      tx.get(invRef),
      tx.get(userRef),
      tx.get(memberRef),
    ]);

    if (!homeDoc.exists) throw new HttpsError("not-found", "Home not found");
    if (freshInv.data()?.["used"] === true) {
      throw new HttpsError("deadline-exceeded", "Invite code already used");
    }

    // Free-plan gate: max N active members per home (ver joinHome).
    const homeDataTx = homeDoc.data()!;
    const isAlreadyActiveMember = existingMember.exists &&
      existingMember.data()?.["status"] === "active";
    if (!isPremium(homeDataTx["premiumStatus"] as string | undefined) &&
        !isAlreadyActiveMember) {
      const activeMembersSnap = await tx.get(
        homeRef.collection("members").where("status", "==", "active")
      );
      if (activeMembersSnap.size >= FREE_LIMITS.maxActiveMembers) {
        throw new HttpsError("failed-precondition", FREE_LIMIT_CODES.members);
      }
    }

    const homeName = homeDataTx["name"] as string;
    const profile = readMemberProfileFields(userDoc.data());
    const now = FieldValue.serverTimestamp();

    // Rejoin: preservar rol previo (admin/member) si el doc ya existía.
    const preservedRole =
      (existingMember.data()?.["role"] as string | undefined) ?? "member";

    tx.update(invRef, { used: true, usedAt: now, usedBy: uid });
    tx.set(
      db.collection("users").doc(uid).collection("memberships").doc(homeRef.id),
      {
        homeNameSnapshot: homeName,
        homePhotoSnapshot: (homeDataTx["photoUrl"] as string | undefined) ?? null,
        role: preservedRole,
        billingState: "none",
        status: "active",
        joinedAt: now,
        leftAt: null,
      }
    );
    if (existingMember.exists) {
      tx.update(memberRef, {
        nickname: profile.nickname,
        photoUrl: profile.photoUrl,
        phone: sanitizeMemberPhone(profile.phone, profile.phoneVisibility),
        phoneVisibility: profile.phoneVisibility,
        status: "active",
        rejoinedAt: now,
      });
    } else {
      tx.set(
        memberRef,
        buildNewMemberDoc({
          uid,
          nickname: profile.nickname,
          role: "member",
          photoUrl: profile.photoUrl,
          phone: profile.phone,
          phoneVisibility: profile.phoneVisibility,
        })
      );
    }
  });

  // Devolver el homeId para que el cliente (onboarding) navegue al hogar sin
  // tener que consultar invitations por su cuenta (Hallazgo #01).
  return { homeId: homeRef.id };
});

// ---------------------------------------------------------------------------
// leaveHome
// Input:  { homeId: string }
// ---------------------------------------------------------------------------
export const leaveHome = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  const uid = request.auth.uid;
  const data = request.data as { homeId?: string };
  const homeId = data.homeId;

  if (!homeId) {
    throw new HttpsError("invalid-argument", "homeId is required");
  }

  const membershipRef = db
    .collection("users")
    .doc(uid)
    .collection("memberships")
    .doc(homeId);
  const homeRef = db.collection("homes").doc(homeId);
  const memberRef = homeRef.collection("members").doc(uid);

  await db.runTransaction(async (tx) => {
    const [membershipDoc, homeDoc, memberDoc] = await Promise.all([
      tx.get(membershipRef),
      tx.get(homeRef),
      tx.get(memberRef),
    ]);

    if (!membershipDoc.exists) {
      throw new HttpsError("not-found", "Membership not found");
    }
    if (membershipDoc.data()!["role"] === "owner") {
      throw new HttpsError("failed-precondition", "Owner cannot leave home");
    }

    // Payer cannot leave while there's an active Premium billing period.
    if (homeDoc.exists) {
      const homeData = homeDoc.data()!;
      const PROTECTED_STATUSES = ["active", "cancelledPendingEnd", "rescue"];
      const currentPayerUid = homeData["currentPayerUid"] as
        | string
        | null
        | undefined;
      const premiumStatus = homeData["premiumStatus"] as string | undefined;

      if (
        uid === currentPayerUid &&
        premiumStatus &&
        PROTECTED_STATUSES.includes(premiumStatus)
      ) {
        throw new HttpsError(
          "failed-precondition",
          "payer-cannot-leave-or-be-removed-while-premium-active"
        );
      }
    }

    const now = FieldValue.serverTimestamp();
    tx.update(membershipRef, { status: "left", leftAt: now });
    if (memberDoc.exists) {
      tx.update(memberRef, { status: "left", leftAt: now });
    }
  });

  // Hallazgo #08: reasignar las tareas del que se va y reconstruir el dashboard,
  // igual que el borrado de cuenta (cleanupUserInHome). Sin esto, sus tareas
  // quedan "pegadas" (currentAssigneeUid + assignmentOrder) a un ex-miembro y la
  // rotación seguiría seleccionándolo. Best-effort: la salida ya está confirmada
  // en la transacción; un fallo aquí solo se registra (las exclusiones de
  // 'left' en pasar turno/completar/expirar evitan que se le seleccione igual).
  try {
    await reassignTasksFromDeletedUser(uid, homeId);
    await updateHomeDashboard(homeId);
  } catch (err) {
    logger.error(
      `leaveHome: reasignación de tareas falló home=${homeId} uid=${uid}`,
      err
    );
  }
});

// ---------------------------------------------------------------------------
// removeMember
// SOLO el owner expulsa a un miembro del hogar (Hallazgo #12). Marca
// status="left" en ambos documentos (homes/{homeId}/members/{targetUid} y
// users/{targetUid}/memberships/{homeId}).
// Input:  { homeId: string, targetUid: string }
// ---------------------------------------------------------------------------
export const removeMember = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  const callerUid = request.auth.uid;
  const { homeId, targetUid } = request.data as {
    homeId?: string;
    targetUid?: string;
  };

  if (!homeId?.trim() || !targetUid?.trim()) {
    throw new HttpsError(
      "invalid-argument",
      "homeId and targetUid are required"
    );
  }
  if (callerUid === targetUid) {
    throw new HttpsError(
      "failed-precondition",
      "cannot-remove-self-use-leave-home"
    );
  }

  const homeRef = db.collection("homes").doc(homeId);
  const callerMemberRef = homeRef.collection("members").doc(callerUid);
  const targetMemberRef = homeRef.collection("members").doc(targetUid);
  const targetMembershipRef = db
    .collection("users")
    .doc(targetUid)
    .collection("memberships")
    .doc(homeId);

  await db.runTransaction(async (tx) => {
    const [homeDoc, callerDoc, targetDoc] = await Promise.all([
      tx.get(homeRef),
      tx.get(callerMemberRef),
      tx.get(targetMemberRef),
    ]);

    if (!callerDoc.exists) {
      throw new HttpsError("permission-denied", "caller-not-member");
    }
    if (!targetDoc.exists) {
      throw new HttpsError("not-found", "target-not-member");
    }

    const callerRole = callerDoc.data()!["role"] as string | undefined;
    const targetRole = targetDoc.data()!["role"] as string | undefined;

    if (targetRole === "owner") {
      throw new HttpsError("failed-precondition", "cannot-remove-owner");
    }
    // Hallazgo #12: SOLO el owner puede expulsar. Antes un admin podía expulsar
    // unilateralmente a cualquier member (y la matriz permitía admin→member sin
    // confirmación del owner). La UI ya ocultaba el botón a los no-owners, pero
    // la callable lo aceptaba → un admin podía escalar llamándola directamente.
    // Alineamos el backend con la UI: expulsar es prerrogativa exclusiva del
    // owner. Los admins gestionan tareas, no echan gente.
    if (callerRole !== "owner") {
      throw new HttpsError("permission-denied", "only-owner-can-remove");
    }

    // Payer protection — misma regla que leaveHome.
    if (homeDoc.exists) {
      const homeData = homeDoc.data()!;
      const PROTECTED_STATUSES = ["active", "cancelledPendingEnd", "rescue"];
      const currentPayerUid = homeData["currentPayerUid"] as
        | string
        | null
        | undefined;
      const premiumStatus = homeData["premiumStatus"] as string | undefined;

      if (
        targetUid === currentPayerUid &&
        premiumStatus &&
        PROTECTED_STATUSES.includes(premiumStatus)
      ) {
        throw new HttpsError(
          "failed-precondition",
          "payer-cannot-leave-or-be-removed-while-premium-active"
        );
      }
    }

    const now = FieldValue.serverTimestamp();
    tx.update(targetMemberRef, { status: "left", leftAt: now });
    tx.set(
      targetMembershipRef,
      { status: "left", leftAt: now },
      { merge: true }
    );
  });

  // Hallazgo #08: reasignar las tareas del expulsado y reconstruir el dashboard,
  // igual que el borrado de cuenta (cleanupUserInHome). Sin esto, sus tareas
  // quedan "pegadas" (currentAssigneeUid + assignmentOrder) a un ex-miembro y la
  // rotación seguiría seleccionándolo. Best-effort: la expulsión ya está
  // confirmada en la transacción; un fallo aquí solo se registra (las
  // exclusiones de 'left' en pasar turno/completar/expirar son la red de
  // seguridad).
  try {
    await reassignTasksFromDeletedUser(targetUid, homeId);
    await updateHomeDashboard(homeId);
  } catch (err) {
    logger.error(
      `removeMember: reasignación de tareas falló home=${homeId} target=${targetUid}`,
      err
    );
  }

  logger.info(
    `removeMember: target=${targetUid} in home=${homeId} by caller=${callerUid}`
  );
});

// ---------------------------------------------------------------------------
// reinstateMember
// Owner/admin REINCORPORA a un miembro que dejó el hogar (status="left"),
// reactivando su membresía (status="active") en ambos documentos. Respeta el
// límite de miembros del plan Free. El rol vuelve a "member" (no se restaura
// admin automáticamente; el owner puede re-promover).
// Input:  { homeId: string, targetUid: string }
// ---------------------------------------------------------------------------
export const reinstateMember = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  const callerUid = request.auth.uid;
  const { homeId, targetUid } = request.data as {
    homeId?: string;
    targetUid?: string;
  };

  if (!homeId?.trim() || !targetUid?.trim()) {
    throw new HttpsError(
      "invalid-argument",
      "homeId and targetUid are required"
    );
  }

  const homeRef = db.collection("homes").doc(homeId);
  const callerMemberRef = homeRef.collection("members").doc(callerUid);
  const targetMemberRef = homeRef.collection("members").doc(targetUid);
  const targetMembershipRef = db
    .collection("users")
    .doc(targetUid)
    .collection("memberships")
    .doc(homeId);

  await db.runTransaction(async (tx) => {
    const [homeDoc, callerDoc, targetDoc] = await Promise.all([
      tx.get(homeRef),
      tx.get(callerMemberRef),
      tx.get(targetMemberRef),
    ]);

    if (!callerDoc.exists) {
      throw new HttpsError("permission-denied", "caller-not-member");
    }
    if (!targetDoc.exists) {
      throw new HttpsError("not-found", "target-not-member");
    }

    const callerRole = callerDoc.data()!["role"] as string | undefined;
    const callerStatus = callerDoc.data()!["status"] as string | undefined;
    if (
      callerStatus !== "active" ||
      (callerRole !== "owner" && callerRole !== "admin")
    ) {
      throw new HttpsError("permission-denied", "insufficient-role");
    }

    const targetStatus = targetDoc.data()!["status"] as string | undefined;
    if (targetStatus !== "left") {
      throw new HttpsError("failed-precondition", "target-not-left");
    }

    // Límite de miembros del plan Free (el target está 'left', no cuenta aún).
    if (!isPremium(homeDoc.data()?.["premiumStatus"] as string | undefined)) {
      const activeMembersSnap = await tx.get(
        homeRef.collection("members").where("status", "==", "active")
      );
      if (activeMembersSnap.size >= FREE_LIMITS.maxActiveMembers) {
        throw new HttpsError("failed-precondition", FREE_LIMIT_CODES.members);
      }
    }

    const now = FieldValue.serverTimestamp();
    tx.update(targetMemberRef, {
      status: "active",
      role: "member",
      rejoinedAt: now,
      leftAt: FieldValue.delete(),
    });
    tx.set(
      targetMembershipRef,
      { status: "active", rejoinedAt: now, leftAt: FieldValue.delete() },
      { merge: true }
    );
  });

  logger.info(
    `reinstateMember: target=${targetUid} in home=${homeId} by caller=${callerUid}`
  );
});

// ---------------------------------------------------------------------------
// closeHome
// Input:  { homeId: string }
// ---------------------------------------------------------------------------
export const closeHome = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  const uid = request.auth.uid;
  const data = request.data as { homeId?: string };
  const homeId = data.homeId;

  if (!homeId) {
    throw new HttpsError("invalid-argument", "homeId is required");
  }

  const homeRef = db.collection("homes").doc(homeId);
  const homeDoc = await homeRef.get();

  if (!homeDoc.exists) {
    throw new HttpsError("not-found", "Home not found");
  }
  if (homeDoc.data()!["ownerUid"] !== uid) {
    throw new HttpsError("permission-denied", "Only the owner can close the home");
  }

  const userMembershipsSnap = await db
    .collection("users")
    .doc(uid)
    .collection("memberships")
    .get();

  const batch = db.batch();
  batch.update(homeRef, {
    premiumStatus: "purged",
    updatedAt: FieldValue.serverTimestamp(),
  });

  for (const doc of userMembershipsSnap.docs) {
    if (doc.id === homeId) {
      batch.delete(doc.ref);
    }
  }

  await batch.commit();

  logger.info(`Home closed: ${homeId} by owner ${uid}`);
});

// ---------------------------------------------------------------------------
// generateInviteCode
// Genera un código de invitación de 6 caracteres para unirse al hogar.
// Input:  { homeId: string }
// Output: { code: string }
// ---------------------------------------------------------------------------
export const generateInviteCode = onCall(async (request) => {
  logger.info("generateInviteCode called", {
    hasAuth: !!request.auth,
    uid: request.auth?.uid ?? "none",
  });
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  const uid = request.auth.uid;
  const data = request.data as { homeId?: string };
  const homeId = data.homeId?.trim();

  if (!homeId) {
    throw new HttpsError("invalid-argument", "homeId is required");
  }

  // Verificar que el usuario es miembro del hogar
  const memberRef = db.collection("homes").doc(homeId).collection("members").doc(uid);
  const memberDoc = await memberRef.get();
  if (!memberDoc.exists) {
    throw new HttpsError("permission-denied", "Not a member of this home");
  }

  // Generar código único de 6 caracteres alfanuméricos. Usamos randomInt
  // (CSPRNG) en vez de Math.random(): el código es un secreto que da acceso
  // al hogar y se consulta por collectionGroup global, así que no debe ser
  // predecible.
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 6; i++) {
    code += chars[randomInt(chars.length)];
  }

  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 días
  const invRef = db.collection("homes").doc(homeId).collection("invitations").doc();

  // Revocar (marcar como usados) los códigos activos previos del hogar
  const oldCodesSnap = await db.collection("homes").doc(homeId)
    .collection("invitations")
    .where("used", "==", false)
    .get();

  const batch = db.batch();
  for (const doc of oldCodesSnap.docs) {
    batch.update(doc.ref, { used: true, revokedAt: FieldValue.serverTimestamp() });
  }
  batch.set(invRef, {
    code,
    createdBy: uid,
    used: false,
    expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
    createdAt: FieldValue.serverTimestamp(),
  });
  await batch.commit();

  logger.info(`Invite code generated for home ${homeId} by ${uid}`);
  return { code, expiresAt: expiresAt.toISOString() };
});

// ---------------------------------------------------------------------------
// repairMemberDocument
// Función de migración/reparación: crea el documento homes/{homeId}/members/{uid}
// si no existe, a partir del membership en users/{uid}/memberships/{homeId}.
// Idempotente: usa merge:true, seguro de llamar múltiples veces.
// Input:  { homeId: string }
// ---------------------------------------------------------------------------
export const repairMemberDocument = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  const uid = request.auth.uid;
  const data = request.data as { homeId?: string };
  const homeId = data.homeId;

  if (!homeId) {
    throw new HttpsError("invalid-argument", "homeId is required");
  }

  // Verificar que el usuario tiene membership
  const membershipRef = db
    .collection("users").doc(uid)
    .collection("memberships").doc(homeId);
  const membershipDoc = await membershipRef.get();

  if (!membershipDoc.exists) {
    throw new HttpsError("not-found", "No membership found for this home");
  }

  const membership = membershipDoc.data()!;
  const role = (membership["role"] as string) ?? "member";
  const status = (membership["status"] as string) ?? "active";
  const joinedAt = membership["joinedAt"] ?? FieldValue.serverTimestamp();

  // Verificar si ya existe el documento de miembro
  const memberRef = db.collection("homes").doc(homeId).collection("members").doc(uid);
  const memberDoc = await memberRef.get();

  if (memberDoc.exists) {
    // Ya existe, no hacer nada
    return { created: false };
  }

  // Obtener perfil del usuario para nickname, foto, teléfono y su visibilidad
  const userSnap = await db.collection("users").doc(uid).get();
  const { nickname, photoUrl, phone, phoneVisibility } =
    readMemberProfileFields(userSnap.exists ? userSnap.data() : undefined);

  await memberRef.set({
    nickname,
    photoUrl,
    bio: null,
    phone: sanitizeMemberPhone(phone, phoneVisibility),
    phoneVisibility,
    role,
    status,
    joinedAt,
    tasksCompleted: 0,
    passedCount: 0,
    complianceRate: 0.0,
    currentStreak: 0,
    averageScore: 0.0,
  });

  logger.info(`Member document repaired for uid=${uid} homeId=${homeId}`);
  return { created: true };
});

// ---------------------------------------------------------------------------
// promoteToAdmin
// Solo el owner puede promover a un miembro a admin.
// Input:  { homeId: string, targetUid: string }
// ---------------------------------------------------------------------------
export const promoteToAdmin = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Must be authenticated");

  const uid = request.auth.uid;
  const { homeId, targetUid } = request.data as { homeId?: string; targetUid?: string };
  if (!homeId || !targetUid) {
    throw new HttpsError("invalid-argument", "homeId and targetUid are required");
  }

  const homeRef = db.collection("homes").doc(homeId);
  const callerRef = homeRef.collection("members").doc(uid);
  const targetRef = homeRef.collection("members").doc(targetUid);

  const targetMembershipRef = db
    .collection("users").doc(targetUid)
    .collection("memberships").doc(homeId);

  await db.runTransaction(async (tx) => {
    const [homeDoc, callerDoc, targetDoc] = await Promise.all([
      tx.get(homeRef),
      tx.get(callerRef),
      tx.get(targetRef),
    ]);

    if (!homeDoc.exists) throw new HttpsError("not-found", "Home not found");
    if (!callerDoc.exists) throw new HttpsError("permission-denied", "Caller is not a member");
    if (callerDoc.data()!["role"] !== "owner") {
      throw new HttpsError("permission-denied", "Only the owner can promote members");
    }
    if (!targetDoc.exists) throw new HttpsError("not-found", "Target member not found");
    if (targetDoc.data()!["role"] !== "member") {
      throw new HttpsError("failed-precondition", "Target is not a regular member");
    }

    // Free-plan: solo el owner puede tener rol admin. Bloqueamos cualquier
    // promoción mientras el hogar no esté en Premium activo.
    const premiumStatus = homeDoc.data()!["premiumStatus"] as string | undefined;
    if (!isPremium(premiumStatus)) {
      throw new HttpsError("failed-precondition", FREE_LIMIT_CODES.admins);
    }

    // Hallazgo #12: tope de administradores. Antes no había ninguno → un hogar
    // podía acumular admins ilimitados. Contamos los admins ACTIVOS (un admin
    // expulsado conserva role:'admin' con status:'left' hasta su reasignación,
    // así que debe excluirse). La query va dentro de la transacción y antes de
    // cualquier escritura (regla de Firestore: lecturas primero).
    const adminsSnap = await tx.get(
      homeRef.collection("members").where("role", "==", "admin")
    );
    const activeAdmins = adminsSnap.docs.filter(
      (d) => d.data()["status"] !== "left"
    ).length;
    if (activeAdmins >= PREMIUM_LIMITS.maxAdminsBesidesOwner) {
      throw new HttpsError("resource-exhausted", "max_admins_reached");
    }

    // Actualizar rol en ambos documentos para que las reglas Firestore
    // (que leen de users/{uid}/memberships/{homeId}) vean el rol correcto.
    tx.update(targetRef, { role: "admin" });
    tx.update(targetMembershipRef, { role: "admin" });

    // Mantener `dashboard.planCounters.totalAdmins` sincronizado para que
    // el banner free-limit del cliente reaccione sin recalcular. El
    // dashboard se inicializa en createHome con totalAdmins=1 (owner) y
    // hasta ahora no se actualizaba en promote/demote (bug detectado en
    // el análisis multi-agente).
    const dashRef = homeRef.collection("views").doc("dashboard");
    tx.set(
      dashRef,
      { planCounters: { totalAdmins: FieldValue.increment(1) } },
      { merge: true },
    );
  });

  logger.info(`promoteToAdmin: uid=${targetUid} in home=${homeId} by owner=${uid}`);
});

// ---------------------------------------------------------------------------
// demoteFromAdmin
// Solo el owner puede degradar un admin a miembro.
// Input:  { homeId: string, targetUid: string }
// ---------------------------------------------------------------------------
export const demoteFromAdmin = onCall(async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Must be authenticated");

  const uid = request.auth.uid;
  const { homeId, targetUid } = request.data as { homeId?: string; targetUid?: string };
  if (!homeId || !targetUid) {
    throw new HttpsError("invalid-argument", "homeId and targetUid are required");
  }

  const homeRef = db.collection("homes").doc(homeId);
  const callerRef = homeRef.collection("members").doc(uid);
  const targetRef = homeRef.collection("members").doc(targetUid);

  const targetMembershipRef = db
    .collection("users").doc(targetUid)
    .collection("memberships").doc(homeId);

  await db.runTransaction(async (tx) => {
    const [callerDoc, targetDoc] = await Promise.all([tx.get(callerRef), tx.get(targetRef)]);

    if (!callerDoc.exists) throw new HttpsError("permission-denied", "Caller is not a member");
    if (callerDoc.data()!["role"] !== "owner") {
      throw new HttpsError("permission-denied", "Only the owner can demote admins");
    }
    if (!targetDoc.exists) throw new HttpsError("not-found", "Target member not found");
    if (targetDoc.data()!["role"] !== "admin") {
      throw new HttpsError("failed-precondition", "Target is not an admin");
    }

    // Actualizar rol en ambos documentos (ver promoteToAdmin para contexto).
    tx.update(targetRef, { role: "member" });
    tx.update(targetMembershipRef, { role: "member" });

    // Mantener counter sincronizado (ver promoteToAdmin).
    const dashRef = homeRef.collection("views").doc("dashboard");
    tx.set(
      dashRef,
      { planCounters: { totalAdmins: FieldValue.increment(-1) } },
      { merge: true },
    );
  });

  logger.info(`demoteFromAdmin: uid=${targetUid} in home=${homeId} by owner=${uid}`);
});

// ---------------------------------------------------------------------------
// syncMemberProfile  (Firestore trigger)
// Cuando users/{uid} se actualiza, propaga el perfil (nickname, photoUrl,
// teléfono y su visibilidad) a todos los documentos homes/{homeId}/members/{uid}
// en los que el usuario participa. El teléfono y su visibilidad son
// preferencias globales del usuario: al editarlas deben re-sincronizarse en
// todos los hogares para que los demás miembros las vean (o dejen de verlas).
// ---------------------------------------------------------------------------
export const syncMemberProfile = onDocumentUpdated(
  "users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const profileBefore = readMemberProfileFields(before);
    const profileAfter = readMemberProfileFields(after);

    if (
      profileBefore.nickname === profileAfter.nickname &&
      profileBefore.photoUrl === profileAfter.photoUrl &&
      profileBefore.phone === profileAfter.phone &&
      profileBefore.phoneVisibility === profileAfter.phoneVisibility
    ) {
      return; // Sin cambios relevantes
    }

    const membershipsSnap = await db
      .collection("users")
      .doc(uid)
      .collection("memberships")
      .get();

    if (membershipsSnap.empty) return;

    const batch = db.batch();
    for (const membershipDoc of membershipsSnap.docs) {
      const homeId = membershipDoc.id;
      const memberRef = db
        .collection("homes")
        .doc(homeId)
        .collection("members")
        .doc(uid);
      batch.update(memberRef, {
        nickname: profileAfter.nickname,
        photoUrl: profileAfter.photoUrl,
        phone: sanitizeMemberPhone(profileAfter.phone, profileAfter.phoneVisibility),
        phoneVisibility: profileAfter.phoneVisibility,
      });
    }

    await batch.commit();
    logger.info(
      `syncMemberProfile: synced uid=${uid} to ${membershipsSnap.size} home(s)`
    );
  }
);

// ---------------------------------------------------------------------------
// syncHomeSnapshotToMemberships  (Firestore trigger)
// Cuando homes/{homeId} se actualiza (nombre o foto), propaga el snapshot
// (`homeNameSnapshot` + `homePhotoSnapshot`) a todas las memberships
// users/{uid}/memberships/{homeId} de sus miembros. Es el equivalente "al revés"
// de syncMemberProfile: aquí la fuente es el hogar y los destinos las
// membership cards que pintan el selector de hogares y "Mis hogares" (que NO
// leen el documento del hogar en vivo, sino su snapshot denormalizado). Sin
// esto, renombrar el hogar o cambiar su avatar dejaba el selector con el dato
// viejo hasta re-unirse.
// ---------------------------------------------------------------------------
export const syncHomeSnapshotToMemberships = onDocumentUpdated(
  "homes/{homeId}",
  async (event) => {
    const homeId = event.params.homeId;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const nameBefore = (before["name"] as string | undefined) ?? "";
    const nameAfter = (after["name"] as string | undefined) ?? "";
    const photoBefore = (before["photoUrl"] as string | undefined) ?? null;
    const photoAfter = (after["photoUrl"] as string | undefined) ?? null;

    if (nameBefore === nameAfter && photoBefore === photoAfter) {
      return; // Sin cambios relevantes para el snapshot de membership
    }

    // Miembros vigentes del hogar (cada uno tiene su membership card a
    // sincronizar). Los que dejaron el hogar (left/removed) no nos interesan.
    const membersSnap = await db
      .collection("homes")
      .doc(homeId)
      .collection("members")
      .where("status", "in", ["active", "frozen"])
      .get();

    if (membersSnap.empty) return;

    // Update individual con .catch (como en update_dashboard): una membership
    // que ya no exista no debe tumbar la sincronización del resto.
    const updates = membersSnap.docs.map((memberDoc) =>
      db
        .collection("users")
        .doc(memberDoc.id)
        .collection("memberships")
        .doc(homeId)
        .update({
          homeNameSnapshot: nameAfter,
          homePhotoSnapshot: photoAfter,
        })
        .catch((err: unknown) =>
          logger.warn(
            `syncHomeSnapshotToMemberships: could not update membership ` +
              `uid=${memberDoc.id} home=${homeId}: ${String(err)}`
          )
        )
    );
    await Promise.all(updates);
    logger.info(
      `syncHomeSnapshotToMemberships: synced home=${homeId} to ` +
        `${membersSnap.size} membership(s)`
    );
  }
);

// ---------------------------------------------------------------------------
// transferOwnership
// Input:  { homeId: string, newOwnerUid: string }
// ---------------------------------------------------------------------------
export const transferOwnership = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  const uid = request.auth.uid;
  const data = request.data as { homeId?: string; newOwnerUid?: string };
  const homeId = data.homeId?.trim();
  const newOwnerUid = data.newOwnerUid?.trim();

  if (!homeId || !newOwnerUid) {
    throw new HttpsError(
      "invalid-argument",
      "homeId and newOwnerUid are required"
    );
  }

  if (newOwnerUid === uid) {
    throw new HttpsError(
      "invalid-argument",
      "Cannot transfer ownership to yourself"
    );
  }

  const homeRef = db.collection("homes").doc(homeId);

  const callerMemberRef = homeRef.collection("members").doc(uid);
  const newOwnerMemberRef = homeRef.collection("members").doc(newOwnerUid);

  await db.runTransaction(async (tx) => {
    const [homeDoc, newOwnerMemberDoc, callerMemberDoc] = await Promise.all([
      tx.get(homeRef),
      tx.get(newOwnerMemberRef),
      tx.get(callerMemberRef),
    ]);

    if (!homeDoc.exists) {
      throw new HttpsError("not-found", "Home not found");
    }
    if (homeDoc.data()!["ownerUid"] !== uid) {
      throw new HttpsError(
        "permission-denied",
        "Only the current owner can transfer ownership"
      );
    }

    if (!callerMemberDoc.exists) {
      throw new HttpsError("permission-denied", "Caller is not a member of this home");
    }

    // Frozen members can receive ownership (Caso D: only frozen members remain)
    if (!newOwnerMemberDoc.exists) {
      throw new HttpsError("not-found", "New owner is not a member of this home");
    }
    // ...pero un ex-miembro (status 'left') NO puede recibir la propiedad: el
    // hogar quedaría con un owner que ya no participa y sin ruta de cierre.
    if (newOwnerMemberDoc.data()?.["status"] === "left") {
      throw new HttpsError(
        "failed-precondition",
        "Cannot transfer ownership to a member who left the home"
      );
    }

    // Payer lock: si el caller es payer con Premium activo, no puede transferir
    // ownership (sería un backdoor para salirse del hogar vía transferencia).
    const homeData = homeDoc.data()!;
    const PROTECTED_STATUSES = ["active", "cancelledPendingEnd", "rescue"];
    const currentPayerUid = homeData["currentPayerUid"] as
      | string
      | null
      | undefined;
    const premiumStatus = homeData["premiumStatus"] as string | undefined;
    if (
      uid === currentPayerUid &&
      premiumStatus &&
      PROTECTED_STATUSES.includes(premiumStatus)
    ) {
      throw new HttpsError(
        "failed-precondition",
        "payer-cannot-transfer-ownership-while-premium-active"
      );
    }

    // homes/{homeId}: actualizar ownerUid
    tx.update(homeRef, { ownerUid: newOwnerUid });

    // homes/{homeId}/members: cambiar roles
    tx.update(newOwnerMemberRef, { role: "owner" });
    tx.update(callerMemberRef, { role: "admin" });

    // users/.../memberships: reflejar cambio de rol
    tx.update(
      db.collection("users").doc(newOwnerUid).collection("memberships").doc(homeId),
      { role: "owner" }
    );
    tx.update(
      db.collection("users").doc(uid).collection("memberships").doc(homeId),
      { role: "admin" }
    );
  });

  logger.info(
    `transferOwnership: ${uid} → ${newOwnerUid} in home ${homeId}`
  );
});

// Hallazgo #17: callable READ-ONLY de diagnóstico de soporte (App Check + claim
// `support`). Definida en su propio módulo; se re-exporta aquí para que el
// barrel `export * from "./homes"` del index raíz la despliegue.
export { supportDiagnoseHome } from "./support_diagnostics";

