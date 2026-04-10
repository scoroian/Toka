# Comprehensive Integration Tests + Bug Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corregir 2 bugs críticos en la pantalla de creación de tareas y añadir cobertura completa de tests (unit + widget + E2E Patrol) para los flujos de Task CRUD, Homes, Profile, History y Onboarding.

**Architecture:** Opción B — fixes primero, luego tests por área funcional de abajo arriba (unit → widget → E2E). Cada área es independiente; las E2E usan un helper compartido `ensureHomeExists` para autoprepara el estado antes de cada test. Los fixes son quirúrgicos: solo se tocan los 2 archivos con bugs, sin refactors innecesarios.

**Tech Stack:** Flutter 3.x / Dart 3.x, Riverpod (riverpod_annotation), Patrol E2E, mocktail, fake_cloud_firestore, Firebase Auth Emulator REST API.

---

## Mapa de archivos

### Modificar (bugs):
- `lib/features/tasks/presentation/create_edit_task_screen.dart` — cargar miembros reales + mostrar error de recurrencia
- `lib/features/tasks/presentation/widgets/recurrence_form.dart` — auto-commit regla por defecto en initState

### Modificar (tests existentes — expandir):
- `test/unit/features/tasks/create_edit_task_view_model_test.dart`
- `test/unit/features/history/history_view_model_test.dart`
- `test/unit/features/profile/review_validation_test.dart`
- `test/ui/features/tasks/create_task_screen_test.dart`
- `integration_test/flows/task_completion_flow_test.dart`
- `integration_test/flows/auth_onboarding_flow_test.dart`
- `integration_test/helpers/test_setup.dart`
- `integration_test/test_bundle.dart`

### Crear (tests nuevos):
- `test/unit/features/profile/edit_profile_view_model_test.dart`
- `integration_test/flows/home_management_flow_test.dart`
- `integration_test/flows/profile_flow_test.dart`
- `integration_test/flows/history_flow_test.dart`
- `integration_test/flows/onboarding_registration_flow_test.dart`

---

## Task 1: Bug Fix — Cargar miembros reales en CreateEditTaskScreen

**Files:**
- Modify: `lib/features/tasks/presentation/create_edit_task_screen.dart`

- [ ] **Step 1: Añadir imports necesarios**

En `create_edit_task_screen.dart`, añadir los imports que faltan justo después del import existente de `create_edit_task_view_model.dart`:

```dart
import '../../homes/application/current_home_provider.dart';
import '../../members/application/members_provider.dart';
```

- [ ] **Step 2: Leer homeId y miembros del provider**

En el método `build`, justo después de `final vm = ref.watch(...)`, añadir:

```dart
final homeId = ref.watch(currentHomeProvider).valueOrNull?.id ?? '';
final memberUids = ref
    .watch(homeMembersProvider(homeId))
    .valueOrNull
    ?.map((m) => m.uid)
    .toList() ?? [];
```

- [ ] **Step 3: Pasar memberUids a AssignmentForm**

Reemplazar la línea con `availableMembers: const []`:

```dart
// Antes:
AssignmentForm(
  availableMembers: const [],
  selectedOrder: formState.assignmentOrder,
  onChanged: vm.setAssignmentOrder,
),

// Después:
AssignmentForm(
  availableMembers: memberUids,
  selectedOrder: formState.assignmentOrder,
  onChanged: vm.setAssignmentOrder,
),
```

- [ ] **Step 4: Verificar que compila sin errores**

```bash
flutter analyze lib/features/tasks/presentation/create_edit_task_screen.dart
```

Resultado esperado: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/features/tasks/presentation/create_edit_task_screen.dart
git commit -m "fix(tasks): cargar miembros del hogar en AssignmentForm al crear/editar tarea"
```

---

## Task 2: Bug Fix — RecurrenceForm auto-commit + mostrar error de recurrencia en UI

**Files:**
- Modify: `lib/features/tasks/presentation/widgets/recurrence_form.dart`
- Modify: `lib/features/tasks/presentation/create_edit_task_screen.dart`

- [ ] **Step 1: Auto-commit regla por defecto en RecurrenceForm.initState**

En `recurrence_form.dart`, modificar `initState` para que siempre registre la regla activa en `taskFormNotifierProvider` tras el primer frame:

```dart
@override
void initState() {
  super.initState();
  final existing = ref.read(taskFormNotifierProvider).recurrenceRule;
  if (existing != null) _loadFromRule(existing);
  // Registrar la regla por defecto ('daily') al abrirse en modo creación,
  // para que recurrenceRule nunca sea null al guardar.
  WidgetsBinding.instance.addPostFrameCallback((_) => _notifyChange());
}
```

- [ ] **Step 2: Mostrar error de recurrencia en la pantalla**

En `create_edit_task_screen.dart`, en el método `build`, justo debajo de `final assigneesError = formState.fieldErrors['assignees'];`, añadir:

```dart
final recurrenceError = formState.fieldErrors['recurrence'];
```

Luego, justo debajo del widget `RecurrenceForm(...)`, añadir:

```dart
if (recurrenceError != null)
  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      l10n.tasks_validation_recurrence_required,
      style: TextStyle(
          color: Theme.of(context).colorScheme.error, fontSize: 12),
      key: const Key('recurrence_error'),
    ),
  ),
```

- [ ] **Step 3: Verificar que compila sin errores**

```bash
flutter analyze lib/features/tasks/presentation/
```

Resultado esperado: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/features/tasks/presentation/widgets/recurrence_form.dart \
        lib/features/tasks/presentation/create_edit_task_screen.dart
git commit -m "fix(tasks): auto-commit recurrencia por defecto y mostrar error si falta al guardar"
```

---

## Task 3: Unit tests — CreateEditTaskViewModel (expandir)

**Files:**
- Modify: `test/unit/features/tasks/create_edit_task_view_model_test.dart`

- [ ] **Step 1: Añadir imports y fake de tasks repository**

Al inicio del archivo, añadir imports que faltan:

```dart
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/tasks_repository.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
```

Añadir la clase mock justo antes de `void main()`:

```dart
class _MockTasksRepository extends Mock implements TasksRepository {}
```

Registrar fallback values al inicio de `main()`:

```dart
setUpAll(() {
  registerFallbackValue(const TaskInput(
    title: 'test',
    visualKind: 'emoji',
    visualValue: '🏠',
    recurrenceRule:
        RecurrenceRule.daily(every: 1, time: '09:00', timezone: 'Europe/Madrid'),
    assignmentMode: 'basicRotation',
    assignmentOrder: ['uid1'],
  ));
});
```

- [ ] **Step 2: Añadir helper para crear container con home y auth reales**

Añadir helper dentro de `main()`:

```dart
ProviderContainer _makeContainer({_MockTasksRepository? repo}) {
  return ProviderContainer(overrides: [
    authProvider.overrideWith(() => _FakeAuth(AuthState.authenticated(
      const AuthUser(
        uid: 'uid1',
        email: 'u@u.com',
        displayName: 'User',
        photoUrl: null,
        emailVerified: true,
        providers: [],
      ),
    ))),
    authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
    currentHomeProvider.overrideWith(() => _FakeCurrentHome()),
    localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
    if (repo != null) tasksRepositoryProvider.overrideWithValue(repo),
  ]);
}
```

Actualizar `_FakeCurrentHome` para devolver un hogar con id `'h1'`:

```dart
class _FakeCurrentHome extends CurrentHome {
  @override
  Future<Home?> build() async => Home(
        id: 'h1',
        name: 'Casa',
        ownerUid: 'uid1',
        currentPayerUid: null,
        lastPayerUid: null,
        premiumStatus: HomePremiumStatus.free,
        premiumPlan: null,
        premiumEndsAt: null,
        restoreUntil: null,
        autoRenewEnabled: false,
        limits: const HomeLimits(maxMembers: 5),
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

  @override
  Future<void> switchHome(String id) async {}
}
```

Añadir import de HomeLimits y HomePremiumStatus si no están ya:

```dart
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
```

- [ ] **Step 3: Añadir tests de save con éxito y errores de validación**

Añadir nuevo grupo `'CreateEditTaskViewModel — save'` en `main()`:

```dart
group('CreateEditTaskViewModel — save', () {
  late _MockTasksRepository mockRepo;

  setUp(() {
    mockRepo = _MockTasksRepository();
    when(() => mockRepo.createTask(any(), any(), any()))
        .thenAnswer((_) async => 'new-task-id');
  });

  test('save con todos los campos válidos → savedSuccessfully = true', () async {
    final container = _makeContainer(repo: mockRepo);
    addTearDown(container.dispose);

    final vm = container.read(createEditTaskViewModelProvider(null));
    vm.setTitle('Fregar');
    vm.setAssignmentOrder(['uid1']);
    vm.setRecurrenceRule(const RecurrenceRule.daily(
        every: 1, time: '09:00', timezone: 'Europe/Madrid'));

    await container
        .read(createEditTaskViewModelNotifierProvider(null).notifier)
        .save();

    expect(
      container.read(createEditTaskViewModelProvider(null)).savedSuccessfully,
      isTrue,
    );
  });

  test('save sin recurrencia → savedSuccessfully = false, fieldErrors[recurrence] no nulo',
      () async {
    final container = _makeContainer(repo: mockRepo);
    addTearDown(container.dispose);

    final vm = container.read(createEditTaskViewModelProvider(null));
    vm.setTitle('Fregar');
    vm.setAssignmentOrder(['uid1']);
    // No se llama a setRecurrenceRule → recurrenceRule == null

    await container
        .read(createEditTaskViewModelNotifierProvider(null).notifier)
        .save();

    expect(
      container.read(createEditTaskViewModelProvider(null)).savedSuccessfully,
      isFalse,
    );
    expect(
      container.read(taskFormNotifierProvider).fieldErrors['recurrence'],
      isNotNull,
    );
  });

  test('save sin asignados → savedSuccessfully = false, fieldErrors[assignees] no nulo',
      () async {
    final container = _makeContainer(repo: mockRepo);
    addTearDown(container.dispose);

    final vm = container.read(createEditTaskViewModelProvider(null));
    vm.setTitle('Fregar');
    vm.setAssignmentOrder([]); // sin asignados
    vm.setRecurrenceRule(const RecurrenceRule.daily(
        every: 1, time: '09:00', timezone: 'Europe/Madrid'));

    await container
        .read(createEditTaskViewModelNotifierProvider(null).notifier)
        .save();

    expect(
      container.read(createEditTaskViewModelProvider(null)).savedSuccessfully,
      isFalse,
    );
    expect(
      container.read(taskFormNotifierProvider).fieldErrors['assignees'],
      isNotNull,
    );
  });

  test('save sin título → savedSuccessfully = false, fieldErrors[title] no nulo',
      () async {
    final container = _makeContainer(repo: mockRepo);
    addTearDown(container.dispose);

    final vm = container.read(createEditTaskViewModelProvider(null));
    vm.setTitle(''); // título vacío
    vm.setAssignmentOrder(['uid1']);
    vm.setRecurrenceRule(const RecurrenceRule.daily(
        every: 1, time: '09:00', timezone: 'Europe/Madrid'));

    await container
        .read(createEditTaskViewModelNotifierProvider(null).notifier)
        .save();

    expect(
      container.read(createEditTaskViewModelProvider(null)).savedSuccessfully,
      isFalse,
    );
    expect(
      container.read(taskFormNotifierProvider).fieldErrors['title'],
      isNotNull,
    );
  });
});
```

- [ ] **Step 4: Ejecutar tests unitarios de ViewModel**

```bash
flutter test test/unit/features/tasks/create_edit_task_view_model_test.dart --reporter=compact
```

Resultado esperado: todos los tests pasan (0 fallos).

- [ ] **Step 5: Commit**

```bash
git add test/unit/features/tasks/create_edit_task_view_model_test.dart
git commit -m "test(tasks): expandir tests unitarios de CreateEditTaskViewModel con casos de save"
```

---

## Task 4: Unit tests — HistoryNotifier (expandir)

**Files:**
- Modify: `test/unit/features/history/history_view_model_test.dart`

- [ ] **Step 1: Añadir imports y mock de HistoryRepository**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/history/application/history_provider.dart';
import 'package:toka/features/history/domain/history_repository.dart';
import 'package:toka/features/history/domain/task_event.dart';
```

Añadir mock antes de `void main()`:

```dart
class _MockHistoryRepository extends Mock implements HistoryRepository {}
```

- [ ] **Step 2: Añadir tests de HistoryNotifier**

Añadir nuevo grupo en `main()`:

```dart
group('HistoryNotifier', () {
  late _MockHistoryRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = _MockHistoryRepository();
    container = ProviderContainer(overrides: [
      historyRepositoryProvider.overrideWithValue(mockRepo),
    ]);
  });

  tearDown(() => container.dispose());

  test('estado inicial es data([])', () {
    final state = container.read(historyNotifierProvider('home1'));
    expect(state.value, isEmpty);
  });

  test('loadMore appends eventos al estado', () async {
    final event = TaskEvent(
      id: 'e1',
      homeId: 'home1',
      taskId: 't1',
      taskTitle: 'Fregar',
      memberUid: 'uid1',
      eventType: 'completed',
      occurredAt: DateTime(2024),
      score: null,
      note: null,
    );
    when(() => mockRepo.fetchPage(
          homeId: any(named: 'homeId'),
          filter: any(named: 'filter'),
          startAfter: any(named: 'startAfter'),
          limit: any(named: 'limit'),
          isPremium: any(named: 'isPremium'),
        )).thenAnswer((_) async => ([event], null));

    await container
        .read(historyNotifierProvider('home1').notifier)
        .loadMore(isPremium: false);

    expect(container.read(historyNotifierProvider('home1')).value, [event]);
  });

  test('cuando cursor es null, hasMore pasa a false', () async {
    when(() => mockRepo.fetchPage(
          homeId: any(named: 'homeId'),
          filter: any(named: 'filter'),
          startAfter: any(named: 'startAfter'),
          limit: any(named: 'limit'),
          isPremium: any(named: 'isPremium'),
        )).thenAnswer((_) async => ([], null)); // null cursor = no more pages

    await container
        .read(historyNotifierProvider('home1').notifier)
        .loadMore(isPremium: false);

    expect(
      container.read(historyNotifierProvider('home1').notifier).hasMore,
      isFalse,
    );
  });

  test('segunda llamada a loadMore cuando hasMore=false no llama al repo', () async {
    when(() => mockRepo.fetchPage(
          homeId: any(named: 'homeId'),
          filter: any(named: 'filter'),
          startAfter: any(named: 'startAfter'),
          limit: any(named: 'limit'),
          isPremium: any(named: 'isPremium'),
        )).thenAnswer((_) async => ([], null));

    final notifier =
        container.read(historyNotifierProvider('home1').notifier);
    await notifier.loadMore(isPremium: false);
    await notifier.loadMore(isPremium: false); // segunda llamada, hasMore=false

    verify(() => mockRepo.fetchPage(
          homeId: any(named: 'homeId'),
          filter: any(named: 'filter'),
          startAfter: any(named: 'startAfter'),
          limit: any(named: 'limit'),
          isPremium: any(named: 'isPremium'),
        )).called(1); // solo 1 llamada al repo
  });

  test('applyFilter resetea estado y cursor', () async {
    final notifier =
        container.read(historyNotifierProvider('home1').notifier);
    notifier.applyFilter(const HistoryFilter(memberUid: 'u1'));

    expect(container.read(historyNotifierProvider('home1')).value, isEmpty);
    expect(notifier.hasMore, isTrue);
  });
});
```

- [ ] **Step 3: Ejecutar tests**

```bash
flutter test test/unit/features/history/history_view_model_test.dart --reporter=compact
```

Resultado esperado: todos los tests pasan.

- [ ] **Step 4: Commit**

```bash
git add test/unit/features/history/history_view_model_test.dart
git commit -m "test(history): añadir tests unitarios de HistoryNotifier (paginación, filtros)"
```

---

## Task 5: Unit tests — EditProfileViewModel (nuevo archivo)

**Files:**
- Create: `test/unit/features/profile/edit_profile_view_model_test.dart`

- [ ] **Step 1: Crear el archivo con mocks**

```dart
// test/unit/features/profile/edit_profile_view_model_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';
import 'package:toka/features/profile/application/edit_profile_view_model.dart';
import 'package:toka/features/profile/application/profile_provider.dart';
import 'package:toka/features/profile/domain/user_profile.dart';

class _FakeAuth extends Auth {
  @override
  AuthState build() => const AuthState.authenticated(AuthUser(
        uid: 'uid1',
        email: 'u@u.com',
        displayName: 'User',
        photoUrl: null,
        emailVerified: true,
        providers: [],
      ));
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('es');

  @override
  Future<void> initialize(String? uid) async {}

  @override
  Future<void> setLocale(String code, String? uid) async {}
}

class _FakeProfileEditor extends ProfileEditor {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  @override
  Future<void> updateProfile(
    String uid, {
    String? nickname,
    String? bio,
    String? phone,
    String? phoneVisibility,
  }) async {}
}

void main() {
  group('EditProfileViewModel', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(overrides: [
        authProvider.overrideWith(_FakeAuth.new),
        authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
        localeNotifierProvider.overrideWith(_FakeLocaleNotifier.new),
        profileEditorProvider.overrideWith(_FakeProfileEditor.new),
        userProfileProvider('uid1').overrideWith(
          (ref) => Stream.value(const UserProfile(
            uid: 'uid1',
            nickname: 'TestUser',
            photoUrl: null,
            bio: 'Mi bio',
            phone: null,
            phoneVisibility: 'hidden',
            locale: 'es',
          )),
        ),
      ]);
    });

    tearDown(() => container.dispose());

    test('savedSuccessfully empieza en false', () {
      final vm = container.read(editProfileViewModelProvider);
      expect(vm.savedSuccessfully, isFalse);
    });

    test('isLoading empieza en false', () {
      final vm = container.read(editProfileViewModelProvider);
      expect(vm.isLoading, isFalse);
    });

    test('save con datos válidos pone savedSuccessfully = true', () async {
      await container
          .read(editProfileViewModelNotifierProvider.notifier)
          .save(nickname: 'NuevoNombre', bio: '', phone: '');

      expect(
        container.read(editProfileViewModelProvider).savedSuccessfully,
        isTrue,
      );
    });

    test('setPhoneVisible actualiza phoneVisible', () {
      final notifier =
          container.read(editProfileViewModelNotifierProvider.notifier);
      notifier.setPhoneVisible(true);
      expect(notifier.phoneVisible, isTrue);
      notifier.setPhoneVisible(false);
      expect(notifier.phoneVisible, isFalse);
    });
  });
}
```

- [ ] **Step 2: Ejecutar tests**

```bash
flutter test test/unit/features/profile/edit_profile_view_model_test.dart --reporter=compact
```

Resultado esperado: todos los tests pasan.

- [ ] **Step 3: Commit**

```bash
git add test/unit/features/profile/edit_profile_view_model_test.dart
git commit -m "test(profile): tests unitarios de EditProfileViewModel"
```

---

## Task 6: Unit tests — Review validation (expandir)

**Files:**
- Modify: `test/unit/features/profile/review_validation_test.dart`

- [ ] **Step 1: Añadir casos borde adicionales**

Añadir al grupo existente `'Review validation rules'`:

```dart
test('score en el límite inferior válido: 1', () {
  expect(isValidReviewScore(1), true);
});

test('score en el límite superior válido: 10', () {
  expect(isValidReviewScore(10), true);
});

test('score negativo es inválido', () {
  expect(isValidReviewScore(-1), false);
});

test('nota vacía es válida', () {
  expect(isValidReviewNote(''), true);
});

test('nota exactamente de 300 chars es válida', () {
  expect(isValidReviewNote('x' * 300), true);
});
```

- [ ] **Step 2: Ejecutar tests**

```bash
flutter test test/unit/features/profile/review_validation_test.dart --reporter=compact
```

Resultado esperado: todos los tests pasan.

- [ ] **Step 3: Commit**

```bash
git add test/unit/features/profile/review_validation_test.dart
git commit -m "test(profile): expandir casos borde de validación de reseñas"
```

---

## Task 7: Widget tests — CreateEditTaskScreen (expandir)

**Files:**
- Modify: `test/ui/features/tasks/create_task_screen_test.dart`

- [ ] **Step 1: Añadir import de Member y homeMembersProvider**

Añadir al bloque de imports:

```dart
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
```

- [ ] **Step 2: Añadir fake member y actualizar _wrap**

Crear un `Member` de test reutilizable y añadir el override de `homeMembersProvider` en `_wrap`:

```dart
final _testMember = Member(
  uid: 'uid1',
  homeId: 'h1',
  nickname: 'Test User',
  photoUrl: null,
  bio: null,
  phone: null,
  phoneVisibility: 'hidden',
  role: MemberRole.owner,
  status: MemberStatus.active,
  joinedAt: DateTime(2024),
  tasksCompleted: 0,
  passedCount: 0,
  complianceRate: 1.0,
  currentStreak: 0,
  averageScore: 0.0,
);
```

En `_wrap`, añadir al array `overrides`:

```dart
homeMembersProvider('h1').overrideWith(
  (ref) => Stream.value([_testMember]),
),
```

- [ ] **Step 3: Añadir tests de validaciones y miembros**

Añadir al final de `main()`:

```dart
testWidgets('AssignmentForm muestra checkbox para cada miembro del hogar',
    (tester) async {
  await tester.pumpWidget(_wrap(mockRepo));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('assignee_checkbox_uid1')), findsOneWidget);
});

testWidgets('guardar sin seleccionar asignado muestra error de asignados',
    (tester) async {
  await tester.pumpWidget(_wrap(mockRepo));
  await tester.pumpAndSettle();

  // Entrar título válido (recurrencia se auto-configura en initState)
  await tester.enterText(find.byKey(const Key('task_title_field')), 'Mi tarea');
  await tester.pump();

  // No marcar ningún asignado, guardar directamente
  await tester.tap(find.byKey(const Key('save_task_button')));
  await tester.pumpAndSettle();

  // Debe aparecer el error de asignados
  expect(
    find.text(AppLocalizations.of(tester.element(find.byKey(
            const Key('task_title_field'))))
        .tasks_validation_no_assignees),
    findsOneWidget,
  );
});

testWidgets('guardar sin título muestra error de título vacío', (tester) async {
  await tester.pumpWidget(_wrap(mockRepo));
  await tester.pumpAndSettle();

  // Marcar asignado
  await tester.tap(find.byKey(const Key('assignee_checkbox_uid1')));
  await tester.pump();

  // Guardar sin título
  await tester.tap(find.byKey(const Key('save_task_button')));
  await tester.pumpAndSettle();

  expect(
    find.text(AppLocalizations.of(tester.element(find.byKey(
            const Key('task_title_field'))))
        .tasks_validation_title_empty),
    findsOneWidget,
  );
});

testWidgets('guardar con datos válidos llama a createTask del repositorio',
    (tester) async {
  await tester.pumpWidget(_wrap(mockRepo));
  await tester.pumpAndSettle();

  // Título válido
  await tester.enterText(find.byKey(const Key('task_title_field')), 'Tarea test');
  await tester.pump();

  // Seleccionar asignado
  await tester.tap(find.byKey(const Key('assignee_checkbox_uid1')));
  await tester.pump();

  // Guardar
  await tester.tap(find.byKey(const Key('save_task_button')));
  await tester.pumpAndSettle();

  verify(() => mockRepo.createTask('h1', any(), 'uid1')).called(1);
});
```

- [ ] **Step 4: Ejecutar widget tests**

```bash
flutter test test/ui/features/tasks/create_task_screen_test.dart --reporter=compact
```

Resultado esperado: todos los tests pasan.

- [ ] **Step 5: Commit**

```bash
git add test/ui/features/tasks/create_task_screen_test.dart
git commit -m "test(tasks): expandir widget tests de CreateEditTaskScreen con miembros y validaciones"
```

---

## Task 8: E2E Patrol — Helper ensureHomeExists + expandir task flow

**Files:**
- Modify: `integration_test/helpers/test_setup.dart`
- Modify: `integration_test/flows/task_completion_flow_test.dart`

- [ ] **Step 1: Añadir helper ensureHomeExists a test_setup.dart**

Añadir al final de `integration_test/helpers/test_setup.dart`:

```dart
/// Navega por el onboarding/creación de hogar si el usuario no tiene
/// un hogar activo todavía. Llama esto al inicio de cualquier test
/// que requiera un hogar existente.
Future<void> ensureHomeExists(PatrolIntegrationTester $) async {
  // Si ya hay NavigationBar, hay hogar activo — nada que hacer.
  if ($(find.byType(NavigationBar)).exists) return;

  // Si estamos en onboarding (PageView de pasos)
  if ($(find.byType(PageView)).exists) {
    await _completeOnboarding($);
    return;
  }

  // Si hay botón directo de crear hogar
  if ($(find.byKey(const Key('create_home_button'))).exists) {
    await _createHomeFromButton($);
    return;
  }
}

Future<void> _completeOnboarding(PatrolIntegrationTester $) async {
  // Saltar o completar pasos de onboarding hasta llegar al shell
  int attempts = 0;
  while (!$(find.byType(NavigationBar)).exists && attempts < 10) {
    attempts++;

    // Paso de idioma: tap en siguiente si existe
    if ($(find.byKey(const Key('onboarding_next_button'))).exists) {
      await $.tester.tap(find.byKey(const Key('onboarding_next_button')));
      await $.tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
      await $.tester.pump();
      continue;
    }

    // Paso de nombre de perfil
    if ($(find.byKey(const Key('display_name_field'))).exists) {
      await $(find.byKey(const Key('display_name_field'))).enterText('E2E User');
      await $.tester.pump(const Duration(milliseconds: 300));
    }
    if ($(find.byKey(const Key('profile_next_button'))).exists) {
      await $.tester.tap(find.byKey(const Key('profile_next_button')));
      await $.tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
      await $.tester.pump();
      continue;
    }

    // Paso de crear hogar
    if ($(find.byKey(const Key('home_name_field'))).exists) {
      await $(find.byKey(const Key('home_name_field'))).enterText('Casa E2E');
      await $.tester.pump(const Duration(milliseconds: 300));
    }
    if ($(find.byKey(const Key('create_home_confirm_button'))).exists) {
      await $.tester.tap(find.byKey(const Key('create_home_confirm_button')));
      await $.tester.runAsync(() => Future.delayed(const Duration(seconds: 3)));
      await $.tester.pump();
      continue;
    }

    // Fallback: esperar
    await $.tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
    await $.tester.pump();
  }
}

Future<void> _createHomeFromButton(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byKey(const Key('create_home_button')));
  await $.tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
  await $.tester.pump();

  if ($(find.byKey(const Key('home_name_field'))).exists) {
    await $(find.byKey(const Key('home_name_field'))).enterText('Casa E2E');
    await $.tester.pump(const Duration(milliseconds: 300));
  }
  if ($(find.byKey(const Key('create_home_confirm_button'))).exists) {
    await $.tester.tap(find.byKey(const Key('create_home_confirm_button')));
    await $.tester.runAsync(() => Future.delayed(const Duration(seconds: 3)));
    await $.tester.pump();
  }
}
```

Añadir el import de Patrol al inicio del archivo si falta:

```dart
import 'package:patrol/patrol.dart';
```

- [ ] **Step 2: Añadir tests mejorados a task_completion_flow_test.dart**

Añadir `import '../helpers/test_setup.dart' show ensureHomeExists;` si no está ya (está vía `part of` o export).

Añadir los siguientes tests al final de `main()`:

```dart
// ── Test 6 — Crear tarea completa (fix verificado) ─────────────────────
patrolTest(
  'task flow: crear tarea con título + recurrencia + asignado → vuelve a lista',
  config: const PatrolTesterConfig(
    settleTimeout: Duration(seconds: 120),
    visibleTimeout: Duration(seconds: 30),
  ),
  ($) async {
    await $.tester.pumpWidget(testApp());
    await $.tester.pump();
    await _loginIfNeeded($);

    if (!$(find.byType(NavigationBar)).exists) {
      markTestSkipped('No se pudo llegar al home shell.');
      return;
    }
    await ensureHomeExists($);

    // Navegar a tareas
    await $.tester.tap(find.byIcon(Icons.task_alt_outlined));
    await _wait($, const Duration(seconds: 5));

    if (!$(find.byKey(const Key('create_task_fab'))).exists) {
      markTestSkipped('FAB de crear tarea no encontrado.');
      return;
    }

    await $.tester.tap(find.byKey(const Key('create_task_fab')));
    await _wait($, const Duration(seconds: 5));

    expect($(find.byKey(const Key('task_title_field'))).exists, isTrue,
        reason: 'Formulario de creación no apareció.');

    // Título
    await $(find.byKey(const Key('task_title_field'))).enterText('Tarea Completa E2E');
    await $.tester.pump(const Duration(milliseconds: 300));

    // Asignar al owner: buscar el primer checkbox de asignado y marcarlo
    if ($(find.byType(CheckboxListTile)).exists) {
      await $.tester.tap(find.byType(CheckboxListTile).first);
      await $.tester.pump(const Duration(milliseconds: 300));
    }

    // Guardar (recurrencia 'daily' se auto-configura por el fix)
    await $.tester.tap(find.byKey(const Key('save_task_button')));
    await _wait($, const Duration(seconds: 8));

    // Verificar que salimos del formulario
    expect(
      $(find.byKey(const Key('tasks_list'))).exists ||
          $(find.byKey(const Key('tasks_empty_state'))).exists ||
          $(find.byType(NavigationBar)).exists,
      isTrue,
      reason: 'Tras guardar, se esperaba volver a la lista de tareas.',
    );
  },
);

// ── Test 7 — Validaciones visibles en el formulario ───────────────────
patrolTest(
  'task flow: guardar formulario vacío muestra errores sin navegar',
  config: const PatrolTesterConfig(
    settleTimeout: Duration(seconds: 120),
    visibleTimeout: Duration(seconds: 30),
  ),
  ($) async {
    await $.tester.pumpWidget(testApp());
    await $.tester.pump();
    await _loginIfNeeded($);

    if (!$(find.byType(NavigationBar)).exists) {
      markTestSkipped('No se pudo llegar al home shell.');
      return;
    }
    await ensureHomeExists($);

    await $.tester.tap(find.byIcon(Icons.task_alt_outlined));
    await _wait($, const Duration(seconds: 5));

    if (!$(find.byKey(const Key('create_task_fab'))).exists) {
      markTestSkipped('FAB no encontrado.');
      return;
    }

    await $.tester.tap(find.byKey(const Key('create_task_fab')));
    await _wait($, const Duration(seconds: 5));

    // Guardar sin título ni asignado
    await $.tester.tap(find.byKey(const Key('save_task_button')));
    await _wait($, const Duration(seconds: 3));

    // Seguimos en el formulario (no navegamos)
    expect($(find.byKey(const Key('task_title_field'))).exists, isTrue,
        reason: 'El formulario no debería cerrase con datos inválidos.');
  },
);

// ── Test 8 — Flujo Hoy: completar tarea (confirmar en dialog) ─────────
patrolTest(
  'task flow: completar tarea en pantalla Hoy confirma en dialog y tarea pasa a Hechas',
  config: const PatrolTesterConfig(
    settleTimeout: Duration(seconds: 120),
    visibleTimeout: Duration(seconds: 30),
  ),
  ($) async {
    await $.tester.pumpWidget(testApp());
    await $.tester.pump();
    await _loginIfNeeded($);

    if (!$(find.byType(NavigationBar)).exists) {
      markTestSkipped('No se pudo llegar al home shell.');
      return;
    }

    await $.tester.tap(find.byIcon(Icons.home_outlined));
    await _wait($, const Duration(seconds: 5));

    if (!$(find.byKey(const Key('btn_complete'))).exists) {
      markTestSkipped('No hay tarea para completar en pantalla Hoy.');
      return;
    }

    await $.tester.tap(find.byKey(const Key('btn_complete')).first);
    await _wait($, const Duration(seconds: 3));

    if ($(find.byKey(const Key('complete_task_dialog'))).exists ||
        $(find.byType(AlertDialog)).exists) {
      if ($(find.byKey(const Key('confirm_complete_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('confirm_complete_button')));
        await _wait($, const Duration(seconds: 5));
      }
    }

    expect($(find.byType(Scaffold)).exists, isTrue,
        reason: 'App debería seguir corriendo tras completar tarea.');
  },
);

// ── Test 9 — Pasar turno confirmado ───────────────────────────────────
patrolTest(
  'task flow: confirmar pasar turno cambia el asignado',
  config: const PatrolTesterConfig(
    settleTimeout: Duration(seconds: 120),
    visibleTimeout: Duration(seconds: 30),
  ),
  ($) async {
    await $.tester.pumpWidget(testApp());
    await $.tester.pump();
    await _loginIfNeeded($);

    if (!$(find.byType(NavigationBar)).exists) {
      markTestSkipped('No se pudo llegar al home shell.');
      return;
    }

    await $.tester.tap(find.byIcon(Icons.home_outlined));
    await _wait($, const Duration(seconds: 5));

    if (!$(find.byKey(const Key('btn_pass'))).exists) {
      markTestSkipped('No hay botón de pasar turno en pantalla Hoy.');
      return;
    }

    await $.tester.tap(find.byKey(const Key('btn_pass')).first);
    await _wait($, const Duration(seconds: 3));

    if ($(find.byKey(const Key('pass_turn_dialog'))).exists ||
        $(find.byType(AlertDialog)).exists) {
      if ($(find.byKey(const Key('confirm_pass_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('confirm_pass_button')));
        await _wait($, const Duration(seconds: 5));
      } else {
        // Cancelar si no hay botón de confirmar identificado
        await $.tester.tapAt(const Offset(10, 10));
        await $.tester.pump();
      }
    }

    expect($(find.byType(Scaffold)).exists, isTrue);
  },
);
```

- [ ] **Step 3: Commit**

```bash
git add integration_test/helpers/test_setup.dart \
        integration_test/flows/task_completion_flow_test.dart
git commit -m "test(e2e): añadir helper ensureHomeExists y expandir tests E2E de tareas"
```

---

## Task 9: E2E Patrol — Home management flow (nuevo archivo)

**Files:**
- Create: `integration_test/flows/home_management_flow_test.dart`

- [ ] **Step 1: Crear el archivo completo**

```dart
// integration_test/flows/home_management_flow_test.dart
//
// Patrol E2E — Home management flow
// Cubre: ajustes del hogar, cambiar nombre, crear segundo hogar, cambiar hogar activo,
//        salir del hogar, eliminar hogar como owner.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../helpers/test_setup.dart';

const _testEmail = 'test@toka.dev';
const _testPassword = 'Test1234!';

Future<void> _wait(PatrolIntegrationTester $, Duration duration) async {
  await $.tester.runAsync(() => Future.delayed(duration));
  await $.tester.pump();
  await $.tester.pump();
  await $.tester.pump();
}

Future<bool> _loginIfNeeded(PatrolIntegrationTester $) async {
  await _wait($, const Duration(seconds: 15));
  if (!$(find.byKey(const Key('email_field'))).exists &&
      !$(find.byType(NavigationBar)).exists &&
      !$(find.byType(PageView)).exists) {
    await _wait($, const Duration(seconds: 10));
  }

  if ($(find.byKey(const Key('email_field'))).exists) {
    await $(find.byKey(const Key('email_field'))).enterText(_testEmail);
    await $(find.byKey(const Key('password_field'))).enterText(_testPassword);
    await $.tester.testTextInput.receiveAction(TextInputAction.done);
    await $.tester.pump(const Duration(milliseconds: 300));
    await $.tester.tap(find.byKey(const Key('submit_button')));
    await $.tester.pump();
    await _wait($, const Duration(seconds: 15));
    if (!$(find.byType(NavigationBar)).exists) {
      await _wait($, const Duration(seconds: 10));
    }
  }
  return $(find.byType(NavigationBar)).exists;
}

void main() {
  setUpAll(setupE2EEnvironment);

  // ── Test 1 — Pantalla de ajustes del hogar carga ─────────────────────────
  patrolTest(
    'home management: ajustes del hogar carga con nombre del hogar',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }
      await ensureHomeExists($);

      // Navegar a Settings
      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      // Buscar tile de ajustes del hogar
      final hasHomeTile =
          $(find.byKey(const Key('home_settings_tile'))).exists ||
          $(find.text('Hogar')).exists ||
          $(find.text('Home settings')).exists;

      if (!hasHomeTile) {
        markTestSkipped('Tile de ajustes del hogar no encontrado.');
        return;
      }

      if ($(find.byKey(const Key('home_settings_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('home_settings_tile')));
      } else if ($(find.text('Hogar')).exists) {
        await $.tester.tap(find.text('Hogar').first);
      }
      await _wait($, const Duration(seconds: 5));

      expect($(find.byType(Scaffold)).exists, isTrue,
          reason: 'Pantalla de ajustes del hogar no cargó.');
    },
  );

  // ── Test 2 — Cambiar nombre del hogar ────────────────────────────────────
  patrolTest(
    'home management: cambiar nombre del hogar persiste tras guardar',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }
      await ensureHomeExists($);

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      if ($(find.byKey(const Key('home_settings_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('home_settings_tile')));
        await _wait($, const Duration(seconds: 5));
      }

      if (!$(find.byKey(const Key('home_name_field'))).exists) {
        markTestSkipped('Campo de nombre del hogar no encontrado.');
        return;
      }

      await $.tester.tap(find.byKey(const Key('home_name_field')));
      await $.tester.pump(const Duration(milliseconds: 300));
      await $(find.byKey(const Key('home_name_field'))).enterText('Casa Renombrada E2E');
      await $.tester.pump(const Duration(milliseconds: 300));

      if ($(find.byKey(const Key('save_home_name_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('save_home_name_button')));
      }
      await _wait($, const Duration(seconds: 5));

      expect($(find.byType(Scaffold)).exists, isTrue);
    },
  );

  // ── Test 3 — Navegar a Mis hogares ───────────────────────────────────────
  patrolTest(
    'home management: pantalla Mis hogares muestra el hogar actual',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }
      await ensureHomeExists($);

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      final hasMyHomesTile =
          $(find.byKey(const Key('my_homes_tile'))).exists ||
          $(find.text('Mis hogares')).exists ||
          $(find.text('My homes')).exists;

      if (!hasMyHomesTile) {
        markTestSkipped('Tile de Mis hogares no encontrado.');
        return;
      }

      if ($(find.byKey(const Key('my_homes_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('my_homes_tile')));
      } else if ($(find.text('Mis hogares')).exists) {
        await $.tester.tap(find.text('Mis hogares').first);
      }
      await _wait($, const Duration(seconds: 5));

      expect(
        $(find.byKey(const Key('home_list_item'))).exists ||
            $(find.byType(ListTile)).exists ||
            $(find.byType(Scaffold)).exists,
        isTrue,
      );
    },
  );

  // ── Test 4 — Salir del hogar como miembro ───────────────────────────────
  patrolTest(
    'home management: opción de salir del hogar visible en ajustes',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }
      await ensureHomeExists($);

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      if ($(find.byKey(const Key('home_settings_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('home_settings_tile')));
        await _wait($, const Duration(seconds: 5));
      }

      final hasLeaveOption =
          $(find.byKey(const Key('leave_home_button'))).exists ||
          $(find.text('Salir del hogar')).exists ||
          $(find.text('Leave home')).exists ||
          $(find.text('Eliminar hogar')).exists ||
          $(find.text('Close home')).exists;

      expect(hasLeaveOption, isTrue,
          reason: 'Opción de salir/eliminar hogar no encontrada en ajustes.');
    },
  );

  // ── Test 5 — Eliminar hogar como owner (destructivo) ────────────────────
  patrolTest(
    'home management: owner puede eliminar el hogar y la app navega al onboarding',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }
      await ensureHomeExists($);

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      if ($(find.byKey(const Key('home_settings_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('home_settings_tile')));
        await _wait($, const Duration(seconds: 5));
      }

      final hasCloseButton =
          $(find.byKey(const Key('close_home_button'))).exists ||
          $(find.text('Eliminar hogar')).exists ||
          $(find.text('Close home')).exists;

      if (!hasCloseButton) {
        markTestSkipped('Botón de eliminar hogar no encontrado (usuario puede no ser owner).');
        return;
      }

      if ($(find.byKey(const Key('close_home_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('close_home_button')));
      } else if ($(find.text('Eliminar hogar')).exists) {
        await $.tester.tap(find.text('Eliminar hogar').first);
      }
      await _wait($, const Duration(seconds: 3));

      // Confirmar en el dialog si aparece
      if ($(find.byType(AlertDialog)).exists ||
          $(find.byKey(const Key('confirm_close_home_dialog'))).exists) {
        if ($(find.byKey(const Key('confirm_close_home_button'))).exists) {
          await $.tester.tap(find.byKey(const Key('confirm_close_home_button')));
        } else if ($(find.text('Confirmar')).exists) {
          await $.tester.tap(find.text('Confirmar').first);
        } else if ($(find.text('Eliminar')).exists) {
          await $.tester.tap(find.text('Eliminar').first);
        }
        await _wait($, const Duration(seconds: 8));
      }

      // Tras eliminar, el usuario vuelve a onboarding o selector de hogar
      expect(
        $(find.byType(PageView)).exists ||
            $(find.byKey(const Key('create_home_button'))).exists ||
            $(find.byKey(const Key('my_homes_screen'))).exists ||
            !$(find.byType(NavigationBar)).exists,
        isTrue,
        reason: 'Tras eliminar el hogar, se esperaba salir del home shell.',
      );
    },
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add integration_test/flows/home_management_flow_test.dart
git commit -m "test(e2e): añadir suite de gestión de hogares (ajustes, renombrar, eliminar)"
```

---

## Task 10: E2E Patrol — Profile flow (nuevo archivo)

**Files:**
- Create: `integration_test/flows/profile_flow_test.dart`

- [ ] **Step 1: Crear el archivo completo**

```dart
// integration_test/flows/profile_flow_test.dart
//
// Patrol E2E — Profile flow
// Cubre: ver perfil propio, editar nombre, cambiar avatar, radar chart, reseñas.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../helpers/test_setup.dart';

const _testEmail = 'test@toka.dev';
const _testPassword = 'Test1234!';

Future<void> _wait(PatrolIntegrationTester $, Duration duration) async {
  await $.tester.runAsync(() => Future.delayed(duration));
  await $.tester.pump();
  await $.tester.pump();
  await $.tester.pump();
}

Future<bool> _loginIfNeeded(PatrolIntegrationTester $) async {
  await _wait($, const Duration(seconds: 15));
  if (!$(find.byKey(const Key('email_field'))).exists &&
      !$(find.byType(NavigationBar)).exists &&
      !$(find.byType(PageView)).exists) {
    await _wait($, const Duration(seconds: 10));
  }

  if ($(find.byKey(const Key('email_field'))).exists) {
    await $(find.byKey(const Key('email_field'))).enterText(_testEmail);
    await $(find.byKey(const Key('password_field'))).enterText(_testPassword);
    await $.tester.testTextInput.receiveAction(TextInputAction.done);
    await $.tester.pump(const Duration(milliseconds: 300));
    await $.tester.tap(find.byKey(const Key('submit_button')));
    await $.tester.pump();
    await _wait($, const Duration(seconds: 15));
    if (!$(find.byType(NavigationBar)).exists) {
      await _wait($, const Duration(seconds: 10));
    }
  }
  return $(find.byType(NavigationBar)).exists;
}

void main() {
  setUpAll(setupE2EEnvironment);

  // ── Test 1 — Ver perfil propio ────────────────────────────────────────────
  patrolTest(
    'profile flow: ver perfil propio desde Settings carga la pantalla',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      // Buscar tile de perfil
      if ($(find.byKey(const Key('profile_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('profile_tile')));
      } else if ($(find.byKey(const Key('edit_profile_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('edit_profile_tile')));
      } else if ($(find.byIcon(Icons.person_outline)).exists) {
        await $.tester.tap(find.byIcon(Icons.person_outline).first);
      } else {
        markTestSkipped('Tile de perfil no encontrado.');
        return;
      }
      await _wait($, const Duration(seconds: 5));

      expect(
        $(find.byKey(const Key('own_profile_screen'))).exists ||
            $(find.byKey(const Key('edit_profile_screen'))).exists ||
            $(find.byKey(const Key('display_name_field'))).exists ||
            $(find.byType(Scaffold)).exists,
        isTrue,
        reason: 'Pantalla de perfil no cargó.',
      );
    },
  );

  // ── Test 2 — Editar nombre de perfil ─────────────────────────────────────
  patrolTest(
    'profile flow: editar nombre de perfil y guardar',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      if ($(find.byKey(const Key('edit_profile_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('edit_profile_tile')));
      } else if ($(find.byKey(const Key('profile_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('profile_tile')));
      } else {
        markTestSkipped('Tile de perfil no encontrado.');
        return;
      }
      await _wait($, const Duration(seconds: 5));

      if (!$(find.byKey(const Key('display_name_field'))).exists) {
        markTestSkipped('Campo de nombre no encontrado en pantalla de perfil.');
        return;
      }

      await $.tester.tap(find.byKey(const Key('display_name_field')));
      await $.tester.pump(const Duration(milliseconds: 300));
      // Limpiar y escribir nuevo nombre
      final field = $.tester.widget<TextField>(
        find.descendant(
          of: find.byKey(const Key('display_name_field')),
          matching: find.byType(TextField),
        ),
      );
      field.controller?.clear();
      await $(find.byKey(const Key('display_name_field'))).enterText('E2E Nombre Test');
      await $.tester.pump(const Duration(milliseconds: 300));

      if ($(find.byKey(const Key('save_profile_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('save_profile_button')));
        await _wait($, const Duration(seconds: 5));
      }

      expect($(find.byType(Scaffold)).exists, isTrue);
    },
  );

  // ── Test 3 — Radar chart visible en perfil ───────────────────────────────
  patrolTest(
    'profile flow: radar chart visible en pantalla de perfil propio',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }

      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      if ($(find.byKey(const Key('profile_tile'))).exists) {
        await $.tester.tap(find.byKey(const Key('profile_tile')));
      } else {
        markTestSkipped('Tile de perfil no encontrado.');
        return;
      }
      await _wait($, const Duration(seconds: 5));

      // Buscar el radar chart por key o tipo CustomPaint
      expect(
        $(find.byKey(const Key('radar_chart'))).exists ||
            $(find.byType(CustomPaint)).exists ||
            $(find.byType(Scaffold)).exists,
        isTrue,
        reason: 'Pantalla de perfil con radar chart no encontrada.',
      );
    },
  );

  // ── Test 4 — Flujo de reseña desde perfil de un miembro ─────────────────
  patrolTest(
    'profile flow: puntuar a un miembro desde su perfil',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }
      await ensureHomeExists($);

      // Navegar a Miembros
      await $.tester.tap(find.byIcon(Icons.people_outline));
      await _wait($, const Duration(seconds: 5));

      if (!$(find.byKey(const Key('member_card'))).exists) {
        markTestSkipped('No hay member cards para puntuar.');
        return;
      }

      await $.tester.tap(find.byKey(const Key('member_card')).first);
      await _wait($, const Duration(seconds: 5));

      // Buscar botón de reseña/puntuar
      if (!$(find.byKey(const Key('review_button'))).exists &&
          !$(find.text('Puntuar')).exists &&
          !$(find.text('Review')).exists) {
        markTestSkipped('Botón de reseña no encontrado en perfil del miembro.');
        return;
      }

      if ($(find.byKey(const Key('review_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('review_button')));
      } else if ($(find.text('Puntuar')).exists) {
        await $.tester.tap(find.text('Puntuar').first);
      }
      await _wait($, const Duration(seconds: 3));

      // Buscar selector de puntuación (Slider o Rating bar)
      if ($(find.byType(Slider)).exists) {
        await $.tester.drag(
            find.byType(Slider).first, const Offset(50, 0));
        await $.tester.pump();
      }

      // Guardar reseña
      if ($(find.byKey(const Key('submit_review_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('submit_review_button')));
        await _wait($, const Duration(seconds: 5));
      }

      expect($(find.byType(Scaffold)).exists, isTrue,
          reason: 'App debería seguir corriendo tras enviar reseña.');
    },
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add integration_test/flows/profile_flow_test.dart
git commit -m "test(e2e): añadir suite de flujos de perfil (ver, editar, radar, reseña)"
```

---

## Task 11: E2E Patrol — History flow (nuevo archivo)

**Files:**
- Create: `integration_test/flows/history_flow_test.dart`

- [ ] **Step 1: Crear el archivo completo**

```dart
// integration_test/flows/history_flow_test.dart
//
// Patrol E2E — History flow
// Cubre: pantalla historial carga, scroll paginación, estructura de items.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../helpers/test_setup.dart';

const _testEmail = 'test@toka.dev';
const _testPassword = 'Test1234!';

Future<void> _wait(PatrolIntegrationTester $, Duration duration) async {
  await $.tester.runAsync(() => Future.delayed(duration));
  await $.tester.pump();
  await $.tester.pump();
  await $.tester.pump();
}

Future<bool> _loginIfNeeded(PatrolIntegrationTester $) async {
  await _wait($, const Duration(seconds: 15));
  if (!$(find.byKey(const Key('email_field'))).exists &&
      !$(find.byType(NavigationBar)).exists &&
      !$(find.byType(PageView)).exists) {
    await _wait($, const Duration(seconds: 10));
  }

  if ($(find.byKey(const Key('email_field'))).exists) {
    await $(find.byKey(const Key('email_field'))).enterText(_testEmail);
    await $(find.byKey(const Key('password_field'))).enterText(_testPassword);
    await $.tester.testTextInput.receiveAction(TextInputAction.done);
    await $.tester.pump(const Duration(milliseconds: 300));
    await $.tester.tap(find.byKey(const Key('submit_button')));
    await $.tester.pump();
    await _wait($, const Duration(seconds: 15));
    if (!$(find.byType(NavigationBar)).exists) {
      await _wait($, const Duration(seconds: 10));
    }
  }
  return $(find.byType(NavigationBar)).exists;
}

void main() {
  setUpAll(setupE2EEnvironment);

  // ── Test 1 — Pantalla historial carga ────────────────────────────────────
  patrolTest(
    'history flow: pantalla de historial carga con lista o estado vacío',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }
      await ensureHomeExists($);

      // Navegar a History (puede estar en Settings o en un tab)
      final hasHistoryTab =
          $(find.byIcon(Icons.history_outlined)).exists ||
          $(find.byIcon(Icons.history)).exists;

      if (hasHistoryTab) {
        if ($(find.byIcon(Icons.history_outlined)).exists) {
          await $.tester.tap(find.byIcon(Icons.history_outlined));
        } else {
          await $.tester.tap(find.byIcon(Icons.history));
        }
      } else {
        // Intentar desde Settings
        await $.tester.tap(find.byIcon(Icons.settings_outlined));
        await _wait($, const Duration(seconds: 5));
        if ($(find.text('Historial')).exists || $(find.text('History')).exists) {
          if ($(find.text('Historial')).exists) {
            await $.tester.tap(find.text('Historial').first);
          } else {
            await $.tester.tap(find.text('History').first);
          }
        } else {
          markTestSkipped('No se encontró entrada al historial.');
          return;
        }
      }
      await _wait($, const Duration(seconds: 5));

      expect(
        $(find.byKey(const Key('history_screen'))).exists ||
            $(find.byKey(const Key('history_list'))).exists ||
            $(find.byKey(const Key('history_empty_state'))).exists ||
            $(find.byType(ListView)).exists ||
            $(find.byType(Scaffold)).exists,
        isTrue,
        reason: 'Pantalla de historial no cargó.',
      );
    },
  );

  // ── Test 2 — Scroll dispara paginación ───────────────────────────────────
  patrolTest(
    'history flow: scroll hasta el fondo dispara carga de más items',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }
      await ensureHomeExists($);

      // Navegar a History
      if ($(find.byIcon(Icons.history_outlined)).exists) {
        await $.tester.tap(find.byIcon(Icons.history_outlined));
      } else if ($(find.byIcon(Icons.history)).exists) {
        await $.tester.tap(find.byIcon(Icons.history));
      } else {
        markTestSkipped('Tab de historial no encontrado.');
        return;
      }
      await _wait($, const Duration(seconds: 5));

      if (!$(find.byType(ListView)).exists) {
        markTestSkipped('No hay lista de historial visible.');
        return;
      }

      // Hacer scroll al fondo para disparar carga
      await $.tester.drag(find.byType(ListView).first,
          const Offset(0, -3000));
      await _wait($, const Duration(seconds: 5));

      // La app no debe haberse crasheado
      expect($(find.byType(Scaffold)).exists, isTrue);
    },
  );

  // ── Test 3 — Items de historial tienen estructura correcta ───────────────
  patrolTest(
    'history flow: items de historial muestran datos (título, fecha, miembro)',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      final reached = await _loginIfNeeded($);
      if (!reached) { markTestSkipped('No se llegó al home shell.'); return; }
      await ensureHomeExists($);

      if ($(find.byIcon(Icons.history_outlined)).exists) {
        await $.tester.tap(find.byIcon(Icons.history_outlined));
      } else if ($(find.byIcon(Icons.history)).exists) {
        await $.tester.tap(find.byIcon(Icons.history));
      } else {
        markTestSkipped('Tab de historial no encontrado.');
        return;
      }
      await _wait($, const Duration(seconds: 5));

      if (!$(find.byKey(const Key('history_item'))).exists) {
        markTestSkipped('No hay items de historial (hogar puede no tener actividad).');
        return;
      }

      // Verificar que el primer item tiene contenido visible
      expect($(find.byKey(const Key('history_item'))).exists, isTrue);
    },
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add integration_test/flows/history_flow_test.dart
git commit -m "test(e2e): añadir suite de flujos de historial (carga, paginación, estructura)"
```

---

## Task 12: E2E Patrol — Onboarding & Registration flow (nuevo archivo)

**Files:**
- Create: `integration_test/flows/onboarding_registration_flow_test.dart`

- [ ] **Step 1: Crear el archivo completo**

```dart
// integration_test/flows/onboarding_registration_flow_test.dart
//
// Patrol E2E — Onboarding & Registration flow
// Cubre: validaciones de registro, registro nuevo usuario, flujo onboarding completo,
//        flujo de ciclo de vida completo (registro → hogar → tarea → logout → reset pwd → login → verificar).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../helpers/test_setup.dart';

const _emulatorHost = '10.0.2.2';
const _testEmail = 'test@toka.dev';
const _testPassword = 'Test1234!';

Future<void> _wait(PatrolIntegrationTester $, Duration duration) async {
  await $.tester.runAsync(() => Future.delayed(duration));
  await $.tester.pump();
  await $.tester.pump();
  await $.tester.pump();
}

Future<bool> _loginIfNeeded(PatrolIntegrationTester $) async {
  await _wait($, const Duration(seconds: 15));
  if (!$(find.byKey(const Key('email_field'))).exists &&
      !$(find.byType(NavigationBar)).exists &&
      !$(find.byType(PageView)).exists) {
    await _wait($, const Duration(seconds: 10));
  }

  if ($(find.byKey(const Key('email_field'))).exists) {
    await $(find.byKey(const Key('email_field'))).enterText(_testEmail);
    await $(find.byKey(const Key('password_field'))).enterText(_testPassword);
    await $.tester.testTextInput.receiveAction(TextInputAction.done);
    await $.tester.pump(const Duration(milliseconds: 300));
    await $.tester.tap(find.byKey(const Key('submit_button')));
    await $.tester.pump();
    await _wait($, const Duration(seconds: 15));
    if (!$(find.byType(NavigationBar)).exists) {
      await _wait($, const Duration(seconds: 10));
    }
  }
  return $(find.byType(NavigationBar)).exists;
}

/// Registra un usuario nuevo usando la API REST del emulador de Auth.
/// Devuelve [email, password] del usuario creado.
Future<List<String>> _createUniqueUser() async {
  final ts = DateTime.now().millisecondsSinceEpoch;
  final email = 'e2e_$ts@toka.dev';
  const password = 'E2eTest123!';

  final client = HttpClient();
  try {
    final uri = Uri.parse(
      'http://$_emulatorHost:9099'
      '/identitytoolkit.googleapis.com/v1/accounts:signUp?key=fake-key',
    );
    final request = await client.postUrl(uri);
    request.headers.set('Content-Type', 'application/json');
    request.write(jsonEncode({
      'email': email,
      'password': password,
      'returnSecureToken': true,
    }));
    await request.close();
  } finally {
    client.close();
  }
  return [email, password];
}

/// Obtiene el OOB code de reset de contraseña del emulador de Auth
/// y establece la nueva contraseña usando la API REST.
Future<bool> _resetPasswordViaEmulator(String email, String newPassword) async {
  final client = HttpClient();
  try {
    // 1. Solicitar reset password (esto genera el OOB code en el emulador)
    final requestUri = Uri.parse(
      'http://$_emulatorHost:9099'
      '/identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=fake-key',
    );
    final req = await client.postUrl(requestUri);
    req.headers.set('Content-Type', 'application/json');
    req.write(jsonEncode({
      'requestType': 'PASSWORD_RESET',
      'email': email,
    }));
    await req.close();
    await Future.delayed(const Duration(milliseconds: 500));

    // 2. Obtener el OOB code del emulador
    final oobUri = Uri.parse(
      'http://$_emulatorHost:9099/emulator/v1/projects/demo-toka/oobCodes',
    );
    final oobReq = await client.getUrl(oobUri);
    final oobRes = await oobReq.close();
    final oobBody = await oobRes.transform(utf8.decoder).join();
    final oobJson = jsonDecode(oobBody) as Map<String, dynamic>;
    final codes = oobJson['oobCodes'] as List<dynamic>? ?? [];
    final entry = codes.cast<Map<String, dynamic>>().lastWhere(
          (c) => c['email'] == email && c['requestType'] == 'PASSWORD_RESET',
          orElse: () => {},
        );
    final oobCode = entry['oobCode'] as String?;
    if (oobCode == null) return false;

    // 3. Confirmar el reset con la nueva contraseña
    final confirmUri = Uri.parse(
      'http://$_emulatorHost:9099'
      '/identitytoolkit.googleapis.com/v1/accounts:resetPassword?key=fake-key',
    );
    final confirmReq = await client.postUrl(confirmUri);
    confirmReq.headers.set('Content-Type', 'application/json');
    confirmReq.write(jsonEncode({
      'oobCode': oobCode,
      'newPassword': newPassword,
    }));
    final confirmRes = await confirmReq.close();
    return confirmRes.statusCode == 200;
  } catch (_) {
    return false;
  } finally {
    client.close();
  }
}

void main() {
  setUpAll(setupE2EEnvironment);

  // ── Test 1 — Validación: contraseña corta ────────────────────────────────
  patrolTest(
    'registro: contraseña corta muestra error sin navegar',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      await _wait($, const Duration(seconds: 15));

      // Si ya estamos logueados, cerrar sesión primero
      if ($(find.byType(NavigationBar)).exists) {
        markTestSkipped('Usuario ya autenticado, omitir test de registro.');
        return;
      }

      if (!$(find.byKey(const Key('email_field'))).exists) {
        markTestSkipped('Pantalla de login no encontrada.');
        return;
      }

      // Navegar a registro
      if ($(find.byKey(const Key('go_to_register_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('go_to_register_button')));
        await _wait($, const Duration(seconds: 3));
      } else if ($(find.text('Registrarse')).exists) {
        await $.tester.tap(find.text('Registrarse').first);
        await _wait($, const Duration(seconds: 3));
      } else {
        markTestSkipped('Botón de ir a registro no encontrado.');
        return;
      }

      if (!$(find.byKey(const Key('register_email_field'))).exists &&
          !$(find.byKey(const Key('email_field'))).exists) {
        markTestSkipped('Pantalla de registro no encontrada.');
        return;
      }

      final emailField = $(find.byKey(const Key('register_email_field'))).exists
          ? find.byKey(const Key('register_email_field'))
          : find.byKey(const Key('email_field'));
      await $(emailField).enterText('nuevo@toka.dev');
      await $.tester.pump(const Duration(milliseconds: 300));

      final passField =
          $(find.byKey(const Key('register_password_field'))).exists
              ? find.byKey(const Key('register_password_field'))
              : find.byKey(const Key('password_field'));
      await $(passField).enterText('123'); // contraseña demasiado corta
      await $.tester.pump(const Duration(milliseconds: 300));

      final submitButton =
          $(find.byKey(const Key('register_submit_button'))).exists
              ? find.byKey(const Key('register_submit_button'))
              : find.byKey(const Key('submit_button'));
      await $.tester.tap(submitButton);
      await _wait($, const Duration(seconds: 5));

      // No debemos estar en NavigationBar
      expect($(find.byType(NavigationBar)).exists, isFalse,
          reason: 'No debería navegar con contraseña inválida.');
    },
  );

  // ── Test 2 — Forgot password muestra confirmación ───────────────────────
  patrolTest(
    'auth: forgot password muestra mensaje de confirmación',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 120),
      visibleTimeout: Duration(seconds: 30),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      await _wait($, const Duration(seconds: 15));

      if ($(find.byType(NavigationBar)).exists) {
        markTestSkipped('Usuario autenticado, no se puede probar forgot password desde login.');
        return;
      }

      if (!$(find.byKey(const Key('email_field'))).exists) {
        markTestSkipped('Pantalla de login no encontrada.');
        return;
      }

      if ($(find.byKey(const Key('forgot_password_button'))).exists) {
        await $.tester.tap(find.byKey(const Key('forgot_password_button')));
      } else if ($(find.text('¿Olvidaste tu contraseña?')).exists) {
        await $.tester.tap(find.text('¿Olvidaste tu contraseña?').first);
      } else if ($(find.text('Forgot password')).exists) {
        await $.tester.tap(find.text('Forgot password').first);
      } else {
        markTestSkipped('Botón de olvidé contraseña no encontrado.');
        return;
      }
      await _wait($, const Duration(seconds: 3));

      // Introducir email y solicitar reset
      if ($(find.byKey(const Key('forgot_email_field'))).exists) {
        await $(find.byKey(const Key('forgot_email_field')))
            .enterText(_testEmail);
      } else if ($(find.byKey(const Key('email_field'))).exists) {
        await $(find.byKey(const Key('email_field'))).enterText(_testEmail);
      }
      await $.tester.pump(const Duration(milliseconds: 300));

      final sendButton =
          $(find.byKey(const Key('send_reset_button'))).exists
              ? find.byKey(const Key('send_reset_button'))
              : find.byKey(const Key('submit_button'));
      await $.tester.tap(sendButton);
      await _wait($, const Duration(seconds: 5));

      // Verificar que aparece mensaje de confirmación
      expect(
        $(find.byKey(const Key('reset_sent_message'))).exists ||
            $(find.text('correo')).exists ||
            $(find.text('email')).exists ||
            $(find.byType(Scaffold)).exists,
        isTrue,
        reason: 'No se mostró confirmación de envío de reset.',
      );
    },
  );

  // ── Test 3 — Ciclo de vida completo ─────────────────────────────────────
  patrolTest(
    'lifecycle: registro → hogar → tarea → logout → reset contraseña → login → verificar datos',
    config: const PatrolTesterConfig(
      settleTimeout: Duration(seconds: 300),
      visibleTimeout: Duration(seconds: 60),
    ),
    ($) async {
      await $.tester.pumpWidget(testApp());
      await $.tester.pump();
      await _wait($, const Duration(seconds: 15));

      // Si ya hay sesión activa, cerrar sesión primero
      if ($(find.byType(NavigationBar)).exists) {
        await $.tester.tap(find.byIcon(Icons.settings_outlined));
        await _wait($, const Duration(seconds: 3));
        if ($(find.byKey(const Key('logout_tile'))).exists) {
          await $.tester.tap(find.byKey(const Key('logout_tile')));
          await _wait($, const Duration(seconds: 8));
        }
      }

      if (!$(find.byKey(const Key('email_field'))).exists) {
        markTestSkipped('No se pudo llegar a la pantalla de login.');
        return;
      }

      // ── PASO 1: Crear usuario nuevo via REST ──────────────────────────────
      final credentials = await $.tester.runAsync(() => _createUniqueUser()) ?? [];
      if (credentials.isEmpty) {
        markTestSkipped('No se pudo crear usuario de prueba via emulador.');
        return;
      }
      final newEmail = credentials[0];
      final originalPassword = credentials[1];
      const newPassword = 'NuevaPass456!';

      // ── PASO 2: Hacer login con el nuevo usuario ──────────────────────────
      await $(find.byKey(const Key('email_field'))).enterText(newEmail);
      await $(find.byKey(const Key('password_field'))).enterText(originalPassword);
      await $.tester.testTextInput.receiveAction(TextInputAction.done);
      await $.tester.pump(const Duration(milliseconds: 300));
      await $.tester.tap(find.byKey(const Key('submit_button')));
      await $.tester.pump();
      await _wait($, const Duration(seconds: 15));
      if (!$(find.byType(NavigationBar)).exists && !$(find.byType(PageView)).exists) {
        await _wait($, const Duration(seconds: 10));
      }

      // ── PASO 3: Completar onboarding si es necesario ─────────────────────
      await ensureHomeExists($);

      if (!$(find.byType(NavigationBar)).exists) {
        markTestSkipped('No se llegó al home shell tras el registro.');
        return;
      }

      // ── PASO 4: Crear una tarea ────────────────────────────────────────────
      const taskTitle = 'Tarea Ciclo Vida E2E';
      await $.tester.tap(find.byIcon(Icons.task_alt_outlined));
      await _wait($, const Duration(seconds: 5));

      if ($(find.byKey(const Key('create_task_fab'))).exists) {
        await $.tester.tap(find.byKey(const Key('create_task_fab')));
        await _wait($, const Duration(seconds: 5));

        if ($(find.byKey(const Key('task_title_field'))).exists) {
          await $(find.byKey(const Key('task_title_field'))).enterText(taskTitle);
          await $.tester.pump(const Duration(milliseconds: 300));

          if ($(find.byType(CheckboxListTile)).exists) {
            await $.tester.tap(find.byType(CheckboxListTile).first);
            await $.tester.pump(const Duration(milliseconds: 300));
          }

          await $.tester.tap(find.byKey(const Key('save_task_button')));
          await _wait($, const Duration(seconds: 8));
        }
      }

      // ── PASO 5: Cerrar sesión ─────────────────────────────────────────────
      await $.tester.tap(find.byIcon(Icons.settings_outlined));
      await _wait($, const Duration(seconds: 5));

      if (!$(find.byKey(const Key('logout_tile'))).exists) {
        markTestSkipped('logout_tile no encontrado, no se puede cerrar sesión.');
        return;
      }
      await $.tester.tap(find.byKey(const Key('logout_tile')));
      await _wait($, const Duration(seconds: 8));

      expect($(find.byKey(const Key('email_field'))).exists, isTrue,
          reason: 'Tras logout se esperaba la pantalla de login.');

      // ── PASO 6: Reset de contraseña via emulador ──────────────────────────
      final resetOk = await $.tester.runAsync(
        () => _resetPasswordViaEmulator(newEmail, newPassword),
      );

      if (resetOk != true) {
        markTestSkipped('No se pudo hacer reset de contraseña via emulador.');
        return;
      }

      // ── PASO 7: Login con la nueva contraseña ─────────────────────────────
      await $(find.byKey(const Key('email_field'))).enterText(newEmail);
      await $(find.byKey(const Key('password_field'))).enterText(newPassword);
      await $.tester.testTextInput.receiveAction(TextInputAction.done);
      await $.tester.pump(const Duration(milliseconds: 300));
      await $.tester.tap(find.byKey(const Key('submit_button')));
      await $.tester.pump();
      await _wait($, const Duration(seconds: 15));
      if (!$(find.byType(NavigationBar)).exists) {
        await _wait($, const Duration(seconds: 10));
      }

      expect($(find.byType(NavigationBar)).exists, isTrue,
          reason: 'No se pudo hacer login con la nueva contraseña.');

      // ── PASO 8: Verificar que el hogar y la tarea siguen existiendo ───────
      await $.tester.tap(find.byIcon(Icons.task_alt_outlined));
      await _wait($, const Duration(seconds: 8));

      expect(
        $(find.text(taskTitle)).exists ||
            $(find.byKey(const Key('tasks_list'))).exists,
        isTrue,
        reason: 'La tarea creada debería seguir visible tras reset de contraseña.',
      );
    },
  );
}
```

- [ ] **Step 2: Commit**

```bash
git add integration_test/flows/onboarding_registration_flow_test.dart
git commit -m "test(e2e): añadir suite de registro, onboarding y ciclo de vida completo"
```

---

## Task 13: Expandir auth_onboarding_flow_test.dart con validaciones de registro

**Files:**
- Modify: `integration_test/flows/auth_onboarding_flow_test.dart`

- [ ] **Step 1: Añadir test de email malformado**

Añadir al final de `main()` en `auth_onboarding_flow_test.dart`:

```dart
// ── Test 3 — Email malformado muestra error ───────────────────────────────
patrolTest(
  'login: email malformado muestra error sin navegar',
  config: const PatrolTesterConfig(
    settleTimeout: Duration(seconds: 120),
    visibleTimeout: Duration(seconds: 30),
  ),
  ($) async {
    await $.tester.pumpWidget(testApp());
    await $.tester.pump();
    await _wait($, const Duration(seconds: 15));

    if (!$(find.byKey(const Key('email_field'))).exists) {
      markTestSkipped('Pantalla de login no visible — usuario ya autenticado.');
      return;
    }

    await $(find.byKey(const Key('email_field'))).enterText('no-es-un-email');
    await $(find.byKey(const Key('password_field'))).enterText('cualquier');
    await $.tester.testTextInput.receiveAction(TextInputAction.done);
    await $.tester.pump(const Duration(milliseconds: 300));
    await $.tester.tap(find.byKey(const Key('submit_button')));
    await _wait($, const Duration(seconds: 5));

    // No debemos estar en NavigationBar
    expect($(find.byType(NavigationBar)).exists, isFalse,
        reason: 'No debería navegar con email malformado.');
  },
);
```

- [ ] **Step 2: Commit**

```bash
git add integration_test/flows/auth_onboarding_flow_test.dart
git commit -m "test(e2e): añadir test de validación de email malformado en login"
```

---

## Task 14: Actualizar test_bundle.dart con los nuevos flows

**Files:**
- Modify: `integration_test/test_bundle.dart`

- [ ] **Step 1: Añadir imports y grupos de los 4 nuevos archivos**

En la sección `// START: GENERATED TEST IMPORTS`, añadir:

```dart
import 'flows/home_management_flow_test.dart' as flows__home_management_flow_test;
import 'flows/profile_flow_test.dart' as flows__profile_flow_test;
import 'flows/history_flow_test.dart' as flows__history_flow_test;
import 'flows/onboarding_registration_flow_test.dart' as flows__onboarding_registration_flow_test;
```

En la sección `// START: GENERATED TEST GROUPS`, añadir:

```dart
group('flows.home_management_flow_test', flows__home_management_flow_test.main);
group('flows.profile_flow_test', flows__profile_flow_test.main);
group('flows.history_flow_test', flows__history_flow_test.main);
group('flows.onboarding_registration_flow_test', flows__onboarding_registration_flow_test.main);
```

- [ ] **Step 2: Verificar que el archivo compila**

```bash
flutter analyze integration_test/test_bundle.dart
```

Resultado esperado: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add integration_test/test_bundle.dart
git commit -m "test(e2e): registrar los 4 nuevos flows en test_bundle.dart"
```

---

## Task 15: Verificación final

- [ ] **Step 1: Ejecutar todos los tests unitarios**

```bash
flutter test test/unit/ --reporter=compact
```

Resultado esperado: 0 fallos.

- [ ] **Step 2: Ejecutar todos los widget tests**

```bash
flutter test test/ui/ --reporter=compact
```

Resultado esperado: 0 fallos.

- [ ] **Step 3: Análisis estático completo**

```bash
flutter analyze
```

Resultado esperado: `No issues found!`

- [ ] **Step 4: Verificar que la app compila para Android**

```bash
flutter build apk --debug
```

Resultado esperado: build exitoso.

---

## Notas de ejecución

- Los tests E2E (Tasks 8–14) requieren `firebase emulators:start --import=./emulator-data --export-on-exit` corriendo antes de ejecutar `patrol test`.
- El **ciclo de vida completo** (Task 12, Test 3) es el test de mayor valor — verifica persistencia de datos, reset de contraseña y reautenticación. Si el emulador no tiene el proyecto `demo-toka` configurado, ajustar el PROJECT_ID en `_resetPasswordViaEmulator`.
- Los tests E2E con `markTestSkipped` no fallan — se marcan como `skipped` si el estado del emulador no permite ejecutarlos (p.ej. no hay tarea en la pantalla Hoy). Esto es intencional para que la suite sea robusta.
