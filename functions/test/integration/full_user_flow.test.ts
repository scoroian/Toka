// functions/test/integration/full_user_flow.test.ts
//
// Flujo completo encadenado: crea usuario → crea hogar → crea tareas
// → completa tarea → pasa turno → invita segundo miembro → reasigna → segundo completa.

import {
  cleanAll, createUser, createHome, addMemberToHome,
  createTask, getDb, makeCallableRequest,
} from './helpers/setup';
import { applyTaskCompletion } from '../../src/tasks/apply_task_completion';
import { passTaskTurn } from '../../src/tasks/pass_task_turn';
import { manualReassign } from '../../src/tasks/manual_reassign';

const wrappedCompletion = (req: any): Promise<any> => (applyTaskCompletion as any).run(req);
const wrappedPass = (req: any): Promise<any> => (passTaskTurn as any).run(req);
const wrappedReassign = (req: any): Promise<any> => (manualReassign as any).run(req);

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
