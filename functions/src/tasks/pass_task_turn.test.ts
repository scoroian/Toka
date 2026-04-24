// functions/src/tasks/pass_task_turn.test.ts
//
// Tests unitarios de la LÓGICA de pasar turno (BUG-06).
//
// El callable completo (`passTaskTurn` en `pass_task_turn.ts`) requiere
// emuladores Firestore, que quedan fuera del alcance de `npm test`. Este
// archivo verifica el contrato clave del callable: pasar turno SIEMPRE avanza
// en assignmentOrder, independientemente de `onMissAssign` (que solo rige el
// cron de expiración).
import { getNextEligibleMember } from "./pass_turn_helpers";
import { computeNextAssignee } from "../jobs/process_expired_tasks";

describe("passTaskTurn — separación respecto al cron de miss (BUG-06)", () => {
  it("pasar turno con sameAssignee y 2 miembros → alterna A ↔ B", () => {
    // passTaskTurn usa getNextEligibleMember, que NO consulta onMissAssign.
    expect(getNextEligibleMember(["A", "B"], "A", [])).toBe("B");
    expect(getNextEligibleMember(["A", "B"], "B", [])).toBe("A");
  });

  it("cron de miss con sameAssignee → mantiene al mismo asignado", () => {
    // processExpiredTasks sí consulta onMissAssign: sameAssignee mantiene.
    expect(computeNextAssignee("sameAssignee", "A", ["A", "B"], [])).toBe("A");
    expect(computeNextAssignee("sameAssignee", "B", ["A", "B"], [])).toBe("B");
  });

  it("cron de miss con nextInRotation y 2 miembros → alterna A ↔ B", () => {
    expect(computeNextAssignee("nextInRotation", "A", ["A", "B"], [])).toBe("B");
    expect(computeNextAssignee("nextInRotation", "B", ["A", "B"], [])).toBe("A");
  });

  it("pasar turno con 3 miembros avanza al siguiente en orden", () => {
    expect(getNextEligibleMember(["A", "B", "C"], "A", [])).toBe("B");
    expect(getNextEligibleMember(["A", "B", "C"], "B", [])).toBe("C");
    expect(getNextEligibleMember(["A", "B", "C"], "C", [])).toBe("A");
  });

  it("pasar turno con un único miembro activo → no rota (noCandidate)", () => {
    // Con 1 solo miembro en el orden, o todos los demás frozen,
    // el helper devuelve currentUid; el callable debe marcar noCandidate=true.
    expect(getNextEligibleMember(["A"], "A", [])).toBe("A");
    expect(getNextEligibleMember(["A", "B"], "A", ["B"])).toBe("A");
  });
});
