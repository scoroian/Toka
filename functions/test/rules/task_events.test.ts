// functions/test/rules/task_events.test.ts
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
    projectId: 'demo-toka-taskevents-rules',
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
    await setDoc(doc(db, `homes/${HOME1}/taskEvents/event1`), {
      eventType: 'completed',
      taskId: 'task1',
      performerUid: MEMBER_UID,
    });

    await setDoc(doc(db, `users/${OWNER_UID}/memberships/${HOME1}`), { status: 'active', role: 'owner' });
    await setDoc(doc(db, `users/${ADMIN_UID}/memberships/${HOME1}`), { status: 'active', role: 'admin' });
    await setDoc(doc(db, `users/${MEMBER_UID}/memberships/${HOME1}`), { status: 'active', role: 'member' });
    await setDoc(doc(db, `users/${FROZEN_UID}/memberships/${HOME1}`), { status: 'frozen', role: 'admin' });
  });
});

// ─── READ ──────────────────────────────────────────────────────────────────────

describe('taskEvents — read', () => {
  it('owner puede leer taskEvent', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });

  it('admin puede leer taskEvent', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });

  it('member activo puede leer taskEvent', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });

  it('member frozen puede leer taskEvent', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });

  it('outsider autenticado NO puede leer taskEvent', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });

  it('no autenticado NO puede leer taskEvent', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });
});

// ─── WRITE (todos denegados — solo Functions) ───────────────────────────────────

describe('taskEvents — write (siempre denegado)', () => {
  const newEvent = { eventType: 'completed', taskId: 'task1', performerUid: MEMBER_UID };

  it('owner NO puede crear taskEvent directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event2`), newEvent));
  });

  it('admin NO puede crear taskEvent directamente', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event3`), newEvent));
  });

  it('member NO puede crear taskEvent directamente', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event4`), newEvent));
  });

  it('owner NO puede actualizar taskEvent directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`), { note: 'edit' }));
  });

  it('owner NO puede borrar taskEvent directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });

  it('no autenticado NO puede escribir taskEvent', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event5`), newEvent));
  });

  it('outsider autenticado NO puede borrar taskEvent', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/taskEvents/event1`)));
  });
});
