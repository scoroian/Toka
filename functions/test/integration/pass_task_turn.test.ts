// functions/test/integration/pass_task_turn.test.ts
import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, addMemberToHome,
  createTask, getDb, makeCallableRequest,
} from './helpers/setup';
import { passTaskTurn } from '../../src/tasks/pass_task_turn';

const wrapped = (req: any): Promise<any> => (passTaskTurn as any).run(req);

const HOME = 'home-pass';
const OWNER = 'owner-pass';
const MEMBER_A = 'member-pass-a';
const MEMBER_B = 'member-pass-b';
const FROZEN = 'frozen-pass';

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
  await createUser(MEMBER_A);
  await createUser(MEMBER_B);
  await createUser(FROZEN);
  await createHome(HOME, OWNER);
  // MEMBER_A con completions previas para que complianceAfter < complianceBefore sea verificable
  await addMemberToHome(HOME, MEMBER_A, 'member', 'active', { completedCount: 5, complianceRate: 1.0 });
  await addMemberToHome(HOME, MEMBER_B, 'member', 'active');
  await addMemberToHome(HOME, FROZEN, 'member', 'frozen');

  // task-multi: orden [MEMBER_A, MEMBER_B, OWNER]
  await createTask(HOME, 'task-multi', MEMBER_A, { assignmentOrder: [MEMBER_A, MEMBER_B, OWNER] });
  // task-solo: solo MEMBER_A, sin más elegibles
  await createTask(HOME, 'task-solo', MEMBER_A, { assignmentOrder: [MEMBER_A] });
  // task-vacaciones: 'member-absent' de VACACIONES. La ausencia EFECTIVA la marca
  // el campo `vacation` (isMemberCurrentlyAbsent lo lee), NO un status:'absent'
  // denormalizado —las Firestore rules no lo permiten— por eso el miembro sigue
  // status:'active' con una vacación activa que cubre hoy (Hallazgo #09).
  await addMemberToHome(HOME, 'member-absent', 'member', 'active', {
    vacation: {
      isActive: true,
      startDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 24 * 60 * 60 * 1000)),
      endDate: null,
      reason: 'test',
      createdAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() - 24 * 60 * 60 * 1000)),
    },
  });
  await createTask(HOME, 'task-vacaciones', MEMBER_A, { assignmentOrder: [MEMBER_A, 'member-absent'] });
  // task-inactive: status != active
  await createTask(HOME, 'task-inactive', MEMBER_A, { status: 'completed' });
});


describe('passTaskTurn — happy path', () => {
  it('pasa turno con múltiples elegibles → siguiente asignado', async () => {
    const result = await wrapped(makeCallableRequest(MEMBER_A, {
      homeId: HOME, taskId: 'task-multi', reason: 'Estoy ocupado',
    }));

    expect(result.toUid).toBe(MEMBER_B);
    expect(result.noCandidate).toBe(false);
    expect(result.complianceAfter).toBeLessThan(result.complianceBefore);
  });

  it('pasar turno crea evento passed en Firestore', async () => {
    const eventsSnap = await getDb()
      .collection('homes').doc(HOME).collection('taskEvents')
      .where('taskId', '==', 'task-multi')
      .get();
    expect(eventsSnap.size).toBe(1);
    const ev = eventsSnap.docs[0].data();
    expect(ev['eventType']).toBe('passed');
    expect(ev['penaltyApplied']).toBe(true);
    expect(ev['actorUid']).toBe(MEMBER_A);
    expect(ev['toUid']).toBe(MEMBER_B);
  });

  it('pasar turno actualiza passedCount del member', async () => {
    const m = await getDb().collection('homes').doc(HOME).collection('members').doc(MEMBER_A).get();
    expect(m.data()!['passedCount']).toBe(1);
  });

  it('miembro absent excluido del siguiente turno', async () => {
    // task-vacaciones: [MEMBER_A, 'member-absent'] → absent excluido → vuelve a MEMBER_A (noCandidate)
    const result = await wrapped(makeCallableRequest(MEMBER_A, {
      homeId: HOME, taskId: 'task-vacaciones',
    }));
    expect(result.noCandidate).toBe(true);
    expect(result.toUid).toBe(MEMBER_A);
  });

  it('sin elegibles (solo un miembro en orden) → noCandidate = true', async () => {
    const result = await wrapped(makeCallableRequest(MEMBER_A, {
      homeId: HOME, taskId: 'task-solo',
    }));
    expect(result.noCandidate).toBe(true);
  });
});

describe('passTaskTurn — errores', () => {
  it('sin autenticación → unauthenticated', async () => {
    await expect(
      wrapped({ data: { homeId: HOME, taskId: 'task-multi' }, auth: null, rawRequest: {} })
    ).rejects.toMatchObject({ code: 'unauthenticated' });
  });

  it('no es el assignee actual → permission-denied', async () => {
    // task-multi ahora está asignada a MEMBER_B
    await expect(
      wrapped(makeCallableRequest(MEMBER_A, { homeId: HOME, taskId: 'task-multi' }))
    ).rejects.toMatchObject({ code: 'permission-denied' });
  });

  it('tarea no activa → failed-precondition', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER_A, { homeId: HOME, taskId: 'task-inactive' }))
    ).rejects.toMatchObject({ code: 'failed-precondition' });
  });

  it('taskId inexistente → not-found', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER_A, { homeId: HOME, taskId: 'no-existe' }))
    ).rejects.toMatchObject({ code: 'not-found' });
  });

  it('homeId vacío → invalid-argument', async () => {
    await expect(
      wrapped(makeCallableRequest(MEMBER_A, { homeId: '', taskId: 'task-multi' }))
    ).rejects.toMatchObject({ code: 'invalid-argument' });
  });
});

// Hallazgo #08: un ex-miembro (status 'left') que siga en assignmentOrder NUNCA
// debe recibir el turno. Defensa en profundidad por si una tarea zombi conserva
// al fantasma en el orden (p. ej. reasignación previa fallida o dato heredado).
describe('passTaskTurn — excluye miembros left (Hallazgo #08)', () => {
  const LEFT = 'left-pass';

  beforeAll(async () => {
    await createUser(LEFT);
    await addMemberToHome(HOME, LEFT, 'member', 'left');
    // task-left-skip: orden [OWNER, LEFT, MEMBER_B] → al pasar OWNER debe saltar
    // al ex-miembro LEFT y elegir a MEMBER_B (activo).
    await createTask(HOME, 'task-left-skip', OWNER, {
      assignmentOrder: [OWNER, LEFT, MEMBER_B],
    });
    // task-left-only: orden [OWNER, LEFT] → sin más elegibles vivos → noCandidate.
    await createTask(HOME, 'task-left-only', OWNER, {
      assignmentOrder: [OWNER, LEFT],
    });
  });

  it('salta al ex-miembro y elige al siguiente activo', async () => {
    const result = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, taskId: 'task-left-skip',
    }));
    expect(result.toUid).toBe(MEMBER_B);
    expect(result.toUid).not.toBe(LEFT);
  });

  it('si el único otro candidato es left → noCandidate (no se le pasa)', async () => {
    const result = await wrapped(makeCallableRequest(OWNER, {
      homeId: HOME, taskId: 'task-left-only',
    }));
    expect(result.noCandidate).toBe(true);
    expect(result.toUid).toBe(OWNER);
  });
});

// Hallazgo #11(a): la penalización se aplica SIEMPRE (penaltyApplied=true), con
// independencia de lo alto que sea el cumplimiento del que pasa. Para un usuario
// consolidado la caída es sub-1pp; el backend penaliza igual, por eso el diálogo
// debe avisar siempre (regla de producto #7). Este test fija ese contrato.
describe('passTaskTurn — penaliza aunque el cumplimiento sea alto (Hallazgo #11a)', () => {
  const CONSOL = 'consol-pass';

  beforeAll(async () => {
    await createUser(CONSOL);
    // 100 completadas, 0 pasadas → cumplimiento 100%; al pasar baja a 100/101 ≈ 99%.
    await addMemberToHome(HOME, CONSOL, 'member', 'active', {
      tasksCompleted: 100, passedCount: 0, complianceRate: 1.0,
    });
    await createTask(HOME, 'task-consol', CONSOL, {
      assignmentOrder: [CONSOL, MEMBER_B],
    });
  });

  it('caída sub-1pp pero penaltyApplied=true igualmente', async () => {
    const result = await wrapped(makeCallableRequest(CONSOL, {
      homeId: HOME, taskId: 'task-consol',
    }));

    // La caída es mínima (≈0.99 pp) — invisible a un umbral de 1%...
    expect(result.complianceBefore - result.complianceAfter).toBeLessThan(0.01);
    expect(result.complianceAfter).toBeLessThan(result.complianceBefore);

    // ...pero el evento se marca con penaltyApplied=true igualmente.
    const eventsSnap = await getDb()
      .collection('homes').doc(HOME).collection('taskEvents')
      .where('taskId', '==', 'task-consol')
      .get();
    expect(eventsSnap.size).toBe(1);
    expect(eventsSnap.docs[0].data()['penaltyApplied']).toBe(true);
  });
});
