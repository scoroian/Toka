// functions/src/tasks/manual_reassign.test.ts

describe("manualReassign — validación de newAssigneeUid", () => {
  type MemberDoc = { exists: boolean; status?: string };

  function validateNewAssignee(member: MemberDoc): { ok: boolean; code?: string } {
    if (!member.exists) return { ok: false, code: "new-assignee-not-in-home" };
    if (member.status !== "active") return { ok: false, code: "new-assignee-not-active" };
    return { ok: true };
  }

  it("miembro activo → ok", () => {
    expect(validateNewAssignee({ exists: true, status: "active" })).toEqual({ ok: true });
  });
  it("miembro inexistente → not-in-home", () => {
    const res = validateNewAssignee({ exists: false });
    expect(res.ok).toBe(false);
    expect(res.code).toBe("new-assignee-not-in-home");
  });
  it("miembro frozen → not-active", () => {
    const res = validateNewAssignee({ exists: true, status: "frozen" });
    expect(res.ok).toBe(false);
    expect(res.code).toBe("new-assignee-not-active");
  });
  it("miembro left → not-active", () => {
    const res = validateNewAssignee({ exists: true, status: "left" });
    expect(res.ok).toBe(false);
    expect(res.code).toBe("new-assignee-not-active");
  });
});
