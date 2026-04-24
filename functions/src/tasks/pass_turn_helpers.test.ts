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

  // ── BUG-06: 2 miembros deben alternar A ↔ B al pasar turno ────────────────
  describe("BUG-06 — 2 miembros alternan A ↔ B", () => {
    it("A → pasa turno → B", () => {
      expect(getNextEligibleMember(["A", "B"], "A", [])).toBe("B");
    });
    it("B → pasa turno → A", () => {
      expect(getNextEligibleMember(["A", "B"], "B", [])).toBe("A");
    });
    it("A → B → A (alternancia estable)", () => {
      const step1 = getNextEligibleMember(["A", "B"], "A", []);
      expect(step1).toBe("B");
      const step2 = getNextEligibleMember(["A", "B"], step1, []);
      expect(step2).toBe("A");
    });
    it("con B frozen, A no rota (único activo)", () => {
      expect(getNextEligibleMember(["A", "B"], "A", ["B"])).toBe("A");
    });
  });
});
