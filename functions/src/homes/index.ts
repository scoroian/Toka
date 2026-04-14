import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

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
  const data = request.data as { name?: string; emoji?: string };
  const name = data.name?.trim();

  if (!name) {
    throw new HttpsError("invalid-argument", "Home name is required");
  }

  // Check available slots
  const userDoc = await db.collection("users").doc(uid).get();
  const userData = userDoc.exists ? userDoc.data()! : {};
  const baseSlots = (userData["baseSlots"] as number) ?? 2;
  const lifetimeUnlocked = (userData["lifetimeUnlocked"] as number) ?? 0;
  const totalSlots = baseSlots + lifetimeUnlocked;

  const membershipsSnap = await db
    .collection("users")
    .doc(uid)
    .collection("memberships")
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
    createdAt: now,
    updatedAt: now,
  };
  if (data.emoji) homeData["emoji"] = data.emoji;

  const membershipData = {
    homeNameSnapshot: name,
    role: "owner",
    billingState: "none",
    status: "active",
    joinedAt: now,
    leftAt: null,
  };

  // Fetch user display name for the member document
  const userSnap = await db.collection("users").doc(uid).get();
  const userData2 = userSnap.exists ? userSnap.data()! : {};
  const nickname = (userData2["nickname"] as string | undefined) ?? "";
  const photoUrl = (userData2["photoUrl"] as string | undefined) ?? null;

  const memberData = {
    nickname,
    photoUrl,
    bio: null,
    phone: null,
    phoneVisibility: "hidden",
    role: "owner",
    status: "active",
    joinedAt: now,
    tasksCompleted: 0,
    passedCount: 0,
    complianceRate: 0.0,
    currentStreak: 0,
    averageScore: 0.0,
  };

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

  await db.runTransaction(async (tx) => {
    const [invDoc, homeDoc] = await Promise.all([
      tx.get(invRef),
      tx.get(homeRef),
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
    if (expiresAt && new Date() > expiresAt) {
      throw new HttpsError("deadline-exceeded", "Invitation expired");
    }

    const homeName = homeDoc.data()!["name"] as string;
    const now = FieldValue.serverTimestamp();

    tx.update(invRef, { used: true, usedAt: now, usedBy: uid });
    tx.set(
      db.collection("users").doc(uid).collection("memberships").doc(homeId),
      {
        homeNameSnapshot: homeName,
        role: "member",
        billingState: "none",
        status: "active",
        joinedAt: now,
        leftAt: null,
      }
    );
    // Crear documento de miembro en la subcolección del hogar
    tx.set(
      db.collection("homes").doc(homeId).collection("members").doc(uid),
      {
        nickname: "",
        photoUrl: null,
        bio: null,
        phone: null,
        phoneVisibility: "hidden",
        role: "member",
        status: "active",
        joinedAt: now,
        tasksCompleted: 0,
        passedCount: 0,
        complianceRate: 0.0,
        currentStreak: 0,
        averageScore: 0.0,
      },
      { merge: true }
    );
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
  if (expiresAt && new Date() > expiresAt) {
    throw new HttpsError("deadline-exceeded", "Invite code has expired");
  }

  const homeRef = invDoc.ref.parent.parent!;
  const invRef = invDoc.ref;

  await db.runTransaction(async (tx) => {
    const [homeDoc, freshInv] = await Promise.all([
      tx.get(homeRef),
      tx.get(invRef),
    ]);

    if (!homeDoc.exists) throw new HttpsError("not-found", "Home not found");
    if (freshInv.data()?.["used"] === true) {
      throw new HttpsError("deadline-exceeded", "Invite code already used");
    }

    const homeName = homeDoc.data()!["name"] as string;
    const now = FieldValue.serverTimestamp();

    tx.update(invRef, { used: true, usedAt: now, usedBy: uid });
    tx.set(
      db.collection("users").doc(uid).collection("memberships").doc(homeRef.id),
      {
        homeNameSnapshot: homeName,
        role: "member",
        billingState: "none",
        status: "active",
        joinedAt: now,
        leftAt: null,
      }
    );
    // Crear documento de miembro en la subcolección del hogar
    tx.set(
      homeRef.collection("members").doc(uid),
      {
        nickname: "",
        photoUrl: null,
        bio: null,
        phone: null,
        phoneVisibility: "hidden",
        role: "member",
        status: "active",
        joinedAt: now,
        tasksCompleted: 0,
        passedCount: 0,
        complianceRate: 0.0,
        currentStreak: 0,
        averageScore: 0.0,
      },
      { merge: true }
    );
  });
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

  const memberDoc = await membershipRef.get();
  if (!memberDoc.exists) {
    throw new HttpsError("not-found", "Membership not found");
  }
  if (memberDoc.data()!["role"] === "owner") {
    throw new HttpsError("failed-precondition", "Owner cannot leave home");
  }

  await membershipRef.update({
    status: "left",
    leftAt: FieldValue.serverTimestamp(),
  });
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

  // Generar código único de 6 caracteres alfanuméricos
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }

  const expiresAt = new Date(Date.now() + 48 * 60 * 60 * 1000); // 48 horas
  const invRef = db.collection("homes").doc(homeId).collection("invitations").doc();

  await invRef.set({
    code,
    createdBy: uid,
    used: false,
    expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
    createdAt: FieldValue.serverTimestamp(),
  });

  logger.info(`Invite code generated for home ${homeId} by ${uid}`);
  return { code };
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

  // Obtener perfil del usuario para el nickname y foto
  const userSnap = await db.collection("users").doc(uid).get();
  const userData = userSnap.exists ? userSnap.data()! : {};
  const nickname = (userData["nickname"] as string | undefined) ?? "";
  const photoUrl = (userData["photoUrl"] as string | undefined) ?? null;

  await memberRef.set({
    nickname,
    photoUrl,
    bio: null,
    phone: null,
    phoneVisibility: "hidden",
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

  await db.runTransaction(async (tx) => {
    const [callerDoc, targetDoc] = await Promise.all([tx.get(callerRef), tx.get(targetRef)]);

    if (!callerDoc.exists) throw new HttpsError("permission-denied", "Caller is not a member");
    if (callerDoc.data()!["role"] !== "owner") {
      throw new HttpsError("permission-denied", "Only the owner can promote members");
    }
    if (!targetDoc.exists) throw new HttpsError("not-found", "Target member not found");
    if (targetDoc.data()!["role"] !== "member") {
      throw new HttpsError("failed-precondition", "Target is not a regular member");
    }

    tx.update(targetRef, { role: "admin" });
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

    tx.update(targetRef, { role: "member" });
  });

  logger.info(`demoteFromAdmin: uid=${targetUid} in home=${homeId} by owner=${uid}`);
});

// ---------------------------------------------------------------------------
// syncMemberProfile  (Firestore trigger)
// Cuando users/{uid} se actualiza, propaga nickname y photoUrl a todos los
// documentos homes/{homeId}/members/{uid} en los que el usuario participa.
// ---------------------------------------------------------------------------
export const syncMemberProfile = onDocumentUpdated(
  "users/{uid}",
  async (event) => {
    const uid = event.params.uid;
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;

    const nicknameBefore = (before["nickname"] as string | undefined) ?? "";
    const nicknameAfter = (after["nickname"] as string | undefined) ?? "";
    const photoUrlBefore = (before["photoUrl"] as string | undefined) ?? null;
    const photoUrlAfter = (after["photoUrl"] as string | undefined) ?? null;

    if (nicknameBefore === nicknameAfter && photoUrlBefore === photoUrlAfter) {
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
        nickname: nicknameAfter,
        photoUrl: photoUrlAfter,
      });
    }

    await batch.commit();
    logger.info(
      `syncMemberProfile: synced uid=${uid} to ${membershipsSnap.size} home(s)`
    );
  }
);
