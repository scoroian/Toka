// functions/test/integration/smart_distribution_load.test.ts
//
// Hallazgo #13: el reparto inteligente debe usar la carga REAL de los últimos
// 60 días (eventos `taskEvents` de tipo `completed`), no el acumulado de por
// vida `completions60d` (que solo se incrementa y nunca decae).
//
// Escenario discriminante (histórico desigual):
//   - VETERAN: completions60d ALTO (5) pero todas sus completaciones son de hace
//              ~90 días → FUERA de la ventana → carga real 0.
//   - ROOKIE:  completions60d BAJO (1) pero 4 completaciones esta última semana
//              → DENTRO de la ventana → carga real 4.
//   - ACTOR (quien completa): 3 completaciones recientes → carga real 3.
//
// Con la lógica vieja (completions60d como peso) el siguiente sería ROOKIE
// (score 1 < ACTOR 3 < VETERAN 5). Con la ventana real, VETERAN (carga 0) es el
// de menor carga y le toca a él: el cumplidor histórico ya no queda excluido.
import * as admin from 'firebase-admin';
import {
  cleanAll,
  createUser,
  createHome,
  addMemberToHome,
  createTask,
  getDb,
  makeCallableRequest,
} from './helpers/setup';
import { applyTaskCompletion } from '../../src/tasks/apply_task_completion';

const wrapped = (req: any): Promise<any> => (applyTaskCompletion as any).run(req);

const HOME = 'home-smart-load';
const ACTOR = 'actor-smart';
const VETERAN = 'veteran-smart';
const ROOKIE = 'rookie-smart';

const DAY_MS = 24 * 60 * 60 * 1000;

/** Siembra `count` eventos `completed` para un performer con una antigüedad dada. */
async function seedCompletedEvents(
  homeId: string,
  performerUid: string,
  count: number,
  ageDays: number
): Promise<void> {
  const db = getDb();
  const completedAt = admin.firestore.Timestamp.fromMillis(Date.now() - ageDays * DAY_MS);
  for (let i = 0; i < count; i++) {
    await db.collection('homes').doc(homeId).collection('taskEvents').add({
      eventType: 'completed',
      taskId: `seed-${performerUid}-${i}`,
      taskTitleSnapshot: 'Tarea histórica',
      actorUid: performerUid,
      performerUid,
      completedAt,
      createdAt: completedAt,
      penaltyApplied: false,
    });
  }
}

beforeAll(async () => {
  await cleanAll();
  await createUser(ACTOR);
  await createUser(VETERAN);
  await createUser(ROOKIE);
  await createHome(HOME, ACTOR);

  const now = admin.firestore.Timestamp.now();
  // lastCompletedAt = ahora para los tres → daysSinceLastExecution ≈ 0, de modo
  // que el score depende solo de la carga reciente (aislamos la variable).
  await addMemberToHome(HOME, VETERAN, 'member', 'active', {
    completions60d: 5,
    lastCompletedAt: now,
  });
  await addMemberToHome(HOME, ROOKIE, 'member', 'active', {
    completions60d: 1,
    lastCompletedAt: now,
  });
  // ACTOR es el owner (creado por createHome); fijamos su histórico también.
  await getDb().collection('homes').doc(HOME).collection('members').doc(ACTOR).update({
    completions60d: 3,
    lastCompletedAt: now,
  });

  // Histórico de eventos: VETERAN fuera de ventana, ROOKIE y ACTOR dentro.
  await seedCompletedEvents(HOME, VETERAN, 5, 90); // fuera de la ventana de 60d
  await seedCompletedEvents(HOME, ROOKIE, 4, 5); // dentro
  await seedCompletedEvents(HOME, ACTOR, 3, 5); // dentro

  await createTask(HOME, 'task-smart', ACTOR, {
    distributionMode: 'smart',
    assignmentOrder: [ACTOR, VETERAN, ROOKIE],
    currentAssigneeUid: ACTOR,
    recurrenceType: 'weekly',
  });
});

describe('reparto inteligente usa la carga real de 60 días (Hallazgo #13)', () => {
  it('asigna al cumplidor histórico (VETERAN) porque su carga reciente es 0', async () => {
    const result = await wrapped(
      makeCallableRequest(ACTOR, { homeId: HOME, taskId: 'task-smart' })
    );

    // Con el acumulado de por vida habría salido ROOKIE (completions60d=1, el más
    // bajo). Con la ventana real, VETERAN (0 recientes) es el de menor carga.
    expect(result.nextAssigneeUid).toBe(VETERAN);

    const task = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-smart').get();
    expect(task.data()!['currentAssigneeUid']).toBe(VETERAN);
  });

  it('sigue manteniendo completions60d (lo usa el downgrade): ACTOR pasa de 3 a 4', async () => {
    const actor = await getDb()
      .collection('homes').doc(HOME).collection('members').doc(ACTOR).get();
    expect(actor.data()!['completions60d']).toBe(4);
  });
});
