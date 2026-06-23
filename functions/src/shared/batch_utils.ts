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
