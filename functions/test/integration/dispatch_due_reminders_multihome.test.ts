// functions/test/integration/dispatch_due_reminders_multihome.test.ts
//
// Hallazgo #15 (coste lineal de jobs): dispatchDueReminders pasa de barrer
// TODOS los homes (db.collection("homes").get() + query por hogar) a un único
// collectionGroup("tasks") filtrado por status==active y nextDueAt en ventana.
// Estos tests verifican que, cruzando varios hogares en UNA pasada, sólo se
// procesan las tareas relevantes y que el homeId se resuelve desde la ruta del
// doc (taskDoc.ref.parent.parent.id).
import * as admin from 'firebase-admin';
import {
  cleanAll, createUser, createHome, createTask,
} from './helpers/setup';
import { dispatchDueReminders } from '../../src/notifications/dispatch_due_reminders';

const mockSend = jest.fn().mockResolvedValue('mock-message-id');
jest.spyOn(admin.messaging(), 'send').mockImplementation(mockSend);

const wrapped = (data: unknown): Promise<unknown> =>
  (dispatchDueReminders as unknown as { run: (d: unknown) => Promise<unknown> }).run(data);

function minutesFromNow(minutes: number): admin.firestore.Timestamp {
  return admin.firestore.Timestamp.fromDate(new Date(Date.now() + minutes * 60 * 1000));
}

const HOME_A = 'mh-home-a';
const HOME_B = 'mh-home-b';
const HOME_IDLE = 'mh-home-idle';
const UA = 'mh-ua';
const UB = 'mh-ub';
const UI = 'mh-ui';

beforeAll(async () => {
  await cleanAll();
  await createUser(UA, { fcmToken: 'tok-a' });
  await createUser(UB, { fcmToken: 'tok-b' });
  await createUser(UI, { fcmToken: 'tok-i' });
  // createHome añade al owner como miembro activo (notifyOnDue ausente → true).
  await createHome(HOME_A, UA);
  await createHome(HOME_B, UB);
  await createHome(HOME_IDLE, UI);

  // Tareas que vencen pronto en hogares DISTINTOS → ambas deben notificar.
  await createTask(HOME_A, 'a-due', UA, { nextDueAt: minutesFromNow(5) });
  await createTask(HOME_B, 'b-due', UB, { nextDueAt: minutesFromNow(7) });
  // Fuera de ventana / hogar sin tareas due → no deben notificar.
  await createTask(HOME_A, 'a-far', UA, { nextDueAt: minutesFromNow(120) });
  await createTask(HOME_IDLE, 'idle-far', UI, { nextDueAt: minutesFromNow(300) });

  // Una sola pasada: el dedup por bucket de 15 min hace que llamadas
  // posteriores en el mismo bucket no reenvíen, así que capturamos los envíos
  // de la primera (y única) ejecución y los inspeccionamos en cada test.
  mockSend.mockClear();
  await wrapped({});
});

function sentCalls(): any[][] {
  return mockSend.mock.calls as any[][];
}

describe('dispatchDueReminders — collectionGroup cruzando varios hogares', () => {
  it('notifica las tareas que vencen en hogares DISTINTOS en una sola pasada', () => {
    const taskIds = sentCalls().map((c) => c[0]?.data?.taskId);
    expect(taskIds).toContain('a-due');
    expect(taskIds).toContain('b-due');
  });

  it('NO notifica tareas fuera de ventana ni hogares sin tareas due', () => {
    const taskIds = sentCalls().map((c) => c[0]?.data?.taskId);
    expect(taskIds).not.toContain('a-far');
    expect(taskIds).not.toContain('idle-far');
  });

  it('resuelve el homeId correcto desde la ruta del doc de tarea', () => {
    const aCall = sentCalls().find((c) => c[0]?.data?.taskId === 'a-due');
    const bCall = sentCalls().find((c) => c[0]?.data?.taskId === 'b-due');
    expect(aCall?.[0]?.data?.homeId).toBe(HOME_A);
    expect(bCall?.[0]?.data?.homeId).toBe(HOME_B);
  });
});
