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
const ADMIN_UID = 'admin1';
const MEMBER_UID = 'member1';
const FROZEN_UID = 'frozen1';
const LEFT_UID = 'left1';
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
    await setDoc(doc(db, `users/${LEFT_UID}/memberships/${HOME1}`), {
      status: 'left',
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

  it('ex-miembro (status:left) NO puede leer el hogar (Hallazgo #01)', async () => {
    const ctx = testEnv.authenticatedContext(LEFT_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}`)));
  });

  it('ex-miembro (status:left) NO puede leer tareas del hogar', async () => {
    const ctx = testEnv.authenticatedContext(LEFT_UID);
    await assertFails(getDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task1`)));
  });

  // Tarea con la forma mínima que exigen las reglas endurecidas de creación
  // (taskCreateKeysAllowed/ValuesAllowed). El test legacy usaba {status:'pending'}
  // y fallaba desde el endurecimiento de tareas (ver Hallazgos.md H-001).
  const validTask = (createdByUid: string) => ({
    homeId: HOME1,
    title: 'Nueva tarea',
    status: 'active',
    createdByUid,
    completedCount90d: 0,
    assignmentOrder: [],
    difficultyWeight: 1,
  });

  it('NADIE crea tareas directamente: el alta es server-side (callable createTask, Hallazgo #14)', async () => {
    // Antes el admin podía escribir la tarea directamente; ahora `allow create:
    // if false` y el alta pasa por la callable transaccional. Cf.
    // functions/test/integration/create_task.test.ts.
    const ctx = testEnv.authenticatedContext(ADMIN_UID);
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task2`), validTask(ADMIN_UID))
    );
  });

  it('miembro normal NO puede crear tareas', async () => {
    const ctx = testEnv.authenticatedContext(MEMBER_UID);
    await assertFails(
      setDoc(doc(ctx.firestore(), `homes/${HOME1}/tasks/task3`), validTask(MEMBER_UID))
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

  describe('update — campos de entitlement reservados al backend', () => {
    it('owner puede actualizar un campo permitido (name)', async () => {
      const ctx = testEnv.authenticatedContext(ADMIN_UID);
      await assertSucceeds(
        updateDoc(doc(ctx.firestore(), `homes/${HOME1}`), { name: 'Nuevo nombre' })
      );
    });

    it('owner NO puede escribir premiumTier (entitlement = solo backend)', async () => {
      const ctx = testEnv.authenticatedContext(ADMIN_UID);
      await assertFails(
        updateDoc(doc(ctx.firestore(), `homes/${HOME1}`), { premiumTier: 'grupo' })
      );
    });

    it('owner NO puede escribir limits (saltarse el tope de miembros)', async () => {
      const ctx = testEnv.authenticatedContext(ADMIN_UID);
      await assertFails(
        updateDoc(doc(ctx.firestore(), `homes/${HOME1}`), { limits: { maxMembers: 999 } })
      );
    });

    it('owner NO puede escribir memberPacks (auto-concederse plazas de pack)', async () => {
      const ctx = testEnv.authenticatedContext(ADMIN_UID);
      await assertFails(
        updateDoc(doc(ctx.firestore(), `homes/${HOME1}`), {
          memberPacks: { plus5: { status: 'active', active: true } },
        })
      );
    });
  });
});
