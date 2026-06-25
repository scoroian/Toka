// functions/src/shared/batch_utils.ts
//
// Hallazgo #16: utilidades para escribir en Firestore sin chocar con el límite
// DURO de 500 operaciones por `WriteBatch`/transacción. En Premium no hay tope
// de tareas, así que una operación que toque "todas las tareas/miembros" de un
// hogar (restaurar premium, reasignar las de un ex-miembro) puede superar 500 y
// reventar EN PRODUCCIÓN (el emulador NO aplica este límite → falso verde).

/** Margen bajo el tope duro de 500 de Firestore (deja hueco para writes extra). */
export const MAX_BATCH_OPS = 450;

/** Parte `items` en grupos de como mucho `size` elementos, preservando el orden. */
export function chunked<T>(items: T[], size: number): T[][] {
  if (size <= 0) throw new Error("chunked: size must be > 0");
  const groups: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    groups.push(items.slice(i, i + size));
  }
  return groups;
}

/** Interfaz mínima de un WriteBatch para poder inyectar un fake en tests. */
export interface CommittableBatch {
  commit(): Promise<unknown>;
}

/**
 * Aplica `apply` a cada item troceando en lotes de como mucho `size` ops y
 * commiteando un batch por lote (nunca un batch con >`size` ops → seguro contra
 * el límite DURO de 500 de Firestore que el emulador NO aplica). No commitea en
 * vacío. Devuelve el nº de batches commiteados.
 *
 * `makeBatch` se inyecta (`() => db.batch()` en producción) para poder testear la
 * mecánica de troceo sin Firestore.
 */
export async function commitInChunks<T, B extends CommittableBatch>(
  items: T[],
  makeBatch: () => B,
  apply: (batch: B, item: T) => void,
  size: number = MAX_BATCH_OPS,
): Promise<number> {
  let batches = 0;
  for (const group of chunked(items, size)) {
    const batch = makeBatch();
    for (const item of group) apply(batch, item);
    await batch.commit();
    batches++;
  }
  return batches;
}
