# Admin Permissions + Task Detail Fix Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corregir permisos de admin (bug), asegurar que el nombre del asignado siempre se muestre correctamente, y añadir los asignados en la lista de próximas fechas del detalle de tarea.

**Architecture:** Todos los cambios son en la capa de aplicación y presentación de Flutter. El rol del usuario se leerá desde `homeMembersProvider` (fuente autoritativa en `homes/{homeId}/members`) en lugar de `userMembershipsProvider` (copia denormalizada en `users/{uid}/memberships` que no se sincroniza al hacer promote). La rotación de asignados futuros se calcula localmente en el view model a partir de `assignmentOrder` y `currentAssigneeUid`. Las dos mejoras se implementan separadas para respetar el orden TDD.

**Tech Stack:** Flutter 3.x / Dart 3.x, Riverpod (riverpod_annotation), freezed, flutter_test

---

## File Map

| Archivo | Tipo | Cambio |
|---|---|---|
| `lib/features/tasks/application/task_detail_view_model.dart` | Modify | Añadir `UpcomingOccurrence` + cálculo rotación (Task 1); fix rol admin (Task 4) |
| `lib/features/tasks/application/all_tasks_view_model.dart` | Modify | Fix rol admin para `canCreate` (Task 6) |
| `lib/features/tasks/presentation/task_detail_screen.dart` | Modify | Mostrar `assigneeName` en próximas fechas (Task 1) |
| `test/unit/features/tasks/task_detail_view_model_test.dart` | Modify | Tests rotación (Task 2) + tests admin canManage (Task 3) |
| `test/unit/features/tasks/all_tasks_view_model_test.dart` | Modify | Tests admin canCreate (Task 5) |
| `test/ui/features/tasks/task_detail_screen_test.dart` | Modify | Actualizar tipo + test nombre asignado en upcoming (Task 7) |

---

## Task 1: UpcomingOccurrence + cálculo rotación + pantalla

> **Nota:** Este task solo añade `UpcomingOccurrence` y el cálculo de rotación. El fix del rol admin es un cambio independiente que ocurre en Task 4. El `canManage` sigue usando `userMembershipsProvider` temporalmente.

**Files:**
- Modify: `lib/features/tasks/application/task_detail_view_model.dart`
- Modify: `lib/features/tasks/presentation/task_detail_screen.dart`

- [ ] **Step 1: Reemplazar `task_detail_view_model.dart`**

```dart
// lib/features/tasks/application/task_detail_view_model.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/application/auth_provider.dart';
import '../../homes/application/current_home_provider.dart';
import '../../homes/application/homes_provider.dart';
import '../../homes/domain/home_membership.dart';
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
import '../domain/task.dart';
import '../domain/task_status.dart';
import 'recurrence_provider.dart';
import 'tasks_provider.dart';

part 'task_detail_view_model.g.dart';

class UpcomingOccurrence {
  const UpcomingOccurrence({required this.date, this.assigneeName});
  final DateTime date;
  final String? assigneeName;
}

class TaskDetailViewData {
  const TaskDetailViewData({
    required this.task,
    required this.canManage,
    required this.currentAssigneeName,
    required this.upcomingOccurrences,
  });
  final Task task;
  final bool canManage;
  final String? currentAssigneeName;
  final List<UpcomingOccurrence> upcomingOccurrences;

  bool get isFrozen => task.status == TaskStatus.frozen;
}

abstract class TaskDetailViewModel {
  AsyncValue<TaskDetailViewData?> get viewData;
  Future<void> toggleFreeze();
  Future<void> deleteTask();
}

class _TaskDetailViewModelImpl implements TaskDetailViewModel {
  const _TaskDetailViewModelImpl({required this.viewData, required this.ref});

  @override
  final AsyncValue<TaskDetailViewData?> viewData;
  final Ref ref;

  @override
  Future<void> toggleFreeze() async {
    final data = viewData.valueOrNull;
    if (data == null) return;
    final homeId = data.task.homeId;
    final repo = ref.read(tasksRepositoryProvider);
    if (data.isFrozen) {
      await repo.unfreezeTask(homeId, data.task.id);
    } else {
      await repo.freezeTask(homeId, data.task.id);
    }
  }

  @override
  Future<void> deleteTask() async {
    final data = viewData.valueOrNull;
    if (data == null) return;
    final homeId = data.task.homeId;
    final uid =
        ref.read(authProvider).whenOrNull(authenticated: (u) => u.uid) ?? '';
    await ref
        .read(tasksRepositoryProvider)
        .deleteTask(homeId, data.task.id, uid);
  }
}

// Calcula las próximas N ocurrencias con el asignado según rotación round-robin.
// Empieza por el siguiente después del currentAssigneeUid.
List<UpcomingOccurrence> _computeUpcomingOccurrences(
    Task task, List<DateTime> dates, List<Member> members) {
  final order = task.assignmentOrder;
  if (order.isEmpty) {
    return dates.map((d) => UpcomingOccurrence(date: d)).toList();
  }
  final currentUid = task.currentAssigneeUid;
  final currentIdx = currentUid != null ? order.indexOf(currentUid) : -1;
  return dates.asMap().entries.map((entry) {
    final i = entry.key;
    final nextIdx = currentIdx >= 0
        ? (currentIdx + 1 + i) % order.length
        : i % order.length;
    final uid = order[nextIdx];
    final member = members.where((m) => m.uid == uid).cast<Member?>().firstOrNull;
    final name =
        (member != null && member.nickname.isNotEmpty) ? member.nickname : null;
    return UpcomingOccurrence(date: entry.value, assigneeName: name);
  }).toList();
}

@riverpod
TaskDetailViewModel taskDetailViewModel(
    TaskDetailViewModelRef ref, String taskId) {
  final homeAsync = ref.watch(currentHomeProvider);
  final authState = ref.watch(authProvider);
  final uid = authState.whenOrNull(authenticated: (u) => u.uid) ?? '';

  final viewData = homeAsync.whenData((home) {
    if (home == null) return null;

    final tasksAsync = ref.watch(homeTasksProvider(home.id));
    final tasks = tasksAsync.valueOrNull ?? [];
    final task = tasks.where((t) => t.id == taskId).cast<Task?>().firstOrNull;
    if (task == null) return null;

    // --- rol (temporal: se migra a homeMembersProvider en Task 4) ---
    final membershipsAsync =
        uid.isNotEmpty ? ref.watch(userMembershipsProvider(uid)) : null;
    final memberships = membershipsAsync?.valueOrNull ?? [];
    final myMembership = memberships
        .where((m) => m.homeId == home.id)
        .cast<HomeMembership?>()
        .firstOrNull;
    final myRole = myMembership?.role;
    final canManage =
        myRole == MemberRole.owner || myRole == MemberRole.admin;

    // --- miembros para lookup de nombre y rotación upcoming ---
    final homeMembers =
        ref.watch(homeMembersProvider(home.id)).valueOrNull ?? [];

    final assigneeMember = task.currentAssigneeUid != null
        ? homeMembers
            .where((m) => m.uid == task.currentAssigneeUid)
            .cast<Member?>()
            .firstOrNull
        : null;
    final currentAssigneeName =
        assigneeMember != null && assigneeMember.nickname.isNotEmpty
            ? assigneeMember.nickname
            : null;

    final upcomingDates =
        ref.watch(upcomingOccurrencesProvider(task.recurrenceRule));
    final upcomingOccurrences = _computeUpcomingOccurrences(
        task, upcomingDates.take(3).toList(), homeMembers);

    return TaskDetailViewData(
      task: task,
      canManage: canManage,
      currentAssigneeName: currentAssigneeName,
      upcomingOccurrences: upcomingOccurrences,
    );
  });

  return _TaskDetailViewModelImpl(viewData: viewData, ref: ref);
}
```

- [ ] **Step 2: Actualizar la sección de próximas fechas en `task_detail_screen.dart`**

Localizar el bloque `upcomingOccurrences.map(...)` (alrededor de línea 154) y reemplazarlo:

```dart
              // ANTES:
              ...data.upcomingOccurrences.map(
                (d) => ListTile(
                  dense: true,
                  title: Text(
                    DateFormat.yMMMd().add_Hm().format(d.toLocal()),
                  ),
                ),
              ),

              // DESPUÉS:
              ...data.upcomingOccurrences.map(
                (occ) => ListTile(
                  dense: true,
                  title: Text(
                    DateFormat.yMMMd().add_Hm().format(occ.date.toLocal()),
                  ),
                  trailing: occ.assigneeName != null
                      ? Text(
                          occ.assigneeName!,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                ),
              ),
```

- [ ] **Step 3: Verificar compilación**

```bash
flutter analyze lib/features/tasks/
```

Resultado esperado: sin errores. Si hay warnings de imports no usados, eliminarlos.

- [ ] **Step 4: Commit**

```bash
git add lib/features/tasks/application/task_detail_view_model.dart \
        lib/features/tasks/presentation/task_detail_screen.dart
git commit -m "feat(tasks): UpcomingOccurrence con nombre de asignado en rotación"
```

---

## Task 2: Tests para rotación de asignados en upcoming

**Files:**
- Modify: `test/unit/features/tasks/task_detail_view_model_test.dart`

- [ ] **Step 1: Añadir imports al archivo de test existente**

Al inicio, después de los imports existentes:

```dart
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/tasks/application/recurrence_provider.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
```

- [ ] **Step 2: Añadir helpers después de las clases fake existentes**

```dart
class _FakeCurrentHomeWithData extends CurrentHome {
  _FakeCurrentHomeWithData(this._home);
  final Home _home;
  @override
  Future<Home?> build() async => _home;
  @override
  Future<void> switchHome(String id) async {}
}

Home _makeTestHome({String id = 'h1'}) => Home(
      id: id,
      name: 'Test Home',
      ownerUid: 'owner-uid',
      currentPayerUid: null,
      lastPayerUid: null,
      premiumStatus: HomePremiumStatus.free,
      premiumPlan: null,
      premiumEndsAt: null,
      restoreUntil: null,
      autoRenewEnabled: false,
      limits: const HomeLimits(maxMembers: 5, isPremium: false),
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

AuthUser _makeTestUser({String uid = 'uid1'}) => AuthUser(
      uid: uid,
      email: null,
      displayName: null,
      photoUrl: null,
      emailVerified: false,
      providers: const [],
    );

Task _makeTestTask({
  String id = 'task-1',
  String homeId = 'h1',
  String? currentAssigneeUid = 'uid-ana',
  List<String> assignmentOrder = const ['uid-ana', 'uid-paco'],
}) =>
    Task(
      id: id,
      homeId: homeId,
      title: 'Test Task',
      visualKind: 'emoji',
      visualValue: '🧹',
      status: TaskStatus.active,
      recurrenceRule: const RecurrenceRule.daily(
          every: 1, time: '09:00', timezone: 'UTC'),
      assignmentMode: 'basicRotation',
      assignmentOrder: assignmentOrder,
      currentAssigneeUid: currentAssigneeUid,
      nextDueAt: DateTime(2025, 6, 15, 9, 0),
      difficultyWeight: 1.0,
      completedCount90d: 0,
      createdByUid: 'uid1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

Member _makeTestMember({
  required String uid,
  String homeId = 'h1',
  required String nickname,
  MemberRole role = MemberRole.member,
}) =>
    Member(
      uid: uid,
      homeId: homeId,
      nickname: nickname,
      photoUrl: null,
      bio: null,
      phone: null,
      phoneVisibility: 'hidden',
      role: role,
      status: MemberStatus.active,
      joinedAt: DateTime(2025, 1, 1),
      tasksCompleted: 0,
      passedCount: 0,
      complianceRate: 1.0,
      currentStreak: 0,
      averageScore: 0.0,
    );

ProviderContainer _makeDetailContainer({
  required String actingUid,
  required Home home,
  required Task task,
  required List<Member> members,
  List<DateTime> upcomingDates = const [],
}) {
  final user = _makeTestUser(uid: actingUid);
  return ProviderContainer(overrides: [
    authProvider.overrideWith(
        () => _FakeAuth(AuthState.authenticated(user))),
    authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
    currentHomeProvider.overrideWith(() => _FakeCurrentHomeWithData(home)),
    localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
    homeTasksProvider(home.id).overrideWith((ref) => Stream.value([task])),
    homeMembersProvider(home.id).overrideWith((ref) => Stream.value(members)),
    upcomingOccurrencesProvider(task.recurrenceRule)
        .overrideWith((ref) => upcomingDates),
  ]);
}

Future<TaskDetailViewData?> _resolveDetailData(
    ProviderContainer container, Task task) async {
  await container.read(currentHomeProvider.future);
  await container.read(homeTasksProvider(task.homeId).future);
  await container.read(homeMembersProvider(task.homeId).future);
  final vm = container.read(taskDetailViewModelProvider(task.id));
  return vm.viewData.valueOrNull;
}
```

- [ ] **Step 3: Escribir tests de rotación en el grupo `TaskDetailViewModel`**

Dentro de `group('TaskDetailViewModel', ...)`, añadir:

```dart
    group('upcomingOccurrences rotación', () {
      test('primer upcoming es Paco cuando Ana es la asignada actual', () async {
        final home = _makeTestHome();
        final task = _makeTestTask(
          currentAssigneeUid: 'uid-ana',
          assignmentOrder: ['uid-ana', 'uid-paco'],
        );
        final members = [
          _makeTestMember(uid: 'uid-ana', nickname: 'Ana'),
          _makeTestMember(uid: 'uid-paco', nickname: 'Paco'),
        ];
        final dates = [
          DateTime(2025, 6, 16),
          DateTime(2025, 6, 17),
          DateTime(2025, 6, 18),
        ];

        final container = _makeDetailContainer(
          actingUid: 'uid-ana',
          home: home,
          task: task,
          members: members,
          upcomingDates: dates,
        );
        addTearDown(container.dispose);

        final data = await _resolveDetailData(container, task);

        expect(data, isNotNull);
        expect(data!.upcomingOccurrences, hasLength(3));
        expect(data.upcomingOccurrences[0].assigneeName, 'Paco');
        expect(data.upcomingOccurrences[1].assigneeName, 'Ana');
        expect(data.upcomingOccurrences[2].assigneeName, 'Paco');
      });

      test('upcoming con assignmentOrder vacío no tiene assigneeName', () async {
        final home = _makeTestHome();
        final task = _makeTestTask(
          currentAssigneeUid: null,
          assignmentOrder: [],
        );
        final container = _makeDetailContainer(
          actingUid: 'uid1',
          home: home,
          task: task,
          members: [],
          upcomingDates: [DateTime(2025, 6, 16)],
        );
        addTearDown(container.dispose);

        final data = await _resolveDetailData(container, task);

        expect(data, isNotNull);
        expect(data!.upcomingOccurrences[0].assigneeName, isNull);
      });

      test('upcoming preserva las fechas correctas', () async {
        final home = _makeTestHome();
        final task = _makeTestTask(
          currentAssigneeUid: 'uid-ana',
          assignmentOrder: ['uid-ana', 'uid-paco'],
        );
        final date1 = DateTime(2025, 6, 16, 9, 0);
        final date2 = DateTime(2025, 6, 17, 9, 0);

        final container = _makeDetailContainer(
          actingUid: 'uid-ana',
          home: home,
          task: task,
          members: [
            _makeTestMember(uid: 'uid-ana', nickname: 'Ana'),
            _makeTestMember(uid: 'uid-paco', nickname: 'Paco'),
          ],
          upcomingDates: [date1, date2],
        );
        addTearDown(container.dispose);

        final data = await _resolveDetailData(container, task);

        expect(data!.upcomingOccurrences[0].date, date1);
        expect(data.upcomingOccurrences[1].date, date2);
      });
    });
```

- [ ] **Step 4: Ejecutar tests**

```bash
flutter test test/unit/features/tasks/task_detail_view_model_test.dart -v
```

Resultado esperado: PASS en todos los tests.

- [ ] **Step 5: Commit**

```bash
git add test/unit/features/tasks/task_detail_view_model_test.dart
git commit -m "test(tasks): tests de rotación de asignados en upcomingOccurrences"
```

---

## Task 3: Test fallido — admin ve canManage=true en task_detail

**Files:**
- Modify: `test/unit/features/tasks/task_detail_view_model_test.dart`

- [ ] **Step 1: Añadir tests de canManage por rol en el grupo `TaskDetailViewModel`**

```dart
    group('canManage por rol', () {
      Future<bool?> _canManageFor(MemberRole role) async {
        const homeId = 'h1';
        const uid = 'uid-test';
        final home = _makeTestHome(id: homeId);
        final task = _makeTestTask(
          homeId: homeId,
          currentAssigneeUid: uid,
          assignmentOrder: [uid],
        );
        final members = [
          _makeTestMember(uid: uid, nickname: 'Test User', role: role),
        ];
        final container = _makeDetailContainer(
          actingUid: uid,
          home: home,
          task: task,
          members: members,
        );
        addTearDown(container.dispose);
        final data = await _resolveDetailData(container, task);
        return data?.canManage;
      }

      test('admin ve canManage = true', () async {
        expect(await _canManageFor(MemberRole.admin), isTrue);
      });

      test('owner ve canManage = true', () async {
        expect(await _canManageFor(MemberRole.owner), isTrue);
      });

      test('member ve canManage = false', () async {
        expect(await _canManageFor(MemberRole.member), isFalse);
      });
    });
```

- [ ] **Step 2: Ejecutar y verificar que el test de admin FALLA**

```bash
flutter test test/unit/features/tasks/task_detail_view_model_test.dart \
  --name "admin ve canManage" -v
```

Resultado esperado: FAIL — `canManage` es `false` aunque el miembro tiene `role: admin`, porque el código aún lee el rol de `userMembershipsProvider` donde el campo no está sincronizado.

- [ ] **Step 3: Commit del test fallido**

```bash
git add test/unit/features/tasks/task_detail_view_model_test.dart
git commit -m "test(tasks): test fallido — admin debe ver canManage=true"
```

---

## Task 4: Fix admin canManage en task_detail_view_model

**Files:**
- Modify: `lib/features/tasks/application/task_detail_view_model.dart`

- [ ] **Step 1: Reemplazar el bloque de rol en `taskDetailViewModel`**

En `task_detail_view_model.dart`, localizar el bloque marcado como `// --- rol (temporal...)` y el bloque de `homeMembers`, y reemplazar ambos por:

```dart
    // --- miembros: fuente para rol Y para lookup de nombre y rotación ---
    final homeMembersAsync = ref.watch(homeMembersProvider(home.id));
    final homeMembers = homeMembersAsync.valueOrNull;
    if (homeMembers == null) return null; // esperando primera emisión

    final myMember = homeMembers
        .where((m) => m.uid == uid)
        .cast<Member?>()
        .firstOrNull;
    final canManage = myMember?.role == MemberRole.owner ||
        myMember?.role == MemberRole.admin;
```

El bloque antiguo a eliminar (dentro de `whenData`):

```dart
    // --- rol (temporal: se migra a homeMembersProvider en Task 4) ---
    final membershipsAsync =
        uid.isNotEmpty ? ref.watch(userMembershipsProvider(uid)) : null;
    final memberships = membershipsAsync?.valueOrNull ?? [];
    final myMembership = memberships
        .where((m) => m.homeId == home.id)
        .cast<HomeMembership?>()
        .firstOrNull;
    final myRole = myMembership?.role;
    final canManage =
        myRole == MemberRole.owner || myRole == MemberRole.admin;

    // --- miembros para lookup de nombre y rotación upcoming ---
    final homeMembers =
        ref.watch(homeMembersProvider(home.id)).valueOrNull ?? [];
```

- [ ] **Step 2: Eliminar imports que ya no se usan**

En los imports de `task_detail_view_model.dart`, eliminar:

```dart
import '../../homes/application/homes_provider.dart';   // solo se usaba para userMembershipsProvider
import '../../homes/domain/home_membership.dart';        // HomeMembership ya no se usa; MemberRole viene de member.dart indirectamente
```

Verificar que `MemberRole` sigue accesible. `MemberRole` está en `home_membership.dart` e importado transitivamente desde `member.dart`. Si el compilador lo requiere explícitamente, mantener:

```dart
import '../../homes/domain/home_membership.dart'; // para MemberRole
```

- [ ] **Step 3: Verificar compilación**

```bash
flutter analyze lib/features/tasks/application/task_detail_view_model.dart
```

Resultado esperado: sin errores.

- [ ] **Step 4: Ejecutar tests**

```bash
flutter test test/unit/features/tasks/task_detail_view_model_test.dart -v
```

Resultado esperado: PASS en todos, incluyendo "admin ve canManage = true".

- [ ] **Step 5: Commit**

```bash
git add lib/features/tasks/application/task_detail_view_model.dart
git commit -m "fix(tasks): canManage lee rol de homeMembersProvider en task_detail_view_model"
```

---

## Task 5: Test fallido — admin ve canCreate=true en all_tasks

**Files:**
- Modify: `test/unit/features/tasks/all_tasks_view_model_test.dart`

- [ ] **Step 1: Añadir imports**

Al inicio del archivo:

```dart
import 'package:flutter/material.dart';
import 'package:toka/features/auth/application/auth_provider.dart';
import 'package:toka/features/auth/application/auth_state.dart';
import 'package:toka/features/auth/domain/auth_user.dart';
import 'package:toka/features/homes/application/current_home_provider.dart';
import 'package:toka/features/homes/domain/home.dart';
import 'package:toka/features/homes/domain/home_limits.dart';
import 'package:toka/features/homes/domain/home_membership.dart';
import 'package:toka/features/i18n/application/locale_provider.dart';
import 'package:toka/features/members/application/members_provider.dart';
import 'package:toka/features/members/domain/member.dart';
import 'package:toka/features/tasks/application/tasks_provider.dart';
import 'package:toka/features/tasks/domain/recurrence_rule.dart';
import 'package:toka/features/tasks/domain/task.dart';
import 'package:toka/features/tasks/domain/task_status.dart';
```

- [ ] **Step 2: Añadir clases fake y helpers después de los imports**

```dart
class _FakeAuth extends Auth {
  _FakeAuth(this._state);
  final AuthState _state;
  @override
  AuthState build() => _state;
}

class _FakeCurrentHome extends CurrentHome {
  _FakeCurrentHome(this._home);
  final Home? _home;
  @override
  Future<Home?> build() async => _home;
  @override
  Future<void> switchHome(String id) async {}
}

class _FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('es');
  @override
  Future<void> initialize(String? uid) async {}
  @override
  Future<void> setLocale(String code, String? uid) async {}
}

Home _makeAllTasksHome({String id = 'h1'}) => Home(
      id: id,
      name: 'Test Home',
      ownerUid: 'owner-uid',
      currentPayerUid: null,
      lastPayerUid: null,
      premiumStatus: HomePremiumStatus.free,
      premiumPlan: null,
      premiumEndsAt: null,
      restoreUntil: null,
      autoRenewEnabled: false,
      limits: const HomeLimits(maxMembers: 5, isPremium: false),
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

Member _makeAllTasksMember({
  required String uid,
  required MemberRole role,
}) =>
    Member(
      uid: uid,
      homeId: 'h1',
      nickname: 'Test',
      photoUrl: null,
      bio: null,
      phone: null,
      phoneVisibility: 'hidden',
      role: role,
      status: MemberStatus.active,
      joinedAt: DateTime(2025, 1, 1),
      tasksCompleted: 0,
      passedCount: 0,
      complianceRate: 1.0,
      currentStreak: 0,
      averageScore: 0.0,
    );

Task _makeAllTasksTask({String homeId = 'h1'}) => Task(
      id: 'task-1',
      homeId: homeId,
      title: 'Test',
      visualKind: 'emoji',
      visualValue: '🧹',
      status: TaskStatus.active,
      recurrenceRule: const RecurrenceRule.daily(
          every: 1, time: '09:00', timezone: 'UTC'),
      assignmentMode: 'basicRotation',
      assignmentOrder: const [],
      currentAssigneeUid: null,
      nextDueAt: DateTime(2025, 6, 15),
      difficultyWeight: 1.0,
      completedCount90d: 0,
      createdByUid: 'uid1',
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

Future<bool?> _resolveCanCreate({
  required String uid,
  required MemberRole role,
}) async {
  const homeId = 'h1';
  final home = _makeAllTasksHome(id: homeId);
  final user = AuthUser(
    uid: uid,
    email: null,
    displayName: null,
    photoUrl: null,
    emailVerified: false,
    providers: const [],
  );
  final member = _makeAllTasksMember(uid: uid, role: role);
  final task = _makeAllTasksTask(homeId: homeId);

  final container = ProviderContainer(overrides: [
    authProvider
        .overrideWith(() => _FakeAuth(AuthState.authenticated(user))),
    authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
    currentHomeProvider.overrideWith(() => _FakeCurrentHome(home)),
    localeNotifierProvider.overrideWith(() => _FakeLocaleNotifier()),
    homeTasksProvider(homeId).overrideWith((ref) => Stream.value([task])),
    homeMembersProvider(homeId).overrideWith((ref) => Stream.value([member])),
  ]);
  addTearDown(container.dispose);

  await container.read(currentHomeProvider.future);
  await container.read(homeTasksProvider(homeId).future);
  await container.read(homeMembersProvider(homeId).future);

  final vm = container.read(allTasksViewModelProvider);
  return vm.viewData.valueOrNull?.canCreate;
}
```

- [ ] **Step 3: Añadir grupo de tests en `main()`**

```dart
  group('AllTasksViewModel canCreate', () {
    test('admin ve canCreate = true', () async {
      expect(await _resolveCanCreate(uid: 'uid-admin', role: MemberRole.admin),
          isTrue);
    });

    test('owner ve canCreate = true', () async {
      expect(await _resolveCanCreate(uid: 'uid-owner', role: MemberRole.owner),
          isTrue);
    });

    test('member ve canCreate = false', () async {
      expect(
          await _resolveCanCreate(uid: 'uid-member', role: MemberRole.member),
          isFalse);
    });
  });
```

- [ ] **Step 4: Ejecutar y verificar que el test de admin FALLA**

```bash
flutter test test/unit/features/tasks/all_tasks_view_model_test.dart \
  --name "admin ve canCreate" -v
```

Resultado esperado: FAIL — admin recibe `canCreate = false` porque el código aún usa `userMembershipsProvider`.

- [ ] **Step 5: Commit**

```bash
git add test/unit/features/tasks/all_tasks_view_model_test.dart
git commit -m "test(tasks): test fallido — admin debe ver canCreate=true en all_tasks"
```

---

## Task 6: Fix admin canCreate en all_tasks_view_model

**Files:**
- Modify: `lib/features/tasks/application/all_tasks_view_model.dart`

- [ ] **Step 1: Actualizar imports**

Eliminar:

```dart
import '../../homes/application/homes_provider.dart';
```

Añadir:

```dart
import '../../members/application/members_provider.dart';
import '../../members/domain/member.dart';
```

Mantener (necesario para `MemberRole`):

```dart
import '../../homes/domain/home_membership.dart';
```

- [ ] **Step 2: Reemplazar bloque de rol en `allTasksViewModel`**

Dentro de la función `allTasksViewModel`, en el `whenData`, localizar:

```dart
    final membershipsAsync =
        uid.isNotEmpty ? ref.watch(userMembershipsProvider(uid)) : null;
    final memberships = membershipsAsync?.valueOrNull ?? [];
    final myMembership = memberships
        .where((m) => m.homeId == home.id)
        .cast<HomeMembership?>()
        .firstOrNull;
    final myRole = myMembership?.role;
    final canCreate =
        myRole == MemberRole.owner || myRole == MemberRole.admin;
```

Reemplazar por:

```dart
    final homeMembers =
        ref.watch(homeMembersProvider(home.id)).valueOrNull ?? [];
    final myMember = homeMembers
        .where((m) => m.uid == uid)
        .cast<Member?>()
        .firstOrNull;
    final canCreate = myMember?.role == MemberRole.owner ||
        myMember?.role == MemberRole.admin;
```

- [ ] **Step 3: Eliminar `HomeMembership` si ya no se usa**

Buscar en el archivo si `HomeMembership` se usa en algún otro lugar. Si no, se puede eliminar su import; pero `MemberRole` sigue en `home_membership.dart` y debe mantenerse.

- [ ] **Step 4: Verificar compilación**

```bash
flutter analyze lib/features/tasks/application/all_tasks_view_model.dart
```

Resultado esperado: sin errores.

- [ ] **Step 5: Ejecutar todos los tests del archivo**

```bash
flutter test test/unit/features/tasks/all_tasks_view_model_test.dart -v
```

Resultado esperado: PASS en todos, incluyendo "admin ve canCreate = true".

- [ ] **Step 6: Commit**

```bash
git add lib/features/tasks/application/all_tasks_view_model.dart
git commit -m "fix(tasks): canCreate lee rol de homeMembersProvider en all_tasks_view_model"
```

---

## Task 7: Actualizar tests UI del detalle de tarea

**Files:**
- Modify: `test/ui/features/tasks/task_detail_screen_test.dart`

- [ ] **Step 1: Verificar que los tests existentes compilan**

Los tests existentes pasan `upcomingOccurrences: []`. El literal `[]` es compatible con `List<UpcomingOccurrence>`, por lo que no requieren cambios.

```bash
flutter test test/ui/features/tasks/task_detail_screen_test.dart -v
```

Resultado esperado: PASS en todos los tests existentes sin cambios.

- [ ] **Step 2: Añadir import de `UpcomingOccurrence` en el test**

`UpcomingOccurrence` está en `task_detail_view_model.dart`, que ya está importado. No se necesita import adicional.

- [ ] **Step 3: Añadir tests para upcoming con nombre de asignado**

Al final del `main()`:

```dart
  testWidgets('muestra el nombre del asignado en próximas fechas',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canManage: false,
      currentAssigneeName: null,
      upcomingOccurrences: [
        UpcomingOccurrence(
          date: DateTime(2025, 6, 16, 9, 0),
          assigneeName: 'Paco',
        ),
        UpcomingOccurrence(
          date: DateTime(2025, 6, 17, 9, 0),
          assigneeName: null,
        ),
      ],
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    expect(find.text('Paco'), findsOneWidget);
  });

  testWidgets(
      'no muestra trailing cuando assigneeName es null en próximas fechas',
      (tester) async {
    final vm = _DataViewModel(TaskDetailViewData(
      task: _makeTask(),
      canManage: false,
      currentAssigneeName: null,
      upcomingOccurrences: [
        UpcomingOccurrence(
          date: DateTime(2025, 6, 16, 9, 0),
          assigneeName: null,
        ),
      ],
    ));
    await tester.pumpWidget(_wrap(vm));
    await tester.pumpAndSettle();

    // Hay un ListTile denso (próximas fechas) pero sin trailing Text
    expect(find.descendant(
      of: find.byType(ListTile),
      matching: find.text('Paco'),
    ), findsNothing);
  });
```

- [ ] **Step 4: Ejecutar todos los tests UI de task_detail**

```bash
flutter test test/ui/features/tasks/task_detail_screen_test.dart -v
```

Resultado esperado: PASS en todos.

- [ ] **Step 5: Commit**

```bash
git add test/ui/features/tasks/task_detail_screen_test.dart
git commit -m "test(tasks): tests UI para assigneeName en upcoming y admin canManage"
```

---

## Task 8: Verificación final

- [ ] **Step 1: Todos los tests unitarios de tasks**

```bash
flutter test test/unit/features/tasks/ -v
```

Resultado esperado: PASS en todos.

- [ ] **Step 2: Todos los tests UI de tasks**

```bash
flutter test test/ui/features/tasks/ -v
```

Resultado esperado: PASS en todos.

- [ ] **Step 3: Análisis estático completo de la feature**

```bash
flutter analyze lib/features/tasks/
```

Resultado esperado: No issues found.

---

## Notas para el implementador

### Por qué `userMembershipsProvider` no se elimina de todo el código
`currentHomeProvider` usa `userMembershipsProvider` para listar los hogares del usuario — ese uso es correcto y no se toca. Solo los view models de tasks lo usaban para el rol, que es el bug.

### Por qué `canManage` retorna null mientras cargan los miembros (Task 4)
Con `if (homeMembers == null) return null`, el view model muestra loading mientras `homeMembersProvider` emite su primera lista. Esto elimina el flash de "—" y los botones ausentes al abrir el detalle por primera vez.

### Rotación en `_computeUpcomingOccurrences`
La función usa el round-robin simple sobre `assignmentOrder` sin excluir miembros en vacaciones/frozen. Para el display del detalle de tarea es suficiente — la lógica real de asignación con exclusiones vive en el backend.

### `UpcomingOccurrence` no es freezed
Es una clase de dato simple de solo lectura (`const`). Freezed sería over-engineering para una clase con dos campos que solo vive en el view model.
