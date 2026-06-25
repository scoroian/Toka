// functions/src/shared/batch_utils.test.ts
//
// Hallazgo #16: el límite de 500 escrituras/batch de Firestore rompe en hogares
// grandes (>500 tareas en Premium, que no tiene tope). El emulador NO aplica ese
// límite (pasa en tests, revienta en prod), así que la garantía se testea en la
// MECÁNICA de troceo: nunca se mete más de `size` ops por lote.

import { chunked, MAX_BATCH_OPS, commitInChunks } from "./batch_utils";

describe("chunked", () => {
  test("trocea en grupos de tamaño máximo `size`", () => {
    const groups = chunked([1, 2, 3, 4, 5], 2);
    expect(groups).toEqual([[1, 2], [3, 4], [5]]);
  });

  test("array vacío → sin grupos", () => {
    expect(chunked([], 450)).toEqual([]);
  });

  test("ningún grupo supera el límite con >500 elementos", () => {
    const items = Array.from({ length: 1234 }, (_, i) => i);
    const groups = chunked(items, MAX_BATCH_OPS);
    expect(groups.every((g) => g.length <= MAX_BATCH_OPS)).toBe(true);
    // se reconstruye el original sin perder ni duplicar
    expect(groups.flat()).toEqual(items);
  });

  test("MAX_BATCH_OPS deja margen bajo el tope duro de 500 de Firestore", () => {
    expect(MAX_BATCH_OPS).toBeLessThanOrEqual(450);
  });
});

describe("commitInChunks", () => {
  // Fake de batch que registra cuántas ops recibió antes de cada commit.
  function makeRecorder() {
    const committedSizes: number[] = [];
    let current = 0;
    const makeBatch = () => {
      current = 0;
      return {
        apply() {
          current++;
        },
        async commit() {
          committedSizes.push(current);
        },
      };
    };
    return { committedSizes, makeBatch };
  }

  test("ningún batch supera MAX_BATCH_OPS y se aplican TODAS las ops (>500)", async () => {
    const items = Array.from({ length: 1234 }, (_, i) => i);
    const { committedSizes, makeBatch } = makeRecorder();
    const batches = await commitInChunks(items, makeBatch, (b) => b.apply());

    expect(committedSizes.every((n) => n <= MAX_BATCH_OPS)).toBe(true);
    expect(committedSizes.reduce((a, b) => a + b, 0)).toBe(1234); // nada perdido
    expect(batches).toBe(Math.ceil(1234 / MAX_BATCH_OPS)); // 3 lotes
  });

  test("≤ MAX_BATCH_OPS ops → un solo batch", async () => {
    const items = Array.from({ length: 25 }, (_, i) => i); // tope de un hogar con packs
    const { committedSizes, makeBatch } = makeRecorder();
    const batches = await commitInChunks(items, makeBatch, (b) => b.apply());
    expect(batches).toBe(1);
    expect(committedSizes).toEqual([25]);
  });

  test("array vacío → ningún batch (no commitea en vacío)", async () => {
    const { committedSizes, makeBatch } = makeRecorder();
    const batches = await commitInChunks([], makeBatch, (b) => b.apply());
    expect(batches).toBe(0);
    expect(committedSizes).toEqual([]);
  });
});
