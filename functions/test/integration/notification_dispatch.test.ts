// functions/test/integration/notification_dispatch.test.ts
//
// Hallazgo #20: cobertura de la LÓGICA NÚCLEO de envío de notificaciones
// (a QUIÉN se notifica y con QUÉ contenido), que NO estaba testeada. La purga de
// tokens muertos (#17) ya se cubre en fcm_token_purge.test.ts; aquí ejercitamos
// las funciones REALES contra el emulador Firestore con el transporte FCM
// mockeado para capturar el payload enviado.
import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, addMemberToHome,
} from './helpers/setup';
import { sendRescueAlerts } from '../../src/notifications/send_rescue_alerts';
import { sendPassNotification } from '../../src/notifications/send_pass_notification';

// Espiamos el transporte FCM (mismo singleton que capturan los handlers a nivel
// de módulo) para inspeccionar el mensaje sin enviar push reales.
const mockMulticast = jest.fn();
const mockSend = jest.fn();
jest.spyOn(admin.messaging(), 'sendEachForMulticast').mockImplementation(mockMulticast as any);
jest.spyOn(admin.messaging(), 'send').mockImplementation(mockSend as any);

function multicastSuccess(n: number): unknown {
  return {
    successCount: n,
    failureCount: 0,
    responses: Array.from({ length: n }, () => ({ success: true })),
  };
}

beforeEach(() => {
  mockMulticast.mockReset();
  mockSend.mockReset();
  mockMulticast.mockResolvedValue(multicastSuccess(2));
  mockSend.mockResolvedValue('projects/demo/messages/1');
});

describe('sendRescueAlerts — destinatarios y contenido (multicast)', () => {
  const HOME = 'rescue-core';
  const OWNER = 'rc-owner';
  const ACTIVE = 'rc-active';
  const LEFT = 'rc-left';
  const FROZEN = 'rc-frozen';
  const NOTOKEN = 'rc-notoken';

  beforeEach(async () => {
    await cleanAll();
    await createUser(OWNER, { fcmToken: 'tok-owner' });
    await createUser(ACTIVE, { fcmToken: 'tok-active' });
    await createUser(LEFT, { fcmToken: 'tok-left' });
    await createUser(FROZEN, { fcmToken: 'tok-frozen' });
    await createUser(NOTOKEN); // miembro activo SIN token
    await createHome(HOME, OWNER, { name: 'Mi Hogar' }); // OWNER = owner/active
    await addMemberToHome(HOME, ACTIVE, 'member', 'active');
    await addMemberToHome(HOME, LEFT, 'member', 'left');
    await addMemberToHome(HOME, FROZEN, 'member', 'frozen');
    await addMemberToHome(HOME, NOTOKEN, 'member', 'active');
  });

  it('notifica SOLO a miembros active con token (excluye left/frozen/sin token)',
    async () => {
      await sendRescueAlerts(HOME, 3);
      expect(mockMulticast).toHaveBeenCalledTimes(1);
      const msg = mockMulticast.mock.calls[0][0];
      expect(new Set(msg.tokens)).toEqual(new Set(['tok-owner', 'tok-active']));
      expect(msg.tokens).not.toContain('tok-left');
      expect(msg.tokens).not.toContain('tok-frozen');
    });

  it('el payload lleva nombre del hogar, daysLeft y data.type=rescue_alert',
    async () => {
      await sendRescueAlerts(HOME, 5);
      const msg = mockMulticast.mock.calls[0][0];
      expect(msg.notification.title).toContain('Mi Hogar');
      expect(msg.notification.body).toContain('5');
      expect(msg.data).toMatchObject({
        type: 'rescue_alert',
        homeId: HOME,
        daysLeft: '5',
      });
    });

  it('si ningún miembro activo tiene token → early return, sin multicast',
    async () => {
      const H = 'rescue-empty';
      const O = 'reo';
      await createUser(O); // owner activo SIN token
      await createHome(H, O, { name: 'Vacío' });
      await sendRescueAlerts(H, 3);
      expect(mockMulticast).not.toHaveBeenCalled();
    });
});

describe('sendPassNotification — guardas y contenido (single-send)', () => {
  const HOME = 'pass-core';
  const OWNER = 'pc-owner';
  const TO = 'pc-to';
  const FROM = 'pc-from';

  beforeEach(async () => {
    await cleanAll();
    await createUser(OWNER, { fcmToken: 'tok-owner' });
    await createUser(TO, { fcmToken: 'tok-to' });
    await createUser(FROM, { fcmToken: 'tok-from' });
    await createHome(HOME, OWNER);
    await addMemberToHome(HOME, TO, 'member', 'active');
    await addMemberToHome(HOME, FROM, 'member', 'active');
  });

  it('destinatario que NO es miembro del hogar → no envía', async () => {
    await createUser('stranger', { fcmToken: 'tok-stranger' });
    await sendPassNotification(HOME, 'task-1', 'Sacar basura', 'stranger', FROM);
    expect(mockSend).not.toHaveBeenCalled();
  });

  it('miembro SIN token → no envía', async () => {
    await createUser('pc-notoken');
    await addMemberToHome(HOME, 'pc-notoken', 'member', 'active');
    await sendPassNotification(HOME, 'task-1', 'Sacar basura', 'pc-notoken', FROM);
    expect(mockSend).not.toHaveBeenCalled();
  });

  it('miembro con token → envía a su token con título/cuerpo/data correctos',
    async () => {
      await sendPassNotification(HOME, 'task-9', 'Fregar platos', TO, FROM);
      expect(mockSend).toHaveBeenCalledTimes(1);
      const msg = mockSend.mock.calls[0][0];
      expect(msg.token).toBe('tok-to');
      expect(msg.notification.title).toContain('Fregar platos');
      expect(msg.data).toMatchObject({
        type: 'task_passed_to_you',
        homeId: HOME,
        taskId: 'task-9',
        fromUid: FROM,
      });
    });
});
