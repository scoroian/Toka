# Diseño: Visualización consistente de miembros con caché

**Fecha:** 2026-04-12  
**Estado:** Aprobado

---

## Problema

En varios puntos de la app se muestran UIDs crudos (ej. `abc123def456`) o avatares con `?` en lugar del nombre y foto/iniciales del miembro. Además, los streams de Firestore se recrean innecesariamente al navegar, generando lecturas repetidas.

## Alcance

Tres focos de corrección + una mejora de infraestructura:

1. **`history_screen.dart`** — actorName y toName muestran UIDs; actorPhotoUrl siempre null
2. **`task_detail_view_model.dart`** — fallback a UID cuando el miembro no está cargado
3. **`assignment_form.dart`** — fallback a UID si nickname vacío; sin avatar en el tile
4. **Infraestructura global** — `homeMembersProvider` auto-dispose + `NetworkImage` sin caché en disco

---

## Arquitectura

### Capa de caché de miembros

**`homeMembersProvider` → `@Riverpod(keepAlive: true)`**

Actualmente es `@riverpod` (auto-dispose). Al no haber ninguna pantalla escuchando, el stream se cancela. Al volver, Firestore reconecta y re-lee todos los documentos del hogar aunque nadie haya cambiado nada.

Con `keepAlive: true`:
- El stream vive durante toda la sesión de la app
- Firestore entrega desde caché local inmediatamente al iniciar
- Solo hace lecturas server cuando un documento de miembro **realmente cambia**
- Coste típico: 3–6 reads al arrancar la app, luego 0 salvo cambio de perfil

**Efecto colateral positivo:** todas las pantallas que ya usan `homeMembersProvider` (formulario de asignación, MemberCard, etc.) se benefician automáticamente.

### Caché de imágenes de perfil

Reemplazar `NetworkImage` / `backgroundImage: NetworkImage(url)` por `CachedNetworkImageProvider` en todos los `CircleAvatar` de la app.

`cached_network_image ^3.4.1` ya está en `pubspec.yaml`. Almacena imágenes en disco respetando HTTP cache headers. Segunda apertura de cualquier pantalla → imagen desde disco, 0 peticiones de red.

---

## Cambios por archivo

### 1. `lib/features/members/application/members_provider.dart`

Cambiar la anotación de `homeMembersProvider`:

```dart
// ANTES
@riverpod
Stream<List<Member>> homeMembers(HomeMembersRef ref, String homeId) { ... }

// DESPUÉS
@Riverpod(keepAlive: true)
Stream<List<Member>> homeMembers(HomeMembersRef ref, String homeId) { ... }
```

Regenerar `members_provider.g.dart` con `build_runner`.

### 2. `lib/features/history/presentation/history_screen.dart`

`_buildEventTile` actualmente pasa `event.actorUid` como nombre y `null` como foto. La pantalla debe:

1. Suscribirse a `homeMembersProvider(homeId)` para obtener la lista de miembros
2. Construir `Map<String, Member> membersByUid` (lookup O(1))
3. En `_buildEventTile`, resolver `actorUid` → `Member` → `nickname` + `photoUrl`
4. Para `PassedEvent`, resolver `toUid` → `Member` → `nickname`
5. Fallback cuando el UID no está en el mapa: nombre = `'?'`, photoUrl = null (el avatar mostrará `?`)

```dart
// Lookup en _buildEventTile
final actor = membersByUid[event.actorUid];
final actorName = actor?.nickname ?? '?';
final actorPhotoUrl = actor?.photoUrl;

String? toName;
if (event is PassedEvent) {
  toName = membersByUid[event.toUid]?.nickname ?? '?';
}
```

El widget `_Avatar` en `history_event_tile.dart` ya muestra iniciales correctamente cuando `photoUrl` es null y el nombre es conocido — solo hay que pasarle el nombre real en lugar del UID.

### 3. `lib/features/tasks/application/task_detail_view_model.dart`

Cambiar el fallback de UID a `null`:

```dart
// ANTES
final currentAssigneeName =
    assigneeMember != null && assigneeMember.nickname.isNotEmpty
        ? assigneeMember.nickname
        : task.currentAssigneeUid;  // ← UID

// DESPUÉS
final currentAssigneeName =
    assigneeMember?.nickname.isNotEmpty == true
        ? assigneeMember!.nickname
        : null;  // la UI ya muestra '—' cuando es null
```

### 4. `lib/features/tasks/presentation/widgets/assignment_form.dart`

Dos mejoras:

- Quitar el fallback a UID: si `nickname` está vacío, mostrar string vacío (en práctica nunca ocurre tras el fix de registro)
- Añadir `CircleAvatar` con foto/iniciales como `secondary` del `CheckboxListTile`

```dart
CheckboxListTile(
  secondary: CircleAvatar(
    backgroundImage: member.photoUrl != null
        ? CachedNetworkImageProvider(member.photoUrl!)
        : null,
    child: member.photoUrl == null
        ? Text(member.nickname.isNotEmpty
              ? member.nickname[0].toUpperCase()
              : '?')
        : null,
  ),
  title: Text(member.nickname),
  ...
)
```

### 5. Avatares en toda la app

Buscar todos los usos de `NetworkImage` dentro de `CircleAvatar` y reemplazar por `CachedNetworkImageProvider`:

Archivos afectados (confirmados en exploración):
- `lib/features/members/presentation/widgets/member_card.dart`
- `lib/features/members/presentation/member_profile_screen.dart`
- `lib/features/profile/presentation/own_profile_screen.dart`
- `lib/features/tasks/presentation/widgets/today_task_card_todo.dart` (`_AssigneeAvatar`)
- `lib/features/history/presentation/widgets/history_event_tile.dart` (`_Avatar`)

Patrón de cambio:
```dart
// ANTES
CircleAvatar(backgroundImage: NetworkImage(url))

// DESPUÉS
CircleAvatar(backgroundImage: CachedNetworkImageProvider(url))
```

---

## Modelo de coste Firebase

| Evento | Reads |
|--------|-------|
| Arranque de app (hogar con 4 miembros) | 4 reads (desde caché local si ya se conectó antes) |
| Navegar entre pantallas | 0 reads (stream keepAlive) |
| Cambio de perfil de 1 miembro | 1 read (delta en tiempo real) |
| Segunda apertura de foto | 0 requests de red (disco) |

Con plan gratuito Firestore (50k reads/día): completamente dentro del umbral incluso con cientos de usuarios activos.

---

## Tests a actualizar / añadir

- Test unitario de `HistoryScreen._buildEventTile`: verifica que se pasa `nickname` en lugar de UID
- Test de widget de `AssignmentForm`: verifica que muestra avatar con iniciales
- Tests existentes de `TaskDetailViewModel`: actualizar el assert del fallback (ahora `null` en vez de UID)

---

## Archivos que NO cambian

- `home_dashboard.dart` — `TaskPreview`, `DoneTaskPreview` mantienen sus campos `*Name` y `*Photo` (ya vienen del dashboard Firestore)
- `task_form_provider.dart`, `create_edit_task_screen.dart` — no afectados
- Cloud Functions — no se tocan
- Reglas de Firestore — no se tocan
