// functions/test/rules/members.test.ts
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
    projectId: 'demo-toka-members-rules',
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
    await setDoc(doc(db, `homes/${HOME1}/members/${OWNER_UID}`), {
      uid: OWNER_UID, role: 'owner', status: 'active',
      notificationPrefs: { taskReminders: true }, vacation: null,
    });
    await setDoc(doc(db, `homes/${HOME1}/members/${ADMIN_UID}`), {
      uid: ADMIN_UID, role: 'admin', status: 'active',
      notificationPrefs: { taskReminders: true }, vacation: null,
    });
    await setDoc(doc(db, `homes/${HOME1}/members/${MEMBER_UID}`), {
      uid: MEMBER_UID, role: 'member', status: 'active',
      notificationPrefs: { taskReminders: true }, vacation: null,
    });
    await setDoc(doc(db, `homes/${HOME1}/members/${FROZEN_UID}`), {
      uid: FROZEN_UID, role: 'member', status: 'frozen',
      notificationPrefs: { taskReminders: false }, vacation: null,
    });

    await setDoc(doc(db, `users/${OWNER_UID}/memberships/${HOME1}`), { status: 'active', role: 'owner' });
    await setDoc(doc(db, `users/${ADMIN_UID}/memberships/${HOME1}`), { status: 'active', role: 'admin' });
    await setDoc(doc(db, `users/${MEMBER_UID}/memberships/${HOME1}`), { status: 'active', role: 'member' });
    await setDoc(doc(db, `users/${FROZEN_UID}/memberships/${HOME1}`), { status: 'frozen', role: 'member' });
  });
});

// ─── READ ──────────────────────────────────────────────────────────────────────

describe('members — read', () => {
  it('owner puede leer cualquier member', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`)));
  });

  it('admin puede leer cualquier member', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`)));
  });

  it('member puede leer cualquier member del hogar', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${OWNER_UID}`)));
  });

  it('member frozen puede leer cualquier member', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${OWNER_UID}`)));
  });

  it('outsider autenticado NO puede leer members', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${OWNER_UID}`)));
  });

  it('no autenticado NO puede leer members', async () => {
    const ctx = testEnv.unauthenticatedContext();
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${OWNER_UID}`)));
  });
});

// ─── UPDATE PROPIO (campos permitidos) ─────────────────────────────────────────

describe('members — update propio (campos permitidos)', () => {
  it('member puede actualizar solo notificationPrefs propias', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        notificationPrefs: { taskReminders: false },
      })
    );
  });

  it('member puede actualizar solo vacation propia', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        vacation: { start: '2026-05-01', end: '2026-05-10' },
      })
    );
  });

  it('member puede actualizar notificationPrefs + vacation juntos', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        notificationPrefs: { taskReminders: false },
        vacation: { start: '2026-06-01', end: '2026-06-10' },
      })
    );
  });
});

// ─── UPDATE PROPIO (campos prohibidos) ─────────────────────────────────────────

describe('members — update propio (campos prohibidos)', () => {
  it('member NO puede cambiar su propio role', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        role: 'admin',
      })
    );
  });

  it('member NO puede cambiar su propio status', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        status: 'frozen',
      })
    );
  });

  it('member NO puede cambiar su propio uid', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        uid: 'otro-uid',
      })
    );
  });

  it('member NO puede combinar campo permitido + campo prohibido', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        notificationPrefs: { taskReminders: false },
        role: 'admin',
      })
    );
  });

  it('member NO puede combinar vacation + campo prohibido', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        vacation: { start: '2026-06-01', end: '2026-06-10' },
        status: 'active',
      })
    );
  });
});

// ─── UPDATE DE OTRO MIEMBRO (siempre denegado via cliente) ─────────────────────

describe('members — update de otro miembro (siempre denegado)', () => {
  it('owner NO puede actualizar notificationPrefs de otro member via cliente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        notificationPrefs: { taskReminders: false },
      })
    );
  });

  it('admin NO puede actualizar notificationPrefs de otro member via cliente', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`), {
        notificationPrefs: { taskReminders: false },
      })
    );
  });

  it('member NO puede actualizar datos de otro member', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      updateDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${ADMIN_UID}`), {
        notificationPrefs: { taskReminders: false },
      })
    );
  });
});

// ─── CREATE / DELETE (siempre denegados) ───────────────────────────────────────

describe('members — create/delete (siempre denegado)', () => {
  it('owner NO puede crear member directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/members/newuser`), { role: 'member', status: 'active' })
    );
  });

  it('owner NO puede borrar member directamente', async () => {
    const ctx = testEnv.authenticatedContext(OWNER_UID);
    await assertFails(deleteDoc(doc(ctx.firestore(), `homes/${HOME1}/members/${MEMBER_UID}`)));
  });

  it('admin NO puede crear member directamente', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/members/newuser2`), { role: 'member', status: 'active' })
    );
  });
});
