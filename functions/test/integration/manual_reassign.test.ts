// functions/test/integration/manual_reassign.test.ts
import * as functionsTest from 'firebase-functions-test';
import {
  cleanAll, createUser, createHome, addMemberToHome,
  createTask, getDb, makeCallableRequest,
} from './helpers/setup';
import { manualReassign } from '../../src/tasks/manual_reassign';

const testEnv = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
const wrapped = testEnv.wrap(manualReassign) as (req: any) => Promise<any>;

const HOME = 'home-reassign';
const OWNER = 'owner-reassign';
const ADMIN = 'admin-reassign';
const MEMBER = 'member-reassign';
const FROZEN = 'frozen-reassign';

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
  await createUser(ADMIN);
  await createUser(MEMBER);
  await createUser(FROZEN);
  await createHome(HOME, OWNER);
  await addMemberToHome(HOME, ADMIN, 'admin', 'active');
  await addMemberToHome(HOME, MEMBER, 'member', 'active');
  await addMemberToHome(HOME, FROZEN, 'member', 'frozen');
  await createTask(HOME, 'task1', MEMBER);
});

afterAll(() => testEnv.cleanup());

describe('manualReassign — happy path', () => {
  it('admin reasigna tarea a otro member activo', async () => {
    const result = await wrapped(makeCallableRequest(ADMIN, {
      homeId: HOME, taskId: 'task1', newAssigneeUid: OWNER, reason: 'Test',
    }));
    expect(result.success).toBe(true);

    const taskDoc = await getDb().collection('homes').doc(HOME).collection('tasks').doc('task1').get();
    expect(taskDoc.data()!['currentAssigneeUid']).toBe(OWNER);
  });

  it('reasignar crea evento manual_reassign en Firestore', async () => {
    const eventsSnap = await getDb()
      .collection('homes').doc(HOME).collection('taskEvents')
      .where('eventType', '==', 'manual_reassign')
      .get();
    expect(eventsSnap.size).toBe(1);
    const ev = eventsSnap.docs[0].data();
    expect(ev['toUid']).toBe(OWNER);
    expect(ev['actorUid']).toBe(ADMIN);
    expect(ev['fromUid']).toBe(MEMBER);
  });

  it('owner puede reasignar tarea', async () => {
    const result = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, taskId: 'task1', newAssigneeUid: MEMBER,
    }));
    expect(result.success).toBe(true);
  });
});

describe('manualReassign — errores', () => {
  it('sin autenticación → unauthenticated', async () => {
    await expect(
      wrapped({ data: { homeId: HOME, taskId: 'task1', newAssigneeUid: MEMBER }, auth: null, rawRequest: {} })
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('member raso intenta reasignar → permission-denied', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: HOME, taskId: 'task1', newAssigneeUid: OWNER }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('outsider intenta reasignar → permission-denied', async () => {
    await expect(
      wrapped(makeCallableRequest('outsider-uid', { homeId: HOME, taskId: 'task1', newAssigneeUid: MEMBER }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('taskId inexistente → not-found', async () => {
    await expect(
      wrapped(makeCallableRequest(ADMIN, { homeId: HOME, taskId: 'no-existe', newAssigneeUid: MEMBER }))
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('falta newAssigneeUid → invalid-argument', async () => {
    await expect(
      wrapped(makeCallableRequest(ADMIN, { homeId: HOME, taskId: 'task1', newAssigneeUid: '' }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});
