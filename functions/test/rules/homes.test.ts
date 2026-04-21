import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { readFileSync } from 'fs';
import * as path from 'path';

let testEnv: RulesTestEnvironment;
const HOME1 = 'home1';
const ADMIN_UID = 'admin1';
const MEMBER_UID = 'member1';
const FROZEN_UID = 'frozen1';
const OUTSIDER_UID = 'outsider1';

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'demo-toka-homes',
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

    await setDoc(doc(db, `homes/${HOME1}`), {
      ownerUid: ADMIN_UID,
      name: 'Test Home',
      premiumStatus: 'active',
    });

    await setDoc(doc(db, `homes/${HOME1}/tasks/task1`), {
      title: 'Limpiar cocina',
      status: 'pending',
    });

    await setDoc(doc(db, `users/${ADMIN_UID}/memberships/${HOME1}`), {
      status: 'active',
      role: 'owner',
    });
    await setDoc(doc(db, `users/${MEMBER_UID}/memberships/${HOME1}`), {
      status: 'active',
      role: 'member',
    });
    await setDoc(doc(db, `users/${FROZEN_UID}/memberships/${HOME1}`), {
      status: 'frozen',
      role: 'member',
    });
    // OUTSIDER_UID intencionalmente sin membresía
  });
});

describe('homes security rules', () => {
  it('miembro activo puede leer el hogar', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}`)));
  });

  it('miembro congelado puede leer el hogar', async () => {
    const ctx = testEnv.authenticatedContext(FROZEN_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}`)));
  });

  it('NO miembro NO puede leer el hogar', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}`)));
  });

  it('admin puede crear tareas', async () => {
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertSucceeds(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task2`), {
        title: 'Nueva tarea',
        status: 'pending',
      })
    );
  });

  it('miembro normal NO puede crear tareas', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task3`), {
        title: 'Intento no permitido',
        status: 'pending',
      })
    );
  });

  it('miembro puede leer tareas del hogar', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertSucceeds(getDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });

  it('usuario externo NO puede leer tareas', async () => {
    const ctx = testEnv.authenticatedContext(OUTSIDER_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });
});
