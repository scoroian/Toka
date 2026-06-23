// functions/test/integration/process_expired_tasks.test.ts
//
// Hallazgo #08 (defensa en profundidad): el cron diario `processExpiredTasks`
// reasigna las tareas vencidas (onMissAssign='nextInRotation') al siguiente en
// la rotación. Un ex-miembro (status 'left') que siga en assignmentOrder NUNCA
// debe recibir la reasignación. Requiere emuladores.

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

const runCron = (): Promise<any> => (processExpiredTasks as any).run({});

function pastDate(days: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(
    new Date(Date.now() - days * 24 * 60 * 60 * 1000)
  );
}

const HOME = 'home-expired-left';
const OWNER = 'owner-exp';
const ACTOR = 'actor-exp'; // responsable que incumple
const OTHER = 'other-exp'; // activo, debe heredar
const LEFT = 'left-exp'; // ex-miembro, debe saltarse

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
  await createUser(ACTOR);
  await createUser(OTHER);
  await createUser(LEFT);
  await createHome(HOME, OWNER, { premiumStatus: 'free' });
  await addMemberToHome(HOME, ACTOR, 'member', 'active');
  await addMemberToHome(HOME, OTHER, 'member', 'active');
  await addMemberToHome(HOME, LEFT, 'member', 'left');
  // Tarea VENCIDA con rotación: orden [ACTOR, LEFT, OTHER]. El siguiente tras
  // ACTOR es el ex-miembro LEFT; debe saltarse y elegir a OTHER.
  await createTask(HOME, 'task-expired', ACTOR, {
    assignmentOrder: [ACTOR, LEFT, OTHER],
    currentAssigneeUid: ACTOR,
    onMissAssign: 'nextInRotation',
    nextDueAt: pastDate(2),
  });

  await runCron();
});

describe('processExpiredTasks — excluye miembros left (Hallazgo #08)', () => {
  it('reasigna la tarea vencida a un activo, nunca al ex-miembro', async () => {
    const task = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-expired').get();
    expect(task.data()!['currentAssigneeUid']).toBe(OTHER);
    expect(task.data()!['currentAssigneeUid']).not.toBe(LEFT);
  });
});

// Hallazgo #10: el cron de expiración también reprograma la nextDueAt derivándola
// de la RecurrenceRule tz-aware (hora de pared estable a través del DST), nunca
// por suma de intervalo en UTC.
describe('processExpiredTasks — recurrencia tz-aware (Hallazgo #10)', () => {
  const HOME2 = 'home-expired-dst';
  const OWNER2 = 'owner-exp-dst';
  const ACTOR2 = 'actor-exp-dst';

  beforeAll(async () => {
    await createUser(OWNER2);
    await createUser(ACTOR2);
    await createHome(HOME2, OWNER2, { premiumStatus: 'free' });
    await addMemberToHome(HOME2, ACTOR2, 'member', 'active');
    // Diaria 09:00 Europe/Madrid VENCIDA la víspera del cambio DST (30-mar-2024
    // 09:00 CET = 08:00Z).
    await createTask(HOME2, 'task-dst-exp', ACTOR2, {
      assignmentOrder: [ACTOR2],
      currentAssigneeUid: ACTOR2,
      onMissAssign: 'sameAssignee',
      recurrenceType: 'daily',
      recurrenceRule: { type: 'daily', every: 1, time: '09:00', timezone: 'Europe/Madrid' },
      nextDueAt: admin.firestore.Timestamp.fromDate(new Date('2024-03-30T08:00:00Z')),
    });
    await runCron();
  });

  it('reprograma la diaria al día siguiente manteniendo 09:00 (07:00Z en CEST)', async () => {
    const task = await getDb()
      .collection('homes').doc(HOME2).collection('tasks').doc('task-dst-exp').get();
    const next = (task.data()!['nextDueAt'] as admin.firestore.Timestamp).toDate();
    // 31-mar-2024 09:00 Madrid (CEST +02:00) = 07:00Z; el bug viejo daba 10:00 local.
    expect(next.toISOString()).toBe('2024-03-31T07:00:00.000Z');
  });
});

// Hallazgo #16: el cron tenía un `.limit(100)` GLOBAL (todo el sistema). Con más
// de 100 tareas vencidas/día, las sobrantes nunca se procesaban → deuda
// acumulada perpetua. Ahora pagina con startAfter hasta vaciar (con cap de
// seguridad logueado, no silencioso) y cachea los miembros por hogar.
describe('processExpiredTasks — sin deuda con >100 tareas vencidas (paginación)', () => {
  const BIGHOME = 'home-expired-big';
  const BIGOWNER = 'owner-exp-big';
  const N = 110; // > 100: rompía el cap global viejo

  const debtQuery = () =>
    getDb()
      .collectionGroup('tasks')
      .where('status', '==', 'active')
      .where('nextDueAt', '<', (() => {
        const c = new Date();
        c.setUTCHours(0, 0, 0, 0);
        return admin.firestore.Timestamp.fromDate(c);
      })())
      .get();

  beforeAll(async () => {
    await createUser(BIGOWNER);
    await createHome(BIGHOME, BIGOWNER, { premiumStatus: 'active' });
    // El owner parte con 10 completadas para que la compliance baje de forma
    // OBSERVABLE con cada falta (con completed=0 sería 0 siempre y no
    // distinguiría stats frescas de cacheadas).
    await getDb()
      .collection('homes').doc(BIGHOME).collection('members').doc(BIGOWNER)
      .update({ tasksCompleted: 10, passedCount: 0, missedCount: 0 });
    // N tareas DIARIAS vencidas ayer, todas del owner (mismo actor → ejercita el
    // cache de miembros y la consistencia de compliance con varias faltas).
    const db = getDb();
    const batch = db.batch();
    for (let i = 0; i < N; i++) {
      const ref = db.collection('homes').doc(BIGHOME).collection('tasks').doc(`big-${i}`);
      batch.set(ref, {
        title: `Big ${i}`,
        status: 'active',
        currentAssigneeUid: BIGOWNER,
        assignmentOrder: [BIGOWNER],
        distributionMode: 'round_robin',
        recurrenceType: 'daily',
        onMissAssign: 'sameAssignee',
        nextDueAt: pastDate(1),
        visualKind: 'emoji',
        visualValue: '🧹',
        completedCount90d: 0,
        frozenUids: [],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    const debtBefore = await debtQuery();
    expect(debtBefore.size).toBeGreaterThanOrEqual(N); // confirma el escenario

    await runCron();
  }, 90000);

  it('procesa TODAS las tareas vencidas: no queda deuda', async () => {
    const debt = await debtQuery();
    // Las diarias vencidas ayer se reprograman a hoy (>= cutoff) → 0 deuda.
    const remainingBig = debt.docs.filter((d) => d.id.startsWith('big-'));
    expect(remainingBig).toHaveLength(0);
  });

  it('un actor con N faltas: missedCount=N y complianceRate consistente (stats frescas en la tx, no cacheadas)', async () => {
    const member = await getDb()
      .collection('homes').doc(BIGHOME).collection('members').doc(BIGOWNER).get();
    const data = member.data()!;
    expect(data['missedCount']).toBe(N);
    // Procesado secuencialmente con lectura FRESCA del actor en cada tx:
    // compliance final = completed / (completed + missed) = 10 / (10 + N).
    // Si se hubieran usado stats CACHEADAS (pre-run), daría 10/11 ≈ 0.909 e
    // inconsistente con missedCount=N.
    expect(data['complianceRate']).toBeCloseTo(10 / (10 + N), 4);
  });
});
