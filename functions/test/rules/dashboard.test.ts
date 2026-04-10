// functions/test/rules/dashboard.test.ts
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const HOME1 = 'home1';
const OWNER_UID = 'owner1';
const ADMIN_UID = 'admin1';
const MEMBER_UID = 'member1';
const FROZEN_UID = 'frozen1';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-dashboard-rules',
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
    await setDoc(doc(db, `homes/${HOME1}/views/dashboard`), {
      tasksTodo: 3, tasksDone: 1,
      premiumFlags: { isPremium: false },
    });

    await setDoc(doc(db, `users/${OWNER_UID}/memberships/${HOME1}`), { status: 'active', role: 'owner' });
    await setDoc(doc(db, `users/${ADMIN_UID}/memberships/${HOME1}`), { status: 'active', role: 'admin' });
    await setDoc(doc(db, `users/${MEMBER_UID}/memberships/${HOME1}`), { status: 'active', role: 'member' });
    await setDoc(doc(db, `users/${FROZEN_UID}/memberships/${HOME1}`), { status: 'frozen', role: 'member' });
  });
});

describe('views/dashboard — read', () => {
  it('owner puede leer dashboard', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`)));
  });

  it('admin puede leer dashboard', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`)));
  });

  it('member activo puede leer dashboard', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`)));
  });

  it('member frozen puede leer dashboard', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`)));
  });

  it('outsider autenticado NO puede leer dashboard', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`)));
  });

  it('no autenticado NO puede leer dashboard', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`)));
  });
});

describe('views/dashboard — write (siempre denegado)', () => {
  it('owner NO puede escribir dashboard directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`), { tasksTodo: 99 }));
  });

  it('admin NO puede escribir dashboard directamente', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`), { tasksTodo: 0 }));
  });

  it('member NO puede escribir dashboard directamente', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`), { tasksTodo: 0 }));
  });

  it('owner NO puede borrar dashboard directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`)));
  });

  it('no autenticado NO puede escribir dashboard directamente', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/views/dashboard`), { tasksTodo: 0 }));
  });
});
