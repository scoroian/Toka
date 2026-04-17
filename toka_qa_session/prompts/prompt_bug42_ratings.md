Eres Claude Code trabajando en la app Flutter "Toka" (proyecto Firebase: toka-dd241, rama: main).

Tu tarea es implementar y verificar la spec:
  docs/superpowers/specs/2026-04-17-ratings-implementation-design.md

**Bug #42:** Las valoraciones de tareas completadas no se guardan. El método `rateEvent()` del view model es un stub vacío con un TODO. Además, `isRated` está hardcodeado a `false`, por lo que el botón de estrella aparece siempre igual sin importar si el usuario ya valoró ese evento. No hay prevención de doble valoración en la UI.

---

## Flujo de trabajo obligatorio (repite hasta que la spec esté resuelta)

### Fase 1 — Backend: añadir `memberReviews` a la CF

1. Leer `functions/src/tasks/submit_review.ts` completo.
2. Dentro de la transacción, después de `tx.set(reviewRef, {...})`, añadir un write a `homes/{homeId}/memberReviews/{reviewerUid}`:
   ```typescript
   const memberReviewsRef = db.collection("homes").doc(homeId)
       .collection("memberReviews").doc(reviewerUid);
   tx.set(memberReviewsRef, {
     ratedEventIds: FieldValue.arrayUnion([taskEventId]),
   }, { merge: true });
   ```
3. Desplegar las functions: `cd functions && npm run build` (verificar que compila sin errores TypeScript).

### Fase 2 — Repositorio: añadir `submitReview`

4. Leer `lib/features/members/domain/members_repository.dart`.
5. Añadir a la interfaz:
   ```dart
   Future<void> submitReview({
     required String homeId,
     required String taskEventId,
     required double score,
     String? note,
   });
   ```
6. Leer `lib/features/members/data/members_repository_impl.dart`.
7. Implementar `submitReview` llamando a la CF `submitReview` con los parámetros correctos. Capturar `FirebaseFunctionsException` con code `'already-exists'` y lanzar `AlreadyRatedException`.
8. Añadir `AlreadyRatedException` en `lib/core/errors/exceptions.dart`.

### Fase 3 — Provider: `ratedEventIds`

9. Crear `lib/features/history/application/rated_events_provider.dart` con un `@riverpod` StreamProvider que lea `homes/{homeId}/memberReviews/{currentUid}` y devuelva un `Set<String>` de ids ya valorados:
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
10. Ejecutar `dart run build_runner build --delete-conflicting-outputs` para generar el código de Riverpod.

### Fase 4 — View model: implementar `rateEvent` y leer `isRated`

11. Leer `lib/features/history/application/history_view_model.dart` completo.
12. En la función factory `historyViewModel`, después de resolver `homeId`, añadir:
    ```dart
    final ratedIds = ref.watch(
      ratedEventIdsProvider(homeId: homeId, currentUid: currentUid)
    ).valueOrNull ?? {};
    ```
13. Reemplazar `const isRated = false;` (línea 144) por `final isRated = ratedIds.contains(e.id);`.
14. En `_HistoryViewModelImpl.rateEvent()`, reemplazar el TODO por la llamada real:
    ```dart
    @override
    Future<void> rateEvent(String eventId, double rating, {String? note}) async {
      if (homeId == null) return;
      await ref.read(membersRepositoryProvider).submitReview(
        homeId: homeId!,
        taskEventId: eventId,
        score: rating,
        note: note,
      );
    }
    ```

### Fase 5 — UI: diferenciar rated/unrated

15. Leer `lib/features/history/presentation/skins/history_screen_v2.dart`, método `_buildTile`.
16. Cambiar el trailing para mostrar `Icons.star` (amarillo, no pulsable) cuando `item.isRated == true`, y el `IconButton` de `Icons.star_border` solo cuando `item.canRate == true`:
    ```dart
    trailing: item.isRated
        ? const Icon(Icons.star, color: Colors.amber, size: 22)
        : item.canRate
            ? IconButton(
                key: Key('rate_button_${item.raw.id}'),
                icon: const Icon(Icons.star_border),
                tooltip: AppLocalizations.of(context).history_rate_button,
                onPressed: () => _showRateSheet(item, vm),
              )
            : null,
    ```

### Fase 6 — Verificación

17. Ejecutar `flutter analyze` — debe pasar sin errores.
18. Ejecutar `flutter run -d emulator-5554`.
19. Login como owner → tab Historial.
20. Capturar la pantalla:
    ```bash
    adb exec-out screencap -p > /tmp/screen_raw.png
    python3 -c "
    from PIL import Image
    img = Image.open('/tmp/screen_raw.png')
    if max(img.size) > 1900:
        img.thumbnail((1500, 1500), Image.LANCZOS)
    img.save('/tmp/screen.png')
    " 2>/dev/null || cp /tmp/screen_raw.png /tmp/screen.png
    ```
21. Leer `/tmp/screen.png` → identificar un evento completado por otro miembro → verificar que aparece el botón `star_border`.
22. Tap sobre el botón de estrella (coordenada derecha del tile) → verificar que se abre el sheet de valoración.
23. Seleccionar puntuación → tap Enviar.
24. Verificar que el botón cambia a `star` amarillo (sin ser pulsable).
25. Capturar para confirmar el cambio.
26. Intentar pulsar el star amarillo → no debe abrirse el sheet.
27. Cuando esté resuelto, marcar **Bug #42** como CORREGIDO en `toka_qa_session/QA_SESSION.md`.

---

## Notas importantes

- La CF `submitReview` solo funciona con hogares Premium. Si el hogar QA no es premium, la CF devuelve `failed-precondition`. En ese caso, usar los emuladores o activar Premium temporalmente en Firestore para el hogar de prueba (`premiumStatus: "active"`).
- El score en la CF va de 1 a 10 (no de 1 a 5). El `RateEventSheet` usa un `Slider` — asegúrate de que el rango coincide con lo que espera la CF.

## Cuentas de prueba

| Rol | Email | Contraseña |
|-----|-------|------------|
| Owner | toka.qa.owner@gmail.com | TokaQA2024! |
| Member | toka.qa.member@gmail.com | TokaQA2024! |

## Procedimiento de login como owner
```bash
adb shell input tap 540 1053
adb shell input text "toka.qa.owner@gmail.com"
adb shell input tap 540 1242
adb shell input text "TokaQA2024!"
adb shell input tap 540 1441
```

Responde siempre en español.
