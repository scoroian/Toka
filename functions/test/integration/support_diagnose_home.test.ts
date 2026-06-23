// functions/test/integration/support_diagnose_home.test.ts
//
// Hallazgo #17: callable READ-ONLY de diagnóstico de soporte. Verifica end-to-end
// (contra emuladores):
//   - solo accede una cuenta con el claim `support` (sin claim → permission-denied,
//     sin auth → unauthenticated);
//   - devuelve el estado del hogar (premium, miembros, tareas próximas, eventos);
//   - NO expone datos privados: teléfonos, tokens FCM ni notas de valoración.
// App Check se ejerce en producción (enforceAppCheck); al invocar .run()
// directamente en tests, esa capa se omite (igual que en syncEntitlement).

import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, addMemberToHome, createTask, getDb,
} from './helpers/setup';
import { supportDiagnoseHome } from '../../src/homes/support_diagnostics';

const wrapped = (req: any): Promise<any> => (supportDiagnoseHome as any).run(req);

function supportReq(uid: string, data: unknown) {
  return { data, auth: { uid, token: { uid, support: true } }, rawRequest: {} };
}
function normalReq(uid: string, data: unknown) {
  return { data, auth: { uid, token: { uid } }, rawRequest: {} };
}

const HOME = 'home-diag';
const OWNER = 'owner-diag';
const MEMBER = 'member-diag';
const SUPPORT = 'support-agent';

beforeAll(async () => {
  await cleanAll();
  await createUser(SUPPORT);
  await createUser(OWNER, { fcmToken: 'owner-secret-token', phone: '+34611000111' });
  await createUser(MEMBER); // sin token
  await createHome(HOME, OWNER, {
    name: 'Hogar Diagnóstico',
    premiumStatus: 'active',
    premiumPlan: 'yearly',
    timezone: 'Europe/Madrid',
  });
  // Owner: teléfono visible para co-miembros (presente en el doc de miembro).
  await addMemberToHome(HOME, OWNER, 'owner', 'active', {
    nickname: 'Dueño',
    phone: '+34611000111',
    phoneVisibility: 'sameHomeMembers',
    completedCount: 9,
  });
  // Member: teléfono oculto (null en el doc) y sin token.
  await addMemberToHome(HOME, MEMBER, 'member', 'active', {
    nickname: 'Miembro',
    phone: null,
    phoneVisibility: 'hidden',
  });

  await createTask(HOME, 'task-1', OWNER, {
    title: 'Fregar suelo',
    nextDueAt: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 3600_000)),
  });

  // Evento completado CON una nota de valoración privada en la subcolección.
  await getDb().collection('homes').doc(HOME).collection('taskEvents').doc('ev1').set({
    eventType: 'completed',
    performerUid: OWNER,
    taskId: 'task-1',
    createdAt: admin.firestore.Timestamp.now(),
  });
  await getDb().collection('homes').doc(HOME)
    .collection('taskEvents').doc('ev1')
    .collection('reviews').doc(MEMBER)
    .set({
      reviewerUid: MEMBER,
      performerUid: OWNER,
      score: 8,
      note: 'NOTA-PRIVADA-SECRETA',
      createdAt: admin.firestore.Timestamp.now(),
    });
});

describe('supportDiagnoseHome — autorización', () => {
  it('sin auth → unauthenticated', async () => {
    await expect(
      wrapped({ data: { homeId: HOME }, auth: null, rawRequest: {} })
    ).rejects.toThrow(/unauthenticated|not authenticated/i);
  });

  it('autenticado SIN claim de soporte → permission-denied', async () => {
    await expect(wrapped(normalReq(OWNER, { homeId: HOME }))).rejects.toThrow(
      /permission-denied|support/i
    );
  });

  it('homeId ausente → invalid-argument', async () => {
    await expect(wrapped(supportReq(SUPPORT, {}))).rejects.toThrow(/invalid-argument|homeId/i);
  });

  it('hogar inexistente → not-found', async () => {
    await expect(
      wrapped(supportReq(SUPPORT, { homeId: 'no-such-home' }))
    ).rejects.toThrow(/not-found|not found/i);
  });
});

describe('supportDiagnoseHome — diagnóstico (soporte autorizado)', () => {
  let result: any;
  beforeAll(async () => {
    result = await wrapped(supportReq(SUPPORT, { homeId: HOME }));
  });

  it('devuelve la cabecera del hogar (premium/owner/timezone)', () => {
    expect(result.homeId).toBe(HOME);
    expect(result.home.premiumStatus).toBe('active');
    expect(result.home.premiumPlan).toBe('yearly');
    expect(result.home.ownerUid).toBe(OWNER);
    expect(result.home.timezone).toBe('Europe/Madrid');
  });

  it('devuelve los miembros con presencia de teléfono/token como booleanos', () => {
    expect(result.memberCount).toBe(2);
    const owner = result.members.find((m: any) => m.uid === OWNER);
    const member = result.members.find((m: any) => m.uid === MEMBER);
    expect(owner.hasPhone).toBe(true); // teléfono presente en su doc
    expect(owner.hasFcmToken).toBe(true); // token presente en users/{uid}
    expect(member.hasPhone).toBe(false); // oculto → null
    expect(member.hasFcmToken).toBe(false);
  });

  it('devuelve tareas próximas y eventos recientes', () => {
    expect(result.upcomingTasks.some((t: any) => t.taskId === 'task-1')).toBe(true);
    expect(result.recentEvents.some((e: any) => e.eventId === 'ev1')).toBe(true);
  });

  it('NO expone datos privados: teléfono, token ni nota de valoración', () => {
    const json = JSON.stringify(result);
    expect(json).not.toContain('+34611000111'); // teléfono en claro
    expect(json).not.toContain('owner-secret-token'); // token FCM
    expect(json).not.toContain('NOTA-PRIVADA-SECRETA'); // nota privada
    // Ningún miembro lleva las claves crudas:
    for (const m of result.members) {
      expect(m).not.toHaveProperty('phone');
      expect(m).not.toHaveProperty('fcmToken');
    }
  });
});
