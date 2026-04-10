// functions/test/rules/invitations.test.ts
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
    projectId: 'demo-toka-invitations-rules',
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
    // Invitación con code (lectura pública habilitada)
    await setDoc(doc(db, `homes/${HOME1}/invitations/inv1`), {
      code: 'ABC123',
      expiresAt: new Date(Date.now() + 86400000),
      createdBy: OWNER_UID,
    });
    // Invitación sin code
    await setDoc(doc(db, `homes/${HOME1}/invitations/inv2`), {
      expiresAt: new Date(Date.now() + 86400000),
      createdBy: OWNER_UID,
    });

    await setDoc(doc(db, `users/${OWNER_UID}/memberships/${HOME1}`), { status: 'active', role: 'owner' });
    await setDoc(doc(db, `users/${ADMIN_UID}/memberships/${HOME1}`), { status: 'active', role: 'admin' });
    await setDoc(doc(db, `users/${MEMBER_UID}/memberships/${HOME1}`), { status: 'active', role: 'member' });
    await setDoc(doc(db, `users/${FROZEN_UID}/memberships/${HOME1}`), { status: 'frozen', role: 'admin' });
  });
});

// ─── READ ──────────────────────────────────────────────────────────────────────

describe('invitations — read por admin/owner', () => {
  it('owner puede leer invitación', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });

  it('admin puede leer invitación', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });

  it('member raso NO puede leer invitación (sin code visible)', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv2`)));
  });
});

describe('invitations — read público por code', () => {
  it('outsider autenticado puede leer invitación que tiene code', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });

  it('outsider autenticado NO puede leer invitación sin code', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv2`)));
  });

  it('no autenticado NO puede leer invitación', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });
});

// ─── CREATE ────────────────────────────────────────────────────────────────────

describe('invitations — create', () => {
  const newInv = { code: 'XYZ789', createdBy: OWNER_UID };

  it('owner puede crear invitación', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(setDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv3`), newInv));
  });

  it('admin puede crear invitación', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(setDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv4`), newInv));
  });

  it('member raso NO puede crear invitación', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv5`), newInv));
  });

  it('admin frozen NO puede crear invitación', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv6`), newInv));
  });

  it('outsider NO puede crear invitación', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv7`), newInv));
  });

  it('no autenticado NO puede crear invitación', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(setDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv8`), newInv));
  });
});

// ─── UPDATE ────────────────────────────────────────────────────────────────────

describe('invitations — update', () => {
  it('owner puede actualizar invitación', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`), { used: true }));
  });

  it('admin puede actualizar invitación', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`), { used: true }));
  });

  it('member raso NO puede actualizar invitación', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`), { used: true }));
  });

  it('outsider NO puede actualizar invitación', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(updateDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`), { used: true }));
  });
});

// ─── DELETE ────────────────────────────────────────────────────────────────────

describe('invitations — delete', () => {
  it('owner puede eliminar invitación', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });

  it('admin puede eliminar invitación', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv2`)));
  });

  it('member raso NO puede eliminar invitación', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });

  it('outsider NO puede eliminar invitación', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });

  it('no autenticado NO puede eliminar invitación', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/invitations/inv1`)));
  });
});
