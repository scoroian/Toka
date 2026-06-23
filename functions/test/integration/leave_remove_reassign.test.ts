// functions/test/integration/leave_remove_reassign.test.ts
//
// Hallazgo #08 — "Tareas zombi de ex-miembros". Verifica end-to-end (contra
// emuladores) que al EXPULSAR (removeMember) o SALIR (leaveHome) de un hogar,
// las tareas del ausente se reasignan a un miembro activo y el ausente sale del
// `assignmentOrder`, igual que ya hacía el borrado de cuenta (cleanupDeletedUser).
//
// Requiere emuladores (firebase emulators:start) — ver jest.integration.config.js.

import {
  cleanAll,
  createUser,
  createHome,
  addMemberToHome,
  createTask,
  getDb,
  makeCallableRequest,
} from './helpers/setup';
import { leaveHome, removeMember } from '../../src/homes/index';

const removeWrapped = (req: any): Promise<any> => (removeMember as any).run(req);
const leaveWrapped = (req: any): Promise<any> => (leaveHome as any).run(req);

beforeAll(async () => {
  await cleanAll();
});

// ---------------------------------------------------------------------------
describe('removeMember — reasigna las tareas del expulsado', () => {
  const HOME = 'home-remove-reassign';
  const OWNER = 'owner-rr';
  const VICTIM = 'victim-rr'; // miembro expulsado con tarea asignada
  const OTHER = 'other-rr'; // miembro activo que hereda la tarea

  beforeAll(async () => {
    await createUser(OWNER);
    await createUser(VICTIM);
    await createUser(OTHER);
    await createHome(HOME, OWNER, { premiumStatus: 'free' });
    await addMemberToHome(HOME, VICTIM, 'member', 'active');
    await addMemberToHome(HOME, OTHER, 'member', 'active');
    // Tarea cuyo responsable actual es el que será expulsado.
    await createTask(HOME, 'task-assigned', VICTIM, {
      assignmentOrder: [VICTIM, OTHER],
      currentAssigneeUid: VICTIM,
    });
    // Tarea donde el expulsado solo está en el orden, no es el responsable.
    await createTask(HOME, 'task-in-order', OTHER, {
      assignmentOrder: [OTHER, VICTIM],
      currentAssigneeUid: OTHER,
    });

    await removeWrapped(
      makeCallableRequest(OWNER, { homeId: HOME, targetUid: VICTIM })
    );
  });

  it('marca al expulsado como left', async () => {
    const doc = await getDb()
      .collection('homes').doc(HOME).collection('members').doc(VICTIM).get();
    expect(doc.data()!['status']).toBe('left');
  });

  it('reasigna su tarea a un miembro activo y lo quita del assignmentOrder', async () => {
    const task = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-assigned').get();
    expect(task.data()!['currentAssigneeUid']).toBe(OTHER);
    expect(task.data()!['assignmentOrder']).toEqual([OTHER]);
  });

  it('lo quita del assignmentOrder aunque no fuera el responsable (sin cambiar al responsable)', async () => {
    const task = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-in-order').get();
    expect(task.data()!['currentAssigneeUid']).toBe(OTHER);
    expect(task.data()!['assignmentOrder']).toEqual([OTHER]);
  });

  it('el dashboard refleja al nuevo responsable activo', async () => {
    const dash = await getDb()
      .collection('homes').doc(HOME).collection('views').doc('dashboard').get();
    expect(dash.exists).toBe(true);
    // El expulsado ya no cuenta como miembro activo.
    expect(dash.data()!['counters']['totalMembers']).toBe(2);
  });
});

// ---------------------------------------------------------------------------
describe('leaveHome — reasigna las tareas del que se va', () => {
  const HOME = 'home-leave-reassign';
  const OWNER = 'owner-lr';
  const LEAVER = 'leaver-lr';

  beforeAll(async () => {
    await createUser(OWNER);
    await createUser(LEAVER);
    await createHome(HOME, OWNER, { premiumStatus: 'free' });
    await addMemberToHome(HOME, LEAVER, 'member', 'active');
    await createTask(HOME, 'task-leaver', LEAVER, {
      assignmentOrder: [LEAVER, OWNER],
      currentAssigneeUid: LEAVER,
    });

    await leaveWrapped(makeCallableRequest(LEAVER, { homeId: HOME }));
  });

  it('marca al que se va como left', async () => {
    const doc = await getDb()
      .collection('homes').doc(HOME).collection('members').doc(LEAVER).get();
    expect(doc.data()!['status']).toBe('left');
  });

  it('reasigna su tarea al owner y lo quita del assignmentOrder', async () => {
    const task = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-leaver').get();
    expect(task.data()!['currentAssigneeUid']).toBe(OWNER);
    expect(task.data()!['assignmentOrder']).toEqual([OWNER]);
  });
});

// ---------------------------------------------------------------------------
describe('removeMember — sin elegibles restantes → responsable null', () => {
  const HOME = 'home-remove-solo';
  const OWNER = 'owner-rs';
  const SOLO = 'solo-rs';

  beforeAll(async () => {
    await createUser(OWNER);
    await createUser(SOLO);
    await createHome(HOME, OWNER, { premiumStatus: 'free' });
    await addMemberToHome(HOME, SOLO, 'member', 'active');
    // Tarea cuyo orden es SOLO únicamente (el owner no participa en ella).
    await createTask(HOME, 'task-solo', SOLO, {
      assignmentOrder: [SOLO],
      currentAssigneeUid: SOLO,
    });

    await removeWrapped(
      makeCallableRequest(OWNER, { homeId: HOME, targetUid: SOLO })
    );
  });

  it('deja la tarea sin responsable y con assignmentOrder vacío', async () => {
    const task = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-solo').get();
    expect(task.data()!['currentAssigneeUid']).toBeNull();
    expect(task.data()!['assignmentOrder']).toEqual([]);
  });
});
