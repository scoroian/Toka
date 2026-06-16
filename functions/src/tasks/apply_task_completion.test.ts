// functions/src/tasks/apply_task_completion.test.ts
//
// Lógica pura de autorización de applyTaskCompletion. Regresión: antes solo se
// validaba que el caller fuera el currentAssigneeUid; un ex-miembro (status
// 'left') o congelado podía completar la tarea y mutar contadores/streak del
// hogar. Ahora se exige además que el caller sea miembro ACTIVO.

describe("applyTaskCompletion — autorización de miembro activo", () => {
  function canComplete(
    isAssignee: boolean,
    memberStatus: string | undefined
  ): { ok: boolean; code?: string } {
    if (!isAssignee) return { ok: false, code: "not-your-turn" };
    if (memberStatus !== "active") return { ok: false, code: "not-active-member" };
    return { ok: true };
  }

  it("asignado y activo → ok", () => {
    expect(canComplete(true, "active")).toEqual({ ok: true });
  });
  it("asignado pero ex-miembro (left) → rechazado [regresión]", () => {
    expect(canComplete(true, "left")).toEqual({ ok: false, code: "not-active-member" });
  });
  it("asignado pero congelado (frozen) → rechazado", () => {
    expect(canComplete(true, "frozen")).toEqual({ ok: false, code: "not-active-member" });
  });
  it("asignado pero sin documento de miembro → rechazado", () => {
    expect(canComplete(true, undefined)).toEqual({ ok: false, code: "not-active-member" });
  });
  it("no es su turno → rechazado", () => {
    expect(canComplete(false, "active")).toEqual({ ok: false, code: "not-your-turn" });
  });
});
