# P1 — Perfil de miembro no se actualiza reactivamente al cambiar rol

## Bug que corrige
- **Bug #24** — Tras promover a un miembro a Admin mediante el botón "Hacer administrador" en su perfil, la pantalla de perfil NO se actualiza reactivamente: sigue mostrando "Miembro" hasta que el usuario sale y vuelve a entrar. El provider que alimenta el perfil no se invalida al cambiar el rol en Firestore.

## Causa raíz

El provider que alimenta `MemberProfileScreen` probablemente usa un `Future` (lectura puntual) en lugar de un `Stream` (tiempo real). Al actualizar el rol en Firestore, el Future ya tiene su valor y no recibe la actualización. O bien, el Stream existe pero el provider está usando `keepAlive` o no está observando el documento correcto.

## Archivos a investigar

| Archivo | Qué buscar |
|---------|-----------|
| `lib/features/members/application/member_profile_view_model.dart` | ¿Usa FutureProvider o StreamProvider? |
| `lib/features/members/data/member_repository.dart` | ¿Hay `watchMember(uid)` que devuelva Stream? |
| `lib/features/members/presentation/member_profile_screen.dart` | ¿Cómo observa el estado del provider? |

## Cambios requeridos

### 1. Convertir el provider de perfil de Future a Stream

Si `memberProfileProvider` es un `FutureProvider`:

```dart
// ANTES — lectura puntual, no reactiva
@riverpod
Future<Member?> memberProfile(MemberProfileRef ref, String uid) async {
  return ref.read(memberRepositoryProvider).getMember(uid);
}

// DESPUÉS — stream en tiempo real
@riverpod
Stream<Member?> memberProfile(MemberProfileRef ref, String uid) {
  return ref.watch(memberRepositoryProvider).watchMember(uid);
}
```

### 2. Añadir `watchMember` en el repositorio

En `lib/features/members/data/member_repository.dart`, añadir:

```dart
Stream<Member?> watchMember(String uid) {
  final homeId = _getCurrentHomeId();
  return _firestore
      .doc('homes/$homeId/members/$uid')
      .snapshots()
      .map((snap) => snap.exists ? Member.fromJson(snap.data()!) : null);
}
```

### 3. Actualizar la UI para usar AsyncValue con Stream

En `MemberProfileScreen`:

```dart
final memberAsync = ref.watch(memberProfileProvider(uid));

return memberAsync.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, st) => ErrorWidget(e),
  data: (member) => member != null
      ? MemberProfileBody(member: member)
      : const MemberNotFoundWidget(),
);
```

### 4. Invalidar provider tras acción de cambio de rol (alternativa si no se usa stream)

Si se prefiere mantener el Future pero invalidar manualmente tras la acción:

```dart
// En el handler del botón "Hacer administrador"
onPressed: () async {
  await ref.read(memberRepositoryProvider).promoteToAdmin(uid);
  ref.invalidate(memberProfileProvider(uid)); // Forzar recarga
},
```

> Preferir el enfoque de Stream (opción 1) sobre la invalidación manual, ya que también actualizará la UI si otro dispositivo cambia el rol.

## Criterios de aceptación

- [ ] Tras promover a Admin, el perfil muestra "Admin" sin necesidad de salir y volver a entrar.
- [ ] Tras degradar de Admin a Miembro, el perfil muestra "Miembro" reactivamente.
- [ ] Los botones de gestión de rol (Hacer admin / Quitar admin) aparecen/desaparecen correctamente según el rol actual.
- [ ] No hay flash o lag visible entre la acción y la actualización de la UI.

## Tests requeridos

- Test unitario: `MemberProfileViewModel` con stream mock que emite 2 valores (Member → Admin) → UI muestra Admin sin rebuilt manual.
- Test de widget: botón "Hacer administrador" → after tap → widget muestra "Admin".
