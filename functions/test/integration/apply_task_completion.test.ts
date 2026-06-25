// functions/test/integration/apply_task_completion.test.ts
import * as admin from 'firebase-admin';
import {
  cleanAll,
  createUser,
  createHome,
  addMemberToHome,
  createTask,
  getDb,
  makeCallableRequest,
} from './helpers/setup';
import { applyTaskCompletion } from '../../src/tasks/apply_task_completion';

// firebase-admin ya está inicializado en setup_env.js (setupFiles).
// Llamamos .run() directamente para evitar problemas de tipos con functionsTest.wrap().
const wrapped = (req: any): Promise<any> => (applyTaskCompletion as any).run(req);

const HOME = 'home-completion';
const OWNER = 'owner-completion';
const MEMBER = 'member-completion';
const FROZEN = 'frozen-completion';

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
  await createUser(MEMBER);
  await createUser(FROZEN);
  await createHome(HOME, OWNER);
  await addMemberToHome(HOME, MEMBER, 'member', 'active');
  await addMemberToHome(HOME, FROZEN, 'member', 'frozen');
  await createTask(HOME, 'task1', MEMBER, { assignmentOrder: [MEMBER, OWNER] });
  await createTask(HOME, 'task-frozen', FROZEN, { assignmentOrder: [FROZEN] });
  await createTask(HOME, 'task-completed', MEMBER, { status: 'completed' });
});


describe('applyTaskCompletion — happy path', () => {
  it('member completa su propia tarea → evento creado', async () => {
    const result = await wrapped(makeCallableRequest(MEMBER, { homeId: HOME, taskId: 'task1' }));

    expect(result).toHaveProperty('eventId');
    expect(result).toHaveProperty('nextAssigneeUid');

    // Verificar evento en Firestore
    const eventsSnap = await getDb()
      .collection('homes').doc(HOME).collection('taskEvents')
      .where('taskId', '==', 'task1')
      .get();
    expect(eventsSnap.size).toBe(1);
    expect(eventsSnap.docs[0].data()).toMatchObject({
      eventType: 'completed',
      actorUid: MEMBER,
      performerUid: MEMBER,
    });
  });

  it('completar tarea actualiza stats del member', async () => {
    const memberDoc = await getDb()
      .collection('homes').doc(HOME).collection('members').doc(MEMBER).get();
    const data = memberDoc.data()!;
    // Campo canónico tras el hardening: tasksCompleted (completedCount se borra
    // con FieldValue.delete() para migrar datos de la versión anterior).
    expect(data['tasksCompleted']).toBeGreaterThan(0);
    expect(data['complianceRate']).toBeGreaterThan(0);
  });

  it('completar tarea avanza el assignee al siguiente en la lista', async () => {
    const taskDoc = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task1').get();
    // El siguiente después de MEMBER en [MEMBER, OWNER] es OWNER
    expect(taskDoc.data()!['currentAssigneeUid']).toBe(OWNER);
  });

  it('reconstruye el dashboard dentro de la llamada (no fire-and-forget)', async () => {
    // Con applyTaskCompletion esperando a updateHomeDashboard, el dashboard ya
    // refleja la completación al volver de la llamada. Antes era fire-and-forget
    // y, en Cloud Functions gen2, el rebuild quedaba estrangulado tras la
    // respuesta (~10s de desfase en la pantalla Hoy). task1 se completó arriba.
    const dash = await getDb()
      .collection('homes').doc(HOME).collection('views').doc('dashboard').get();
    expect(dash.exists).toBe(true);
    expect(dash.data()!['counters']['tasksDoneToday']).toBeGreaterThanOrEqual(1);
  });
});

describe('applyTaskCompletion — errores', () => {
  it('llamada sin autenticación → unauthenticated', async () => {
    await expect(
      wrapped({ data: { homeId: HOME, taskId: 'task1' }, auth: null, rawRequest: {} })
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('member intenta completar tarea asignada a otro → permission-denied', async () => {
    // La tarea task1 ahora está asignada a OWNER (tras el test anterior)
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: HOME, taskId: 'task1' }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('tarea con status != active → failed-precondition', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: HOME, taskId: 'task-completed' }))
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('taskId inexistente → not-found', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: HOME, taskId: 'no-existe' }))
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('homeId o taskId vacíos → invalid-argument', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER, { homeId: '', taskId: '' }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});

// Hallazgo #08: al completar, el siguiente responsable NUNCA debe ser un
// ex-miembro (status 'left') que siga en el assignmentOrder. Defensa en
// profundidad por si una tarea zombi conserva al fantasma en el orden.
describe('applyTaskCompletion — no reasigna a miembros left (Hallazgo #08)', () => {
  const COMP = 'comp-left';
  const OTHER_C = 'other-left-c';
  const LEFT_C = 'left-c';

  beforeAll(async () => {
    await createUser(COMP);
    await createUser(OTHER_C);
    await createUser(LEFT_C);
    await addMemberToHome(HOME, COMP, 'member', 'active');
    await addMemberToHome(HOME, OTHER_C, 'member', 'active');
    await addMemberToHome(HOME, LEFT_C, 'member', 'left');
    // Orden [COMP, LEFT_C, OTHER_C]: el siguiente tras COMP es el ex-miembro
    // LEFT_C; debe saltarse y elegir a OTHER_C (activo).
    await createTask(HOME, 'task-left-comp', COMP, {
      assignmentOrder: [COMP, LEFT_C, OTHER_C],
      currentAssigneeUid: COMP,
    });
  });

  it('salta al ex-miembro y asigna al siguiente activo', async () => {
    const result = await wrapped(
      makeCallableRequest(COMP, { homeId: HOME, taskId: 'task-left-comp' })
    );
    expect(result.nextAssigneeUid).toBe(OTHER_C);
    expect(result.nextAssigneeUid).not.toBe(LEFT_C);

    const task = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-left-comp').get();
    expect(task.data()!['currentAssigneeUid']).toBe(OTHER_C);
  });
});

// Hallazgo #02: idempotencia exactamente-una-vez por `completionId`. El cliente
// genera una clave por completación y la reutiliza al reintentar; el backend la
// usa como id determinista del taskEvent y, si ya existe, NO re-aplica nada.
// Esto evita el doble evento cuando una escritura sí se aplicó pero se perdió la
// respuesta (caso peligroso: hogar de 1 persona + tarea recurrente).
describe('applyTaskCompletion — idempotencia por completionId (Hallazgo #02)', () => {
  const SOLO = 'solo-idem';

  beforeAll(async () => {
    await createUser(SOLO);
    await addMemberToHome(HOME, SOLO, 'member', 'active');
    // assignmentOrder = [SOLO]: tras completar, el turno vuelve a SOLO; sin
    // dedup, un reintento con la misma id duplicaría el evento.
    await createTask(HOME, 'task-idem', SOLO, {
      assignmentOrder: [SOLO],
      currentAssigneeUid: SOLO,
      recurrenceType: 'daily',
    });
  });

  it('repetir con la MISMA completionId no duplica evento ni stats', async () => {
    const cid = 'cid-fixed-1';

    const r1 = await wrapped(
      makeCallableRequest(SOLO, { homeId: HOME, taskId: 'task-idem', completionId: cid })
    );
    expect(r1.eventId).toBe(cid);

    const completedAfter1 = (
      await getDb().collection('homes').doc(HOME).collection('members').doc(SOLO).get()
    ).data()!['tasksCompleted'];

    // Reintento con la MISMA clave → no-op idempotente.
    const r2 = await wrapped(
      makeCallableRequest(SOLO, { homeId: HOME, taskId: 'task-idem', completionId: cid })
    );
    expect(r2.eventId).toBe(cid);

    // Un único evento para esa tarea, con id = completionId.
    const byTask = await getDb()
      .collection('homes').doc(HOME).collection('taskEvents')
      .where('taskId', '==', 'task-idem')
      .get();
    expect(byTask.size).toBe(1);
    expect(byTask.docs[0].id).toBe(cid);

    // Stats sin doble incremento.
    const completedAfter2 = (
      await getDb().collection('homes').doc(HOME).collection('members').doc(SOLO).get()
    ).data()!['tasksCompleted'];
    expect(completedAfter2).toBe(completedAfter1);
  });

  it('completionId con caracteres inválidos → invalid-argument', async () => {
    await expect(
      wrapped(makeCallableRequest(SOLO, {
        homeId: HOME, taskId: 'task-idem', completionId: 'bad/id',
      }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});

// Hallazgo #10: al completar, la siguiente nextDueAt se deriva de la
// RecurrenceRule en la zona del hogar (tz-aware), NO sumando intervalos en UTC.
describe('applyTaskCompletion — recurrencia tz-aware (Hallazgo #10)', () => {
  const REC = 'rec-actor';

  beforeAll(async () => {
    await createUser(REC);
    await addMemberToHome(HOME, REC, 'member', 'active');
  });

  it('diaria 09:00 Europe/Madrid: la siguiente mantiene 09:00 a través del DST', async () => {
    // nextDueAt = 30-mar-2024 09:00 Madrid (CET +01:00) = 08:00Z, víspera del cambio.
    await createTask(HOME, 'task-dst-daily', REC, {
      currentAssigneeUid: REC,
      assignmentOrder: [REC],
      recurrenceType: 'daily',
      recurrenceRule: { type: 'daily', every: 1, time: '09:00', timezone: 'Europe/Madrid' },
      nextDueAt: admin.firestore.Timestamp.fromDate(new Date('2024-03-30T08:00:00Z')),
    });

    await wrapped(makeCallableRequest(REC, { homeId: HOME, taskId: 'task-dst-daily' }));

    const task = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-dst-daily').get();
    const next = (task.data()!['nextDueAt'] as admin.firestore.Timestamp).toDate();
    // 31-mar-2024 09:00 Madrid (CEST +02:00) = 07:00Z. El bug viejo (suma UTC)
    // habría dado las 10:00 locales (08:00Z).
    expect(next.toISOString()).toBe('2024-03-31T07:00:00.000Z');
  });

  it('mensual 2.º martes: recalcula el día real (no suma +1 mes ciego)', async () => {
    // nextDueAt = 2.º martes de abril 2026 = 14-abr 09:00 Madrid (CEST) = 07:00Z.
    await createTask(HOME, 'task-monthly-nth', REC, {
      currentAssigneeUid: REC,
      assignmentOrder: [REC],
      recurrenceType: 'monthly',
      recurrenceRule: {
        type: 'monthlyNth',
        weekOfMonth: 2,
        weekday: 'TUE',
        time: '09:00',
        timezone: 'Europe/Madrid',
      },
      nextDueAt: admin.firestore.Timestamp.fromDate(new Date('2026-04-14T07:00:00Z')),
    });

    await wrapped(makeCallableRequest(REC, { homeId: HOME, taskId: 'task-monthly-nth' }));

    const task = await getDb()
      .collection('homes').doc(HOME).collection('tasks').doc('task-monthly-nth').get();
    const next = (task.data()!['nextDueAt'] as admin.firestore.Timestamp).toDate();
    // 2.º martes de mayo 2026 = 12-may 09:00 Madrid = 07:00Z (no el 14-may de un +1 mes ciego).
    expect(next.toISOString()).toBe('2026-05-12T07:00:00.000Z');
  });
});
