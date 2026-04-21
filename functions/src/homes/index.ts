import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";
import { buildNewMemberDoc } from "./member_factory";
import { FREE_LIMITS, FREE_LIMIT_CODES, isPremium } from "../shared/free_limits";

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

  const memberData = buildNewMemberDoc({
    uid,
    nickname,
    role: "owner",
    photoUrl,
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
      adFlags: {
        showBanner: true,
        bannerUnit: "ca-app-pub-3940256099942544/6300978111",
      },
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
    const userDataTx = userDoc.data() ?? {};
    const memberNickname = (userDataTx["nickname"] as string | undefined) ?? "";
    const memberPhotoUrl = (userDataTx["photoUrl"] as string | undefined) ?? null;
    const now = FieldValue.serverTimestamp();

    // Rejoin: preservar rol previo (admin/member) si el doc ya existía.
    const preservedRole =
      (existingMember.data()?.["role"] as string | undefined) ?? "member";

    tx.update(invRef, { used: true, usedAt: now, usedBy: uid });
    tx.set(
      db.collection("users").doc(uid).collection("memberships").doc(homeId),
      {
        homeNameSnapshot: homeName,
        role: preservedRole,
        billingState: "none",
        status: "active",
        joinedAt: now,
        leftAt: null,
      }
    );
    if (existingMember.exists) {
      tx.update(memberRef, {
        nickname: memberNickname,
        photoUrl: memberPhotoUrl,
        status: "active",
        rejoinedAt: now,
      });
    } else {
      tx.set(
        memberRef,
        buildNewMemberDoc({
          uid,
          nickname: memberNickname,
          role: "member",
          photoUrl: memberPhotoUrl,
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
    const userDataTx = userDoc.data() ?? {};
    const memberNickname = (userDataTx["nickname"] as string | undefined) ?? "";
    const memberPhotoUrl = (userDataTx["photoUrl"] as string | undefined) ?? null;
    const now = FieldValue.serverTimestamp();

    // Rejoin: preservar rol previo (admin/member) si el doc ya existía.
    const preservedRole =
      (existingMember.data()?.["role"] as string | undefined) ?? "member";

    tx.update(invRef, { used: true, usedAt: now, usedBy: uid });
    tx.set(
      db.collection("users").doc(uid).collection("memberships").doc(homeRef.id),
      {
        homeNameSnapshot: homeName,
        role: preservedRole,
        billingState: "none",
        status: "active",
        joinedAt: now,
        leftAt: null,
      }
    );
    if (existingMember.exists) {
      tx.update(memberRef, {
        nickname: memberNickname,
        photoUrl: memberPhotoUrl,
        status: "active",
        rejoinedAt: now,
      });
    } else {
      tx.set(
        memberRef,
        buildNewMemberDoc({
          uid,
          nickname: memberNickname,
          role: "member",
          photoUrl: memberPhotoUrl,
        })
      );
    }
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
});

// ---------------------------------------------------------------------------
// removeMember
// Owner/admin expulsa a un miembro del hogar. Marca status="left" en ambos
// documentos (homes/{homeId}/members/{targetUid} y
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
    if (callerRole !== "owner" && callerRole !== "admin") {
      throw new HttpsError("permission-denied", "insufficient-role");
    }
    if (callerRole === "admin" && targetRole === "admin") {
      throw new HttpsError("permission-denied", "admin-cannot-remove-admin");
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

  logger.info(
    `removeMember: target=${targetUid} in home=${homeId} by caller=${callerUid}`
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

  // Generar código único de 6 caracteres alfanuméricos
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let code = "";
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
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

    // Actualizar rol en ambos documentos para que las reglas Firestore
    // (que leen de users/{uid}/memberships/{homeId}) vean el rol correcto.
    tx.update(targetRef, { role: "admin" });
    tx.update(targetMembershipRef, { role: "admin" });
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

// DEBUG PREMIUM — REMOVE BEFORE PRODUCTION
// ---------------------------------------------------------------------------
// debugSetPremiumStatus
// Cambia `premiumStatus` de un hogar a uno de 6 valores válidos y propaga el
// cambio a `homes/{homeId}/views/dashboard.premiumFlags` de forma coherente.
// Solo el owner puede llamarla. Pensado exclusivamente para QA/desarrollo.
// Input:  { homeId: string, status: "free" | "active" | "cancelledPendingEnd"
//          | "rescue" | "expiredFree" | "restorable" }
// Output: { ok: true }
// ---------------------------------------------------------------------------
const DEBUG_VALID_STATUSES = [
  "free",
  "active",
  "cancelledPendingEnd",
  "rescue",
  "expiredFree",
  "restorable",
] as const;

type DebugPremiumStatus = typeof DEBUG_VALID_STATUSES[number];

export const debugSetPremiumStatus = onCall(async (request) => {
  if (process.env.FUNCTIONS_EMULATOR !== "true") {
    throw new HttpsError(
      "permission-denied",
      "Debug operations only available in emulator"
    );
  }

  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  const uid = request.auth.uid;
  const data = request.data as { homeId?: string; status?: string };
  const homeId = data.homeId?.trim();
  const status = data.status?.trim();

  if (!homeId) {
    throw new HttpsError("invalid-argument", "homeId is required");
  }
  if (!status || !DEBUG_VALID_STATUSES.includes(status as DebugPremiumStatus)) {
    throw new HttpsError(
      "invalid-argument",
      `status must be one of: ${DEBUG_VALID_STATUSES.join(", ")}`
    );
  }

  const homeRef = db.collection("homes").doc(homeId);
  const dashboardRef = homeRef.collection("views").doc("dashboard");
  const homeDoc = await homeRef.get();

  if (!homeDoc.exists) {
    throw new HttpsError("not-found", "Home not found");
  }
  if (homeDoc.data()!["ownerUid"] !== uid) {
    throw new HttpsError(
      "permission-denied",
      "Only the owner can use the debug premium toggle"
    );
  }

  const now = Date.now();
  const day = 24 * 60 * 60 * 1000;
  const typed = status as DebugPremiumStatus;

  let premiumEndsAt: admin.firestore.Timestamp | null = null;
  let restoreUntil: admin.firestore.Timestamp | null = null;
  let autoRenewEnabled = false;
  let premiumPlan: string | null = null;

  switch (typed) {
    case "free":
      break;
    case "active":
      premiumEndsAt = admin.firestore.Timestamp.fromMillis(now + 30 * day);
      autoRenewEnabled = true;
      premiumPlan = "debug";
      break;
    case "cancelledPendingEnd":
      premiumEndsAt = admin.firestore.Timestamp.fromMillis(now + 10 * day);
      premiumPlan = "debug";
      break;
    case "rescue":
      premiumEndsAt = admin.firestore.Timestamp.fromMillis(now + 2 * day);
      premiumPlan = "debug";
      break;
    case "expiredFree":
      premiumEndsAt = admin.firestore.Timestamp.fromMillis(now - 1 * day);
      break;
    case "restorable":
      premiumEndsAt = admin.firestore.Timestamp.fromMillis(now - 2 * day);
      restoreUntil = admin.firestore.Timestamp.fromMillis(now + 20 * day);
      break;
  }

  const isPremium =
    typed === "active" ||
    typed === "cancelledPendingEnd" ||
    typed === "rescue";

  // En prod syncEntitlement setea currentPayerUid al uid comprador. En QA lo
  // alineamos con el owner para que los guards de payer-lock funcionen igual.
  const currentPayerUid = isPremium ? uid : null;

  const batch = db.batch();
  batch.update(homeRef, {
    premiumStatus: typed,
    premiumEndsAt,
    restoreUntil,
    autoRenewEnabled,
    premiumPlan,
    currentPayerUid,
    updatedAt: FieldValue.serverTimestamp(),
  });
  batch.set(
    dashboardRef,
    {
      premiumFlags: {
        isPremium,
        showAds: !isPremium,
        canUseSmartDistribution: isPremium,
        canUseVacations: isPremium,
        canUseReviews: isPremium,
      },
      rescueFlags: {
        isInRescue: typed === "rescue",
        daysLeft: typed === "rescue" ? 2 : null,
      },
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true }
  );
  await batch.commit();

  logger.info(
    `debugSetPremiumStatus: home=${homeId} status=${typed} by owner=${uid}`
  );
  return { ok: true };
});
// END DEBUG PREMIUM
