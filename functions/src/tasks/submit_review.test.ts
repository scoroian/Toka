// functions/src/tasks/submit_review.test.ts

// Calcula el avg ponderado: (oldAvg * oldCount + score) / newCount
describe("submit_review — cálculo de promedio ponderado", () => {
  function calcNewAvg(oldAvg: number, oldCount: number, score: number): number {
    const newCount = oldCount + 1;
    return (oldAvg * oldCount + score) / newCount;
  }

  it("primera valoración: avg = score", () => {
    expect(calcNewAvg(0, 0, 8)).toBe(8);
  });

  it("segunda valoración: promedio correcto", () => {
    // oldAvg=8, oldCount=1, score=10 → (8+10)/2 = 9
    expect(calcNewAvg(8, 1, 10)).toBe(9);
  });

  it("con 4 valoraciones previas de 5, nueva de 10 → 6", () => {
    expect(calcNewAvg(5, 4, 10)).toBe(6);
  });

  it("score mínimo 1 no produce negativo", () => {
    expect(calcNewAvg(10, 9, 1)).toBeGreaterThan(0);
  });
});

describe("submit_review — validación de score", () => {
  function isValidScore(score: unknown): boolean {
    return typeof score === "number" && score >= 1 && score <= 10;
  }

  it("score 1 es válido", () => expect(isValidScore(1)).toBe(true));
  it("score 10 es válido", () => expect(isValidScore(10)).toBe(true));
  it("score 0 no es válido", () => expect(isValidScore(0)).toBe(false));
  it("score 11 no es válido", () => expect(isValidScore(11)).toBe(false));
  it("score string no es válido", () => expect(isValidScore("8")).toBe(false));
});

describe("submit_review — validación de nota", () => {
  function isValidNote(note: string | undefined): boolean {
    if (note === undefined) return true;
    return note.length <= 300;
  }

  it("nota undefined es válida", () => expect(isValidNote(undefined)).toBe(true));
  it("nota de 300 chars es válida", () => expect(isValidNote("a".repeat(300))).toBe(true));
  it("nota de 301 chars no es válida", () => expect(isValidNote("a".repeat(301))).toBe(false));
});
