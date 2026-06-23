// functions/test/integration/create_task.test.ts
//
// Enforcement server-side del límite Free de tareas (Hallazgo #14).
// Ejercita la callable REAL contra el emulador Firestore. El test clave es
// `concurrencia`: demuestra que una ráfaga de altas NO elude el límite (el
// bypass original vivía en que las reglas leían un contador denormalizado).

import * as admin from 'firebase-admin';
import {
  cleanAll,
  createUser,
  createHome,
  addMemberToHome,
  createTask as seedTask,
  getDb,
  makeCallableRequest,
} from './helpers/setup';
import { createTask } from '../../src/tasks/create_task';

const wrapped = (req: any): Promise<any> => (createTask as any).run(req);

const HOME = 'home-create';
const OWNER = 'owner-create';
const MEMBER = 'member-create';
const FROZEN = 'frozen-create';
const OUTSIDER = 'outsider-create';

function taskPayload(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    title: 'Tarea',
    description: null,
    visualKind: 'emoji',
    visualValue: '🧹',
    recurrenceType: 'daily',
    recurrenceRule: { kind: 'daily', every: 1, time: '09:00', timezone: 'Europe/Madrid' },
    assignmentMode: 'basicRotation',
    assignmentOrder: [OWNER],
    difficultyWeight: 1.0,
    onMissAssign: 'sameAssignee',
    nextDueAt: '2026-07-01T09:00:00.000Z',
    ...overrides,
  };
}

// Puntual (oneTime): cuenta como activa pero NO como recurrente automática.
// Útil para aislar el límite de 4 activas del límite de 3 recurrentes.
function oneTimePayload(overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return taskPayload({
    recurrenceType: 'oneTime',
    recurrenceRule: { kind: 'oneTime', date: '2026-07-01', time: '09:00', timezone: 'Europe/Madrid' },
    ...overrides,
  });
}

async function activeTaskCount(homeId: string): Promise<number> {
  const snap = await getDb()
    .collection('homes').doc(homeId).collection('tasks')
    .where('status', '==', 'active').get();
  return snap.size;
}

async function seedPeople(): Promise<void> {
  await createUser(OWNER);
  await createUser(MEMBER);
  await createUser(FROZEN);
  await createUser(OUTSIDER);
}

beforeEach(async () => {
  await cleanAll();
  await seedPeople();
});

describe('createTask — plan Free: límite de tareas activas', () => {
  beforeEach(async () => {
    await createHome(HOME, OWNER, { premiumStatus: 'free' });
    await addMemberToHome(HOME, MEMBER, 'member', 'active');
    await addMemberToHome(HOME, FROZEN, 'admin', 'frozen');
  });

  it('permite crear exactamente 4 tareas activas y rechaza la 5ª', async () => {
    // Puntuales para aislar el cupo de 4 activas del de 3 recurrentes.
    for (let i = 0; i < 4; i++) {
      const res = await wrapped(
        makeCallableRequest(OWNER, { homeId: HOME, task: oneTimePayload({ title: `T${i}` }) })
      );
      expect(res.taskId).toBeTruthy();
    }
    expect(await activeTaskCount(HOME)).toBe(4);

    await expect(
      wrapped(makeCallableRequest(OWNER, { homeId: HOME, task: oneTimePayload({ title: 'T5' }) }))
    ).rejects.toMatchObject({ code: 'failed-precondition', message: 'free_limit_tasks' });

    expect(await activeTaskCount(HOME)).toBe(4);
  });

  it('NO depende del contador denormalizado: rechaza aunque planCounters mienta', async () => {
    // Sembramos un dashboard con activeTasks=0 (obsoleto/falso) y 4 tareas reales.
    for (let i = 0; i < 4; i++) await seedTask(HOME, `real${i}`, OWNER);
    await getDb().collection('homes').doc(HOME).collection('views').doc('dashboard').set({
      planCounters: { activeTasks: 0, automaticRecurringTasks: 0, activeMembers: 1, totalAdmins: 1 },
    });

    await expect(
      wrapped(makeCallableRequest(OWNER, { homeId: HOME, task: taskPayload() }))
    ).rejects.toMatchObject({ code: 'failed-precondition', message: 'free_limit_tasks' });
  });

  it('una tarea congelada (frozen) no consume cupo: con 3 activas + 1 frozen permite crear la 4ª', async () => {
    for (let i = 0; i < 3; i++) await seedTask(HOME, `act${i}`, OWNER);
    await seedTask(HOME, 'froz', OWNER, { status: 'frozen' });

    const res = await wrapped(
      makeCallableRequest(OWNER, { homeId: HOME, task: oneTimePayload({ title: 'cuarta' }) })
    );
    expect(res.taskId).toBeTruthy();
    expect(await activeTaskCount(HOME)).toBe(4);
  });
});

describe('createTask — plan Free: límite de recurrentes automáticas', () => {
  beforeEach(async () => {
    await createHome(HOME, OWNER, { premiumStatus: 'free' });
  });

  it('rechaza la 4ª recurrente automática pero permite una puntual (oneTime)', async () => {
    for (let i = 0; i < 3; i++) {
      await seedTask(HOME, `rec${i}`, OWNER, { recurrenceType: 'daily' });
    }
    // 4ª recurrente → bloqueada
    await expect(
      wrapped(makeCallableRequest(OWNER, {
        homeId: HOME,
        task: taskPayload({ recurrenceType: 'weekly' }),
      }))
    ).rejects.toMatchObject({ code: 'failed-precondition', message: 'free_limit_recurring' });

    // puntual con 3 activas (<4) → permitida
    const res = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME,
      task: taskPayload({
        recurrenceType: 'oneTime',
        recurrenceRule: { kind: 'oneTime', date: '2026-07-01', time: '09:00', timezone: 'Europe/Madrid' },
      }),
    }));
    expect(res.taskId).toBeTruthy();
  });
});

describe('createTask — concurrencia (no eludible por ráfaga)', () => {
  beforeEach(async () => {
    await createHome(HOME, OWNER, { premiumStatus: 'free' });
  });

  it('8 altas en paralelo desde Free vacío → exactamente 4 activas, 4 rechazos', async () => {
    const attempts = Array.from({ length: 8 }, (_, i) =>
      wrapped(makeCallableRequest(OWNER, { homeId: HOME, task: oneTimePayload({ title: `burst${i}` }) }))
    );
    const results = await Promise.allSettled(attempts);
    const ok = results.filter((r) => r.status === 'fulfilled').length;
    const rejected = results.filter(
      (r) => r.status === 'rejected' &&
        (r.reason as { message?: string }).message === 'free_limit_tasks'
    ).length;

    expect(await activeTaskCount(HOME)).toBe(4);
    expect(ok).toBe(4);
    expect(rejected).toBe(4);
  });
});

describe('createTask — Premium ignora los límites', () => {
  beforeEach(async () => {
    await createHome(HOME, OWNER, { premiumStatus: 'active' });
  });

  it('con 10 tareas activas permite seguir creando', async () => {
    for (let i = 0; i < 10; i++) await seedTask(HOME, `p${i}`, OWNER);
    const res = await wrapped(makeCallableRequest(OWNER, { homeId: HOME, task: taskPayload() }));
    expect(res.taskId).toBeTruthy();
    expect(await activeTaskCount(HOME)).toBe(11);
  });

  it('permite smartDistribution', async () => {
    const res = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME,
      task: taskPayload({ assignmentMode: 'smartDistribution' }),
    }));
    expect(res.taskId).toBeTruthy();
  });
});

describe('createTask — autorización y validación', () => {
  beforeEach(async () => {
    await createHome(HOME, OWNER, { premiumStatus: 'free' });
    await addMemberToHome(HOME, MEMBER, 'member', 'active');
    await addMemberToHome(HOME, FROZEN, 'admin', 'frozen');
  });

  it('no autenticado → unauthenticated', async () => {
    await expect(
      wrapped({ data: { homeId: HOME, task: taskPayload() }, auth: null, rawRequest: {} })
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('outsider (no miembro) → permission-denied', async () => {
    await expect(
      wrapped(makeCallableRequest(OUTSIDER, { homeId: HOME, task: taskPayload() }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('member raso activo → permission-denied', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: HOME, task: taskPayload({ assignmentOrder: [MEMBER] }) }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('admin congelado (frozen) → permission-denied', async () => {
    await expect(
      wrapped(makeCallableRequest(FROZEN, { homeId: HOME, task: taskPayload({ assignmentOrder: [FROZEN] }) }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('smartDistribution en Free → permission-denied', async () => {
    await expect(
      wrapped(makeCallableRequest(OWNER, {
        homeId: HOME,
        task: taskPayload({ assignmentMode: 'smartDistribution' }),
      }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('título vacío → invalid-argument', async () => {
    await expect(
      wrapped(makeCallableRequest(OWNER, { homeId: HOME, task: taskPayload({ title: '   ' }) }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });

  it('nextDueAt inválido → invalid-argument', async () => {
    await expect(
      wrapped(makeCallableRequest(OWNER, { homeId: HOME, task: taskPayload({ nextDueAt: 'no-es-fecha' }) }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
