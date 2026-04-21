# Spec: Resolver UIDs en Historial y hacer visibles las notas de valoración

**Fecha:** 2026-04-21
**Estado:** Propuesto
**Prioridad:** Alta (BUG-19, BUG-20, BUG-21)

---

## Contexto

Tres bugs relacionados con transparencia del historial y las valoraciones tras QA 2026-04-20:

- **BUG-19 (alto):** En los eventos de "pase de turno" del historial, el texto muestra el UID crudo del miembro (p.ej. `zY9mR...`) en lugar de su alias/nombre. Otros tipos de evento sí resuelven el alias.
- **BUG-20 (alto):** Cuando un autor de review escribe una nota privada (`reviews/{reviewerUid}.note`), la nota **no aparece en ninguna pantalla**. El autor no puede releer lo que escribió, aunque el documento persiste correctamente en Firestore.
- **BUG-21 (alto):** El **evaluado** (performerUid de la tarea) tampoco ve la nota de la valoración que recibió, aunque el documento maestro indica que la nota debe ser privada **entre autor y evaluado** (sección 7.4).

Resultado: la feature de notas es prácticamente invisible. Los usuarios la escriben una vez, no la vuelven a ver, y dejan de usarla.

---

## Decisiones clave

- **Resolver todos los UIDs** del historial vía el `MemberDisplayCache` existente (ver spec `2026-04-12-member-display-cache-design.md`). Pasar turno no es distinto de otros eventos — la falta de resolución es un descuido.
- **Añadir una pantalla de detalle de evento** accesible desde el tile del historial, que muestra:
  - Resumen del evento (ya se muestra en el tile).
  - Si el evento tiene `reviews` asociados y el usuario actual es autor o evaluado de alguno de ellos → muestra la(s) review(s) con su nota completa.
- **La nota es visible para exactamente 2 UIDs:** `reviewerUid` y `performerUid` del evento. Cualquier otro (incluido el owner del hogar) ve el número de estrellas y la etiqueta de tags si las hubiera, pero **no** la nota.

---

## Esquema de datos

Sin cambios en Firestore. La información ya existe:

- `homes/{homeId}/taskEvents/{eventId}` — campo `performerUid` y `type` (ya presentes).
- `homes/{homeId}/taskEvents/{eventId}/reviews/{reviewerUid}` — documentos de review. Campo `note` (opcional, string), `stars` (1-5), `tags` (array).

Sólo se amplía la lectura en cliente.

---

## BUG-19: resolución de UID en "pase de turno"

### Localización

[lib/features/history/presentation/widgets/history_event_tile.dart](lib/features/history/presentation/widgets/history_event_tile.dart) formatea el texto del evento. Para `type == "taskPassed"` hoy compone algo tipo:

```dart
"${event.payload['fromUid']} pasó el turno a ${event.payload['toUid']}"
```

usando el UID crudo. Otros tipos (`taskCompleted`, `memberJoined`) usan `memberDisplayCache.displayNameOf(uid)`.

### Fix

Homogeneizar el render con un helper central:

```dart
String _nameOrFallback(String? uid, WidgetRef ref) {
  if (uid == null || uid.isEmpty) return '—';
  return ref.read(memberDisplayCacheProvider).displayNameOf(uid)
      ?? uid.substring(0, 6); // fallback corto, nunca UID completo
}
```

Reemplazar **todas** las interpolaciones `${event.payload['xxxUid']}` del tile por llamadas a `_nameOrFallback`. Auditar los casos: `taskPassed`, `taskReassigned`, `memberLeft`, `memberKicked`, `adminGranted`, `adminRevoked`.

**Test de regresión:** `history_event_tile_test.dart` existing — añadir golden por cada tipo de evento mostrando el alias resuelto.

---

## BUG-20 y BUG-21: visibilidad de notas

### Nueva pantalla: `HistoryEventDetailScreen`

Ubicación: `lib/features/history/presentation/history_event_detail_screen.dart`.
Ruta: `/history/:homeId/:eventId`. Añadir al router de la feature.

**Trigger:** cualquier evento en el historial con `type in ["taskCompleted","taskPassed","taskReassigned"]` se vuelve tapable. Al pulsar abre esta pantalla.

**Contenido:**

1. **Cabecera:** título de la tarea, fecha, visual (icono/emoji).
2. **Resumen:** tipo de evento + actores (con nombres resueltos).
3. **Bloque Reviews** (sólo si hay reviews asociadas):

   ```
   for each review r in taskEvents/{eventId}/reviews:
     // Permisos de visibilidad:
     bool canSeeStars = true; // público
     bool canSeeNote = (authUid == r.reviewerUid) || (authUid == event.performerUid);

     render:
       Avatar(r.reviewerUid)  "Valoración de ${nameOf(r.reviewerUid)}"
       Stars(r.stars)
       Tags(r.tags)
       if canSeeNote and r.note.isNotEmpty:
         Container(
           child: Text(r.note),
           decoration: subtle border,
           label: "Nota privada (sólo tú y ${nameOf(event.performerUid)})"
         )
   ```

4. **Acción "Editar mi valoración"** sólo si `authUid == r.reviewerUid` y el evento ocurrió hace ≤ 7 días (misma política que la sheet de creación).

### Provider

Nuevo `historyEventDetailProvider` en `lib/features/history/application/`:

```dart
@Riverpod(keepAlive: false)
Stream<HistoryEventDetail> historyEventDetail(
  HistoryEventDetailRef ref, {
  required String homeId,
  required String eventId,
}) async* {
  final eventDoc = FirebaseFirestore.instance
      .doc('homes/$homeId/taskEvents/$eventId');
  final reviewsCol = eventDoc.collection('reviews');

  await for (final _ in eventDoc.snapshots()) {
    final eventSnap = await eventDoc.get();
    final reviewsSnap = await reviewsCol.get();
    yield HistoryEventDetail.from(eventSnap, reviewsSnap);
  }
}
```

Simple y correcto; la carga de reviews es N<5 en el 99% de casos.

### Acceso desde el perfil del miembro

En [lib/features/members/presentation/members_screen.dart](lib/features/members/presentation/members_screen.dart) (perfil detallado del miembro), si `authUid == memberUid` o si `authUid` ha hecho alguna review sobre `memberUid`, mostrar una sección **"Últimas valoraciones"** con las 5 últimas reviews visibles (aplicando el mismo filtro `canSeeNote` de arriba). Cada item abre la pantalla de detalle de evento.

Esto da un segundo punto de descubrimiento sin duplicar la UI — el listado llama al mismo detalle.

---

## Reglas Firestore

Sin cambios. Las reglas actuales ya permiten leer `reviews/{reviewerUid}` si eres `reviewerUid` o `performerUid` del evento (verificar y, si no, endurecer):

```
match /homes/{homeId}/taskEvents/{eventId}/reviews/{reviewerUid} {
  allow read: if request.auth != null
    && (request.auth.uid == reviewerUid
        || request.auth.uid == get(/databases/$(database)/documents/homes/$(homeId)/taskEvents/$(eventId)).data.performerUid);
}
```

Si no estaba así, se añade. Para el listado desde el perfil se hace una query collectionGroup `reviews` filtrando en cliente; para listas grandes se puede optimizar con una colección de índice `users/{uid}/incomingReviews/{eventId}` — **fuera de alcance**, por ahora asumimos volumen bajo.

---

## i18n

- `historyEventDetailTitle`
- `reviewPrivateNoteLabel` — "Nota privada"
- `reviewPrivateNoteHint` — "Sólo tú y {name} veis esta nota"
- `noReviewsOnEvent` — "Aún no hay valoraciones para este evento"
- `memberProfileLastReviews` — "Últimas valoraciones"

---

## Tests

### Unitarios
- `history_event_tile_test.dart`: todos los tipos resuelven alias (no UID crudo).
- `history_event_detail_provider_test.dart`: combinaciones autor/evaluado/terceros.

### UI
- Golden `history_event_detail_screen_test.dart`:
  - Variante autor (ve nota).
  - Variante evaluado (ve nota).
  - Variante tercero (no ve nota — el bloque muestra sólo estrellas + tags).
  - Variante sin reviews.

### Integración (emuladores)
- Tres usuarios en el mismo hogar: A reseña a B; A y B ven la nota, C no.

---

## Fuera de alcance

- Permitir responder/comentar una review (feature futura).
- Adjuntar foto en la review.
- Historial por miembro — sólo el puntual de detalle; un listado global por miembro vendría de otra spec si se necesita.
- Agregación denormalizada para evitar collectionGroup reads (optimización a futuro si el coste sube).
