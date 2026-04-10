// functions/test/integration/helpers/setup.ts
//
// Factory helpers para seeds de datos en tests de integración.
// Importar DESPUÉS de que global_setup.js haya establecido FIRESTORE_EMULATOR_HOST.

import * as admin from 'firebase-admin';

// Inicializar firebase-admin solo una vez
let _app: admin.app.App | null = null;

export function getApp(): admin.app.App {
  if (!_app) {
    _app = admin.initializeApp(
      { projectId: process.env.GCLOUD_PROJECT ?? 'demo-toka-integration' },
      'integration-tests-' + Date.now()
    );
  }
  return _app;
}

export function getDb(): admin.firestore.Firestore {
  return getApp().firestore();
}

/** Borra todas las colecciones usadas en tests */
export async function cleanAll(): Promise<void> {
  const db = getDb();
  const collections = ['homes', 'users'];
  for (const col of collections) {
    const snap = await db.collection(col).get();
    const batch = db.batch();
    snap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }
}

/** Crea un usuario en Firestore (simula el doc creado tras Auth) */
export async function createUser(uid: string, overrides: Record<string, unknown> = {}): Promise<void> {
  await getDb().collection('users').doc(uid).set({
    uid,
    displayName: `User ${uid}`,
    email: `${uid}@test.toka`,
    locale: 'es',
    baseHomeSlots: 2,
    lifetimeUnlockedHomeSlots: 0,
    homeSlotCap: 5,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    ...overrides,
  });
}

/** Crea un hogar y añade al owner como member */
export async function createHome(
  homeId: string,
  ownerUid: string,
  overrides: Record<string, unknown> = {}
): Promise<void> {
  const db = getDb();
  await db.collection('homes').doc(homeId).set({
    ownerUid,
    name: `Home ${homeId}`,
    premiumStatus: 'free',
    limits: { maxMembers: 5, maxTasks: 20 },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    ...overrides,
  });
  await addMemberToHome(homeId, ownerUid, 'owner', 'active');
}

/** Añade un miembro al hogar (en homes/{id}/members y users/{uid}/memberships) */
export async function addMemberToHome(
  homeId: string,
  uid: string,
  role: 'owner' | 'admin' | 'member',
  status: 'active' | 'frozen' | 'absent' = 'active',
  overrides: Record<string, unknown> = {}
): Promise<void> {
  const db = getDb();
  const memberData = {
    uid,
    role,
    status,
    billingState: role === 'owner' ? 'currentPayer' : 'none',
    completedCount: 0,
    passedCount: 0,
    complianceRate: 1.0,
    completions60d: 0,
    notificationPrefs: { taskReminders: true, passNotifications: true },
    vacation: null,
    joinedAt: admin.firestore.FieldValue.serverTimestamp(),
    ...overrides,
  };
  await db.collection('homes').doc(homeId).collection('members').doc(uid).set(memberData);
  await db.collection('users').doc(uid).collection('memberships').doc(homeId).set({ role, status });
}

/** Crea una tarea activa en el hogar */
export async function createTask(
  homeId: string,
  taskId: string,
  assignedToUid: string,
  overrides: Record<string, unknown> = {}
): Promise<void> {
  await getDb()
    .collection('homes')
    .doc(homeId)
    .collection('tasks')
    .doc(taskId)
    .set({
      title: `Task ${taskId}`,
      status: 'active',
      currentAssigneeUid: assignedToUid,
      assignmentOrder: [assignedToUid],
      distributionMode: 'round_robin',
      recurrenceType: 'weekly',
      nextDueAt: admin.firestore.Timestamp.fromDate(new Date()),
      visualKind: 'emoji',
      visualValue: '🧹',
      completedCount90d: 0,
      frozenUids: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      ...overrides,
    });
}

/** Construye un CallableRequest simulado para firebase-functions-test */
export function makeCallableRequest(uid: string, data: unknown): {
  data: unknown;
  auth: { uid: string; token: Record<string, unknown> };
  rawRequest: unknown;
} {
  return {
    data,
    auth: { uid, token: { uid } },
    rawRequest: {},
  };
}
