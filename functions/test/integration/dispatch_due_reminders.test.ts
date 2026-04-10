// functions/test/integration/dispatch_due_reminders.test.ts
import * as admin from 'firebase-admin';
import * as functionsTest from 'firebase-functions-test';
import {
  cleanAll, createUser, createHome, addMemberToHome,
  createTask,
} from './helpers/setup';
import { dispatchDueReminders } from '../../src/notifications/dispatch_due_reminders';

// Mock de admin.messaging() antes de que dispatchDueReminders lo use
const mockSend = jest.fn().mockResolvedValue('mock-message-id');
jest.spyOn(admin, 'messaging').mockReturnValue({ send: mockSend } as any);

const testEnv = functionsTest({ projectId: process.env.GCLOUD_PROJECT });
const wrapped = testEnv.wrap(dispatchDueReminders) as (req: any) => Promise<any>;

const HOME = 'home-reminders';
const OWNER = 'owner-reminders';
const MEMBER = 'member-reminders';
const MEMBER_NO_TOKEN = 'member-no-token';
const MEMBER_NOTIF_OFF = 'member-notif-off';

function minutesFromNow(minutes: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() + minutes * 60 * 1000));
}

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER);
  await createUser(MEMBER);
  await createUser(MEMBER_NO_TOKEN);
  await createUser(MEMBER_NOTIF_OFF);
  await createHome(HOME, OWNER);

  // MEMBER con FCM token y notifyOnDue=true → debe recibir reminder
  await addMemberToHome(HOME, MEMBER, 'member', 'active', {
    notificationPrefs: { taskReminders: true, notifyOnDue: true, fcmToken: 'valid-token-abc' },
  });

  // MEMBER_NO_TOKEN sin FCM token → no debe recibir reminder
  await addMemberToHome(HOME, MEMBER_NO_TOKEN, 'member', 'active', {
    notificationPrefs: { taskReminders: true, notifyOnDue: true, fcmToken: null },
  });

  // MEMBER_NOTIF_OFF con notifyOnDue=false → no debe recibir reminder
  await addMemberToHome(HOME, MEMBER_NOTIF_OFF, 'member', 'active', {
    notificationPrefs: { taskReminders: false, notifyOnDue: false, fcmToken: 'valid-token-xyz' },
  });

  // Tarea venciendo en 5 minutos → dentro de la ventana de 15 min
  await createTask(HOME, 'task-due-soon', MEMBER, {
    nextDueAt: minutesFromNow(5),
  });

  // Tarea venciendo en 60 minutos → fuera de la ventana
  await createTask(HOME, 'task-due-far', MEMBER, {
    nextDueAt: minutesFromNow(60),
  });

  // Tarea ya completada → no debe notificar
  await createTask(HOME, 'task-done', MEMBER, {
    status: 'completed',
    nextDueAt: minutesFromNow(5),
  });

  // Tarea para MEMBER_NO_TOKEN
  await createTask(HOME, 'task-no-token', MEMBER_NO_TOKEN, {
    nextDueAt: minutesFromNow(5),
  });

  // Tarea para MEMBER_NOTIF_OFF
  await createTask(HOME, 'task-notif-off', MEMBER_NOTIF_OFF, {
    nextDueAt: minutesFromNow(5),
  });
});

beforeEach(() => {
  mockSend.mockClear();
});

afterAll(() => testEnv.cleanup());

describe('dispatchDueReminders — envío de notificaciones', () => {
  it('tarea venciendo pronto con token FCM válido → send() llamado', async () => {
    await wrapped({});

    expect(mockSend).toHaveBeenCalledWith(
      expect.objectContaining({
        token: 'valid-token-abc',
        data: expect.objectContaining({ homeId: HOME, taskId: 'task-due-soon' }),
      })
    );
  });

  it('tarea venciendo en 60 min (fuera de ventana) → NO se envía notificación', async () => {
    await wrapped({});

    const calls = mockSend.mock.calls;
    const calledForFarTask = calls.some(
      (call: any[]) => call[0]?.data?.taskId === 'task-due-far'
    );
    expect(calledForFarTask).toBe(false);
  });

  it('tarea completada → NO se envía notificación', async () => {
    await wrapped({});

    const calls = mockSend.mock.calls;
    const calledForDoneTask = calls.some(
      (call: any[]) => call[0]?.data?.taskId === 'task-done'
    );
    expect(calledForDoneTask).toBe(false);
  });

  it('assignee sin FCM token → NO se envía notificación', async () => {
    await wrapped({});

    const calls = mockSend.mock.calls;
    const calledForNoToken = calls.some(
      (call: any[]) => call[0]?.data?.taskId === 'task-no-token'
    );
    expect(calledForNoToken).toBe(false);
  });

  it('assignee con notifyOnDue=false → NO se envía notificación', async () => {
    await wrapped({});

    const calls = mockSend.mock.calls;
    const calledForNotifOff = calls.some(
      (call: any[]) => call[0]?.data?.taskId === 'task-notif-off'
    );
    expect(calledForNotifOff).toBe(false);
  });

  it('deduplicación: segunda llamada en el mismo bucket → NO duplica el envío', async () => {
    // Primera llamada
    await wrapped({});
    const firstCallCount = mockSend.mock.calls.length;

    mockSend.mockClear();

    // Segunda llamada en el mismo bucket de 15 min
    await wrapped({});
    // El sent_notification doc ya existe → no debe reenviar
    expect(mockSend.mock.calls.length).toBe(0);
  });
});
