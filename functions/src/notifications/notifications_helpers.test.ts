// functions/src/notifications/notifications_helpers.test.ts

describe("dispatchDueReminders — deduplicación por bucket", () => {
  function buildNotifKey(taskId: string, date: Date): string {
    const bucket = Math.floor(date.getUTCMinutes() / 15) * 15;
    return `${taskId}_${date.toISOString().slice(0, 11)}${String(date.getUTCHours()).padStart(2, '0')}${String(bucket).padStart(2, '0')}`;
  }

  it("misma tarea en el mismo bucket de 15min → misma clave", () => {
    const d1 = new Date("2026-04-08T10:03:00Z");
    const d2 = new Date("2026-04-08T10:07:00Z");
    expect(buildNotifKey("t1", d1)).toBe(buildNotifKey("t1", d2));
  });
  it("misma tarea en distinto bucket → distinta clave", () => {
    const d1 = new Date("2026-04-08T10:03:00Z");
    const d2 = new Date("2026-04-08T10:18:00Z");
    expect(buildNotifKey("t1", d1)).not.toBe(buildNotifKey("t1", d2));
  });
  it("distinta tarea en mismo bucket → distinta clave", () => {
    const d = new Date("2026-04-08T10:03:00Z");
    expect(buildNotifKey("t1", d)).not.toBe(buildNotifKey("t2", d));
  });
});

describe("dispatchDueReminders — ventana de 15 minutos", () => {
  function isInNext15Minutes(taskDueMs: number, nowMs: number): boolean {
    const in15 = nowMs + 15 * 60 * 1000;
    return taskDueMs >= nowMs && taskDueMs <= in15;
  }

  it("tarea en 10 min → en ventana", () => {
    const now = Date.now();
    expect(isInNext15Minutes(now + 10 * 60 * 1000, now)).toBe(true);
  });
  it("tarea en 20 min → fuera de ventana", () => {
    const now = Date.now();
    expect(isInNext15Minutes(now + 20 * 60 * 1000, now)).toBe(false);
  });
  it("tarea en el pasado → fuera de ventana", () => {
    const now = Date.now();
    expect(isInNext15Minutes(now - 1000, now)).toBe(false);
  });
});
