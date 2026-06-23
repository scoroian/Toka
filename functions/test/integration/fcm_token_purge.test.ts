// functions/test/integration/fcm_token_purge.test.ts
//
// Hallazgo #17: tras un envío FCM, los tokens muertos
// (messaging/registration-token-not-registered) deben borrarse de
// users/{uid}.fcmToken para que los recordatorios no degraden en silencio
// (reintentando para siempre contra dispositivos desinstalados). Verificamos:
//   - multicast (sendRescueAlerts): solo se purga el token con error de "no
//     registrado"; los válidos se conservan.
//   - single-send (dispatchDueReminders): el token se purga si el envío falla
//     con ese código.
//   - errores transitorios (server-unavailable): NO se purga el token.
//   - NUNCA se loguea el token (se comprueba en el código, no aquí).

import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, addMemberToHome, createTask, getDb,
} from './helpers/setup';
import { sendRescueAlerts } from '../../src/notifications/send_rescue_alerts';
import { dispatchDueReminders } from '../../src/notifications/dispatch_due_reminders';
import { sendPassNotification } from '../../src/notifications/send_pass_notification';

// Espiamos los métodos del singleton de messaging (misma instancia que capturan
// los handlers a nivel de módulo).
const mockMulticast = jest.fn();
const mockSend = jest.fn();
jest.spyOn(admin.messaging(), 'sendEachForMulticast').mockImplementation(mockMulticast as any);
jest.spyOn(admin.messaging(), 'send').mockImplementation(mockSend as any);

const runDispatch = (): Promise<any> => (dispatchDueReminders as any).run({});

const UNREGISTERED = { code: 'messaging/registration-token-not-registered' };
const TRANSIENT = { code: 'messaging/server-unavailable' };

async function getToken(uid: string): Promise<string | undefined> {
  const snap = await getDb().collection('users').doc(uid).get();
  return snap.data()?.['fcmToken'];
}

function minutesFromNow(m: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() + m * 60 * 1000));
}

beforeEach(() => {
  mockMulticast.mockReset();
  mockSend.mockReset();
});

describe('sendRescueAlerts — purga de tokens muertos (multicast)', () => {
  const HOME = 'home-rescue-purge';
  const ALIVE = 'user-alive';
  const DEAD = 'user-dead';

  beforeEach(async () => {
    await cleanAll();
    await createUser(ALIVE, { fcmToken: 'token-alive' });
    await createUser(DEAD, { fcmToken: 'token-dead' });
    await createHome(HOME, ALIVE, { name: 'Hogar Rescate' });
    await addMemberToHome(HOME, DEAD, 'member', 'active');
  });

  it('borra SOLO el token con error not-registered y conserva el válido', async () => {
    // El orden de tokens lo decide el código (entries por uid). Devolvemos una
    // respuesta por token: éxito para el válido, not-registered para el muerto.
    mockMulticast.mockImplementation(async (msg: any) => {
      const responses = (msg.tokens as string[]).map((t) =>
        t === 'token-dead'
          ? { success: false, error: UNREGISTERED }
          : { success: true, messageId: 'ok' }
      );
      return {
        successCount: responses.filter((r) => r.success).length,
        failureCount: responses.filter((r) => !r.success).length,
        responses,
      };
    });

    await sendRescueAlerts(HOME, 2);

    expect(await getToken(DEAD)).toBeUndefined(); // purgado
    expect(await getToken(ALIVE)).toBe('token-alive'); // intacto
  });

  it('error transitorio (server-unavailable) NO purga el token', async () => {
    mockMulticast.mockImplementation(async (msg: any) => {
      const responses = (msg.tokens as string[]).map((t) =>
        t === 'token-dead'
          ? { success: false, error: TRANSIENT }
          : { success: true, messageId: 'ok' }
      );
      return {
        successCount: responses.filter((r) => r.success).length,
        failureCount: responses.filter((r) => !r.success).length,
        responses,
      };
    });

    await sendRescueAlerts(HOME, 2);

    expect(await getToken(DEAD)).toBe('token-dead'); // conservado
    expect(await getToken(ALIVE)).toBe('token-alive');
  });
});

describe('dispatchDueReminders — purga de token muerto (single-send)', () => {
  const HOME = 'home-dispatch-purge';
  const OWNER = 'owner-dispatch-purge';
  const ASSIGNEE = 'assignee-dispatch-purge';

  beforeEach(async () => {
    await cleanAll();
    await createUser(OWNER);
    await createUser(ASSIGNEE, { fcmToken: 'token-to-die' });
    await createHome(HOME, OWNER, { name: 'Hogar Dispatch' });
    await addMemberToHome(HOME, ASSIGNEE, 'member', 'active', {
      notificationPrefs: { taskReminders: true, notifyOnDue: true },
    });
    await createTask(HOME, 'task-soon', ASSIGNEE, { nextDueAt: minutesFromNow(5) });
  });

  it('send() falla con not-registered → borra users/{uid}.fcmToken', async () => {
    mockSend.mockRejectedValue(UNREGISTERED);

    await runDispatch();

    expect(mockSend).toHaveBeenCalled();
    expect(await getToken(ASSIGNEE)).toBeUndefined();
  });

  it('send() falla con error transitorio → conserva el token', async () => {
    mockSend.mockRejectedValue(TRANSIENT);

    await runDispatch();

    expect(await getToken(ASSIGNEE)).toBe('token-to-die');
  });
});

describe('sendPassNotification — purga de token muerto (single-send)', () => {
  const HOME = 'home-pass-purge';
  const OWNER = 'owner-pass-purge';
  const TO = 'to-pass-purge';

  beforeEach(async () => {
    await cleanAll();
    await createUser(OWNER);
    await createUser(TO, { fcmToken: 'pass-token' });
    await createHome(HOME, OWNER, { name: 'Hogar Pase' });
    await addMemberToHome(HOME, TO, 'member', 'active');
  });

  it('send() falla con not-registered → borra el token del destinatario', async () => {
    mockSend.mockRejectedValue(UNREGISTERED);

    await sendPassNotification(HOME, 'task-x', 'Sacar basura', TO, OWNER);

    expect(await getToken(TO)).toBeUndefined();
  });

  it('send() falla con error transitorio → conserva el token', async () => {
    mockSend.mockRejectedValue(TRANSIENT);

    await sendPassNotification(HOME, 'task-x', 'Sacar basura', TO, OWNER);

    expect(await getToken(TO)).toBe('pass-token');
  });
});
