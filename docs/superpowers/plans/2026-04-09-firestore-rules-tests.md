# Firestore Rules Tests — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Cubrir con tests exhaustivos las 8 rutas de Firestore Rules que actualmente no tienen tests (tasks, taskEvents, members, invitations, memberTaskStats, downgrade, subscriptions/history, dashboard).

**Architecture:** Cada archivo de test sigue exactamente el mismo patrón que los existentes en `functions/test/rules/`: `initializeTestEnvironment` con `projectId` único, seed con `withSecurityRulesDisabled`, y `assertSucceeds`/`assertFails` por caso.

**Tech Stack:** Jest, `@firebase/rules-unit-testing` ^3.0.0, `firebase/firestore` (ya instalados).

---

## Archivos a crear

- `functions/test/rules/tasks.test.ts`
- `functions/test/rules/task_events.test.ts`
- `functions/test/rules/members.test.ts`
- `functions/test/rules/invitations.test.ts`
- `functions/test/rules/member_task_stats.test.ts`
- `functions/test/rules/downgrade.test.ts`
- `functions/test/rules/subscriptions.test.ts`
- `functions/test/rules/dashboard.test.ts`

---

## Task 1: tasks.test.ts

**Files:**
- Create: `functions/test/rules/tasks.test.ts`

- [ ] **Step 1: Crear el archivo de test**

```typescript
// functions/test/rules/tasks.test.ts
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
} from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const HOME1 = 'home1';
const OWNER_UID = 'owner1';
const ADMIN_UID = 'admin1';
const MEMBER_UID = 'member1';
const FROZEN_UID = 'frozen1';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-tasks-rules',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await setDoc(doc(db, `homes/${HOME1}`), { ownerUid: OWNER_UID, name: 'Test Home' });
    await setDoc(doc(db, `homes/${HOME1}/tasks/task1`), {
      title: 'Limpiar cocina',
      status: 'active',
      currentAssigneeUid: MEMBER_UID,
    });

    await setDoc(doc(db, `users/${OWNER_UID}/memberships/${HOME1}`), { status: 'active', role: 'owner' });
    await setDoc(doc(db, `users/${ADMIN_UID}/memberships/${HOME1}`), { status: 'active', role: 'admin' });
    await setDoc(doc(db, `users/${MEMBER_UID}/memberships/${HOME1}`), { status: 'active', role: 'member' });
    await setDoc(doc(db, `users/${FROZEN_UID}/memberships/${HOME1}`), { status: 'frozen', role: 'admin' });
    // OUTSIDER_UID sin membresía
  });
});

// ─── READ ──────────────────────────────────────────────────────────────────────

describe('tasks — read', () => {
  it('owner puede leer tarea', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });

  it('admin puede leer tarea', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });

  it('member activo puede leer tarea', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });

  it('member frozen puede leer tarea', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });

  it('outsider autenticado NO puede leer tarea', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });

  it('no autenticado NO puede leer tarea', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });
});

// ─── CREATE ────────────────────────────────────────────────────────────────────

describe('tasks — create', () => {
  const newTask = { title: 'Nueva tarea', status: 'active' };

  it('owner activo puede crear tarea', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task2`), newTask));
  });

  it('admin activo puede crear tarea', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task3`), newTask));
  });

  it('member raso activo NO puede crear tarea', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task4`), newTask));
  });

  it('admin frozen NO puede crear tarea', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task5`), newTask));
  });

  it('outsider autenticado NO puede crear tarea', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task6`), newTask));
  });

  it('no autenticado NO puede crear tarea', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task7`), newTask));
  });
});

// ─── UPDATE ────────────────────────────────────────────────────────────────────

describe('tasks — update', () => {
  const patch = { title: 'Título actualizado' };

  it('owner activo puede actualizar tarea', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`), patch));
  });

  it('admin activo puede actualizar tarea', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`), patch));
  });

  it('member raso activo NO puede actualizar tarea', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`), patch));
  });

  it('admin frozen NO puede actualizar tarea', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`), patch));
  });

  it('outsider autenticado NO puede actualizar tarea', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`), patch));
  });

  it('no autenticado NO puede actualizar tarea', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`), patch));
  });
});

// ─── DELETE (soft delete — nadie puede borrar físicamente) ─────────────────────

describe('tasks — delete (siempre denegado — soft delete via update)', () => {
  it('owner NO puede borrar tarea físicamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });

  it('admin NO puede borrar tarea físicamente', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });

  it('member NO puede borrar tarea físicamente', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });

  it('frozen NO puede borrar tarea físicamente', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });

  it('outsider NO puede borrar tarea físicamente', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });

  it('no autenticado NO puede borrar tarea físicamente', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });
});
```

- [ ] **Step 2: Ejecutar y verificar que pasan**

```bash
cd functions && npm test -- --testPathPattern=tasks.test
```

Esperado: 18 tests en verde.

- [ ] **Step 3: Commit**

```bash
git add functions/test/rules/tasks.test.ts
git commit -m "test(rules): cobertura exhaustiva de tasks — read/create/update/delete"
```

---

## Task 2: task_events.test.ts

**Files:**
- Create: `functions/test/rules/task_events.test.ts`

- [ ] **Step 1: Crear el archivo de test**

```typescript
// functions/test/rules/task_events.test.ts
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const HOME1 = 'home1';
const OWNER_UID = 'owner1';
const ADMIN_UID = 'admin1';
const MEMBER_UID = 'member1';
const FROZEN_UID = 'frozen1';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-taskevents-rules',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await setDoc(doc(db, `homes/${HOME1}`), { ownerUid: OWNER_UID });
    await setDoc(doc(db, `homes/${HOME1}/taskEvents/event1`), {
      eventType: 'completed',
      taskId: 'task1',
      performerUid: MEMBER_UID,
    });

    await setDoc(doc(db, `users/${OWNER_UID}/memberships/${HOME1}`), { status: 'active', role: 'owner' });
    await setDoc(doc(db, `users/${ADMIN_UID}/memberships/${HOME1}`), { status: 'active', role: 'admin' });
    await setDoc(doc(db, `users/${MEMBER_UID}/memberships/${HOME1}`), { status: 'active', role: 'member' });
    await setDoc(doc(db, `users/${FROZEN_UID}/memberships/${HOME1}`), { status: 'frozen', role: 'member' });
  });
});

// ─── READ ──────────────────────────────────────────────────────────────────────

describe('taskEvents — read', () => {
  it('owner puede leer taskEvent', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });

  it('admin puede leer taskEvent', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });

  it('member activo puede leer taskEvent', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });

  it('member frozen puede leer taskEvent', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });

  it('outsider autenticado NO puede leer taskEvent', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });

  it('no autenticado NO puede leer taskEvent', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });
});

// ─── WRITE (todos denegados — solo Functions) ───────────────────────────────────

describe('taskEvents — write (siempre denegado)', () => {
  const newEvent = { eventType: 'completed', taskId: 'task1' };

  it('owner NO puede crear taskEvent directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event2`), newEvent));
  });

  it('admin NO puede crear taskEvent directamente', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event3`), newEvent));
  });

  it('member NO puede crear taskEvent directamente', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event4`), newEvent));
  });

  it('owner NO puede actualizar taskEvent directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`), { note: 'edit' }));
  });

  it('owner NO puede borrar taskEvent directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });

  it('no autenticado NO puede escribir taskEvent', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event5`), newEvent));
  });
});
```

- [ ] **Step 2: Ejecutar y verificar que pasan**

```bash
cd functions && npm test -- --testPathPattern=task_events.test
```

Esperado: 12 tests en verde.

- [ ] **Step 3: Commit**

```bash
git add functions/test/rules/task_events.test.ts
git commit -m "test(rules): cobertura exhaustiva de taskEvents — read y write denegado"
```

---

## Task 3: members.test.ts

**Files:**
- Create: `functions/test/rules/members.test.ts`

- [ ] **Step 1: Crear el archivo de test**

```typescript
// functions/test/rules/members.test.ts
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const HOME1 = 'home1';
const OWNER_UID = 'owner1';
const ADMIN_UID = 'admin1';
const MEMBER_UID = 'member1';
const FROZEN_UID = 'frozen1';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-members-rules',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await setDoc(doc(db, `homes/${HOME1}`), { ownerUid: OWNER_UID });
    await setDoc(doc(db, `homes/${HOME1}/members/${OWNER_UID}`), {
      uid: OWNER_UID, role: 'owner', status: 'active',
      notificationPrefs: { taskReminders: true }, vacation: null,
    });
    await setDoc(doc(db, `homes/${HOME1}/members/${ADMIN_UID}`), {
      uid: ADMIN_UID, role: 'admin', status: 'active',
      notificationPrefs: { taskReminders: true }, vacation: null,
    });
    await setDoc(doc(db, `homes/${HOME1}/members/${MEMBER_UID}`), {
      uid: MEMBER_UID, role: 'member', status: 'active',
      notificationPrefs: { taskReminders: true }, vacation: null,
    });
    await setDoc(doc(db, `homes/${HOME1}/members/${FROZEN_UID}`), {
      uid: FROZEN_UID, role: 'member', status: 'frozen',
      notificationPrefs: { taskReminders: false }, vacation: null,
    });

    await setDoc(doc(db, `users/${OWNER_UID}/memberships/${HOME1}`), { status: 'active', role: 'owner' });
    await setDoc(doc(db, `users/${ADMIN_UID}/memberships/${HOME1}`), { status: 'active', role: 'admin' });
    await setDoc(doc(db, `users/${MEMBER_UID}/memberships/${HOME1}`), { status: 'active', role: 'member' });
    await setDoc(doc(db, `users/${FROZEN_UID}/memberships/${HOME1}`), { status: 'frozen', role: 'member' });
  });
});

// ─── READ ──────────────────────────────────────────────────────────────────────

describe('members — read', () => {
  it('owner puede leer cualquier member', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`)));
  });

  it('admin puede leer cualquier member', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`)));
  });

  it('member puede leer cualquier member del hogar', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${OWNER_UID}`)));
  });

  it('member frozen puede leer cualquier member', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${OWNER_UID}`)));
  });

  it('outsider autenticado NO puede leer members', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${OWNER_UID}`)));
  });

  it('no autenticado NO puede leer members', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${OWNER_UID}`)));
  });
});

// ─── UPDATE PROPIO (campos permitidos) ─────────────────────────────────────────

describe('members — update propio (campos permitidos)', () => {
  it('member puede actualizar solo notificationPrefs propias', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        notificationPrefs: { taskReminders: false },
      })
    );
  });

  it('member puede actualizar solo vacation propia', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        vacation: { start: '2026-05-01', end: '2026-05-10' },
      })
    );
  });

  it('member puede actualizar notificationPrefs + vacation juntos', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        notificationPrefs: { taskReminders: false },
        vacation: { start: '2026-06-01', end: '2026-06-10' },
      })
    );
  });
});

// ─── UPDATE PROPIO (campos prohibidos) ─────────────────────────────────────────

describe('members — update propio (campos prohibidos)', () => {
  it('member NO puede cambiar su propio role', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        role: 'admin',
      })
    );
  });

  it('member NO puede cambiar su propio status', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        status: 'active',
      })
    );
  });

  it('member NO puede cambiar su propio uid', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        uid: 'otro-uid',
      })
    );
  });

  it('member NO puede combinar campo permitido + campo prohibido', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        notificationPrefs: { taskReminders: false },
        role: 'admin',
      })
    );
  });

  it('member NO puede combinar vacation + campo prohibido', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        vacation: { start: '2026-06-01', end: '2026-06-10' },
        status: 'active',
      })
    );
  });
});

// ─── UPDATE DE OTRO MIEMBRO (siempre denegado via cliente) ─────────────────────

describe('members — update de otro miembro (siempre denegado)', () => {
  it('owner NO puede actualizar notificationPrefs de otro member via cliente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        notificationPrefs: { taskReminders: false },
      })
    );
  });

  it('admin NO puede actualizar notificationPrefs de otro member via cliente', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        notificationPrefs: { taskReminders: false },
      })
    );
  });

  it('member NO puede actualizar datos de otro member', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${ADMIN_UID}`), {
        notificationPrefs: { taskReminders: false },
      })
    );
  });
});

// ─── CREATE / DELETE (siempre denegados) ───────────────────────────────────────

describe('members — create/delete (siempre denegado)', () => {
  it('owner NO puede crear member directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/members/newuser`), { role: 'member', status: 'active' })
    );
  });

  it('owner NO puede borrar member directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`)));
  });

  it('admin NO puede crear member directamente', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/members/newuser2`), { role: 'member', status: 'active' })
    );
  });
});
```

- [ ] **Step 2: Ejecutar y verificar que pasan**

```bash
cd functions && npm test -- --testPathPattern=members.test
```

Esperado: 19 tests en verde.

- [ ] **Step 3: Commit**

```bash
git add functions/test/rules/members.test.ts
git commit -m "test(rules): cobertura exhaustiva de members — read, update campos permitidos/prohibidos, create/delete denegados"
```

---

## Task 4: invitations.test.ts

**Files:**
- Create: `functions/test/rules/invitations.test.ts`

- [ ] **Step 1: Crear el archivo de test**

```typescript
// functions/test/rules/invitations.test.ts
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const HOME1 = 'home1';
const OWNER_UID = 'owner1';
const ADMIN_UID = 'admin1';
const MEMBER_UID = 'member1';
const FROZEN_UID = 'frozen1';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-invitations-rules',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await setDoc(doc(db, `homes/${HOME1}`), { ownerUid: OWNER_UID });
    // Invitación con code (lectura pública habilitada)
    await setDoc(doc(db, `homes/${HOME1}/invitations/inv1`), {
      code: 'ABC123',
      expiresAt: new Date(Date.now() + 86400000),
      createdBy: OWNER_UID,
    });
    // Invitación sin code
    await setDoc(doc(db, `homes/${HOME1}/invitations/inv2`), {
      expiresAt: new Date(Date.now() + 86400000),
      createdBy: OWNER_UID,
    });

    await setDoc(doc(db, `users/${OWNER_UID}/memberships/${HOME1}`), { status: 'active', role: 'owner' });
    await setDoc(doc(db, `users/${ADMIN_UID}/memberships/${HOME1}`), { status: 'active', role: 'admin' });
    await setDoc(doc(db, `users/${MEMBER_UID}/memberships/${HOME1}`), { status: 'active', role: 'member' });
    await setDoc(doc(db, `users/${FROZEN_UID}/memberships/${HOME1}`), { status: 'frozen', role: 'admin' });
  });
});

// ─── READ ──────────────────────────────────────────────────────────────────────

describe('invitations — read por admin/owner', () => {
  it('owner puede leer invitación', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });

  it('admin puede leer invitación', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });

  it('member raso NO puede leer invitación (sin code visible)', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv2`)));
  });
});

describe('invitations — read público por code', () => {
  it('outsider autenticado puede leer invitación que tiene code', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });

  it('outsider autenticado NO puede leer invitación sin code', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv2`)));
  });

  it('no autenticado NO puede leer invitación', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });
});

// ─── CREATE ────────────────────────────────────────────────────────────────────

describe('invitations — create', () => {
  const newInv = { code: 'XYZ789', createdBy: OWNER_UID };

  it('owner puede crear invitación', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(setDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv3`), newInv));
  });

  it('admin puede crear invitación', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(setDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv4`), newInv));
  });

  it('member raso NO puede crear invitación', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv5`), newInv));
  });

  it('admin frozen NO puede crear invitación', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv6`), newInv));
  });

  it('outsider NO puede crear invitación', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv7`), newInv));
  });

  it('no autenticado NO puede crear invitación', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv8`), newInv));
  });
});

// ─── UPDATE ────────────────────────────────────────────────────────────────────

describe('invitations — update', () => {
  it('owner puede actualizar invitación', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`), { used: true }));
  });

  it('admin puede actualizar invitación', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`), { used: true }));
  });

  it('member raso NO puede actualizar invitación', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`), { used: true }));
  });

  it('outsider NO puede actualizar invitación', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`), { used: true }));
  });
});

// ─── DELETE ────────────────────────────────────────────────────────────────────

describe('invitations — delete', () => {
  it('owner puede eliminar invitación', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });

  it('admin puede eliminar invitación', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv2`)));
  });

  it('member raso NO puede eliminar invitación', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });

  it('outsider NO puede eliminar invitación', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });

  it('no autenticado NO puede eliminar invitación', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });
});
```

- [ ] **Step 2: Ejecutar y verificar que pasan**

```bash
cd functions && npm test -- --testPathPattern=invitations.test
```

Esperado: 21 tests en verde.

- [ ] **Step 3: Commit**

```bash
git add functions/test/rules/invitations.test.ts
git commit -m "test(rules): cobertura exhaustiva de invitations — read público/admin, create/update/delete"
```

---

## Task 5: member_task_stats.test.ts

**Files:**
- Create: `functions/test/rules/member_task_stats.test.ts`

- [ ] **Step 1: Crear el archivo de test**

```typescript
// functions/test/rules/member_task_stats.test.ts
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const HOME1 = 'home1';
const OWNER_UID = 'owner1';
const ADMIN_UID = 'admin1';
const MEMBER_UID = 'member1';
const FROZEN_UID = 'frozen1';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-stats-rules',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await setDoc(doc(db, `homes/${HOME1}`), { ownerUid: OWNER_UID });
    await setDoc(doc(db, `homes/${HOME1}/memberTaskStats/stat1`), {
      memberUid: MEMBER_UID, completedCount: 5, passedCount: 1,
    });

    await setDoc(doc(db, `users/${OWNER_UID}/memberships/${HOME1}`), { status: 'active', role: 'owner' });
    await setDoc(doc(db, `users/${ADMIN_UID}/memberships/${HOME1}`), { status: 'active', role: 'admin' });
    await setDoc(doc(db, `users/${MEMBER_UID}/memberships/${HOME1}`), { status: 'active', role: 'member' });
    await setDoc(doc(db, `users/${FROZEN_UID}/memberships/${HOME1}`), { status: 'frozen', role: 'member' });
  });
});

describe('memberTaskStats — read', () => {
  it('owner puede leer stats', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/memberTaskStats/stat1`)));
  });

  it('admin puede leer stats', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/memberTaskStats/stat1`)));
  });

  it('member activo puede leer stats', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/memberTaskStats/stat1`)));
  });

  it('member frozen puede leer stats', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/memberTaskStats/stat1`)));
  });

  it('outsider autenticado NO puede leer stats', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/memberTaskStats/stat1`)));
  });

  it('no autenticado NO puede leer stats', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/memberTaskStats/stat1`)));
  });
});

describe('memberTaskStats — write (siempre denegado)', () => {
  it('owner NO puede escribir stats directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/memberTaskStats/stat2`), { completedCount: 0 }));
  });

  it('admin NO puede escribir stats directamente', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/memberTaskStats/stat1`), { completedCount: 99 }));
  });

  it('member NO puede escribir stats directamente', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/memberTaskStats/stat1`)));
  });

  it('no autenticado NO puede escribir stats', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/memberTaskStats/stat3`), { completedCount: 0 }));
  });
});
```

- [ ] **Step 2: Ejecutar y verificar que pasan**

```bash
cd functions && npm test -- --testPathPattern=member_task_stats.test
```

Esperado: 10 tests en verde.

- [ ] **Step 3: Commit**

```bash
git add functions/test/rules/member_task_stats.test.ts
git commit -m "test(rules): cobertura exhaustiva de memberTaskStats — read miembros, write denegado"
```

---

## Task 6: downgrade.test.ts

**Files:**
- Create: `functions/test/rules/downgrade.test.ts`

- [ ] **Step 1: Crear el archivo de test**

```typescript
// functions/test/rules/downgrade.test.ts
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const HOME1 = 'home1';
const OWNER_UID = 'owner1';
const ADMIN_UID = 'admin1';
const MEMBER_UID = 'member1';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-downgrade-rules',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await setDoc(doc(db, `homes/${HOME1}`), { ownerUid: OWNER_UID });
    await setDoc(doc(db, `homes/${HOME1}/downgrade/current`), {
      selectedMemberIds: [OWNER_UID],
      selectedTaskIds: [],
    });

    await setDoc(doc(db, `users/${OWNER_UID}/memberships/${HOME1}`), { status: 'active', role: 'owner' });
    await setDoc(doc(db, `users/${ADMIN_UID}/memberships/${HOME1}`), { status: 'active', role: 'admin' });
    await setDoc(doc(db, `users/${MEMBER_UID}/memberships/${HOME1}`), { status: 'active', role: 'member' });
  });
});

describe('downgrade/current — read', () => {
  it('owner puede leer el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`)));
  });

  it('admin NO puede leer el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`)));
  });

  it('member raso NO puede leer el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`)));
  });

  it('outsider autenticado NO puede leer el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`)));
  });

  it('no autenticado NO puede leer el plan de downgrade', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`)));
  });
});

describe('downgrade/current — write', () => {
  const plan = { selectedMemberIds: ['owner1'], selectedTaskIds: ['task1'] };

  it('owner puede escribir el plan de downgrade manual', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(setDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`), plan));
  });

  it('owner puede actualizar el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`), { selectedTaskIds: [] }));
  });

  it('admin NO puede escribir el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`), plan));
  });

  it('member raso NO puede escribir el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`), plan));
  });

  it('outsider NO puede escribir el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`), plan));
  });

  it('no autenticado NO puede escribir el plan de downgrade', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`), plan));
  });
});
```

- [ ] **Step 2: Ejecutar y verificar que pasan**

```bash
cd functions && npm test -- --testPathPattern=downgrade.test
```

Esperado: 11 tests en verde.

- [ ] **Step 3: Commit**

```bash
git add functions/test/rules/downgrade.test.ts
git commit -m "test(rules): cobertura exhaustiva de downgrade/current — solo owner puede leer y escribir"
```

---

## Task 7: subscriptions.test.ts

**Files:**
- Create: `functions/test/rules/subscriptions.test.ts`

- [ ] **Step 1: Crear el archivo de test**

```typescript
// functions/test/rules/subscriptions.test.ts
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const HOME1 = 'home1';
const OWNER_UID = 'owner1';
const CURRENT_PAYER_UID = 'payer1';
const FORMER_PAYER_UID = 'former1';
const PLAIN_MEMBER_UID = 'member1';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-subscriptions-rules',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await setDoc(doc(db, `homes/${HOME1}`), { ownerUid: OWNER_UID });
    await setDoc(doc(db, `homes/${HOME1}/subscriptions/history/charge1`), {
      chargeId: 'charge1',
      plan: 'monthly',
      amount: 4.99,
    });

    await setDoc(doc(db, `users/${OWNER_UID}/memberships/${HOME1}`), {
      status: 'active', role: 'owner', billingState: 'currentPayer',
    });
    await setDoc(doc(db, `users/${CURRENT_PAYER_UID}/memberships/${HOME1}`), {
      status: 'active', role: 'admin', billingState: 'currentPayer',
    });
    await setDoc(doc(db, `users/${FORMER_PAYER_UID}/memberships/${HOME1}`), {
      status: 'active', role: 'member', billingState: 'formerPayer',
    });
    await setDoc(doc(db, `users/${PLAIN_MEMBER_UID}/memberships/${HOME1}`), {
      status: 'active', role: 'member', billingState: 'none',
    });
  });
});

// ─── READ ──────────────────────────────────────────────────────────────────────

describe('subscriptions/history — read', () => {
  it('miembro con billingState currentPayer puede leer historial de cargos', async () => {
    const ctx = testEnv.authenticatedContext(CURRENT_PAYER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge1`)));
  });

  it('miembro con billingState formerPayer puede leer historial de cargos', async () => {
    const ctx = testEnv.authenticatedContext(FORMER_PAYER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge1`)));
  });

  it('owner con billingState currentPayer puede leer historial de cargos', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge1`)));
  });

  it('miembro con billingState none NO puede leer historial de cargos', async () => {
    const ctx = testEnv.authenticatedContext(PLAIN_MEMBER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge1`)));
  });

  it('outsider autenticado NO puede leer historial de cargos', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge1`)));
  });

  it('no autenticado NO puede leer historial de cargos', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge1`)));
  });
});

// ─── WRITE (todos denegados) ───────────────────────────────────────────────────

describe('subscriptions/history — write (siempre denegado)', () => {
  it('currentPayer NO puede escribir historial directamente', async () => {
    const ctx = testEnv.authenticatedContext(CURRENT_PAYER_UID);
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge2`), {
        chargeId: 'charge2', plan: 'monthly',
      })
    );
  });

  it('owner NO puede escribir historial directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge3`), {
        chargeId: 'charge3', plan: 'annual',
      })
    );
  });

  it('no autenticado NO puede escribir historial', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/subscriptions/history/charge4`), {
        chargeId: 'charge4', plan: 'monthly',
      })
    );
  });
});
```

- [ ] **Step 2: Ejecutar y verificar que pasan**

```bash
cd functions && npm test -- --testPathPattern=subscriptions.test
```

Esperado: 9 tests en verde.

- [ ] **Step 3: Commit**

```bash
git add functions/test/rules/subscriptions.test.ts
git commit -m "test(rules): cobertura exhaustiva de subscriptions/history — currentPayer y formerPayer"
```

---

## Task 8: dashboard.test.ts

**Files:**
- Create: `functions/test/rules/dashboard.test.ts`

- [ ] **Step 1: Crear el archivo de test**

```typescript
// functions/test/rules/dashboard.test.ts
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const HOME1 = 'home1';
const OWNER_UID = 'owner1';
const ADMIN_UID = 'admin1';
const MEMBER_UID = 'member1';
const FROZEN_UID = 'frozen1';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-dashboard-rules',
    firestore: {
      rules: readFileSync(path.resolve(__dirname, '../../../firestore.rules'), 'utf8'),
      host: 'localhost',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();

  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();

    await setDoc(doc(db, `homes/${HOME1}`), { ownerUid: OWNER_UID });
    await setDoc(doc(db, `homes/${HOME1}/views/dashboard`), {
      tasksTodo: 3, tasksDone: 1,
      premiumFlags: { isPremium: false },
    });

    await setDoc(doc(db, `users/${OWNER_UID}/memberships/${HOME1}`), { status: 'active', role: 'owner' });
    await setDoc(doc(db, `users/${ADMIN_UID}/memberships/${HOME1}`), { status: 'active', role: 'admin' });
    await setDoc(doc(db, `users/${MEMBER_UID}/memberships/${HOME1}`), { status: 'active', role: 'member' });
    await setDoc(doc(db, `users/${FROZEN_UID}/memberships/${HOME1}`), { status: 'frozen', role: 'member' });
  });
});

describe('views/dashboard — read', () => {
  it('owner puede leer dashboard', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`)));
  });

  it('admin puede leer dashboard', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`)));
  });

  it('member activo puede leer dashboard', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`)));
  });

  it('member frozen puede leer dashboard', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`)));
  });

  it('outsider autenticado NO puede leer dashboard', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`)));
  });

  it('no autenticado NO puede leer dashboard', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`)));
  });
});

describe('views/dashboard — write (siempre denegado)', () => {
  it('owner NO puede escribir dashboard directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`), { tasksTodo: 99 }));
  });

  it('admin NO puede escribir dashboard directamente', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`), { tasksTodo: 0 }));
  });

  it('member NO puede escribir dashboard directamente', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`), { tasksTodo: 0 }));
  });

  it('no autenticado NO puede escribir dashboard directamente', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`), { tasksTodo: 0 }));
  });
});
```

- [ ] **Step 2: Ejecutar y verificar que pasan**

```bash
cd functions && npm test -- --testPathPattern=dashboard.test
```

Esperado: 10 tests en verde.

- [ ] **Step 3: Ejecutar todos los tests de rules juntos**

```bash
cd functions && npm test -- --testPathPattern=test/rules
```

Esperado: todos los archivos de rules en verde (los 8 nuevos + los 4 existentes).

- [ ] **Step 4: Commit final**

```bash
git add functions/test/rules/dashboard.test.ts
git commit -m "test(rules): cobertura exhaustiva de views/dashboard — read miembros, write denegado"
```
