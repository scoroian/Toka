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
  serverTimestamp,
  Timestamp,
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

function validTask(homeId = HOME1, createdByUid = OWNER_UID, overrides: Record<string, unknown> = {}) {
  return {
    homeId,
    title: 'Limpiar cocina',
    description: 'Pasar escoba y fregar',
    visualKind: 'emoji',
    visualValue: '🧹',
    status: 'active',
    recurrenceType: 'daily',
    recurrenceRule: {
      type: 'daily',
      every: 1,
      time: '09:00',
      timezone: 'Europe/Madrid',
    },
    assignmentMode: 'basicRotation',
    assignmentOrder: [OWNER_UID, MEMBER_UID],
    currentAssigneeUid: OWNER_UID,
    nextDueAt: Timestamp.fromDate(new Date('2026-04-28T09:00:00.000Z')),
    difficultyWeight: 1,
    completedCount90d: 0,
    createdByUid,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
    onMissAssign: 'sameAssignee',
    ...overrides,
  };
}

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

    // premiumStatus='active' para no activar gates Free en los tests base.
    await setDoc(doc(db, `homes/${HOME1}`), {
      ownerUid: OWNER_UID,
      name: 'Test Home',
      premiumStatus: 'active',
    });
    await setDoc(doc(db, `homes/${HOME1}/tasks/task1`), validTask());

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
  it('owner activo puede crear tarea válida', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task2`), validTask(HOME1, OWNER_UID)));
  });

  it('admin activo puede crear tarea válida', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task3`), validTask(HOME1, ADMIN_UID)));
  });

  it('member raso activo NO puede crear tarea', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task4`), validTask(HOME1, MEMBER_UID)));
  });

  it('admin frozen NO puede crear tarea', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task5`), validTask(HOME1, FROZEN_UID)));
  });

  it('outsider autenticado NO puede crear tarea', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task6`), validTask(HOME1, OUTSIDER_UID)));
  });

  it('no autenticado NO puede crear tarea', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task7`), validTask(HOME1, OWNER_UID)));
  });

  it('admin NO puede crear tarea con completedCount90d distinto de cero', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task_bad_counter`),
      validTask(HOME1, ADMIN_UID, { completedCount90d: 10 })));
  });

  it('admin NO puede crear tarea con homeId distinto al path', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task_bad_home`),
      validTask('other-home', ADMIN_UID)));
  });

  it('admin NO puede crear tarea declarando otro createdByUid', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task_bad_creator`),
      validTask(HOME1, OWNER_UID)));
  });
});

// ─── UPDATE ────────────────────────────────────────────────────────────────────

describe('tasks — update', () => {
  const patch = { title: 'Título actualizado', updatedAt: serverTimestamp() };

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

  it('admin NO puede modificar completedCount90d desde cliente', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`), {
      completedCount90d: 999,
      updatedAt: serverTimestamp(),
    }));
  });

  it('admin NO puede modificar createdByUid desde cliente', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`), {
      createdByUid: ADMIN_UID,
      updatedAt: serverTimestamp(),
    }));
  });

  it('admin puede hacer soft-delete con status=deleted', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`), {
      status: 'deleted',
      updatedAt: serverTimestamp(),
    }));
  });

  it('admin NO puede escribir estado desconocido', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`), {
      status: 'completedOneTime',
      updatedAt: serverTimestamp(),
    }));
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

// ─── FREE LIMITS ───────────────────────────────────────────────────────────────

describe('tasks — create (Free plan limits)', () => {
  const FREE_HOME = 'home_free';

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, `homes/${FREE_HOME}`), {
        ownerUid: OWNER_UID,
        name: 'Free Home',
        premiumStatus: 'free',
      });
      await setDoc(
        doc(db, `users/${OWNER_UID}/memberships/${FREE_HOME}`),
        { status: 'active', role: 'owner' },
      );
    });
  });

  it('Free: permite crear puntual cuando activeTasks=3 y oneTime', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), `homes/${FREE_HOME}/views/dashboard`),
        {
          planCounters: {
            activeTasks: 3,
            automaticRecurringTasks: 3,
            activeMembers: 1,
            totalAdmins: 1,
          },
        },
      );
    });
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      setDoc(doc(ctx.firestore(), `homes/${FREE_HOME}/tasks/t_ot`),
        validTask(FREE_HOME, OWNER_UID, {
          recurrenceType: 'oneTime',
          recurrenceRule: { kind: 'oneTime', date: '2026-04-28', time: '09:00', timezone: 'Europe/Madrid' },
        })),
    );
  });

  it('Free: bloquea crear cuando activeTasks ya es 4', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), `homes/${FREE_HOME}/views/dashboard`),
        {
          planCounters: {
            activeTasks: 4,
            automaticRecurringTasks: 1,
            activeMembers: 1,
            totalAdmins: 1,
          },
        },
      );
    });
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${FREE_HOME}/tasks/t_fail`),
        validTask(FREE_HOME, OWNER_UID, {
          recurrenceType: 'oneTime',
          recurrenceRule: { kind: 'oneTime', date: '2026-04-28', time: '09:00', timezone: 'Europe/Madrid' },
        })),
    );
  });

  it('Free: bloquea crear recurrente cuando automaticRecurringTasks=3', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(
        doc(ctx.firestore(), `homes/${FREE_HOME}/views/dashboard`),
        {
          planCounters: {
            activeTasks: 3,
            automaticRecurringTasks: 3,
            activeMembers: 1,
            totalAdmins: 1,
          },
        },
      );
    });
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${FREE_HOME}/tasks/t_rec`),
        validTask(FREE_HOME, OWNER_UID, {
          recurrenceRule: { kind: 'daily', every: 1, time: '09:00', timezone: 'Europe/Madrid' },
        })),
    );
  });

  it('Premium: ignora los contadores aunque estén al tope', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, `homes/${FREE_HOME}`), {
        ownerUid: OWNER_UID,
        name: 'Premium Home',
        premiumStatus: 'active',
      });
      await setDoc(doc(db, `homes/${FREE_HOME}/views/dashboard`), {
        planCounters: {
          activeTasks: 99,
          automaticRecurringTasks: 99,
          activeMembers: 1,
          totalAdmins: 1,
        },
      });
    });
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(
      setDoc(doc(ctx.firestore(), `homes/${FREE_HOME}/tasks/t_premium`),
        validTask(FREE_HOME, OWNER_UID, {
          recurrenceType: 'weekly',
          recurrenceRule: { kind: 'weekly', weekdays: ['MON'], time: '09:00', timezone: 'Europe/Madrid' },
        })),
    );
  });
});
