# Spec: Implementar valoraciones de tareas completadas (Bug #42)

**Fecha:** 2026-04-17
**Estado:** Aprobado
**Bug:** #42 (valoraciones no se guardan, botón no diferencia eventos ya valorados, no hay prevención de doble valoración)

---

## Contexto

### Causa 1 — `rateEvent()` es un stub vacío

`_HistoryViewModelImpl.rateEvent()` (líneas 100–104 de `history_view_model.dart`) tiene solo un comentario TODO y no hace nada:

```dart
@override
Future<void> rateEvent(String eventId, double rating, {String? note}) async {
  if (homeId == null) return;
  // TODO: write to homes/{homeId}/taskRatings when schema is defined
}
```

La Cloud Function `submitReview` **está completamente implementada** y lista para recibir llamadas. Solo falta invocarla desde Flutter con `{ homeId, taskEventId, score, note }`.

### Causa 2 — `isRated` siempre es `false`

En la función `historyViewModel` (línea 144 de `history_view_model.dart`):

```dart
const isRated = false; // hardcoded
```

`canRate` depende de `isRated`. Al estar siempre en `false`, el botón de estrella aparece en todos los eventos completados ajenos, aunque el usuario ya los haya valorado.

### Causa 3 — Icono no distingue estado rated/unrated

En `history_screen_v2.dart` (línea 116):

```dart
trailing: item.canRate
    ? IconButton(icon: const Icon(Icons.star_border), ...)
    : null,
```

Siempre muestra `Icons.star_border`. Cuando el usuario ya valoró, debería mostrar `Icons.star` en color amarillo y no ser pulsable.

---

## Solución

### 1. Implementar `rateEvent()` en el view model

**Archivo:** `lib/features/history/application/history_view_model.dart`

```dart
@override
Future<void> rateEvent(String eventId, double rating, {String? note}) async {
  if (homeId == null) return;
  await ref.read(membersRepositoryProvider)
      // Llamar a la CF submitReview via functions callable
      .submitReview(
        homeId: homeId!,
        taskEventId: eventId,
        score: rating,
        note: note,
      );
}
```

> Añadir `submitReview` a `MembersRepository` / `MembersRepositoryImpl` (ver sección de repositorio abajo).

### 2. Leer `isRated` desde Firestore

El check de si ya existe una valoración propia se lee de la subcolección `homes/{homeId}/taskEvents/{eventId}/reviews/{currentUid}`.

**Estrategia:** No se carga una review por cada evento individualmente (coste prohibitivo). En su lugar, para la pantalla de Historial se carga un `Set<String>` de `eventIds` que el usuario ya valoró.

**Nuevo provider:**

```dart
// lib/features/history/application/rated_events_provider.dart

@riverpod
Stream<Set<String>> ratedEventIds(RatedEventIdsRef ref, {
  required String homeId,
  required String currentUid,
}) {
  return FirebaseFirestore.instance
      .collectionGroup('reviews')
      .where('reviewerUid', isEqualTo: currentUid)
      // Limitar a reviews de este hogar (campo homeId en el doc de review no existe,
      // así que filtramos por ruta: solo taskEvents bajo este homeId)
      // Nota: collectionGroup no permite filtrar por path directamente.
      // Alternativa: leer una subcolección plana por usuario.
      .snapshots()
      .map((snap) => snap.docs
          .where((d) => d.reference.path.contains('homes/$homeId/'))
          .map((d) => d.reference.parent.parent!.id) // taskEvent id
          .toSet());
}
```

> **Alternativa más limpia:** Mantener un documento `homes/{homeId}/memberReviews/{uid}` con un array de `eventIds` ya valorados, actualizado por la CF `submitReview`. Esto evita `collectionGroup` y el filtrado manual. La CF ya actualiza `memberTaskStats`; añadir el write a `memberReviews` es trivial.

**Recomendación:** Usar la alternativa del documento `memberReviews`. La CF `submitReview` añade en la transacción:

```typescript
// En submit_review.ts, dentro de la transacción, tras crear el review:
const memberReviewsRef = db.collection("homes").doc(homeId)
    .collection("memberReviews").doc(reviewerUid);
tx.set(memberReviewsRef, {
  ratedEventIds: FieldValue.arrayUnion([taskEventId]),
}, { merge: true });
```

Y en Flutter, el provider lee este documento:

```dart
@riverpod
Stream<Set<String>> ratedEventIds(RatedEventIdsRef ref, {
  required String homeId,
  required String currentUid,
}) {
  return FirebaseFirestore.instance
      .collection('homes').doc(homeId)
      .collection('memberReviews').doc(currentUid)
      .snapshots()
      .map((snap) {
        if (!snap.exists) return <String>{};
        final ids = (snap.data()?['ratedEventIds'] as List?)?.cast<String>() ?? [];
        return ids.toSet();
      });
}
```

### 3. Usar `ratedEventIds` en `historyViewModel`

```dart
// En la función historyViewModel, después de resolver homeId:

final ratedIds = ref.watch(
  ratedEventIdsProvider(homeId: homeId, currentUid: currentUid)
).valueOrNull ?? {};

// Reemplazar `const isRated = false;` por:
final isRated = ratedIds.contains(e.id);
```

### 4. Añadir `submitReview` al repositorio

**Archivo:** `lib/features/members/domain/members_repository.dart`

```dart
Future<void> submitReview({
  required String homeId,
  required String taskEventId,
  required double score,
  String? note,
});
```

**Archivo:** `lib/features/members/data/members_repository_impl.dart`

```dart
@override
Future<void> submitReview({
  required String homeId,
  required String taskEventId,
  required double score,
  String? note,
}) async {
  try {
    await _functions.httpsCallable('submitReview').call({
      'homeId': homeId,
      'taskEventId': taskEventId,
      'score': score,
      if (note != null) 'note': note,
    });
  } on FirebaseFunctionsException catch (e) {
    if (e.code == 'already-exists') throw const AlreadyRatedException();
    rethrow;
  }
}
```

Añadir `AlreadyRatedException` en `lib/core/errors/exceptions.dart`.

### 5. Mostrar estado "ya valorado" en la UI

**Archivo:** `lib/features/history/presentation/skins/history_screen_v2.dart`

Cambiar el trailing del tile para diferenciar el estado:

```dart
// Antes:
trailing: item.canRate
    ? IconButton(icon: const Icon(Icons.star_border), ...)
    : null,

// Después:
trailing: item.isRated
    ? const Icon(Icons.star, color: Colors.amber, size: 22)  // rated, no pulsable
    : item.canRate
        ? IconButton(
            key: Key('rate_button_${item.raw.id}'),
            icon: const Icon(Icons.star_border),
            tooltip: AppLocalizations.of(context).history_rate_button,
            onPressed: () => _showRateSheet(item, vm),
          )
        : null,
```

---

## Archivos afectados

| Archivo | Acción |
|---|---|
| `lib/features/history/application/history_view_model.dart` | Implementar `rateEvent()`; leer `ratedEventIds` para `isRated` |
| `lib/features/history/application/rated_events_provider.dart` | Crear nuevo provider `ratedEventIds` |
| `lib/features/history/presentation/skins/history_screen_v2.dart` | Diferenciar icono rated/unrated |
| `lib/features/members/domain/members_repository.dart` | Añadir `submitReview()` a la interfaz |
| `lib/features/members/data/members_repository_impl.dart` | Implementar `submitReview()` llamando a la CF |
| `lib/core/errors/exceptions.dart` | Añadir `AlreadyRatedException` |
| `functions/src/tasks/submit_review.ts` | Añadir write a `memberReviews/{uid}` en la transacción |

---

## Tests requeridos

### Unitarios
- `rateEvent()` llama a `submitReview` con los parámetros correctos.
- `rateEvent()` con `AlreadyRatedException` muestra snackbar apropiado.
- `ratedEventIds` provider emite un `Set<String>` con los ids del array `ratedEventIds`.
- `isRated = true` cuando el eventId está en el set; `false` en caso contrario.
- `canRate = false` cuando `isRated = true`.

### Widget
- Evento completado ajeno no valorado: muestra `IconButton` con `Icons.star_border`.
- Evento completado ajeno ya valorado: muestra `Icon(Icons.star)` estático (no pulsable).
- Evento propio: no muestra trailing de estrella.
- Tap en `rate_button_*` → `RateEventSheet` se abre.
- Submit del sheet → llama `vm.rateEvent(eventId, rating, note: note)`.

### CF (integración)
- `submitReview` escribe el documento en `reviews/{uid}` **y** actualiza `memberReviews/{uid}.ratedEventIds`.
- Segunda llamada al mismo `taskEventId` devuelve error `already-exists`.
- No premium → error `failed-precondition`.
- Auto-review → error `permission-denied`.
