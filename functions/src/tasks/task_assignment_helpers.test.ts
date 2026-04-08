// functions/src/tasks/task_assignment_helpers.test.ts
import {
  scoreOf,
  getNextAssigneeRoundRobin,
  getNextAssigneeSmart,
  addRecurrenceInterval,
} from "./task_assignment_helpers";

describe("scoreOf", () => {
  it("calcula score básico correctamente", () => {
    expect(scoreOf({ completionsRecent: 5, difficultyWeight: 2.0, daysSinceLastExecution: 0 }))
      .toBe(10);
  });
  it("penaliza por días sin ejecutar", () => {
    const s = scoreOf({ completionsRecent: 0, difficultyWeight: 1.0, daysSinceLastExecution: 10 });
    expect(s).toBe(-1);
  });
});

describe("getNextAssigneeRoundRobin", () => {
  it("retorna null para orden vacío", () => {
    expect(getNextAssigneeRoundRobin([], "u1", [])).toBeNull();
  });
  it("avanza al siguiente en orden circular", () => {
    expect(getNextAssigneeRoundRobin(["u1","u2","u3"], "u1", [])).toBe("u2");
    expect(getNextAssigneeRoundRobin(["u1","u2","u3"], "u3", [])).toBe("u1");
  });
  it("salta excluidos", () => {
    expect(getNextAssigneeRoundRobin(["u1","u2","u3"], "u1", ["u2"])).toBe("u3");
  });
  it("retorna currentUid si todos excluidos", () => {
    expect(getNextAssigneeRoundRobin(["u1","u2"], "u1", ["u2"])).toBe("u1");
  });
});

describe("getNextAssigneeSmart", () => {
  it("elige al miembro con menor score (menos carga)", () => {
    const loadData = new Map([
      ["u1", { completionsRecent: 10, difficultyWeight: 1.0, daysSinceLastExecution: 0 }],
      ["u2", { completionsRecent: 2, difficultyWeight: 1.0, daysSinceLastExecution: 0 }],
    ]);
    expect(getNextAssigneeSmart(["u1","u2"], "u1", [], loadData)).toBe("u2");
  });
  it("salta excluidos", () => {
    const loadData = new Map([
      ["u1", { completionsRecent: 0, difficultyWeight: 1.0, daysSinceLastExecution: 0 }],
      ["u2", { completionsRecent: 0, difficultyWeight: 1.0, daysSinceLastExecution: 0 }],
    ]);
    expect(getNextAssigneeSmart(["u1","u2"], "u1", ["u2"], loadData)).toBe("u1");
  });
  it("retorna currentUid para orden vacío", () => {
    expect(getNextAssigneeSmart([], "u1", [], new Map())).toBe("u1");
  });
});

describe("addRecurrenceInterval", () => {
  const base = new Date("2026-04-08T10:00:00Z");
  it("hourly +1 hora", () => {
    const r = addRecurrenceInterval(base, "hourly");
    expect(r.getUTCHours()).toBe(11);
  });
  it("daily +1 día", () => {
    const r = addRecurrenceInterval(base, "daily");
    expect(r.getUTCDate()).toBe(9);
  });
  it("weekly +7 días", () => {
    const r = addRecurrenceInterval(base, "weekly");
    expect(r.getUTCDate()).toBe(15);
  });
  it("monthly +1 mes", () => {
    const r = addRecurrenceInterval(base, "monthly");
    expect(r.getUTCMonth()).toBe(4); // Mayo
  });
  it("yearly +1 año", () => {
    const r = addRecurrenceInterval(base, "yearly");
    expect(r.getUTCFullYear()).toBe(2027);
  });
  it("tipo desconocido no modifica la fecha", () => {
    const r = addRecurrenceInterval(base, "unknown");
    expect(r.getTime()).toBe(base.getTime());
  });
});
