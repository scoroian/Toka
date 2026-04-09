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
