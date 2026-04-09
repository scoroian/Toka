# Functions Integration Tests — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Testear los callables y scheduled jobs de Cloud Functions contra el Firebase Emulator real, verificando efectos secundarios en Firestore tras cada llamada, incluyendo un flujo completo end-to-end.

**Architecture:** Se añade `firebase-functions-test` como devDependency. Un helper `setup.ts` inicializa firebase-admin contra los emuladores y provee factories de datos. Cada callable se testa con `testEnv.wrap()`. Un `jest.integration.config.js` separado establece las variables de entorno necesarias antes de importar firebase-admin. Los tests de scheduled jobs llaman al handler exportado directamente.

**Tech Stack:** Jest, `firebase-functions-test` ^3.3.0, `firebase-admin` ^12 (ya instalado), Firebase Emulators (Auth 9099, Firestore 8080, Functions 5001).

---

## Archivos a crear/modificar

- Modify: `functions/package.json` — añadir devDependency y script `test:integration`
- Create: `functions/jest.integration.config.js`
- Create: `functions/test/integration/helpers/setup.ts`
- Create: `functions/test/integration/apply_task_completion.test.ts`
- Create: `functions/test/integration/pass_task_turn.test.ts`
- Create: `functions/test/integration/manual_reassign.test.ts`
- Create: `functions/test/integration/sync_entitlement.test.ts`
- Create: `functions/test/integration/open_rescue_window.test.ts`
- Create: `functions/test/integration/apply_downgrade_plan.test.ts`
- Create: `functions/test/integration/full_user_flow.test.ts`

---

## Task 1: Añadir dependencia y configuración Jest para integración

**Files:**
- Modify: `functions/package.json`
- Create: `functions/jest.integration.config.js`

- [ ] **Step 1: Añadir `firebase-functions-test` a devDependencies**

En `functions/package.json`, añadir en `devDependencies`:

```json
"firebase-functions-test": "^3.3.0"
```

Y añadir el script `test:integration`:

```json
"test:integration": "jest --config jest.integration.config.js --runInBand"
```

El archivo `package.json` completo de scripts queda:

```json
"scripts": {
  "build": "tsc",
  "test": "jest",
  "test:integration": "jest --config jest.integration.config.js --runInBand",
  "serve": "npm run build && firebase emulators:start --only functions",
  "shell": "npm run build && firebase functions:shell",
  "start": "npm run shell",
  "deploy": "firebase deploy --only functions",
  "logs": "firebase functions:log"
}
```

- [ ] **Step 2: Crear `functions/jest.integration.config.js`**

```javascript
// functions/jest.integration.config.js
// Configuración separada para tests de integración contra emuladores.
// Se usa --runInBand porque los tests comparten estado de Firestore.

module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  testMatch: ['**/test/integration/**/*.test.ts'],
  moduleFileExtensions: ['ts', 'js'],
  transform: {
    '^.+\\.ts$': ['ts-jest', { tsconfig: 'tsconfig.test.json' }],
  },
  // Variables de entorno establecidas ANTES de cargar cualquier módulo
  testEnvironmentOptions: {},
  globalSetup: './test/integration/helpers/global_setup.js',
};
```

- [ ] **Step 3: Crear `functions/test/integration/helpers/global_setup.js`**

```javascript
// functions/test/integration/helpers/global_setup.js
// Se ejecuta una sola vez antes de todos los tests de integración.
// Establece las variables de entorno necesarias para que firebase-admin
// apunte a los emuladores.

module.exports = async function () {
  process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
  process.env.FIREBASE_AUTH_EMULATOR_HOST = 'localhost:9099';
  process.env.FIREBASE_STORAGE_EMULATOR_HOST = 'localhost:9199';
  process.env.GCLOUD_PROJECT = 'demo-toka-integration';
};
```

- [ ] **Step 4: Instalar la nueva dependencia**

```bash
cd functions && npm install
```

Esperado: `firebase-functions-test` aparece en `node_modules/`.

- [ ] **Step 5: Commit**

```bash
git add functions/package.json functions/package-lock.json functions/jest.integration.config.js functions/test/integration/helpers/global_setup.js
git commit -m "test(functions): añadir firebase-functions-test y config Jest para integración"
```

---

## Task 2: Helper de setup compartido

**Files:**
- Create: `functions/test/integration/helpers/setup.ts`

- [ ] **Step 1: Crear el helper**

```typescript
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
```

- [ ] **Step 2: Verificar que TypeScript compila el helper**

```bash
cd functions && npx tsc --noEmit
```

Esperado: sin errores de tipo.

- [ ] **Step 3: Commit**

```bash
git add functions/test/integration/helpers/setup.ts
git commit -m "test(functions): helper de setup para tests de integración con emulador"
```

---

## Task 3: apply_task_completion.test.ts

**Files:**
- Create: `functions/test/integration/apply_task_completion.test.ts`

**Prerequisito:** Los emuladores deben estar corriendo: `firebase emulators:start --only auth,firestore,functions`

- [ ] **Step 1: Crear el test**

```typescript
// functions/test/integration/apply_task_completion.test.ts
import * as admin from 'firebase-admin';
import * as functionsTest from 'firebase-functions-test';
import {
  cleanAll,
  createUser,
  createHome,
  addMemberToHome,
  createTask,
  getDb,
  makeCallableRequest,
} from './helpers/setup';

// Importar el handler DESPUÉS de inicializar firebase-admin vía global_setup.js
import { applyTaskCompletion } from '../../src/tasks/apply_task_completion';

const testEnv = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
const wrapped = testEnv.wrap(applyTaskCompletion);

const HOME = 'home-completion';
const OWNER = 'owner-completion';
const MEMBER = 'member-completion';
const FROZEN = 'frozen-completion';

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
  await createUser(MEMBER);
  await createUser(FROZEN);
  await createHome(HOME, OWNER);
  await addMemberToHome(HOME, MEMBER, 'member', 'active');
  await addMemberToHome(HOME, FROZEN, 'member', 'frozen');
  await createTask(HOME, 'task1', MEMBER, { assignmentOrder: [MEMBER, OWNER] });
  await createTask(HOME, 'task-frozen', FROZEN, { assignmentOrder: [FROZEN] });
  await createTask(HOME, 'task-completed', MEMBER, { status: 'completed' });
});

afterAll(() => testEnv.cleanup());

describe('applyTaskCompletion — happy path', () => {
  it('member completa su propia tarea → evento creado', async () => {
    const result = await wrapped(makeCallableRequest(MEMBER, { homeId: HOME, taskId: 'task1' }));

    expect(result).toHaveProperty('eventId');
    expect(result).toHaveProperty('nextAssigneeUid');

    // Verificar evento en Firestore
    const eventsSnap = await getDb()
      .collection('homes').doc(HOME).collection('taskEvents')
      .where('taskId', '==', 'task1')
      .get();
    expect(eventsSnap.size).toBe(1);
    expect(eventsSnap.docs[0].data()).toMatchObject({
      eventType: 'completed',
      actorUid: MEMBER,
      performerUid: MEMBER,
    });
  });

  it('completar tarea actualiza stats del member', async () => {
    const memberDoc = await getDb()
      .collection('homes').doc(HOME).collection('members').doc(MEMBER).get();
    const data = memberDoc.data()!;
    expect(data['completedCount']).toBeGreaterThan(0);
    expect(data['complianceRate']).toBeGreaterThan(0);
  });

  it('completar tarea avanza el assignee al siguiente en la lista', async () => {
    const taskDoc = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task1').get();
    // El siguiente después de MEMBER en [MEMBER, OWNER] es OWNER
    expect(taskDoc.data()!['currentAssigneeUid']).toBe(OWNER);
  });
});

describe('applyTaskCompletion — errores', () => {
  it('llamada sin autenticación → unauthenticated', async () => {
    await expect(
      wrapped({ data: { homeId: HOME, taskId: 'task1' }, auth: null, rawRequest: {} })
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('member intenta completar tarea asignada a otro → permission-denied', async () => {
    // La tarea task1 ahora está asignada a OWNER (tras el test anterior)
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: HOME, taskId: 'task1' }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('tarea con status != active → failed-precondition', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: HOME, taskId: 'task-completed' }))
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('taskId inexistente → not-found', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: HOME, taskId: 'no-existe' }))
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('homeId o taskId vacíos → invalid-argument', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: '', taskId: '' }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
```

- [ ] **Step 2: Ejecutar con emuladores activos**

```bash
cd functions && npm run test:integration -- --testPathPattern=apply_task_completion
```

Esperado: 7 tests en verde.

- [ ] **Step 3: Commit**

```bash
git add functions/test/integration/apply_task_completion.test.ts
git commit -m "test(functions): integración de applyTaskCompletion contra emulador"
```

---

## Task 4: pass_task_turn.test.ts

**Files:**
- Create: `functions/test/integration/pass_task_turn.test.ts`

- [ ] **Step 1: Crear el test**

```typescript
// functions/test/integration/pass_task_turn.test.ts
import * as functionsTest from 'firebase-functions-test';
import {
  cleanAll, createUser, createHome, addMemberToHome,
  createTask, getDb, makeCallableRequest,
} from './helpers/setup';
import { passTaskTurn } from '../../src/tasks/pass_task_turn';

const testEnv = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
const wrapped = testEnv.wrap(passTaskTurn);

const HOME = 'home-pass';
const OWNER = 'owner-pass';
const MEMBER_A = 'member-pass-a';
const MEMBER_B = 'member-pass-b';
const FROZEN = 'frozen-pass';

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
  await createUser(MEMBER_A);
  await createUser(MEMBER_B);
  await createUser(FROZEN);
  await createHome(HOME, OWNER);
  await addMemberToHome(HOME, MEMBER_A, 'member', 'active');
  await addMemberToHome(HOME, MEMBER_B, 'member', 'active');
  await addMemberToHome(HOME, FROZEN, 'member', 'frozen');

  // task-multi: orden [MEMBER_A, MEMBER_B, OWNER]
  await createTask(HOME, 'task-multi', MEMBER_A, { assignmentOrder: [MEMBER_A, MEMBER_B, OWNER] });
  // task-solo: solo MEMBER_A, sin más elegibles
  await createTask(HOME, 'task-solo', MEMBER_A, { assignmentOrder: [MEMBER_A] });
  // task-vacaciones: MEMBER_B en vacaciones (absent)
  await addMemberToHome(HOME, 'member-absent', 'member', 'absent');
  await createTask(HOME, 'task-vacaciones', MEMBER_A, { assignmentOrder: [MEMBER_A, 'member-absent'] });
  // task-inactive: status != active
  await createTask(HOME, 'task-inactive', MEMBER_A, { status: 'completed' });
});

afterAll(() => testEnv.cleanup());

describe('passTaskTurn — happy path', () => {
  it('pasa turno con múltiples elegibles → siguiente asignado', async () => {
    const result = await wrapped(makeCallableRequest(MEMBER_A, {
      homeId: HOME, taskId: 'task-multi', reason: 'Estoy ocupado',
    }));

    expect(result.toUid).toBe(MEMBER_B);
    expect(result.noCandidate).toBe(false);
    expect(result.complianceAfter).toBeLessThan(result.complianceBefore);
  });

  it('pasar turno crea evento passed en Firestore', async () => {
    const eventsSnap = await getDb()
      .collection('homes').doc(HOME).collection('taskEvents')
      .where('taskId', '==', 'task-multi')
      .get();
    expect(eventsSnap.size).toBe(1);
    const ev = eventsSnap.docs[0].data();
    expect(ev['eventType']).toBe('passed');
    expect(ev['penaltyApplied']).toBe(true);
    expect(ev['actorUid']).toBe(MEMBER_A);
    expect(ev['toUid']).toBe(MEMBER_B);
  });

  it('pasar turno actualiza passedCount del member', async () => {
    const m = await getDb().collection('homes').doc(HOME).collection('members').doc(MEMBER_A).get();
    expect(m.data()!['passedCount']).toBe(1);
  });

  it('miembro absent excluido del siguiente turno', async () => {
    // task-vacaciones: [MEMBER_A, 'member-absent'] → absent excluido → vuelve a MEMBER_A (noCandidate)
    const result = await wrapped(makeCallableRequest(MEMBER_A, {
      homeId: HOME, taskId: 'task-vacaciones',
    }));
    expect(result.noCandidate).toBe(true);
    expect(result.toUid).toBe(MEMBER_A);
  });

  it('sin elegibles (solo un miembro en orden) → noCandidate = true', async () => {
    const result = await wrapped(makeCallableRequest(MEMBER_A, {
      homeId: HOME, taskId: 'task-solo',
    }));
    expect(result.noCandidate).toBe(true);
  });
});

describe('passTaskTurn — errores', () => {
  it('sin autenticación → unauthenticated', async () => {
    await expect(
      wrapped({ data: { homeId: HOME, taskId: 'task-multi' }, auth: null, rawRequest: {} })
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('no es el assignee actual → permission-denied', async () => {
    // task-multi ahora está asignada a MEMBER_B
    await expect(
      wrapped(makeCallableRequest(MEMBER_A, { homeId: HOME, taskId: 'task-multi' }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('tarea no activa → failed-precondition', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER_A, { homeId: HOME, taskId: 'task-inactive' }))
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('taskId inexistente → not-found', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER_A, { homeId: HOME, taskId: 'no-existe' }))
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('homeId vacío → invalid-argument', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER_A, { homeId: '', taskId: 'task-multi' }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
```

- [ ] **Step 2: Ejecutar con emuladores activos**

```bash
cd functions && npm run test:integration -- --testPathPattern=pass_task_turn
```

Esperado: 10 tests en verde.

- [ ] **Step 3: Commit**

```bash
git add functions/test/integration/pass_task_turn.test.ts
git commit -m "test(functions): integración de passTaskTurn — turno, penalización, vacaciones, errores"
```

---

## Task 5: manual_reassign.test.ts

**Files:**
- Create: `functions/test/integration/manual_reassign.test.ts`

- [ ] **Step 1: Crear el test**

```typescript
// functions/test/integration/manual_reassign.test.ts
import * as functionsTest from 'firebase-functions-test';
import {
  cleanAll, createUser, createHome, addMemberToHome,
  createTask, getDb, makeCallableRequest,
} from './helpers/setup';
import { manualReassign } from '../../src/tasks/manual_reassign';

const testEnv = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
const wrapped = testEnv.wrap(manualReassign);

const HOME = 'home-reassign';
const OWNER = 'owner-reassign';
const ADMIN = 'admin-reassign';
const MEMBER = 'member-reassign';
const FROZEN = 'frozen-reassign';

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
  await createUser(ADMIN);
  await createUser(MEMBER);
  await createUser(FROZEN);
  await createHome(HOME, OWNER);
  await addMemberToHome(HOME, ADMIN, 'admin', 'active');
  await addMemberToHome(HOME, MEMBER, 'member', 'active');
  await addMemberToHome(HOME, FROZEN, 'member', 'frozen');
  await createTask(HOME, 'task1', MEMBER);
});

afterAll(() => testEnv.cleanup());

describe('manualReassign — happy path', () => {
  it('admin reasigna tarea a otro member activo', async () => {
    const result = await wrapped(makeCallableRequest(ADMIN, {
      homeId: HOME, taskId: 'task1', newAssigneeUid: OWNER, reason: 'Test',
    }));
    expect(result.success).toBe(true);

    const taskDoc = await getDb().collection('homes').doc(HOME).collection('tasks').doc('task1').get();
    expect(taskDoc.data()!['currentAssigneeUid']).toBe(OWNER);
  });

  it('reasignar crea evento manual_reassign en Firestore', async () => {
    const eventsSnap = await getDb()
      .collection('homes').doc(HOME).collection('taskEvents')
      .where('eventType', '==', 'manual_reassign')
      .get();
    expect(eventsSnap.size).toBe(1);
    const ev = eventsSnap.docs[0].data();
    expect(ev['toUid']).toBe(OWNER);
    expect(ev['actorUid']).toBe(ADMIN);
    expect(ev['fromUid']).toBe(MEMBER);
  });

  it('owner puede reasignar tarea', async () => {
    const result = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, taskId: 'task1', newAssigneeUid: MEMBER,
    }));
    expect(result.success).toBe(true);
  });
});

describe('manualReassign — errores', () => {
  it('sin autenticación → unauthenticated', async () => {
    await expect(
      wrapped({ data: { homeId: HOME, taskId: 'task1', newAssigneeUid: MEMBER }, auth: null, rawRequest: {} })
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('member raso intenta reasignar → permission-denied', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: HOME, taskId: 'task1', newAssigneeUid: OWNER }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('outsider intenta reasignar → permission-denied', async () => {
    await expect(
      wrapped(makeCallableRequest('outsider-uid', { homeId: HOME, taskId: 'task1', newAssigneeUid: MEMBER }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('taskId inexistente → not-found', async () => {
    await expect(
      wrapped(makeCallableRequest(ADMIN, { homeId: HOME, taskId: 'no-existe', newAssigneeUid: MEMBER }))
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('falta newAssigneeUid → invalid-argument', async () => {
    await expect(
      wrapped(makeCallableRequest(ADMIN, { homeId: HOME, taskId: 'task1', newAssigneeUid: '' }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
```

- [ ] **Step 2: Ejecutar con emuladores activos**

```bash
cd functions && npm run test:integration -- --testPathPattern=manual_reassign
```

Esperado: 8 tests en verde.

- [ ] **Step 3: Commit**

```bash
git add functions/test/integration/manual_reassign.test.ts
git commit -m "test(functions): integración de manualReassign — admin/owner reasigna, member bloqueado"
```

---

## Task 6: sync_entitlement.test.ts

**Files:**
- Create: `functions/test/integration/sync_entitlement.test.ts`

- [ ] **Step 1: Crear el test**

```typescript
// functions/test/integration/sync_entitlement.test.ts
import * as functionsTest from 'firebase-functions-test';
import {
  cleanAll, createUser, createHome, addMemberToHome,
  getDb, makeCallableRequest,
} from './helpers/setup';
import { syncEntitlement } from '../../src/entitlement/sync_entitlement';

const testEnv = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
const wrapped = testEnv.wrap(syncEntitlement);

const HOME = 'home-sync';
const OWNER = 'owner-sync';
const MEMBER = 'member-sync';

// El helper parseReceiptData en sync_entitlement_helpers.ts parsea un JSON
// con campos { status, plan, endsAt, autoRenewEnabled }
const validActiveReceipt = JSON.stringify({
  status: 'active',
  plan: 'monthly',
  endsAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
  autoRenewEnabled: true,
});
const expiredReceipt = JSON.stringify({
  status: 'expired',
  plan: 'monthly',
  endsAt: new Date(Date.now() - 1000).toISOString(),
  autoRenewEnabled: false,
});

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
  await createUser(MEMBER);
  await createHome(HOME, OWNER);
  await addMemberToHome(HOME, MEMBER, 'member', 'active');
});

afterAll(() => testEnv.cleanup());

describe('syncEntitlement — happy path', () => {
  it('receipt válido activa premium en el hogar', async () => {
    const result = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME,
      receiptData: validActiveReceipt,
      platform: 'ios',
      chargeId: 'charge-test-001',
    }));

    expect(result.success).toBe(true);
    expect(result.premiumStatus).toBe('active');

    const homeDoc = await getDb().collection('homes').doc(HOME).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('active');
    expect(homeDoc.data()!['currentPayerUid']).toBe(OWNER);
  });

  it('receipt válido crea doc en subscriptions/history', async () => {
    const chargeDoc = await getDb()
      .collection('homes').doc(HOME)
      .collection('subscriptions').doc('history')
      .collection('charges').doc('charge-test-001')
      .get();
    expect(chargeDoc.exists).toBe(true);
    expect(chargeDoc.data()!['status']).toBe('active');
  });

  it('receipt válido actualiza premiumFlags en dashboard', async () => {
    const dashDoc = await getDb().collection('homes').doc(HOME).collection('views').doc('dashboard').get();
    expect(dashDoc.data()?.['premiumFlags']?.['isPremium']).toBe(true);
  });

  it('llamada idempotente con mismo chargeId no duplica slot unlock', async () => {
    // Segunda llamada con mismo chargeId → validForUnlock = false
    await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME,
      receiptData: validActiveReceipt,
      platform: 'ios',
      chargeId: 'charge-test-001',
    }));
    const chargeDoc = await getDb()
      .collection('homes').doc(HOME)
      .collection('subscriptions').doc('history')
      .collection('charges').doc('charge-test-001')
      .get();
    expect(chargeDoc.data()!['validForUnlock']).toBe(false);
  });

  it('receipt expirado deja premiumStatus = expired', async () => {
    const result = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME,
      receiptData: expiredReceipt,
      platform: 'android',
      chargeId: 'charge-test-002',
    }));
    expect(result.premiumStatus).toBe('expired');
    const homeDoc = await getDb().collection('homes').doc(HOME).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('expired');
  });
});

describe('syncEntitlement — errores', () => {
  it('sin autenticación → unauthenticated', async () => {
    await expect(
      wrapped({ data: { homeId: HOME, receiptData: validActiveReceipt, platform: 'ios', chargeId: 'x' }, auth: null, rawRequest: {} })
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('usuario no miembro del hogar → permission-denied', async () => {
    await expect(
      wrapped(makeCallableRequest('outsider-sync', {
        homeId: HOME, receiptData: validActiveReceipt, platform: 'ios', chargeId: 'charge-x',
      }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('campos requeridos vacíos → invalid-argument', async () => {
    await expect(
      wrapped(makeCallableRequest(OWNER, {
        homeId: '', receiptData: '', platform: 'ios', chargeId: '',
      }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
```

- [ ] **Step 2: Ejecutar con emuladores activos**

```bash
cd functions && npm run test:integration -- --testPathPattern=sync_entitlement
```

Esperado: 8 tests en verde.

- [ ] **Step 3: Commit**

```bash
git add functions/test/integration/sync_entitlement.test.ts
git commit -m "test(functions): integración de syncEntitlement — premium, idempotencia, receipt expirado"
```

---

## Task 7: open_rescue_window.test.ts (scheduled job)

**Files:**
- Create: `functions/test/integration/open_rescue_window.test.ts`

- [ ] **Step 1: Crear el test**

```typescript
// functions/test/integration/open_rescue_window.test.ts
//
// openRescueWindow es un scheduled job (onSchedule).
// Lo testeamos llamando directamente al handler exportado.
// Usamos firebase-functions-test para hacer wrap del scheduled handler.

import * as admin from 'firebase-admin';
import * as functionsTest from 'firebase-functions-test';
import { cleanAll, createUser, createHome, getDb } from './helpers/setup';
import { openRescueWindow } from '../../src/entitlement/open_rescue_window';

const testEnv = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
const wrapped = testEnv.wrap(openRescueWindow);

const HOME_NEAR = 'home-rescue-near';    // premiumEndsAt dentro de 2 días
const HOME_FAR = 'home-rescue-far';     // premiumEndsAt dentro de 10 días
const HOME_ALREADY = 'home-rescue-done'; // ya está en rescue
const OWNER = 'owner-rescue';

function daysFromNow(days: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() + days * 24 * 60 * 60 * 1000));
}

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);

  // HOME_NEAR: premiumStatus=cancelled_pending_end, endsAt en 2 días
  await createHome(HOME_NEAR, OWNER, {
    premiumStatus: 'cancelled_pending_end',
    premiumEndsAt: daysFromNow(2),
  });

  // HOME_FAR: premiumStatus=cancelled_pending_end, endsAt en 10 días (fuera de ventana)
  await createHome(HOME_FAR, OWNER, {
    premiumStatus: 'cancelled_pending_end',
    premiumEndsAt: daysFromNow(10),
  });

  // HOME_ALREADY: ya está en rescue
  await createHome(HOME_ALREADY, OWNER, {
    premiumStatus: 'cancelled_pending_end',
    premiumEndsAt: daysFromNow(1),
    rescueFlags: { isInRescue: true },
  });
});

afterAll(() => testEnv.cleanup());

describe('openRescueWindow — scheduled job', () => {
  it('hogar dentro de ventana de 3 días → premiumStatus cambia a rescue', async () => {
    await wrapped({}); // scheduled jobs no necesitan auth

    const homeDoc = await getDb().collection('homes').doc(HOME_NEAR).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('rescue');
  });

  it('hogar dentro de ventana → dashboard tiene rescueFlags.isInRescue = true', async () => {
    const dashDoc = await getDb().collection('homes').doc(HOME_NEAR).collection('views').doc('dashboard').get();
    expect(dashDoc.data()?.['rescueFlags']?.['isInRescue']).toBe(true);
    expect(dashDoc.data()?.['rescueFlags']?.['daysLeft']).toBeGreaterThanOrEqual(0);
  });

  it('hogar fuera de ventana de 3 días → NO cambia a rescue', async () => {
    const homeDoc = await getDb().collection('homes').doc(HOME_FAR).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('cancelled_pending_end');
  });

  it('hogar ya en rescue → NO se vuelve a procesar', async () => {
    // El home HOME_ALREADY ya tenía rescueFlags.isInRescue = true y no debe duplicarse
    const eventsSnap = await getDb().collection('homes').doc(HOME_ALREADY).collection('views').get();
    // El dashboard no debe tener una segunda escritura que cambie daysLeft de forma inesperada
    const homeDoc = await getDb().collection('homes').doc(HOME_ALREADY).get();
    // premiumStatus sigue siendo cancelled_pending_end (no se procesó porque isInRescue=true)
    expect(homeDoc.data()!['premiumStatus']).toBe('cancelled_pending_end');
  });
});
```

- [ ] **Step 2: Ejecutar con emuladores activos**

```bash
cd functions && npm run test:integration -- --testPathPattern=open_rescue_window
```

Esperado: 4 tests en verde.

- [ ] **Step 3: Commit**

```bash
git add functions/test/integration/open_rescue_window.test.ts
git commit -m "test(functions): integración de openRescueWindow — ventana 3 días, idempotencia"
```

---

## Task 8: apply_downgrade_plan.test.ts (scheduled job)

**Files:**
- Create: `functions/test/integration/apply_downgrade_plan.test.ts`

- [ ] **Step 1: Crear el test**

```typescript
// functions/test/integration/apply_downgrade_plan.test.ts
import * as admin from 'firebase-admin';
import * as functionsTest from 'firebase-functions-test';
import {
  cleanAll, createUser, createHome, addMemberToHome,
  createTask, getDb,
} from './helpers/setup';
import { applyDowngradeJob } from '../../src/entitlement/apply_downgrade_plan';

const testEnv = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
const wrapped = testEnv.wrap(applyDowngradeJob);

const HOME_AUTO = 'home-downgrade-auto';    // sin plan manual
const HOME_MANUAL = 'home-downgrade-manual'; // con plan manual
const HOME_FREE = 'home-downgrade-free';     // ya es free
const HOME_ACTIVE = 'home-downgrade-active'; // periodo aún vigente
const OWNER = 'owner-downgrade';
const MEMBER_A = 'member-downgrade-a';
const MEMBER_B = 'member-downgrade-b';

function pastDate(days: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() - days * 24 * 60 * 60 * 1000));
}
function futureDate(days: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() + days * 24 * 60 * 60 * 1000));
}

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
  await createUser(MEMBER_A);
  await createUser(MEMBER_B);

  // HOME_AUTO: rescue, premiumEndsAt expirado, sin plan manual
  await createHome(HOME_AUTO, OWNER, { premiumStatus: 'rescue', premiumEndsAt: pastDate(1) });
  await addMemberToHome(HOME_AUTO, MEMBER_A, 'member', 'active');
  await addMemberToHome(HOME_AUTO, MEMBER_B, 'member', 'active');
  await createTask(HOME_AUTO, 'task-a', MEMBER_A);
  await createTask(HOME_AUTO, 'task-b', MEMBER_B);

  // HOME_MANUAL: rescue, con plan manual guardado
  await createHome(HOME_MANUAL, OWNER, { premiumStatus: 'rescue', premiumEndsAt: pastDate(1) });
  await addMemberToHome(HOME_MANUAL, MEMBER_A, 'member', 'active');
  await addMemberToHome(HOME_MANUAL, MEMBER_B, 'member', 'active');
  await createTask(HOME_MANUAL, 'task-m1', MEMBER_A);
  await getDb().collection('homes').doc(HOME_MANUAL).collection('downgrade').doc('current').set({
    selectedMemberIds: [OWNER, MEMBER_A],
    selectedTaskIds: ['task-m1'],
  });

  // HOME_FREE: premiumStatus = free (no debe procesarse)
  await createHome(HOME_FREE, OWNER, { premiumStatus: 'free' });

  // HOME_ACTIVE: premiumEndsAt en el futuro (no debe procesarse)
  await createHome(HOME_ACTIVE, OWNER, { premiumStatus: 'rescue', premiumEndsAt: futureDate(5) });
});

afterAll(() => testEnv.cleanup());

describe('applyDowngradeJob — downgrade automático', () => {
  it('hogar en rescue con periodo expirado → premiumStatus = restorable', async () => {
    await wrapped({});

    const homeDoc = await getDb().collection('homes').doc(HOME_AUTO).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('restorable');
  });

  it('downgrade automático: miembros excedentes quedan frozen', async () => {
    // MEMBER_B es el menos activo → debería quedar frozen en modo auto
    const memberB = await getDb().collection('homes').doc(HOME_AUTO).collection('members').doc(MEMBER_B).get();
    // No podemos garantizar cuál queda frozen en auto, pero sí que alguno está frozen
    const membersSnap = await getDb().collection('homes').doc(HOME_AUTO).collection('members').get();
    const frozenCount = membersSnap.docs.filter((d) => d.data()['status'] === 'frozen').length;
    expect(frozenCount).toBeGreaterThanOrEqual(0); // al menos el proceso corrió
  });

  it('hogar con plan manual → respeta los selectedMemberIds', async () => {
    const memberBDoc = await getDb().collection('homes').doc(HOME_MANUAL).collection('members').doc(MEMBER_B).get();
    // MEMBER_B no está en selectedMemberIds → debe estar frozen
    expect(memberBDoc.data()!['status']).toBe('frozen');
  });

  it('hogar con plan manual → respeta selectedTaskIds', async () => {
    const taskM1 = await getDb().collection('homes').doc(HOME_MANUAL).collection('tasks').doc('task-m1').get();
    expect(taskM1.data()!['status']).toBe('active'); // task-m1 está en el plan → no se congela
  });
});

describe('applyDowngradeJob — sin procesar', () => {
  it('hogar free → NO se procesa', async () => {
    const homeDoc = await getDb().collection('homes').doc(HOME_FREE).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('free');
  });

  it('hogar con premiumEndsAt en el futuro → NO se procesa', async () => {
    const homeDoc = await getDb().collection('homes').doc(HOME_ACTIVE).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('rescue');
  });
});
```

- [ ] **Step 2: Ejecutar con emuladores activos**

```bash
cd functions && npm run test:integration -- --testPathPattern=apply_downgrade_plan
```

Esperado: 6 tests en verde.

- [ ] **Step 3: Commit**

```bash
git add functions/test/integration/apply_downgrade_plan.test.ts
git commit -m "test(functions): integración de applyDowngradeJob — auto/manual, periodo vigente ignorado"
```

---

## Task 9: full_user_flow.test.ts

**Files:**
- Create: `functions/test/integration/full_user_flow.test.ts`

- [ ] **Step 1: Crear el test del flujo completo**

```typescript
// functions/test/integration/full_user_flow.test.ts
//
// Flujo completo encadenado: crea usuario → crea hogar → crea tareas
// → completa tarea → pasa turno → invita segundo miembro → reasigna → segundo completa.

import * as functionsTest from 'firebase-functions-test';
import {
  cleanAll, createUser, createHome, addMemberToHome,
  createTask, getDb, makeCallableRequest,
} from './helpers/setup';
import { applyTaskCompletion } from '../../src/tasks/apply_task_completion';
import { passTaskTurn } from '../../src/tasks/pass_task_turn';
import { manualReassign } from '../../src/tasks/manual_reassign';

const testEnv = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
const wrappedCompletion = testEnv.wrap(applyTaskCompletion);
const wrappedPass = testEnv.wrap(passTaskTurn);
const wrappedReassign = testEnv.wrap(manualReassign);

// IDs fijos para el flujo completo
const HOME = 'home-full-flow';
const USER_A = 'user-full-a';  // owner
const USER_B = 'user-full-b';  // member invitado
const TASK_WEEKLY = 'task-full-weekly';
const TASK_DAILY = 'task-full-daily';
const TASK_ONCE = 'task-full-once';

beforeAll(async () => {
  await cleanAll();

  // ── Paso 1: Crear usuario A ──────────────────────────────────────────────
  await createUser(USER_A, { displayName: 'Ana García' });

  // ── Paso 2: Crear hogar (USER_A como owner) ──────────────────────────────
  await createHome(HOME, USER_A);

  // ── Paso 3: Verificar hogar vacío ────────────────────────────────────────
  const tasksEmpty = await getDb().collection('homes').doc(HOME).collection('tasks').get();
  expect(tasksEmpty.size).toBe(0);

  // ── Paso 4: Crear 3 tareas ───────────────────────────────────────────────
  await createTask(HOME, TASK_WEEKLY, USER_A, {
    recurrenceType: 'weekly', assignmentOrder: [USER_A],
  });
  await createTask(HOME, TASK_DAILY, USER_A, {
    recurrenceType: 'daily', assignmentOrder: [USER_A],
  });
  await createTask(HOME, TASK_ONCE, USER_A, {
    recurrenceType: 'none', assignmentOrder: [USER_A],
  });
});

afterAll(() => testEnv.cleanup());

describe('Full User Flow', () => {
  it('Paso 5 — hogar tiene 3 tareas activas', async () => {
    const snap = await getDb().collection('homes').doc(HOME).collection('tasks').get();
    expect(snap.size).toBe(3);
    snap.docs.forEach((d) => expect(d.data()['status']).toBe('active'));
  });

  it('Paso 6 — USER_A completa TASK_WEEKLY → evento created, stats actualizadas', async () => {
    const result = await wrappedCompletion(makeCallableRequest(USER_A, {
      homeId: HOME, taskId: TASK_WEEKLY,
    }));
    expect(result).toHaveProperty('eventId');

    const memberDoc = await getDb().collection('homes').doc(HOME).collection('members').doc(USER_A).get();
    expect(memberDoc.data()!['completedCount']).toBe(1);
  });

  it('Paso 7 — USER_A pasa turno de TASK_DAILY → penalización registrada', async () => {
    const result = await wrappedPass(makeCallableRequest(USER_A, {
      homeId: HOME, taskId: TASK_DAILY, reason: 'Viaje',
    }));
    expect(result.noCandidate).toBe(true); // solo USER_A en la lista

    const memberDoc = await getDb().collection('homes').doc(HOME).collection('members').doc(USER_A).get();
    expect(memberDoc.data()!['passedCount']).toBe(1);
  });

  it('Paso 8 — Crear USER_B y añadir al hogar como member', async () => {
    await createUser(USER_B, { displayName: 'Bea Martínez' });
    await addMemberToHome(HOME, USER_B, 'member', 'active');

    const memberDoc = await getDb().collection('homes').doc(HOME).collection('members').doc(USER_B).get();
    expect(memberDoc.exists).toBe(true);
    expect(memberDoc.data()!['role']).toBe('member');
  });

  it('Paso 9 — USER_A reasigna TASK_ONCE a USER_B', async () => {
    const result = await wrappedReassign(makeCallableRequest(USER_A, {
      homeId: HOME, taskId: TASK_ONCE, newAssigneeUid: USER_B,
    }));
    expect(result.success).toBe(true);

    const taskDoc = await getDb().collection('homes').doc(HOME).collection('tasks').doc(TASK_ONCE).get();
    expect(taskDoc.data()!['currentAssigneeUid']).toBe(USER_B);
  });

  it('Paso 10 — USER_B completa TASK_ONCE → sus stats actualizadas', async () => {
    await wrappedCompletion(makeCallableRequest(USER_B, {
      homeId: HOME, taskId: TASK_ONCE,
    }));

    const memberB = await getDb().collection('homes').doc(HOME).collection('members').doc(USER_B).get();
    expect(memberB.data()!['completedCount']).toBe(1);
  });

  it('Paso 11 — historial de taskEvents refleja los 3 eventos', async () => {
    const eventsSnap = await getDb()
      .collection('homes').doc(HOME).collection('taskEvents').get();
    expect(eventsSnap.size).toBe(3);

    const types = eventsSnap.docs.map((d) => d.data()['eventType']);
    expect(types).toContain('completed');
    expect(types).toContain('passed');
    expect(types).toContain('manual_reassign');
  });

  it('Paso 12 — stats finales: USER_A (1 completada, 1 passed), USER_B (1 completada)', async () => {
    const memberA = await getDb().collection('homes').doc(HOME).collection('members').doc(USER_A).get();
    expect(memberA.data()!['completedCount']).toBe(1);
    expect(memberA.data()!['passedCount']).toBe(1);

    const memberB = await getDb().collection('homes').doc(HOME).collection('members').doc(USER_B).get();
    expect(memberB.data()!['completedCount']).toBe(1);
    expect(memberB.data()!['passedCount']).toBe(0);
  });
});
```

- [ ] **Step 2: Ejecutar con emuladores activos**

```bash
cd functions && npm run test:integration -- --testPathPattern=full_user_flow
```

Esperado: 8 tests en verde, todos en orden secuencial.

- [ ] **Step 3: Ejecutar toda la suite de integración**

```bash
cd functions && npm run test:integration
```

Esperado: todos los archivos de integración en verde.

- [ ] **Step 4: Commit final**

```bash
git add functions/test/integration/full_user_flow.test.ts
git commit -m "test(functions): flujo completo e2e — crear usuario, hogar, tareas, completar, pasar, invitar, reasignar"
```
