// functions/test/integration/reset_dashboards_fanout.test.ts
//
// Hallazgo #15 (coste lineal de jobs): el reset diario de dashboards pasa de un
// job monolítico (Promise.all sobre TODOS los hogares en una invocación) a un
// fan-out de una tarea por hogar (Cloud Tasks). Estos tests ejercitan la lógica
// real de orquestación contra el emulador Firestore, inyectando el `enqueue`
// (en prod es Cloud Tasks) para no depender de la cola desplegada.
import {
  cleanAll, createUser, createHome, createTask, getDb,
} from './helpers/setup';
import {
  enqueueDashboardRebuilds, rebuildDashboardForHome,
} from '../../src/tasks/update_dashboard';

const HOME_1 = 'fanout-home-1';
const HOME_2 = 'fanout-home-2';
const HOME_PURGED = 'fanout-home-purged';
const OWNER1 = 'fanout-o1';
const OWNER2 = 'fanout-o2';
const OWNERP = 'fanout-op';

beforeAll(async () => {
  await cleanAll();
  await createUser(OWNER1);
  await createUser(OWNER2);
  await createUser(OWNERP);
  await createHome(HOME_1, OWNER1);
  await createHome(HOME_2, OWNER2);
  await createHome(HOME_PURGED, OWNERP, { premiumStatus: 'purged' });
  await createTask(HOME_1, 'h1-task', OWNER1, {});
  await createTask(HOME_2, 'h2-task', OWNER2, {});
});

describe('enqueueDashboardRebuilds — fan-out una tarea por hogar', () => {
  it('encola UNA reconstrucción por hogar vivo y EXCLUYE los purged', async () => {
    const enqueued: string[] = [];
    const res = await enqueueDashboardRebuilds(async (homeId) => {
      enqueued.push(homeId);
    });

    expect(enqueued).toContain(HOME_1);
    expect(enqueued).toContain(HOME_2);
    expect(enqueued).not.toContain(HOME_PURGED);
    expect(res.failed).toBe(0);
    expect(res.enqueued).toBe(enqueued.length);
  });

  it('aislamiento: si encolar un hogar falla, el resto se siguen encolando', async () => {
    const enqueued: string[] = [];
    const res = await enqueueDashboardRebuilds(async (homeId) => {
      if (homeId === HOME_1) throw new Error('boom enqueue');
      enqueued.push(homeId);
    });

    // HOME_2 se encoló pese a que HOME_1 falló al encolar.
    expect(enqueued).toContain(HOME_2);
    expect(enqueued).not.toContain(HOME_1);
    expect(res.failed).toBe(1);
    expect(res.enqueued).toBeGreaterThanOrEqual(1);
  });
});

describe('rebuildDashboardForHome — reconstrucción aislada por hogar', () => {
  it('reconstruye el dashboard de UN solo hogar (views/dashboard escrito)', async () => {
    await rebuildDashboardForHome(HOME_1);

    const dash = await getDb()
      .collection('homes').doc(HOME_1)
      .collection('views').doc('dashboard').get();
    expect(dash.exists).toBe(true);
    expect((dash.data() as Record<string, any>).counters.totalActiveTasks).toBe(1);
  });

  it('reintento: si la reconstrucción de un hogar falla, propaga el error (Cloud Tasks reintenta) sin afectar a otro hogar', async () => {
    const failing = async (): Promise<void> => {
      throw new Error('rebuild failed');
    };

    // La invocación de un hogar que falla relanza → Cloud Tasks reintenta SOLO ese.
    await expect(rebuildDashboardForHome(HOME_1, failing)).rejects.toThrow('rebuild failed');

    // Otro hogar es una invocación independiente: su reconstrucción funciona.
    await rebuildDashboardForHome(HOME_2);
    const dash2 = await getDb()
      .collection('homes').doc(HOME_2)
      .collection('views').doc('dashboard').get();
    expect(dash2.exists).toBe(true);
  });
});
