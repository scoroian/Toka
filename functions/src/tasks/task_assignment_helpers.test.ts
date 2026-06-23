// functions/src/tasks/task_assignment_helpers.test.ts
import {
  scoreOf,
  getNextAssigneeRoundRobin,
  getNextAssigneeSmart,
  countCompletionsInWindow,
  type CompletedLoadEvent,
} from "./task_assignment_helpers";

const DAY = 24 * 60 * 60 * 1000;
const NOW = 1_700_000_000_000; // instante fijo de referencia para los tests

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
  it("favorece a quien lleva más días sin ejecutar (recencia)", () => {
    const loadData = new Map([
      ["u1", { completionsRecent: 1, difficultyWeight: 1.0, daysSinceLastExecution: 0 }],  // score 1
      ["u2", { completionsRecent: 1, difficultyWeight: 1.0, daysSinceLastExecution: 30 }], // score 1 - 3 = -2
    ]);
    expect(getNextAssigneeSmart(["u1", "u2"], "u1", [], loadData)).toBe("u2");
  });
  it("la dificultad acumulada pesa en el score", () => {
    const loadData = new Map([
      ["u1", { completionsRecent: 3, difficultyWeight: 3.0, daysSinceLastExecution: 0 }], // score 9
      ["u2", { completionsRecent: 4, difficultyWeight: 1.0, daysSinceLastExecution: 0 }], // score 4
    ]);
    // u1 hizo menos tareas pero más difíciles → mayor carga → elige u2.
    expect(getNextAssigneeSmart(["u1", "u2"], "u1", [], loadData)).toBe("u2");
  });
  it("usa carga por defecto (0) para miembros sin datos", () => {
    const loadData = new Map([
      ["u1", { completionsRecent: 5, difficultyWeight: 1.0, daysSinceLastExecution: 0 }], // score 5
      // u2 sin entrada → default score 0 → menor carga
    ]);
    expect(getNextAssigneeSmart(["u1", "u2"], "u1", [], loadData)).toBe("u2");
  });
});

// Hallazgo #13: la carga del reparto inteligente debe contar las
// completaciones REALES de los últimos 60 días (eventos `taskEvents`), no un
// acumulado de por vida. `countCompletionsInWindow` es el núcleo puro.
describe("countCompletionsInWindow", () => {
  const ev = (performerUid: string, ageDays: number): CompletedLoadEvent => ({
    performerUid,
    completedAtMs: NOW - ageDays * DAY,
  });

  it("cuenta por miembro las completaciones dentro de la ventana", () => {
    const counts = countCompletionsInWindow(
      [ev("u1", 1), ev("u1", 10), ev("u2", 5)],
      NOW,
      60
    );
    expect(counts.get("u1")).toBe(2);
    expect(counts.get("u2")).toBe(1);
  });

  it("excluye eventos más antiguos que la ventana", () => {
    const counts = countCompletionsInWindow(
      [ev("u1", 30), ev("u1", 90), ev("u1", 120)],
      NOW,
      60
    );
    // solo el de hace 30 días entra; los de 90 y 120 quedan fuera
    expect(counts.get("u1")).toBe(1);
  });

  it("incluye el evento justo en el borde de la ventana (>=)", () => {
    const counts = countCompletionsInWindow([ev("u1", 60)], NOW, 60);
    expect(counts.get("u1")).toBe(1);
  });

  it("un miembro sin eventos en la ventana no aparece en el mapa", () => {
    const counts = countCompletionsInWindow([ev("u1", 90)], NOW, 60);
    expect(counts.has("u1")).toBe(false);
  });

  it("ignora eventos sin performerUid", () => {
    const counts = countCompletionsInWindow(
      [ev("", 1), ev("u1", 1)],
      NOW,
      60
    );
    expect(counts.get("u1")).toBe(1);
    expect(counts.has("")).toBe(false);
  });
});

// Hallazgo #13: el síntoma de negocio. Un miembro muy cumplidor en el pasado
// (acumulado de por vida alto) pero SIN actividad reciente NO debe quedar
// excluido del reparto inteligente para siempre. Con la carga por ventana real,
// su carga reciente es 0 y vuelve a ser elegible.
describe("reparto inteligente con carga por ventana (Hallazgo #13)", () => {
  it("un miembro muy cumplidor histórico, sin actividad en 60 días, vuelve a ser elegible", () => {
    const events: CompletedLoadEvent[] = [
      // 'veteran' completó 5 tareas pero hace 70-100 días (fuera de la ventana)
      { performerUid: "veteran", completedAtMs: NOW - 70 * DAY },
      { performerUid: "veteran", completedAtMs: NOW - 80 * DAY },
      { performerUid: "veteran", completedAtMs: NOW - 90 * DAY },
      { performerUid: "veteran", completedAtMs: NOW - 95 * DAY },
      { performerUid: "veteran", completedAtMs: NOW - 100 * DAY },
      // 'rookie' completó 3 tareas esta última semana (dentro de la ventana)
      { performerUid: "rookie", completedAtMs: NOW - 1 * DAY },
      { performerUid: "rookie", completedAtMs: NOW - 2 * DAY },
      { performerUid: "rookie", completedAtMs: NOW - 3 * DAY },
    ];
    const recent = countCompletionsInWindow(events, NOW, 60);

    // veteran: 0 reciente; rookie: 3 reciente
    expect(recent.get("veteran") ?? 0).toBe(0);
    expect(recent.get("rookie")).toBe(3);

    const loadData = new Map([
      ["veteran", { completionsRecent: recent.get("veteran") ?? 0, difficultyWeight: 1.0, daysSinceLastExecution: 0 }],
      ["rookie", { completionsRecent: recent.get("rookie") ?? 0, difficultyWeight: 1.0, daysSinceLastExecution: 0 }],
    ]);

    // El siguiente reparto recae en 'veteran' (carga reciente menor), no en
    // 'rookie'. Con el acumulado de por vida (veteran=5) habría sido al revés.
    expect(getNextAssigneeSmart(["veteran", "rookie"], "rookie", [], loadData)).toBe("veteran");
  });
});

// `addRecurrenceInterval` se eliminó (Hallazgo #10). El cálculo de la siguiente
// ocurrencia se prueba ahora en `recurrence_calculator.test.ts`.
