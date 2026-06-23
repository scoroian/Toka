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
const LEFT_UID = 'left1';
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
    // Ex-miembro: membership conservada con status:'left'.
    await setDoc(doc(db, `users/${LEFT_UID}/memberships/${HOME1}`), { status: 'left', role: 'member' });
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

  it('member LEFT (status:left) NO puede leer tarea (Hallazgo #01)', async () => {
    const ctx = testEnv.authenticatedContext(LEFT_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
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

// El ALTA de tareas pasó a ser EXCLUSIVAMENTE server-side vía la callable
// `createTask` (Hallazgo #14): el límite Free no eludible necesita contar
// documentos, algo imposible en reglas. Por eso `allow create: if false` para
// CUALQUIER cliente, incluido owner/admin. El enforcement de límites, rol y
// smartDistribution se prueba en test/integration/create_task.test.ts.
describe('tasks — create (siempre denegado en cliente — solo vía callable createTask)', () => {
  it('owner NO puede crear tarea directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task2`), validTask(HOME1, OWNER_UID)));
  });

  it('admin NO puede crear tarea directamente', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task3`), validTask(HOME1, ADMIN_UID)));
  });

  it('member raso activo NO puede crear tarea', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task4`), validTask(HOME1, MEMBER_UID)));
  });

  it('outsider autenticado NO puede crear tarea', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task6`), validTask(HOME1, OUTSIDER_UID)));
  });

  it('no autenticado NO puede crear tarea', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task7`), validTask(HOME1, OWNER_UID)));
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

  it('admin puede hacer soft-delete incluyendo deletedAt (auditoría)', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`), {
      status: 'deleted',
      deletedAt: serverTimestamp(),
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

// ─── SMART DISTRIBUTION (gate Premium) ───────────────────────────────────────

describe('tasks — smart distribution (gate Premium)', () => {
  const FREE = 'home_free_smart';
  const PREM = 'home_prem_smart';

  beforeEach(async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      const db = ctx.firestore();
      await setDoc(doc(db, `homes/${FREE}`), {
        ownerUid: OWNER_UID, name: 'Free', premiumStatus: 'free',
      });
      await setDoc(doc(db, `homes/${PREM}`), {
        ownerUid: OWNER_UID, name: 'Prem', premiumStatus: 'active',
      });
      await setDoc(doc(db, `users/${OWNER_UID}/memberships/${FREE}`), { status: 'active', role: 'owner' });
      await setDoc(doc(db, `users/${OWNER_UID}/memberships/${PREM}`), { status: 'active', role: 'owner' });
      // Contadores bajo el tope para que el gate Free de límites NO interfiera:
      // así el único motivo de fallo posible es el gate de smart distribution.
      await setDoc(doc(db, `homes/${FREE}/views/dashboard`), {
        planCounters: { activeTasks: 0, automaticRecurringTasks: 0, activeMembers: 1, totalAdmins: 1 },
      });
      // Tareas existentes en el home Free para los tests de update:
      // una smart (creada cuando el hogar era Premium, antes del downgrade) y una básica.
      await setDoc(doc(db, `homes/${FREE}/tasks/smart_existing`),
        validTask(FREE, OWNER_UID, { assignmentMode: 'smartDistribution' }));
      await setDoc(doc(db, `homes/${FREE}/tasks/basic_existing`),
        validTask(FREE, OWNER_UID, { assignmentMode: 'basicRotation' }));
      await setDoc(doc(db, `homes/${PREM}/tasks/prem_basic`),
        validTask(PREM, OWNER_UID, { assignmentMode: 'basicRotation' }));
    });
  });

  // El gate de smartDistribution en CREATE vive ahora en la callable
  // `createTask` (Hallazgo #14: create es server-side, ver
  // test/integration/create_task.test.ts). Aquí solo quedan los gates de
  // UPDATE, que siguen en reglas (`taskUpdateSmartAllowed`).
  it('Free NO puede CAMBIAR una tarea de básica a smart', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${FREE}/tasks/basic_existing`), {
      assignmentMode: 'smartDistribution',
      updatedAt: serverTimestamp(),
    }));
  });

  it('Free SÍ puede EDITAR (conservando smart) una tarea ya smart tras downgrade', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `homes/${FREE}/tasks/smart_existing`), {
      title: 'Editada tras downgrade',
      assignmentMode: 'smartDistribution',
      updatedAt: serverTimestamp(),
    }));
  });

  it('Free SÍ puede pasar una tarea smart a básica', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `homes/${FREE}/tasks/smart_existing`), {
      assignmentMode: 'basicRotation',
      updatedAt: serverTimestamp(),
    }));
  });

  it('Premium SÍ puede CAMBIAR una tarea de básica a smart', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `homes/${PREM}/tasks/prem_basic`), {
      assignmentMode: 'smartDistribution',
      updatedAt: serverTimestamp(),
    }));
  });
});
