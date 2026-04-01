# Spec-04: Modelo de cuenta, hogares y selector multi-hogar

**Dependencias previas:** Spec-00, Spec-01, Spec-02, Spec-03  
**Oleada:** Oleada 1

---

## Objetivo

Implementar el modelo completo de cuenta de usuario, la gestión de hogares (listar, cambiar, abandonar, cerrar) y el selector multi-hogar en la cabecera de la app.

---

## Reglas de negocio

1. Cada cuenta tiene **2 plazas base** + hasta **3 extra permanentes** = máximo 5.
2. Las plazas extras se desbloquean por **cobros Premium válidos** (no por pruebas, restauraciones sin cobro, pagos fallidos o reembolsos).
3. Los créditos de plaza son **permanentes e irreversibles**.
4. Al pertenecer a más de un hogar, la app abre el `lastSelectedHomeId` y muestra selector en cabecera.
5. El orden del selector: 1) último usado, 2) con tareas pendientes para mí, 3) resto por nombre.
6. El **propietario no puede abandonar** un hogar sin transferir primero la propiedad.
7. Un usuario sin plazas libres no puede crear ni aceptar invitaciones.
8. Un miembro congelado sigue contando como hogar ocupado en la cuenta.

---

## Archivos a crear

```
lib/features/homes/
├── data/
│   ├── homes_repository_impl.dart
│   └── home_model.dart
├── domain/
│   ├── homes_repository.dart
│   ├── home.dart                    (modelo freezed)
│   ├── home_membership.dart         (modelo freezed)
│   └── home_limits.dart             (modelo freezed)
├── application/
│   ├── homes_provider.dart          (lista de hogares del usuario)
│   ├── current_home_provider.dart   (hogar activo seleccionado)
│   └── home_slot_provider.dart      (plazas disponibles)
└── presentation/
    ├── home_selector_widget.dart    (cabecera/dropdown)
    ├── my_homes_screen.dart         (lista de mis hogares)
    └── home_settings_screen.dart   (ajustes del hogar activo)
```

---

## Implementación

### Modelo Home

```dart
@freezed
class Home with _$Home {
  const factory Home({
    required String id,
    required String name,
    required String ownerUid,
    required String? currentPayerUid,
    required String? lastPayerUid,
    required HomePremiumStatus premiumStatus,
    required String? premiumPlan,
    required DateTime? premiumEndsAt,
    required DateTime? restoreUntil,
    required bool autoRenewEnabled,
    required HomeLimits limits,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Home;
}

enum HomePremiumStatus {
  free, active, cancelledPendingEnd, rescue, expiredFree, restorable, purged
}
```

### HomeMembership

```dart
@freezed
class HomeMembership with _$HomeMembership {
  const factory HomeMembership({
    required String homeId,
    required String homeNameSnapshot,
    required MemberRole role,
    required BillingState billingState,
    required MemberStatus status,
    required DateTime joinedAt,
    DateTime? leftAt,
  }) = _HomeMembership;
}

enum MemberRole { owner, admin, member, frozen }
enum BillingState { currentPayer, formerPayer, none }
enum MemberStatus { active, frozen }
```

### HomesRepository

```dart
abstract interface class HomesRepository {
  Stream<List<HomeMembership>> watchUserMemberships(String uid);
  Future<Home> fetchHome(String homeId);
  Future<String> createHome(String name); // retorna homeId
  Future<void> joinHome(String inviteCode);
  Future<void> leaveHome(String homeId);
  Future<void> closeHome(String homeId);  // solo owner, borra todo
  Future<void> updateLastSelectedHome(String uid, String homeId);
  Future<int> getAvailableSlots(String uid);
}
```

### CurrentHomeProvider

```dart
@Riverpod(keepAlive: true)
class CurrentHome extends _$CurrentHome {
  @override
  AsyncValue<Home?> build() {
    final uid = ref.watch(authProvider).valueOrNull?.uid;
    if (uid == null) return const AsyncValue.data(null);
    
    // Escuchar membresías del usuario
    final memberships = ref.watch(userMembershipsProvider(uid));
    
    return memberships.when(
      data: (list) {
        if (list.isEmpty) return const AsyncValue.data(null);
        // Cargar el hogar del lastSelectedHomeId
        ...
      },
      loading: () => const AsyncValue.loading(),
      error: (e, s) => AsyncValue.error(e, s),
    );
  }
  
  Future<void> switchHome(String homeId) async {
    final uid = ref.read(authProvider).valueOrNull?.uid;
    if (uid == null) return;
    await ref.read(homesRepositoryProvider).updateLastSelectedHome(uid, homeId);
    ref.invalidateSelf();
  }
}
```

### HomeSelectorWidget

```dart
// Aparece en la AppBar/cabecera cuando el usuario tiene > 1 hogar
// Muestra el nombre del hogar actual + icono de flecha
// Al tocar, abre un BottomSheet o Popup con la lista ordenada
// Cada elemento: nombre del hogar, rol del usuario, badge si hay tareas pendientes
class HomeSelectorWidget extends ConsumerWidget { ... }
```

### Pantalla Mi perfil de hogar (homeSettings)

Secciones:
- Nombre del hogar (editable si eres owner/admin).
- Plan actual (Free / Premium con fecha de fin).
- Botón "Gestionar suscripción" (si eres owner o pagador).
- Miembros (resumen + link a pantalla completa).
- Código de invitación (generar/regenerar).
- Opciones peligrosas: "Abandonar hogar", "Cerrar hogar" (solo owner).

### Lógica de abandono de hogar

```dart
Future<void> leaveHome(String homeId) async {
  final membership = ...;
  if (membership.role == MemberRole.owner) {
    // Mostrar error: debe transferir primero la propiedad
    throw CannotLeaveAsOwnerException();
  }
  // Si es pagador, cancelar renovación (via Function)
  // Eliminar membresía
}
```

---

## Tests requeridos

### Unitarios

**`test/unit/features/homes/home_test.dart`**
- `Home.fromFirestore` parsea todos los campos.
- `HomePremiumStatus.fromString` mapea correctamente.

**`test/unit/features/homes/homes_repository_test.dart`** (mocktail)
- `watchUserMemberships` emite lista de membresías.
- `getAvailableSlots` retorna `baseSlots + lifetimeUnlocked - currentCount`.
- `createHome` lanza `NoAvailableSlotsException` si slots <= 0.
- `leaveHome` lanza `CannotLeaveAsOwnerException` si es owner.

**`test/unit/features/homes/current_home_provider_test.dart`**
- Con una membresía, devuelve el hogar correcto.
- Sin membresías, devuelve null.
- `switchHome` actualiza `lastSelectedHomeId` y recarga.

**`test/unit/features/homes/home_selector_order_test.dart`**
- Lista ordenada: primero último usado, luego con tareas pendientes, luego por nombre.

### De integración

**`test/integration/features/homes/home_creation_integration_test.dart`**
- Crear hogar → documento correcto en Firestore.
- Segunda creación → usa segunda plaza.
- Tercera creación (sin extra) → error.

**`test/integration/features/homes/leave_home_test.dart`**
- Miembro normal abandona → membresía borrada.
- Owner intenta abandonar → error.

### UI

**`test/ui/features/homes/home_selector_widget_test.dart`**
- Con un hogar: no muestra selector (solo el nombre).
- Con dos hogares: muestra selector con flecha.
- Al tocar, abre lista con ambos hogares.
- Golden test del selector con 3 hogares.

**`test/ui/features/homes/home_settings_screen_test.dart`**
- Owner ve botón "Cerrar hogar".
- Miembro no ve botón "Cerrar hogar".
- Admin ve campo de nombre editable.
- Golden test de la pantalla de ajustes del hogar.

---

## Pruebas manuales requeridas al terminar esta spec

1. **Selector multi-hogar:**
   - Con una cuenta que tiene 2 hogares, abrir la app.
   - Verificar que se abre el último hogar usado.
   - Verificar que en la cabecera aparece el nombre del hogar con un indicador de que se puede cambiar.
   - Tocar el nombre → lista de hogares → seleccionar el otro → la pantalla se actualiza.

2. **Límite de plazas:**
   - Crear una cuenta nueva → 2 plazas disponibles.
   - Crear hogar 1 → queda 1 plaza.
   - Crear hogar 2 → queda 0 plazas.
   - Intentar crear hogar 3 → mensaje "No tienes plazas disponibles".

3. **Abandonar hogar (miembro):**
   - Unirse a un hogar como miembro.
   - Ir a ajustes del hogar → "Abandonar hogar".
   - Confirmar → sale del hogar, deja de aparecer en el selector.

4. **Abandonar hogar (owner bloqueado):**
   - Ser owner de un hogar.
   - Ajustes → "Abandonar hogar" → debe mostrar un mensaje explicando que primero hay que transferir la propiedad.

5. **Código de invitación:**
   - En ajustes del hogar, tocar "Generar código de invitación".
   - Copiar el código.
   - Con otra cuenta en onboarding → "Unirme" → pegar el código → accede al hogar.

6. **Persistencia del hogar activo:**
   - Con 2 hogares, cambiar al hogar 2.
   - Cerrar y reabrir la app.
   - Debe abrirse el hogar 2 (el último seleccionado).
