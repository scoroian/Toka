// functions/test/integration/vacation_reassign.test.ts
//
// Hallazgo #09 (Vacaciones penaliza a los ausentes). Dos propiedades:
//   (B) El cron `processExpiredTasks` NO debe penalizar al responsable que está
//       de vacaciones; en su lugar rueda la tarea hacia un miembro presente.
//   (A) Al iniciar la vacación, el helper de reasignación mueve las tareas
//       activas del ausente a un presente MANTENIÉNDOLO en assignmentOrder
//       (vuelve a la rotación al regresar).
// Requiere emuladores Firebase.

import * as admin from 'firebase-admin';
import {
  cleanAll,
  createUser,
  createHome,
  addMemberToHome,
  createTask,
  getDb,
} from './helpers/setup';
import { processExpiredTasks } from '../../src/jobs/process_expired_tasks';
import {
  reassignActiveTasksForAbsentMember,
  onMemberVacationStart,
} from '../../src/tasks/vacation_reassign';

const runCron = (): Promise<any> => (processExpiredTasks as any).run({});

/** Invoca el handler del trigger con before/after simulados. */
const runVacationTrigger = (
  homeId: string,
  memberId: string,
  before: Record<string, unknown> | undefined,
  after: Record<string, unknown> | undefined
): Promise<any> =>
  (onMemberVacationStart as any).run({
    params: { homeId, memberId },
    data: {
      before: { data: () => before },
      after: { data: () => after },
    },
  });

function pastTs(days: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - days * 24 * 60 * 60 * 1000)
  );
}

/** Objeto `vacation` activo que cubre HOY (start ayer, sin fin). */
function activeVacation(): Record<string, unknown> {
  return {
    isActive: true,
    startDate: pastTs(1),
    endDate: null,
    reason: 'QA09',
    createdAt: pastTs(1),
  };
}

// ── Parte B: el cron no penaliza a un responsable ausente ─────────────────────
describe('processExpiredTasks — no penaliza al responsable de vacaciones (#09)', () => {
  const HOME = 'home-vac-cron';
  const OWNER = 'owner-vac';
  const ABSENT = 'absent-vac'; // de vacaciones, responsable de la tarea vencida
  const PRESENT = 'present-vac'; // activo, debe heredar la tarea

  beforeAll(async () => {
    await cleanAll();
    await createUser(OWNER);
    await createUser(ABSENT);
    await createUser(PRESENT);
    await createHome(HOME, OWNER, { premiumStatus: 'premium' });
    // ABSENT sigue siendo status 'active' (las rules no dejan denormalizar
    // 'absent'); la ausencia EFECTIVA la marca el campo `vacation`.
    await addMemberToHome(HOME, ABSENT, 'member', 'active', {
      vacation: activeVacation(),
      completedCount: 4,
      complianceRate: 1.0,
      missedCount: 0,
    });
    await addMemberToHome(HOME, PRESENT, 'member', 'active');
    // Tarea VENCIDA asignada al ausente, política por defecto (sameAssignee).
    await createTask(HOME, 'task-vac', ABSENT, {
      assignmentOrder: [ABSENT, PRESENT],
      currentAssigneeUid: ABSENT,
      onMissAssign: 'sameAssignee',
      nextDueAt: pastTs(2),
    });

    await runCron();
  });

  it('NO incrementa missedCount ni baja complianceRate del ausente', async () => {
    const m = await getDb()
      .collection('homes').doc(HOME).collection('members').doc(ABSENT).get();
    expect(m.data()!['missedCount'] ?? 0).toBe(0);
    expect(m.data()!['complianceRate']).toBe(1.0);
  });

  it('reasigna la tarea a un miembro presente (no se queda pegada al ausente)', async () => {
    const t = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-vac').get();
    expect(t.data()!['currentAssigneeUid']).toBe(PRESENT);
  });

  it('no emite evento "missed" con penalización para el ausente', async () => {
    const ev = await getDb()
      .collection('homes').doc(HOME).collection('taskEvents')
      .where('eventType', '==', 'missed')
      .where('actorUid', '==', ABSENT)
      .get();
    expect(ev.empty).toBe(true);
  });

  it('mantiene al ausente en assignmentOrder (vuelve a la rotación al regresar)', async () => {
    const t = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-vac').get();
    expect(t.data()!['assignmentOrder']).toContain(ABSENT);
  });
});

// ── Regresión: un responsable PRESENTE que incumple SÍ se penaliza ────────────
describe('processExpiredTasks — un responsable presente sí se penaliza (regresión)', () => {
  const HOME = 'home-vac-reg';
  const OWNER = 'owner-reg';
  const ACTOR = 'actor-reg'; // presente, incumple

  beforeAll(async () => {
    await cleanAll();
    await createUser(OWNER);
    await createUser(ACTOR);
    await createHome(HOME, OWNER, { premiumStatus: 'free' });
    await addMemberToHome(HOME, ACTOR, 'member', 'active', {
      completedCount: 4,
      complianceRate: 1.0,
      missedCount: 0,
    });
    await createTask(HOME, 'task-reg', ACTOR, {
      assignmentOrder: [ACTOR],
      currentAssigneeUid: ACTOR,
      onMissAssign: 'sameAssignee',
      nextDueAt: pastTs(2),
    });
    await runCron();
  });

  it('incrementa missedCount del responsable presente', async () => {
    const m = await getDb()
      .collection('homes').doc(HOME).collection('members').doc(ACTOR).get();
    expect(m.data()!['missedCount']).toBe(1);
    expect(m.data()!['complianceRate']).toBeLessThan(1.0);
  });

  it('emite evento missed con penaltyApplied=true', async () => {
    const ev = await getDb()
      .collection('homes').doc(HOME).collection('taskEvents')
      .where('eventType', '==', 'missed')
      .where('actorUid', '==', ACTOR)
      .get();
    expect(ev.size).toBe(1);
    expect(ev.docs[0].data()['penaltyApplied']).toBe(true);
  });
});

// ── Parte A: reasignación eager al INICIAR la vacación ────────────────────────
describe('reassignActiveTasksForAbsentMember — al iniciar la vacación (#09)', () => {
  const HOME = 'home-vac-eager';
  const OWNER = 'owner-eager';
  const ABSENT = 'absent-eager';
  const PRESENT = 'present-eager';

  beforeEach(async () => {
    await cleanAll();
    await createUser(OWNER);
    await createUser(ABSENT);
    await createUser(PRESENT);
    await createHome(HOME, OWNER, { premiumStatus: 'premium' });
    await addMemberToHome(HOME, ABSENT, 'member', 'active', { vacation: activeVacation() });
    await addMemberToHome(HOME, PRESENT, 'member', 'active');
  });

  it('mueve la tarea del ausente a un presente y lo mantiene en assignmentOrder', async () => {
    await createTask(HOME, 'task-a', ABSENT, {
      assignmentOrder: [ABSENT, PRESENT],
      currentAssigneeUid: ABSENT,
    });

    const n = await reassignActiveTasksForAbsentMember(HOME, ABSENT);

    expect(n).toBe(1);
    const t = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-a').get();
    expect(t.data()!['currentAssigneeUid']).toBe(PRESENT);
    expect(t.data()!['assignmentOrder']).toContain(ABSENT); // vuelve a la rotación
  });

  it('no toca tareas cuyo responsable ya es un presente', async () => {
    await createTask(HOME, 'task-present', PRESENT, {
      assignmentOrder: [PRESENT, ABSENT],
      currentAssigneeUid: PRESENT,
    });

    const n = await reassignActiveTasksForAbsentMember(HOME, ABSENT);

    expect(n).toBe(0);
    const t = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-present').get();
    expect(t.data()!['currentAssigneeUid']).toBe(PRESENT);
  });

  it('si no hay ningún presente disponible, la tarea se queda en el ausente', async () => {
    // PRESENT también de vacaciones → no hay heredero.
    await getDb().collection('homes').doc(HOME).collection('members').doc(PRESENT)
      .update({ vacation: activeVacation() });
    await createTask(HOME, 'task-solo', ABSENT, {
      assignmentOrder: [ABSENT, PRESENT],
      currentAssigneeUid: ABSENT,
    });

    const n = await reassignActiveTasksForAbsentMember(HOME, ABSENT);

    expect(n).toBe(0);
    const t = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-solo').get();
    expect(t.data()!['currentAssigneeUid']).toBe(ABSENT);
  });
});

// ── Trigger onMemberVacationStart: detección de la transición a ausente ───────
describe('onMemberVacationStart — solo reasigna en la transición a ausente (#09)', () => {
  const HOME = 'home-vac-trig';
  const OWNER = 'owner-trig';
  const M = 'member-trig';
  const PRESENT = 'present-trig';
  const present = { status: 'active' };
  const absent = { status: 'active', vacation: activeVacation() };

  beforeEach(async () => {
    await cleanAll();
    await createUser(OWNER);
    await createUser(M);
    await createUser(PRESENT);
    await createHome(HOME, OWNER, { premiumStatus: 'premium' });
    await addMemberToHome(HOME, M, 'member', 'active', { vacation: activeVacation() });
    await addMemberToHome(HOME, PRESENT, 'member', 'active');
    await createTask(HOME, 'task-t', M, {
      assignmentOrder: [M, PRESENT],
      currentAssigneeUid: M,
    });
  });

  it('presente→ausente reasigna la tarea a un presente', async () => {
    await runVacationTrigger(HOME, M, present, absent);
    const t = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-t').get();
    expect(t.data()!['currentAssigneeUid']).toBe(PRESENT);
  });

  it('ya estaba ausente (sin transición) → no reasigna', async () => {
    await runVacationTrigger(HOME, M, absent, absent);
    const t = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-t').get();
    expect(t.data()!['currentAssigneeUid']).toBe(M);
  });

  it('write sin activar vacación (sigue presente) → no reasigna', async () => {
    await runVacationTrigger(HOME, M, present, { status: 'active', vacation: null });
    const t = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-t').get();
    expect(t.data()!['currentAssigneeUid']).toBe(M);
  });
});
