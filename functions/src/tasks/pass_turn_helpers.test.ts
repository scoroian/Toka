// functions/src/tasks/pass_turn_helpers.test.ts
import { getNextEligibleMember } from "./pass_turn_helpers";

describe("getNextEligibleMember", () => {
  it("retorna currentUid para orden vacío", () => {
    expect(getNextEligibleMember([], "u1", [])).toBe("u1");
  });
  it("avanza al siguiente no congelado", () => {
    expect(getNextEligibleMember(["u1","u2","u3"], "u1", [])).toBe("u2");
  });
  it("salta miembros congelados", () => {
    expect(getNextEligibleMember(["u1","u2","u3"], "u1", ["u2"])).toBe("u3");
  });
  it("vuelve al inicio si el siguiente está congelado (circular)", () => {
    expect(getNextEligibleMember(["u1","u2","u3"], "u3", ["u1"])).toBe("u2");
  });
  it("retorna currentUid si todos los demás están congelados", () => {
    expect(getNextEligibleMember(["u1","u2","u3"], "u1", ["u2","u3"])).toBe("u1");
  });
  it("un solo miembro siempre devuelve ese mismo", () => {
    expect(getNextEligibleMember(["u1"], "u1", [])).toBe("u1");
  });
});
