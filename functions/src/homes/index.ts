import { onCall, HttpsError } from "firebase-functions/v2/https";
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

  const batch = db.batch();
  batch.set(homeRef, homeData);
  batch.set(
    db.collection("users").doc(uid).collection("memberships").doc(homeRef.id),
    membershipData
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
