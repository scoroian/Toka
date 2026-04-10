// functions/test/integration/apply_task_completion.test.ts
import * as functionsTest from 'firebase-functions-test';
import {
  cleanAll,
  createUser,
  createHome,
  addMemberToHome,
  createTask,
  getDb,
  makeCallableRequest,
} from './helpers/setup';

// Importar el handler DESPUÉS de inicializar firebase-admin vía global_setup.js
import { applyTaskCompletion } from '../../src/tasks/apply_task_completion';

const testEnv = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const wrapped = testEnv.wrap(applyTaskCompletion) as (req: any) => Promise<any>;

const HOME = 'home-completion';
const OWNER = 'owner-completion';
const MEMBER = 'member-completion';
const FROZEN = 'frozen-completion';

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
  await createUser(MEMBER);
  await createUser(FROZEN);
  await createHome(HOME, OWNER);
  await addMemberToHome(HOME, MEMBER, 'member', 'active');
  await addMemberToHome(HOME, FROZEN, 'member', 'frozen');
  await createTask(HOME, 'task1', MEMBER, { assignmentOrder: [MEMBER, OWNER] });
  await createTask(HOME, 'task-frozen', FROZEN, { assignmentOrder: [FROZEN] });
  await createTask(HOME, 'task-completed', MEMBER, { status: 'completed' });
});

afterAll(() => testEnv.cleanup());

describe('applyTaskCompletion — happy path', () => {
  it('member completa su propia tarea → evento creado', async () => {
    const result = await wrapped(makeCallableRequest(MEMBER, { homeId: HOME, taskId: 'task1' }));

    expect(result).toHaveProperty('eventId');
    expect(result).toHaveProperty('nextAssigneeUid');

    // Verificar evento en Firestore
    const eventsSnap = await getDb()
      .collection('homes').doc(HOME).collection('taskEvents')
      .where('taskId', '==', 'task1')
      .get();
    expect(eventsSnap.size).toBe(1);
    expect(eventsSnap.docs[0].data()).toMatchObject({
      eventType: 'completed',
      actorUid: MEMBER,
      performerUid: MEMBER,
    });
  });

  it('completar tarea actualiza stats del member', async () => {
    const memberDoc = await getDb()
      .collection('homes').doc(HOME).collection('members').doc(MEMBER).get();
    const data = memberDoc.data()!;
    expect(data['completedCount']).toBeGreaterThan(0);
    expect(data['complianceRate']).toBeGreaterThan(0);
  });

  it('completar tarea avanza el assignee al siguiente en la lista', async () => {
    const taskDoc = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task1').get();
    // El siguiente después de MEMBER en [MEMBER, OWNER] es OWNER
    expect(taskDoc.data()!['currentAssigneeUid']).toBe(OWNER);
  });
});

describe('applyTaskCompletion — errores', () => {
  it('llamada sin autenticación → unauthenticated', async () => {
    await expect(
      wrapped({ data: { homeId: HOME, taskId: 'task1' }, auth: null, rawRequest: {} })
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('member intenta completar tarea asignada a otro → permission-denied', async () => {
    // La tarea task1 ahora está asignada a OWNER (tras el test anterior)
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: HOME, taskId: 'task1' }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('tarea con status != active → failed-precondition', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: HOME, taskId: 'task-completed' }))
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('taskId inexistente → not-found', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: HOME, taskId: 'no-existe' }))
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('homeId o taskId vacíos → invalid-argument', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: '', taskId: '' }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
