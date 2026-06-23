// functions/src/tasks/update_dashboard.test.ts
//
// Hallazgo #07 (premortem): el dashboard se quedaba stale al crear/editar/borrar
// tareas porque dependía de una llamada de cliente (refreshDashboard) con catch
// silencioso. La corrección añade un trigger Firestore onWrite sobre las tareas
// que reconstruye el dashboard server-side. Para acotar coste, el trigger sólo
// reconstruye cuando cambia algún campo que el dashboard realmente muestra.
//
// Aquí cubrimos la guarda PURA `dashboardRelevantFieldsChanged` (sin emulador).

import * as admin from "firebase-admin";
import { dashboardRelevantFieldsChanged } from "./dashboard_dedup";

const ts = (millis: number): admin.firestore.Timestamp =>
  admin.firestore.Timestamp.fromMillis(millis);

const baseTask = () => ({
  title: "Fregar",
  status: "active",
  currentAssigneeUid: "u1",
  visualKind: "emoji",
  visualValue: "🧹",
  recurrenceType: "weekly",
  nextDueAt: ts(1_000_000),
  // Campos que el dashboard NO muestra (no deben disparar reconstrucción):
  updatedAt: ts(1_000_000),
  completedCount90d: 0,
  assignmentOrder: ["u1"],
});

describe("dashboardRelevantFieldsChanged", () => {
  it("devuelve false cuando sólo cambian campos irrelevantes para el dashboard", () => {
    const before = baseTask();
    const after = {
      ...baseTask(),
      updatedAt: ts(2_000_000), // solo cambia updatedAt
      completedCount90d: 5, // stat interna, no se muestra
    };
    expect(dashboardRelevantFieldsChanged(before, after)).toBe(false);
  });

  it("devuelve true cuando cambia el status (p.ej. borrado lógico active→deleted)", () => {
    const before = baseTask();
    const after = { ...baseTask(), status: "deleted" };
    expect(dashboardRelevantFieldsChanged(before, after)).toBe(true);
  });

  it("devuelve true cuando cambia el responsable actual (reordenar/pasar turno)", () => {
    const before = baseTask();
    const after = { ...baseTask(), currentAssigneeUid: "u2" };
    expect(dashboardRelevantFieldsChanged(before, after)).toBe(true);
  });

  it("devuelve true cuando cambia el título (editar tarea)", () => {
    const before = baseTask();
    const after = { ...baseTask(), title: "Planchar" };
    expect(dashboardRelevantFieldsChanged(before, after)).toBe(true);
  });

  it("devuelve true cuando cambia nextDueAt (Timestamp por valor temporal)", () => {
    const before = baseTask();
    const after = { ...baseTask(), nextDueAt: ts(9_999_999) };
    expect(dashboardRelevantFieldsChanged(before, after)).toBe(true);
  });

  it("devuelve false para dos Timestamp distintos pero con el mismo instante", () => {
    const before = baseTask();
    const after = { ...baseTask(), nextDueAt: ts(1_000_000) };
    expect(dashboardRelevantFieldsChanged(before, after)).toBe(false);
  });
});
