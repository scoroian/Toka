// functions/src/users/cleanup_user.test.ts
import {
  pickReplacementOwner,
  computeTaskReassignment,
  type MemberSnapshot,
} from "./cleanup_user_helpers";

describe("pickReplacementOwner", () => {
  const m = (
    uid: string,
    role: string,
    status: string,
    joinedAtMillis = 0
  ): MemberSnapshot => ({ uid, role, status, joinedAtMillis });

  it("sin más miembros (solo el borrado) → null (hogar huérfano)", () => {
    expect(pickReplacementOwner([m("owner", "owner", "active")], "owner")).toBeNull();
  });

  it("solo quedan miembros 'left' → null", () => {
    const members = [
      m("owner", "owner", "active"),
      m("a", "member", "left"),
    ];
    expect(pickReplacementOwner(members, "owner")).toBeNull();
  });

  it("prefiere un admin activo sobre un member activo", () => {
    const members = [
      m("owner", "owner", "active"),
      m("memb", "member", "active", 100),
      m("adm", "admin", "active", 200),
    ];
    expect(pickReplacementOwner(members, "owner")).toBe("adm");
  });

  it("prefiere un miembro activo sobre uno congelado aunque el congelado sea admin", () => {
    const members = [
      m("owner", "owner", "active"),
      m("frozenAdmin", "admin", "frozen", 50),
      m("activeMember", "member", "active", 100),
    ];
    expect(pickReplacementOwner(members, "owner")).toBe("activeMember");
  });

  it("a igualdad de estado y rol, elige el más antiguo", () => {
    const members = [
      m("owner", "owner", "active"),
      m("new", "member", "active", 2000),
      m("old", "member", "active", 1000),
    ];
    expect(pickReplacementOwner(members, "owner")).toBe("old");
  });

  it("si solo quedan congelados, elige uno de ellos (no null)", () => {
    const members = [
      m("owner", "owner", "active"),
      m("f", "member", "frozen", 10),
    ];
    expect(pickReplacementOwner(members, "owner")).toBe("f");
  });
});

describe("computeTaskReassignment", () => {
  it("borrado NO es el responsable → conserva responsable, solo lo quita del orden", () => {
    const r = computeTaskReassignment(["a", "b", "c"], "b", "c", ["c"]);
    expect(r.newOrder).toEqual(["a", "b"]);
    expect(r.newAssignee).toBe("b");
    expect(r.changed).toBe(true);
  });

  it("borrado NO está en el orden ni es responsable → sin cambios", () => {
    const r = computeTaskReassignment(["a", "b"], "a", "x", ["x"]);
    expect(r.newOrder).toEqual(["a", "b"]);
    expect(r.newAssignee).toBe("a");
    expect(r.changed).toBe(false);
  });

  it("borrado ES el responsable → reasigna al siguiente elegible", () => {
    const r = computeTaskReassignment(["a", "b"], "a", "a", ["a"]);
    expect(r.newOrder).toEqual(["b"]);
    expect(r.newAssignee).toBe("b");
    expect(r.changed).toBe(true);
  });

  it("borrado ES el responsable y el resto está excluido → responsable null", () => {
    const r = computeTaskReassignment(["a", "b"], "a", "a", ["a", "b"]);
    expect(r.newOrder).toEqual(["b"]);
    expect(r.newAssignee).toBeNull();
  });

  it("borrado ES el responsable y era el único → orden vacío y responsable null", () => {
    const r = computeTaskReassignment(["a"], "a", "a", ["a"]);
    expect(r.newOrder).toEqual([]);
    expect(r.newAssignee).toBeNull();
  });

  it("salta a un elegible más adelante en el orden si el inmediato está excluido", () => {
    const r = computeTaskReassignment(["del", "frozen", "ok"], "del", "del", [
      "del",
      "frozen",
    ]);
    expect(r.newOrder).toEqual(["frozen", "ok"]);
    expect(r.newAssignee).toBe("ok");
  });
});
