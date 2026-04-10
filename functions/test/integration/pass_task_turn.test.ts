// functions/test/integration/pass_task_turn.test.ts
import * as functionsTest from 'firebase-functions-test';
import {
  cleanAll, createUser, createHome, addMemberToHome,
  createTask, getDb, makeCallableRequest,
} from './helpers/setup';
import { passTaskTurn } from '../../src/tasks/pass_task_turn';

const testEnv = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
const wrapped = testEnv.wrap(passTaskTurn) as (req: any) => Promise<any>;

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
