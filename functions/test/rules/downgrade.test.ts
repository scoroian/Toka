// functions/test/rules/downgrade.test.ts
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const HOME1 = 'home1';
const OWNER_UID = 'owner1';
const ADMIN_UID = 'admin1';
const MEMBER_UID = 'member1';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-downgrade-rules',
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

    await setDoc(doc(db, `homes/${HOME1}`), { ownerUid: OWNER_UID });
    await setDoc(doc(db, `homes/${HOME1}/downgrade/current`), {
      selectedMemberIds: [OWNER_UID],
      selectedTaskIds: [],
    });

    await setDoc(doc(db, `users/${OWNER_UID}/memberships/${HOME1}`), { status: 'active', role: 'owner' });
    await setDoc(doc(db, `users/${ADMIN_UID}/memberships/${HOME1}`), { status: 'active', role: 'admin' });
    await setDoc(doc(db, `users/${MEMBER_UID}/memberships/${HOME1}`), { status: 'active', role: 'member' });
  });
});

describe('downgrade/current — read', () => {
  it('owner puede leer el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`)));
  });

  it('admin NO puede leer el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`)));
  });

  it('member raso NO puede leer el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`)));
  });

  it('outsider autenticado NO puede leer el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`)));
  });

  it('no autenticado NO puede leer el plan de downgrade', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`)));
  });
});

describe('downgrade/current — write', () => {
  const plan = { selectedMemberIds: [OWNER_UID], selectedTaskIds: ['task1'] };

  it('owner puede escribir el plan de downgrade manual', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(setDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`), plan));
  });

  it('owner puede actualizar el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`), { selectedTaskIds: [] }));
  });

  it('admin NO puede escribir el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`), plan));
  });

  it('member raso NO puede escribir el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`), plan));
  });

  it('outsider NO puede escribir el plan de downgrade', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`), plan));
  });

  it('no autenticado NO puede escribir el plan de downgrade', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/downgrade/current`), plan));
  });
});
