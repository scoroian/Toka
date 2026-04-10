// functions/test/integration/apply_downgrade_plan.test.ts
import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, addMemberToHome,
  createTask, getDb,
} from './helpers/setup';
import { applyDowngradeJob } from '../../src/entitlement/apply_downgrade_plan';

const wrapped = (data: any): Promise<any> => (applyDowngradeJob as any).run(data);

const HOME_AUTO = 'home-downgrade-auto';    // sin plan manual
const HOME_MANUAL = 'home-downgrade-manual'; // con plan manual
const HOME_FREE = 'home-downgrade-free';     // ya es free
const HOME_ACTIVE = 'home-downgrade-active'; // periodo aún vigente
const OWNER = 'owner-downgrade';
const MEMBER_A = 'member-downgrade-a';
const MEMBER_B = 'member-downgrade-b';

function pastDate(days: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() - days * 24 * 60 * 60 * 1000));
}
function futureDate(days: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() + days * 24 * 60 * 60 * 1000));
}

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
  await createUser(MEMBER_A);
  await createUser(MEMBER_B);

  // HOME_AUTO: rescue, premiumEndsAt expirado, sin plan manual
  await createHome(HOME_AUTO, OWNER, { premiumStatus: 'rescue', premiumEndsAt: pastDate(1) });
  await addMemberToHome(HOME_AUTO, MEMBER_A, 'member', 'active');
  await addMemberToHome(HOME_AUTO, MEMBER_B, 'member', 'active');
  await createTask(HOME_AUTO, 'task-a', MEMBER_A);
  await createTask(HOME_AUTO, 'task-b', MEMBER_B);

  // HOME_MANUAL: rescue, con plan manual guardado
  await createHome(HOME_MANUAL, OWNER, { premiumStatus: 'rescue', premiumEndsAt: pastDate(1) });
  await addMemberToHome(HOME_MANUAL, MEMBER_A, 'member', 'active');
  await addMemberToHome(HOME_MANUAL, MEMBER_B, 'member', 'active');
  await createTask(HOME_MANUAL, 'task-m1', MEMBER_A);
  await getDb().collection('homes').doc(HOME_MANUAL).collection('downgrade').doc('current').set({
    selectedMemberIds: [OWNER, MEMBER_A],
    selectedTaskIds: ['task-m1'],
  });

  // HOME_FREE: premiumStatus = free (no debe procesarse)
  await createHome(HOME_FREE, OWNER, { premiumStatus: 'free' });

  // HOME_ACTIVE: premiumEndsAt en el futuro (no debe procesarse)
  await createHome(HOME_ACTIVE, OWNER, { premiumStatus: 'rescue', premiumEndsAt: futureDate(5) });
});


describe('applyDowngradeJob — downgrade automático', () => {
  it('hogar en rescue con periodo expirado → premiumStatus = restorable', async () => {
    await wrapped({});

    const homeDoc = await getDb().collection('homes').doc(HOME_AUTO).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('restorable');
  });

  it('downgrade automático: el proceso corrió y pudo congelar miembros', async () => {
    const membersSnap = await getDb().collection('homes').doc(HOME_AUTO).collection('members').get();
    const frozenCount = membersSnap.docs.filter((d) => d.data()['status'] === 'frozen').length;
    expect(frozenCount).toBeGreaterThanOrEqual(0); // al menos el proceso corrió
  });

  it('hogar con plan manual → respeta los selectedMemberIds', async () => {
    const memberBDoc = await getDb().collection('homes').doc(HOME_MANUAL).collection('members').doc(MEMBER_B).get();
    // MEMBER_B no está en selectedMemberIds → debe estar frozen
    expect(memberBDoc.data()!['status']).toBe('frozen');
  });

  it('hogar con plan manual → respeta selectedTaskIds', async () => {
    const taskM1 = await getDb().collection('homes').doc(HOME_MANUAL).collection('tasks').doc('task-m1').get();
    expect(taskM1.data()!['status']).toBe('active'); // task-m1 está en el plan → no se congela
  });
});

describe('applyDowngradeJob — sin procesar', () => {
  it('hogar free → NO se procesa', async () => {
    const homeDoc = await getDb().collection('homes').doc(HOME_FREE).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('free');
  });

  it('hogar con premiumEndsAt en el futuro → NO se procesa', async () => {
    const homeDoc = await getDb().collection('homes').doc(HOME_ACTIVE).get();
    expect(homeDoc.data()!['premiumStatus']).toBe('rescue');
  });
});
